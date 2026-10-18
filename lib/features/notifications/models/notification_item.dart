import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  lowStock,
  pendingApproval,
  receivableDue,
  sale,
  refund,
  exchange,
  discount,
  expense,
  purchase,
  stock,
  supplier,
  money,
  moneyLent,
  investor,
  userSecurity,
  system,
  activityLog,
}

enum NotificationPriority {
  high,
  medium,
  low,
}

class AppNotificationItem {
  final String id;
  final String code; // e.g. SAL-01, DSC-01, STF-01
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationPriority priority;
  final String? route;
  final dynamic routeExtra;
  final String? recipientRole; // 'Owner', 'Manager', 'Staff', 'all'
  final String? recipientUserId; // Target specific user ID
  final String? actorUserId; // User who triggered the action
  final String? actorRole; // Role of the actor
  final String? actorName;
  final bool isSelfConfirmation;
  final String delivery; // 'push_inbox', 'inbox_only', 'in_app'
  final Map<String, dynamic>? metadata; // Hidden details for unauthorized roles (e.g. profit, cost)
  bool isRead;
  bool isDismissed;

  AppNotificationItem({
    required this.id,
    this.code = 'SYS-01',
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.route,
    this.routeExtra,
    this.recipientRole,
    this.recipientUserId,
    this.actorUserId,
    this.actorRole,
    this.actorName,
    this.isSelfConfirmation = false,
    this.delivery = 'push_inbox',
    this.metadata,
    this.isRead = false,
    this.isDismissed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'priority': priority.name,
      'route': route,
      'recipientRole': recipientRole,
      'recipientUserId': recipientUserId,
      'actorUserId': actorUserId,
      'actorRole': actorRole,
      'actorName': actorName,
      'isSelfConfirmation': isSelfConfirmation,
      'delivery': delivery,
      'metadata': metadata,
      'isRead': isRead,
      'isDismissed': isDismissed,
    };
  }

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    NotificationType parseType(String? val) {
      return NotificationType.values.firstWhere(
        (e) => e.name == val,
        orElse: () => NotificationType.system,
      );
    }

    NotificationPriority parsePriority(String? val) {
      return NotificationPriority.values.firstWhere(
        (e) => e.name == val,
        orElse: () => NotificationPriority.medium,
      );
    }

    return AppNotificationItem(
      id: map['id'] ?? '',
      code: map['code'] ?? 'SYS-01',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: parseDate(map['timestamp']),
      type: parseType(map['type']),
      priority: parsePriority(map['priority']),
      route: map['route'],
      recipientRole: map['recipientRole'],
      recipientUserId: map['recipientUserId'],
      actorUserId: map['actorUserId'],
      actorRole: map['actorRole'],
      actorName: map['actorName'],
      isSelfConfirmation: map['isSelfConfirmation'] ?? false,
      delivery: map['delivery'] ?? 'push_inbox',
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      isRead: map['isRead'] ?? false,
      isDismissed: map['isDismissed'] ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppNotificationItem.fromJson(String source) =>
      AppNotificationItem.fromMap(jsonDecode(source));

  AppNotificationItem copyWith({
    String? id,
    String? code,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    NotificationPriority? priority,
    String? route,
    dynamic routeExtra,
    String? recipientRole,
    String? recipientUserId,
    String? actorUserId,
    String? actorRole,
    String? actorName,
    bool? isSelfConfirmation,
    String? delivery,
    Map<String, dynamic>? metadata,
    bool? isRead,
    bool? isDismissed,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      route: route ?? this.route,
      routeExtra: routeExtra ?? this.routeExtra,
      recipientRole: recipientRole ?? this.recipientRole,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      actorUserId: actorUserId ?? this.actorUserId,
      actorRole: actorRole ?? this.actorRole,
      actorName: actorName ?? this.actorName,
      isSelfConfirmation: isSelfConfirmation ?? this.isSelfConfirmation,
      delivery: delivery ?? this.delivery,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
