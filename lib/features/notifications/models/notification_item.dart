enum NotificationType {
  lowStock,
  pendingApproval,
  receivableDue,
  sale,
  purchase,
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
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationPriority priority;
  final String? route;
  final dynamic routeExtra;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.route,
    this.routeExtra,
    this.isRead = false,
  });
}
