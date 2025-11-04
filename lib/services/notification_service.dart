// lib/services/notification_service.dart
//
// 手機通知服務 - 負責管理本地推送通知功能

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/notification.dart';

/// 手機通知服務
class NotificationService {
  // 單例模式
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Flutter Local Notifications 插件實例
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 初始化狀態
  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化時區數據
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    // Android 初始化設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化設定
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 整合初始化設定
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 初始化插件
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    _isInitialized = true;
  }

  /// 通知點擊回調
  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      // 可在此處理通知點擊事件，例如導航到特定頁面
      // 根據 payload 內容決定導航目標
    }
  }

  /// 請求通知權限
  Future<bool> requestNotificationPermission() async {
    // Android 13+ 需要請求通知權限
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    // iOS 請求權限
    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? true;
  }

  /// 檢查通知權限狀態
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 顯示立即通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    NotificationType? type,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 檢查權限
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      return;
    }

    // 根據通知類型設定圖示和頻道
    final String channelId = _getChannelId(type);
    final String channelName = _getChannelName(type);
    final String channelDescription = _getChannelDescription(type);

    // Android 通知詳細設定
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS 通知詳細設定
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // 整合通知詳細設定
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // 顯示通知
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// 根據通知類型取得頻道 ID
  String _getChannelId(NotificationType? type) {
    switch (type) {
      case NotificationType.order:
        return 'order_notifications';
      case NotificationType.promotion:
        return 'promotion_notifications';
      case NotificationType.system:
        return 'system_notifications';
      case NotificationType.reward:
        return 'reward_notifications';
      default:
        return 'default_notifications';
    }
  }

  /// 根據通知類型取得頻道名稱
  String _getChannelName(NotificationType? type) {
    switch (type) {
      case NotificationType.order:
        return '訂單通知';
      case NotificationType.promotion:
        return '促銷通知';
      case NotificationType.system:
        return '系統通知';
      case NotificationType.reward:
        return '獎勵通知';
      default:
        return '預設通知';
    }
  }

  /// 根據通知類型取得頻道描述
  String _getChannelDescription(NotificationType? type) {
    switch (type) {
      case NotificationType.order:
        return '接收訂單相關的通知';
      case NotificationType.promotion:
        return '接收促銷活動的通知';
      case NotificationType.system:
        return '接收系統相關的通知';
      case NotificationType.reward:
        return '接收每日獎勵提醒';
      default:
        return '接收一般通知';
    }
  }

  /// 排定每日定時通知
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    NotificationType? type,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 檢查權限
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      return;
    }

    // 根據通知類型設定圖示和頻道
    final String channelId = _getChannelId(type);
    final String channelName = _getChannelName(type);
    final String channelDescription = _getChannelDescription(type);

    // Android 通知詳細設定
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS 通知詳細設定
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // 整合通知詳細設定
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // 設定每日重複的時間
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// 計算下一次指定時間的實例
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 如果今天的時間已經過了，則排定到明天
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 取消定時通知
  Future<void> cancelScheduledNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 取得待處理通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// 取得活躍通知列表 (僅 Android)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final List<ActiveNotification>? activeNotifications =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.getActiveNotifications();
    return activeNotifications ?? [];
  }
}

// 全域通知服務實例
final notificationService = NotificationService();