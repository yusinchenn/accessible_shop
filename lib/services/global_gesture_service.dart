// lib/services/global_gesture_service.dart
//
// 全域手勢服務：提供全域導航手勢支援

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/tts_helper.dart';
import '../providers/auth_provider.dart';
import 'accessibility_service.dart';

/// 全域手勢類型
enum GlobalGestureType {
  /// 兩指上滑 - 回首頁
  twoFingerSwipeUp,

  /// 兩指下滑 - 回上一頁
  twoFingerSwipeDown,
}

/// 全域手勢配置
class GlobalGestureConfig {
  /// 是否啟用語音提示
  final bool enableVoiceFeedback;

  /// 是否啟用觸覺反饋
  final bool enableHapticFeedback;

  /// 手勢靈敏度 (滑動距離閾值，單位：邏輯像素)
  final double swipeThreshold;

  const GlobalGestureConfig({
    this.enableVoiceFeedback = true,
    this.enableHapticFeedback = true,
    this.swipeThreshold = 50.0,
  });
}

/// 全域手勢服務
class GlobalGestureService {
  static final GlobalGestureService _instance = GlobalGestureService._internal();
  factory GlobalGestureService() => _instance;
  GlobalGestureService._internal();

  GlobalGestureConfig _config = const GlobalGestureConfig();

  /// 更新配置
  void updateConfig(GlobalGestureConfig config) {
    _config = config;
  }

  /// 獲取當前配置
  GlobalGestureConfig get config => _config;

  /// 處理兩指上滑（回首頁）
  Future<void> handleTwoFingerSwipeUp(BuildContext context) async {
    debugPrint('[GlobalGesture] 偵測到兩指上滑 - 回首頁');

    // 檢查登入狀態
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      debugPrint('[GlobalGesture] 未登入，無法導航到首頁');
      if (_config.enableVoiceFeedback && accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak('請先登入');
      }
      return;
    }

    // 直接導航到首頁（移除所有路由）
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  /// 處理兩指下滑（回上一頁）
  Future<void> handleTwoFingerSwipeDown(BuildContext context) async {
    debugPrint('[GlobalGesture] 偵測到兩指下滑 - 回上一頁');

    // 檢查是否可以返回
    if (Navigator.of(context).canPop()) {
      // 直接返回上一頁
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // 無法返回時提示
      if (_config.enableVoiceFeedback && accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak('已在最上層頁面');
      }
      debugPrint('[GlobalGesture] 無法返回 - 已在最上層');
    }
  }
}

/// 全域實例
final globalGestureService = GlobalGestureService();
