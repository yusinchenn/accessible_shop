// lib/services/daily_reward_scheduler.dart
//
// 每日獎勵提醒調度服務 - 負責管理每日登入獎勵的定時提醒

import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import 'notification_service.dart';
import 'firestore_service.dart';
import 'database_service.dart';

/// 每日獎勵調度服務
class DailyRewardScheduler {
  // 單例模式
  static final DailyRewardScheduler _instance =
      DailyRewardScheduler._internal();
  factory DailyRewardScheduler() => _instance;
  DailyRewardScheduler._internal();

  // 固定的通知 ID
  static const int _dailyRewardNotificationId = 1000;

  // 提醒時間（12:00）
  static const int _reminderHour = 12;
  static const int _reminderMinute = 0;

  /// 初始化每日獎勵提醒
  Future<void> initialize(String? userId) async {
    if (userId == null) {
      if (kDebugMode) {
        print('⚠️ [DailyRewardScheduler] 用戶未登入，跳過初始化');
      }
      return;
    }

    try {
      // 排定每日 12:00 的提醒通知
      await _scheduleDailyReminder();

      // 立即檢查是否需要提醒（用於剛啟動 App 時）
      await _checkAndNotifyIfNeeded(userId);

      if (kDebugMode) {
        print('✅ [DailyRewardScheduler] 每日獎勵提醒已初始化');
      }
    } catch (e) {
      if (kDebugMode) {
        // 如果是權限錯誤，提供更友善的提示
        if (e.toString().contains('exact_alarms_not_permitted')) {
          print('⚠️ [DailyRewardScheduler] 精確鬧鐘權限未授予，每日提醒功能將無法使用');
          print('   提示：Android 13+ 需要授予「鬧鐘和提醒」權限');
        } else {
          print('❌ [DailyRewardScheduler] 初始化失敗: $e');
        }
      }
      // 不要拋出錯誤，讓應用程式繼續運行
      // 即使每日提醒無法使用，其他功能仍應正常運作
    }
  }

  /// 排定每日提醒通知
  Future<void> _scheduleDailyReminder() async {
    await notificationService.scheduleDailyNotification(
      id: _dailyRewardNotificationId,
      title: '每日登入獎勵',
      body: '別忘了領取今天的免費獎勵！每天登入可獲得 1 元',
      hour: _reminderHour,
      minute: _reminderMinute,
      type: NotificationType.reward,
      payload: 'daily_reward',
    );

    if (kDebugMode) {
      print(
        '✅ [DailyRewardScheduler] 已排定每日 $_reminderHour:$_reminderMinute 提醒',
      );
    }
  }

  /// 檢查並在需要時發送提醒
  Future<void> _checkAndNotifyIfNeeded(String userId) async {
    try {
      // 從 Firestore 檢查是否已領取今日獎勵
      final firestoreService = FirestoreService();
      final hasClaimed = await firestoreService.hasClaimedDailyReward(userId);

      // 如果尚未領取，立即發送提醒
      if (!hasClaimed) {
        final now = DateTime.now();
        // 只在 12:00 之後才發送即時提醒
        if (now.hour >= _reminderHour) {
          await _sendImmediateReminder(userId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DailyRewardScheduler] 檢查獎勵狀態失敗: $e');
      }
    }
  }

  /// 發送即時提醒
  Future<void> _sendImmediateReminder(String userId) async {
    try {
      // 創建應用內通知（會自動發送手機通知）
      final databaseService = DatabaseService();
      await databaseService.createNotification(
        title: '每日登入獎勵',
        content: '您今天還沒有領取獎勵！前往錢包頁面領取 1 元獎勵',
        type: NotificationType.reward,
      );

      if (kDebugMode) {
        print('✅ [DailyRewardScheduler] 已發送即時提醒');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DailyRewardScheduler] 發送即時提醒失敗: $e');
      }
    }
  }

  /// 取消所有每日獎勵提醒
  Future<void> cancelReminders() async {
    await notificationService.cancelScheduledNotification(
      _dailyRewardNotificationId,
    );

    if (kDebugMode) {
      print('✅ [DailyRewardScheduler] 已取消每日獎勵提醒');
    }
  }

  /// 手動觸發檢查（可用於用戶登入後）
  Future<void> checkNow(String userId) async {
    await _checkAndNotifyIfNeeded(userId);
  }
}

// 全域調度服務實例
final dailyRewardScheduler = DailyRewardScheduler();
