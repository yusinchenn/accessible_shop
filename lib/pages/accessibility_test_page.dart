// lib/pages/accessibility_test_page.dart
//
// 無障礙功能測試頁面

import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_gesture_wrapper.dart';
import '../widgets/global_gesture_wrapper.dart';
import '../utils/tts_helper.dart';
import '../utils/app_constants.dart';

/// 無障礙測試頁面
class AccessibilityTestPage extends StatefulWidget {
  const AccessibilityTestPage({super.key});

  @override
  State<AccessibilityTestPage> createState() => _AccessibilityTestPageState();
}

class _AccessibilityTestPageState extends State<AccessibilityTestPage> {
  int _counter = 0;
  String _selectedOption = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      accessibilityService.initialize(context);

      if (accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak("無障礙測試頁面");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSystemMode = accessibilityService.shouldUseSystemAccessibility;

    return GlobalGestureScaffold(
      appBar: AppBar(
        title: const Text('無障礙測試'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 模式指示器
            Card(
              color: isSystemMode ? Colors.blue[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Icon(
                      isSystemMode ? Icons.accessibility_new : Icons.mic,
                      size: 48,
                      color: isSystemMode ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isSystemMode ? '系統無障礙模式' : '自訂語音模式',
                      style: const TextStyle(
                        fontSize: AppFontSizes.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isSystemMode
                          ? '已偵測到 TalkBack/VoiceOver\n使用標準手勢操作'
                          : '使用自訂語音導引\n單擊朗讀 / 雙擊執行',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 測試 1: 計數器按鈕
            const Text(
              '測試 1: 可點擊按鈕',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            AccessibleSpeakWrapper(
              label: '目前計數: $_counter',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '計數: $_counter',
                    style: const TextStyle(
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AccessibleGestureWrapper(
                    label: '增加',
                    description: '將計數加一',
                    onTap: () {
                      setState(() => _counter++);
                      if (accessibilityService.shouldUseCustomTTS) {
                        ttsHelper.speak('計數增加為 $_counter');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+ 增加',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSizes.subtitle,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AccessibleGestureWrapper(
                    label: '減少',
                    description: '將計數減一',
                    enabled: _counter > 0,
                    onTap: _counter > 0
                        ? () {
                            setState(() => _counter--);
                            if (accessibilityService.shouldUseCustomTTS) {
                              ttsHelper.speak('計數減少為 $_counter');
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _counter > 0 ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '- 減少',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSizes.subtitle,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // 測試 2: 單選選項
            const Text(
              '測試 2: 單選選項',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._buildOptions(),

            const SizedBox(height: AppSpacing.xl),

            // 測試 3: 純資訊顯示
            const Text(
              '測試 3: 資訊朗讀',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            AccessibleSpeakWrapper(
              label: '這是一段重要資訊，點擊可朗讀完整內容',
              child: Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '這是一段重要資訊，點擊可朗讀完整內容',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 測試說明
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '測試指南',
                      style: TextStyle(
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      isSystemMode
                          ? '• 單擊元素：聚焦並朗讀\n'
                              '• 雙擊元素：執行動作\n'
                              '• 語音由系統提供\n'
                              '• 可使用 TalkBack/VoiceOver 手勢導航'
                          : '• 單擊元素：朗讀說明\n'
                              '• 雙擊元素：執行動作\n'
                              '• 語音由 App 提供\n'
                              '• 支援自訂語音速度與音調',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions() {
    final options = [
      {'id': 'A', 'label': '選項 A'},
      {'id': 'B', 'label': '選項 B'},
      {'id': 'C', 'label': '選項 C'},
    ];

    return options.map((option) {
      final id = option['id']!;
      final label = option['label']!;
      final isSelected = _selectedOption == id;

      return AccessibleGestureWrapper(
        label: label,
        description: isSelected ? '目前已選擇' : '點擊選擇此選項',
        onTap: () {
          setState(() => _selectedOption = id);
          if (accessibilityService.shouldUseCustomTTS) {
            ttsHelper.speak('已選擇 $label');
          }
        },
        child: Card(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : null,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
