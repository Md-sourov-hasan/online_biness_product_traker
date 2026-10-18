import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../models/notification_item.dart';

class NotificationsController extends GetxController {
  static NotificationsController get to => Get.find<NotificationsController>();

  final DatabaseService _db = Get.find<DatabaseService>();
  final AuthService _auth = Get.find<AuthService>();

  final RxList<AppNotificationItem> notifications = <AppNotificationItem>[].obs;
  final RxSet<String> readNotificationIds = <String>{}.obs;
  final RxSet<String> dismissedNotificationIds = <String>{}.obs;
  final RxString selectedFilter = 'all'.obs; // 'all', 'alerts', 'pending', 'activity'

  static const String _readKey = 'sm_read_notification_ids';
  static const String _dismissedKey = 'sm_dismissed_notification_ids';

  @override
  void onInit() {
    super.onInit();
    _loadPersistedState();
    _buildNotifications();

    // Rebuild when underlying reactive stores update
    ever(_db.products, (_) => _buildNotifications());
    ever(_db.users, (_) => _buildNotifications());
    ever(_db.receivables, (_) => _buildNotifications());
    ever(_db.activityLogs, (_) => _buildNotifications());
    ever(_auth.currentUser, (_) => _buildNotifications());
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList(_readKey) ?? [];
      readNotificationIds.assignAll(readList);

      final dismissedList = prefs.getStringList(_dismissedKey) ?? [];
      dismissedNotificationIds.assignAll(dismissedList);
      _buildNotifications();
    } catch (e) {
      debugPrint('Error loading notification state: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey, readNotificationIds.toList());
      await prefs.setStringList(_dismissedKey, dismissedNotificationIds.toList());
    } catch (e) {
      debugPrint('Error saving notification state: $e');
    }
  }

  void _buildNotifications() {
    final List<AppNotificationItem> items = [];

    // 1. Low Stock Alerts
    for (final product in _db.products) {
      if (product.quantity <= product.lowStockThreshold) {
        final notifId = 'low_stock_${product.id}_${product.quantity}';
        if (!dismissedNotificationIds.contains(notifId)) {
          final isZero = product.quantity <= 0;
          items.add(
            AppNotificationItem(
              id: notifId,
              title: isZero ? 'Out of Stock! 🚨' : 'Low Stock Warning ⚠️',
              message: '${product.name} (${product.brandName}) only has ${product.quantity} units left (Threshold: ${product.lowStockThreshold}). Please restock.',
              timestamp: DateTime.now().subtract(Duration(minutes: (product.quantity + 1) * 3)),
              type: NotificationType.lowStock,
              priority: isZero ? NotificationPriority.high : NotificationPriority.medium,
              route: AppRoute.addEditProductScreen,
              routeExtra: product,
              isRead: readNotificationIds.contains(notifId),
            ),
          );
        }
      }
    }

    // 2. Pending User Approvals (Owner/Admin)
    if (_auth.currentUser.value?.isOwner ?? true) {
      final pendingUsers = _db.users.where((u) => u.approvalStatus == 'pending').toList();
      for (final user in pendingUsers) {
        final notifId = 'pending_user_${user.id}';
        if (!dismissedNotificationIds.contains(notifId)) {
          items.add(
            AppNotificationItem(
              id: notifId,
              title: 'Pending Staff Approval 👤',
              message: '${user.name} (${user.email}) requested ${user.role} role access. Tap to review.',
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              type: NotificationType.pendingApproval,
              priority: NotificationPriority.high,
              route: AppRoute.userManagementScreen,
              isRead: readNotificationIds.contains(notifId),
            ),
          );
        }
      }
    }

    // 3. Receivables & Overdue Debt Alert
    final now = DateTime.now();
    for (final rec in _db.receivables) {
      final isOverdue = now.isAfter(rec.dueDate) && rec.status != 'returned';
      final isUpcoming = rec.dueDate.difference(now).inDays <= 3 && rec.status != 'returned';

      if (isOverdue || isUpcoming) {
        final notifId = 'receivable_${rec.id}';
        if (!dismissedNotificationIds.contains(notifId)) {
          items.add(
            AppNotificationItem(
              id: notifId,
              title: isOverdue ? 'Overdue Receivable Due! ⏱️' : 'Payment Due Soon 💳',
              message: '${rec.borrower} owes ৳${rec.amountLent.toStringAsFixed(1)} (Purpose: ${rec.purpose.isEmpty ? "General" : rec.purpose}).',
              timestamp: rec.dueDate,
              type: NotificationType.receivableDue,
              priority: isOverdue ? NotificationPriority.high : NotificationPriority.medium,
              route: AppRoute.moneyLentScreen,
              isRead: readNotificationIds.contains(notifId),
            ),
          );
        }
      }
    }

    // 4. Critical & Recent Activity Logs (Sales, large refunds, policy updates)
    final recentLogs = _db.activityLogs.take(10);
    for (final log in recentLogs) {
      final notifId = 'activity_${log.id}';
      if (!dismissedNotificationIds.contains(notifId)) {
        NotificationType notifType = NotificationType.activityLog;
        NotificationPriority priority = NotificationPriority.low;

        if (log.type.toLowerCase().contains('sale')) {
          notifType = NotificationType.sale;
        } else if (log.type.toLowerCase().contains('purchase')) {
          notifType = NotificationType.purchase;
        } else if (log.title.toLowerCase().contains('refund') || log.title.toLowerCase().contains('delete')) {
          priority = NotificationPriority.medium;
        }

        items.add(
          AppNotificationItem(
            id: notifId,
            title: log.title,
            message: '${log.description}${log.performedBy != null ? " • by ${log.performedBy}" : ""}',
            timestamp: log.timestamp,
            type: notifType,
            priority: priority,
            route: AppRoute.activityLogsScreen,
            isRead: readNotificationIds.contains(notifId),
          ),
        );
      }
    }

    // Sort by timestamp descending
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifications.assignAll(items);
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<AppNotificationItem> get filteredNotifications {
    final filter = selectedFilter.value;
    if (filter == 'alerts') {
      return notifications
          .where((n) => n.type == NotificationType.lowStock || n.type == NotificationType.receivableDue)
          .toList();
    } else if (filter == 'pending') {
      return notifications
          .where((n) => n.type == NotificationType.pendingApproval)
          .toList();
    } else if (filter == 'activity') {
      return notifications
          .where((n) =>
              n.type == NotificationType.sale ||
              n.type == NotificationType.system ||
              n.type == NotificationType.purchase ||
              n.type == NotificationType.activityLog)
          .toList();
    }
    return notifications;
  }

  void markAsRead(String id) {
    readNotificationIds.add(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
    _persistState();
  }

  void markAllAsRead() {
    for (final notif in notifications) {
      readNotificationIds.add(notif.id);
      notif.isRead = true;
    }
    notifications.refresh();
    _persistState();
  }

  void dismissNotification(String id) {
    dismissedNotificationIds.add(id);
    notifications.removeWhere((n) => n.id == id);
    _persistState();
  }

  void clearAll() {
    for (final notif in notifications) {
      dismissedNotificationIds.add(notif.id);
    }
    notifications.clear();
    _persistState();
  }

  void refreshAll() {
    _buildNotifications();
  }
}
