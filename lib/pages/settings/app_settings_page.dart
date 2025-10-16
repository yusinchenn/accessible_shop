import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({Key? key}) : super(key: key);

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入App設定頁面");
    });
  }

  @override
  void dispose() {
    ttsHelper.speak("進入帳號頁面");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(title: const Text('App 設定')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const Text(
            '這是 App 設定頁面',
            style: AppTextStyles.subtitle,
          ),
        ),
      ),
    );
  }
}
