import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../models/notification_item.dart';
import '../models/notification_settings_model.dart';

class NotificationsController extends GetxController {
  static NotificationsController get to => Get.find<NotificationsController>();

  final DatabaseService _db = Get.find<DatabaseService>();
  final AuthService _auth = Get.find<AuthService>();

  final RxList<AppNotificationItem> allNotifications = <AppNotificationItem>[].obs;
  final Rx<NotificationSettingsModel> settings = NotificationSettingsModel().obs;
  final RxString selectedFilter = 'all'.obs; // 'all', 'alerts', 'pending', 'activity'

  static const String _notificationsStorageKey = 'sm_persisted_notifications_v2';
  static const String _settingsPrefix = 'sm_notif_settings_';

  @override
  void onInit() {
    super.onInit();
    _loadState();

    // Rebuild/refresh when auth user or underlying DB updates
    ever(_auth.currentUser, (user) {
      _loadSettingsForUser(user);
    });

    ever(_db.products, (_) => _syncSystemAlerts());
    ever(_db.users, (_) => _syncSystemAlerts());
    ever(_db.receivables, (_) => _syncSystemAlerts());
    ever(_db.loans, (_) => _syncSystemAlerts());
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(_notificationsStorageKey);

      if (storedJson != null && storedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(storedJson);
        final items = list.map((m) => AppNotificationItem.fromMap(m as Map<String, dynamic>)).toList();
        allNotifications.assignAll(items);
      } else {
        _seedInitialNotifications();
      }

      await _loadSettingsForUser(_auth.currentUser.value);
    } catch (e) {
      debugPrint('Error loading notifications state: $e');
      _seedInitialNotifications();
    }
  }

  Future<void> _loadSettingsForUser(AppUser? user) async {
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix${user.id}';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        settings.value = NotificationSettingsModel.fromJson(jsonStr);
      } else {
        settings.value = NotificationSettingsModel();
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
      settings.value = NotificationSettingsModel();
    }
  }

  Future<void> saveSettings() async {
    final user = _auth.currentUser.value;
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix${user.id}';
      await prefs.setString(key, settings.value.toJson());
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = allNotifications.map((n) => n.toMap()).toList();
      await prefs.setString(_notificationsStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void _seedInitialNotifications() {
    final now = DateTime.now();
    final items = [
      // USR-01: Account waiting approval (Owner only)
      AppNotificationItem(
        id: 'init_usr_01',
        code: 'USR-01',
        title: 'New Account Waiting Approval 👤',
        message: 'Kawsar Ahmed requested Staff access from Mobile Terminal #2.',
        timestamp: now.subtract(const Duration(minutes: 18)),
        type: NotificationType.pendingApproval,
        priority: NotificationPriority.high,
        route: AppRoute.userManagementScreen,
        recipientRole: 'Owner',
        actorName: 'Kawsar Ahmed',
        actorRole: 'Staff',
      ),
      // SAL-01 / STF-01: Staff sale completed
      AppNotificationItem(
        id: 'init_sal_01',
        code: 'SAL-01',
        title: 'New Sale Completed 🛍️',
        message: 'Staff member Tanvir processed a sale of 2 items totaling ৳1,450.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        type: NotificationType.sale,
        priority: NotificationPriority.low,
        route: AppRoute.bottomNavigationScreen,
        actorUserId: 'staff_tanvir',
        actorRole: 'Staff',
        actorName: 'Tanvir',
        recipientRole: 'Owner', // Also visible to Manager
        metadata: {'profit': 420.0, 'items': 2, 'total': 1450.0},
      ),
      // STF-01: Staff confirmation for Tanvir
      AppNotificationItem(
        id: 'init_stf_01',
        code: 'STF-01',
        title: 'Sale Successfully Saved ✅',
        message: 'Your sale of 2 items totaling ৳1,450 was recorded.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        type: NotificationType.sale,
        priority: NotificationPriority.low,
        recipientRole: 'Staff',
        recipientUserId: 'staff_1',
        actorUserId: 'staff_1',
        isSelfConfirmation: true,
      ),
      // STK-01: Low stock alert
      AppNotificationItem(
        id: 'init_stk_01',
        code: 'STK-01',
        title: 'Low Stock Alert ⚠️',
        message: 'Premium Wireless Mouse is below threshold (4 units remaining).',
        timestamp: now.subtract(const Duration(hours: 3)),
        type: NotificationType.lowStock,
        priority: NotificationPriority.medium,
        route: AppRoute.addEditProductScreen,
        recipientRole: 'all',
      ),
      // MNY-01: Loan payment due (Owner only)
      AppNotificationItem(
        id: 'init_mny_01',
        code: 'MNY-01',
        title: 'Loan Installment Due Soon 🏦',
        message: 'Commercial Bank installment of ৳15,000 is due in 3 days.',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.money,
        priority: NotificationPriority.high,
        route: AppRoute.loanManagementScreen,
        recipientRole: 'Owner',
      ),
      // DSC-01: Discount request from Manager (Owner only)
      AppNotificationItem(
        id: 'init_dsc_01',
        code: 'DSC-01',
        title: 'Discount Approval Requested 🏷️',
        message: 'Manager requested a 12% Flash Promo discount on Electronics.',
        timestamp: now.subtract(const Duration(hours: 6)),
        type: NotificationType.discount,
        priority: NotificationPriority.high,
        route: AppRoute.discountManagementScreen,
        recipientRole: 'Owner',
        actorRole: 'Manager',
        actorName: 'Store Manager',
      ),
    ];

    allNotifications.assignAll(items);
    _persistNotifications();
  }

  // ---------------------------------------------------------------------------
  // Central Shared Recipient Determination (Specification Section 1 & Section 6)
  // ---------------------------------------------------------------------------
  static bool isNotificationForUser({
    required AppNotificationItem item,
    required AppUser? user,
    required NotificationSettingsModel currentSettings,
  }) {
    if (user == null) return false;

    // 1. Specific recipient user check
    if (item.recipientUserId != null &&
        item.recipientUserId!.isNotEmpty &&
        item.recipientUserId != user.id) {
      return false;
    }

    // 2. Suppress own actions unless it is a designated confirmation alert
    if (item.actorUserId != null &&
        item.actorUserId == user.id &&
        !item.isSelfConfirmation) {
      return false;
    }

    // 3. STAFF User Rules (Spec Section 4)
    // "Staff must not see profit, purchase cost, loans, investors or other people's entries."
    if (user.isStaff) {
      // Must be a Staff specific code or targeted directly to this staff user
      final isStaffCode = item.code.startsWith('STF-');
      final isTargetedToStaff = item.recipientRole == 'Staff' || item.recipientUserId == user.id;

      if (!isStaffCode && !isTargetedToStaff) {
        return false;
      }

      if (!currentSettings.staffMasterSwitch) {
        // Allow critical in-app blocks (STF-05, STF-07), mute optional inbox notifications
        if (item.code != 'STF-05' && item.code != 'STF-07') {
          return false;
        }
      }

      if (item.code == 'STF-06' && !currentSettings.endOfDayReminder) {
        return false;
      }

      return true;
    }

    // 4. MANAGER User Rules (Spec Section 3)
    // "The Manager does not receive Owner actions, loans, money lent, investor changes, policy changes, user/device approvals, daily summaries or backup reminders."
    if (user.isManager) {
      // Always on: Discount request result (DSC-02)
      if (item.code == 'DSC-02') {
        return true;
      }

      // Manager's own confirmation alerts
      if (item.isSelfConfirmation && item.actorUserId == user.id) {
        return currentSettings.myActions;
      }

      // Stock alerts (STK-01, STK-02)
      if (item.code == 'STK-01' || item.code == 'STK-02') {
        return currentSettings.stockAlerts;
      }

      // Staff sale alerts (SAL-01, SAL-04, SAL-05) - only if performed by Staff
      if ((item.code == 'SAL-01' || item.code == 'SAL-04' || item.code == 'SAL-05') &&
          item.actorRole?.toLowerCase() == 'staff') {
        return currentSettings.staffSalesAndReturns;
      }

      // Staff returns/exchanges (RET-01, RET-02, RET-03) - only if performed by Staff
      if ((item.code == 'RET-01' || item.code == 'RET-02' || item.code == 'RET-03') &&
          item.actorRole?.toLowerCase() == 'staff') {
        return currentSettings.staffSalesAndReturns;
      }

      // Staff expenses (EXP-01, EXP-02) - only if submitted by Staff
      if ((item.code == 'EXP-01' || item.code == 'EXP-02') &&
          item.actorRole?.toLowerCase() == 'staff') {
        return currentSettings.staffExpenses;
      }

      // All other notifications are forbidden for Manager
      return false;
    }

    // 5. OWNER User Rules (Spec Section 2)
    if (user.isOwner) {
      // Staff-only codes (STF-*) and Manager discount result (DSC-02) are not for Owner
      if (item.code.startsWith('STF-') || item.code == 'DSC-02') {
        return false;
      }

      if (!currentSettings.masterSwitch) {
        // Pending approvals remain visible
        if (item.code == 'USR-01') return true;
        return false;
      }

      // Recipient filter evaluation
      final filter = currentSettings.recipientFilter;
      if (filter == 'manager_only' && item.actorRole?.toLowerCase() == 'staff') {
        return false;
      }
      if (filter == 'staff_only' && item.actorRole?.toLowerCase() == 'manager') {
        return false;
      }

      // Category filter switches
      if (item.code.startsWith('SAL-') || item.code.startsWith('RET-')) {
        return currentSettings.salesAndReturns;
      }
      if (item.code.startsWith('EXP-')) {
        return currentSettings.expenses;
      }
      if (item.code.startsWith('STK-') || item.code.startsWith('SUP-')) {
        return currentSettings.stockAndSuppliers;
      }
      if (item.code.startsWith('MNY-')) {
        return currentSettings.moneyRecords;
      }
      if (item.code == 'USR-01') {
        return currentSettings.usersAndSecurity;
      }
      if (item.code.startsWith('SYS-') || item.code == 'DSC-01') {
        return currentSettings.reportsAndSystem;
      }

      return true;
    }

    return false;
  }

  // Filtered notification list for currently active user
  List<AppNotificationItem> get currentUserNotifications {
    final user = _auth.currentUser.value;
    final userSettings = settings.value;

    final list = allNotifications.where((n) {
      if (n.isDismissed) return false;
      return isNotificationForUser(
        item: n,
        user: user,
        currentSettings: userSettings,
      );
    }).toList();

    // Tab filter
    final tab = selectedFilter.value;
    if (tab == 'alerts') {
      return list.where((n) =>
          n.priority == NotificationPriority.high ||
          n.type == NotificationType.lowStock ||
          n.type == NotificationType.receivableDue ||
          n.code == 'SAL-04' ||
          n.code == 'SAL-05' ||
          n.code == 'STF-07').toList();
    } else if (tab == 'pending') {
      return list.where((n) =>
          n.type == NotificationType.pendingApproval ||
          n.code == 'USR-01' ||
          n.code == 'DSC-01').toList();
    } else if (tab == 'activity') {
      return list.where((n) =>
          n.type == NotificationType.sale ||
          n.type == NotificationType.purchase ||
          n.type == NotificationType.expense ||
          n.type == NotificationType.refund ||
          n.type == NotificationType.exchange).toList();
    }

    return list;
  }

  int get unreadCount => currentUserNotifications.where((n) => !n.isRead).length;

  // ---------------------------------------------------------------------------
  // Central Dispatcher Function (Triggering Push + Inbox)
  // ---------------------------------------------------------------------------
  void dispatchNotification(AppNotificationItem item) {
    allNotifications.insert(0, item);
    _persistNotifications();

    // Check if current user is an eligible recipient for active push/banner
    final user = _auth.currentUser.value;
    final isEligible = isNotificationForUser(
      item: item,
      user: user,
      currentSettings: settings.value,
    );

    if (isEligible) {
      // Local push delivery
      if (item.delivery == 'push_inbox' || item.priority == NotificationPriority.high) {
        try {
          if (Get.isRegistered<NotificationService>()) {
            Get.find<NotificationService>().showPushNotification(
              id: item.hashCode,
              title: item.title,
              body: item.message,
              payload: item.route,
            );
          }
        } catch (_) {}
      }

      // In-app immediate feedback
      Get.snackbar(
        item.title,
        item.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: Icon(
          item.priority == NotificationPriority.high
              ? Icons.warning_amber_rounded
              : Icons.notifications_active_rounded,
          color: Colors.amberAccent,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Inbox Actions (Spec Section 5: mark one read, mark all read, dismiss one, clear all)
  // ---------------------------------------------------------------------------
  void markAsRead(String id) {
    final idx = allNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      allNotifications[idx].isRead = true;
      allNotifications.refresh();
      _persistNotifications();
    }
  }

  void markAllAsRead() {
    final user = _auth.currentUser.value;
    final userSettings = settings.value;

    for (final notif in allNotifications) {
      if (isNotificationForUser(item: notif, user: user, currentSettings: userSettings)) {
        notif.isRead = true;
      }
    }
    allNotifications.refresh();
    _persistNotifications();
  }

  void dismissNotification(String id) {
    final idx = allNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      allNotifications[idx].isDismissed = true;
      allNotifications.refresh();
      _persistNotifications();
    }
  }

  void clearAll() {
    final user = _auth.currentUser.value;
    final userSettings = settings.value;

    for (final notif in allNotifications) {
      if (isNotificationForUser(item: notif, user: user, currentSettings: userSettings)) {
        notif.isDismissed = true;
      }
    }
    allNotifications.refresh();
    _persistNotifications();
  }

  // Send interactive Test Notification (Spec Section 5)
  void sendTestNotification() {
    final user = _auth.currentUser.value;

    if (user?.isStaff ?? false) {
      dispatchNotification(
        AppNotificationItem(
          id: const Uuid().v4(),
          code: 'STF-01',
          title: 'Test: Sale Saved Successfully ✅',
          message: 'Your simulated order has been recorded into the terminal.',
          timestamp: DateTime.now(),
          type: NotificationType.sale,
          recipientRole: 'Staff',
          recipientUserId: user!.id,
          actorUserId: user.id,
          isSelfConfirmation: true,
        ),
      );
    } else if (user?.isManager ?? false) {
      dispatchNotification(
        AppNotificationItem(
          id: const Uuid().v4(),
          code: 'SAL-01',
          title: 'Test: Staff Sale Alert 🛍️',
          message: 'Staff Tanvir sold 3 items totaling ৳2,800 (Profit: ৳750).',
          timestamp: DateTime.now(),
          type: NotificationType.sale,
          actorRole: 'Staff',
          actorName: 'Tanvir',
          metadata: {'profit': 750.0, 'items': 3, 'total': 2800.0},
        ),
      );
    } else {
      dispatchNotification(
        AppNotificationItem(
          id: const Uuid().v4(),
          code: 'SYS-01',
          title: 'Test: Daily Operations Summary 📊',
          message: 'Sales: ৳42,500 • Gross Profit: ৳14,200 • Net: ৳9,800.',
          timestamp: DateTime.now(),
          type: NotificationType.system,
          recipientRole: 'Owner',
        ),
      );
    }
  }

  void _syncSystemAlerts() {
    // Dynamically check for out-of-stock items and generate STK-01 / STK-02 if not already present
    for (final product in _db.products) {
      if (product.quantity <= 0) {
        final alertId = 'stk_zero_${product.id}';
        final exists = allNotifications.any((n) => n.id == alertId);
        if (!exists) {
          allNotifications.insert(
            0,
            AppNotificationItem(
              id: alertId,
              code: 'STK-02',
              title: 'Out of Stock Alert! 🚨',
              message: '${product.displayName} has 0 units remaining. Reorder now.',
              timestamp: DateTime.now(),
              type: NotificationType.lowStock,
              priority: NotificationPriority.high,
              route: AppRoute.addEditProductScreen,
              routeExtra: product,
              recipientRole: 'all',
            ),
          );
        }
      }
    }
  }

  void refreshAll() {
    _syncSystemAlerts();
    allNotifications.refresh();
  }
}
