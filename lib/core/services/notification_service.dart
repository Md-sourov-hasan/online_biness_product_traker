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
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin?.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );
    } catch (e) {
      debugPrint(
        'Local notifications not supported or mock in current environment: $e',
      );
    }
  }

  Future<void> showPushNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'stockmate_alerts',
        'StockMate Alerts',
        channelDescription: 'Notifications and operational alerts for StockMate',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'StockMate',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin?.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Could not trigger notification: $e');
    }
  }

  Future<void> showLowStockNotification(
    String productName,
    int currentStock,
  ) async {
    await showPushNotification(
      id: 1,
      title: 'Low Stock Alert! ⚠️',
      body: '$productName is running low ($currentStock units left).',
      payload: 'low_stock',
    );
  }
}
