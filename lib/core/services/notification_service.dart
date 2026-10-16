import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true);

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin?.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );
    } catch (e) {
      debugPrint('Local notifications not supported or mock in current environment: $e');
    }
  }

  Future<void> showLowStockNotification(String productName, int currentStock) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'low_stock_alerts',
        'Low Stock Alerts',
        channelDescription: 'Notifications for products running low on stock',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin?.show(
        id: 0,
        title: 'Low Stock Alert! ⚠️',
        body: '$productName is running low ($currentStock units left).',
        notificationDetails: platformChannelSpecifics,
        payload: 'item x',
      );
    } catch (e) {
      debugPrint('Could not trigger notification: $e');
    }
  }
}
