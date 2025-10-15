// lib/services/accessibility_service.dart
//
// 無障礙服務：偵測系統無障礙模式並提供相應的語音和手勢策略

import 'package:flutter/material.dart';

/// 無障礙服務單例
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  /// 是否啟用系統無障礙服務（TalkBack/VoiceOver）
  bool _isSystemAccessibilityEnabled = false;

  /// 初始化並監聽系統無障礙狀態
  void initialize(BuildContext context) {
    // 檢查系統無障礙服務狀態
    _updateAccessibilityStatus(context);
  }

  /// 更新無障礙狀態
  void _updateAccessibilityStatus(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _isSystemAccessibilityEnabled = mediaQuery.accessibleNavigation;

    debugPrint('[Accessibility] 系統無障礙模式: $_isSystemAccessibilityEnabled');
  }

  /// 檢查是否應該使用系統無障礙（優先使用系統內建）
  bool get shouldUseSystemAccessibility => _isSystemAccessibilityEnabled;

  /// 檢查是否應該使用自訂 TTS（系統無障礙未開啟時）
  bool get shouldUseCustomTTS => !_isSystemAccessibilityEnabled;

  /// 檢查是否應該使用自訂手勢（系統無障礙未開啟時）
  bool get shouldUseCustomGestures => !_isSystemAccessibilityEnabled;
}

/// 全域實例
final accessibilityService = AccessibilityService();
