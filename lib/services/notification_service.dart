// 导入包
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  // Use singleton pattern for initialization
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }


//  显示通知
  Future<void> showNotification(
      {required String title, required String body}) async {
    // Android
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('your.channel.id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');

    // ios
    const String darwinNotificationCategoryPlain = 'plainCategory';
    const DarwinNotificationDetails iosNotificationDetails =
    DarwinNotificationDetails(
      categoryIdentifier: darwinNotificationCategoryPlain, // 通知分类
    );
    // Create cross-platform notifications
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidNotificationDetails,iOS: iosNotificationDetails);

    // initiate a notification
    await _notificationsPlugin.show(
      1,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
