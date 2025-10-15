// lib/widgets/accessible_gesture_wrapper.dart
//
// 智能手勢包裝器：根據系統無障礙模式自動切換手勢策略

import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../utils/tts_helper.dart';

/// 智能手勢包裝器
///
/// 使用方式：
/// ```dart
/// AccessibleGestureWrapper(
///   label: '確認按鈕',
///   description: '點擊後前往下一步',
///   onTap: () { /* 執行動作 */ },
///   child: Container(...),
/// )
/// ```
class AccessibleGestureWrapper extends StatelessWidget {
  /// 語意標籤（用於系統無障礙服務）
  final String label;

  /// 語意描述（用於系統無障礙服務，可選）
  final String? description;

  /// 點擊動作
  final VoidCallback? onTap;

  /// 要包裝的子元件
  final Widget child;

  /// 是否啟用（預設 true）
  final bool enabled;

  /// 自訂朗讀文字（如果與 label 不同）
  final String? customSpeakText;

  const AccessibleGestureWrapper({
    super.key,
    required this.label,
    this.description,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.customSpeakText,
  });

  @override
  Widget build(BuildContext context) {
    // 如果系統無障礙已啟用，使用 Semantics + 標準 Tap
    if (accessibilityService.shouldUseSystemAccessibility) {
      return Semantics(
        label: label,
        hint: description,
        button: true,
        enabled: enabled,
        onTap: enabled ? onTap : null,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: child,
        ),
      );
    }

    // 如果系統無障礙未啟用，使用自訂 TTS + 雙擊手勢
    return GestureDetector(
      onTap: enabled
          ? () {
              final textToSpeak = customSpeakText ?? label;
              ttsHelper.speak(textToSpeak);
            }
          : null,
      onDoubleTap: enabled ? onTap : null,
      child: child,
    );
  }
}

/// 僅提供語音朗讀的包裝器（無手勢動作）
///
/// 使用方式：
/// ```dart
/// AccessibleSpeakWrapper(
///   label: '商品總計 500 元',
///   child: Text('總計: \$500'),
/// )
/// ```
class AccessibleSpeakWrapper extends StatelessWidget {
  /// 語意標籤
  final String label;

  /// 要包裝的子元件
  final Widget child;

  /// 自訂朗讀文字（如果與 label 不同）
  final String? customSpeakText;

  const AccessibleSpeakWrapper({
    super.key,
    required this.label,
    required this.child,
    this.customSpeakText,
  });

  @override
  Widget build(BuildContext context) {
    // 如果系統無障礙已啟用，僅使用 Semantics
    if (accessibilityService.shouldUseSystemAccessibility) {
      return Semantics(
        label: label,
        readOnly: true,
        child: child,
      );
    }

    // 如果系統無障礙未啟用，使用自訂 TTS
    return GestureDetector(
      onTap: () {
        final textToSpeak = customSpeakText ?? label;
        ttsHelper.speak(textToSpeak);
      },
      child: child,
    );
  }
}
