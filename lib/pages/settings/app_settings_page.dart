import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart';
import 'package:accessible_shop/services/accessibility_service.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _announceScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化無障礙服務
    accessibilityService.initialize(context);

    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (routeIsCurrent && !_announceScheduled) {
      _announceScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceScheduled = false;
        _announceEnter();
      });
    }
  }

  /// 執行進入頁面的語音播報
  Future<void> _announceEnter() async {
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      await ttsHelper.speak('進入App設定頁面');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 處理功能項目的單擊（播報）
  void _onFunctionTap(String title, String description) {
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak('$title，$description');
    }
  }

  /// 處理功能項目的雙擊（導航或操作）
  void _onFunctionDoubleTap(String title) {
    // 功能尚未實作，顯示提示
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak('$title功能尚未實作');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title功能尚未實作', style: const TextStyle(fontSize: 18)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      appBar: AppBar(
        title: const Text('App 設定', style: TextStyle(color: AppColors.text_2)),
        centerTitle: true,
        backgroundColor: AppColors.background_2,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頁面說明
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                '管理您的應用程式設定',
                style: AppTextStyles.body.copyWith(color: AppColors.subtitle_2),
              ),
            ),

            // 通知設定
            _buildFunctionCard(
              title: '通知設定',
              description: '管理推播通知和提醒設定',
              icon: Icons.notifications_outlined,
              iconColor: AppColors.primary_2,
              onTap: () => _onFunctionTap('通知設定', '管理推播通知和提醒設定'),
              onDoubleTap: () => _onFunctionDoubleTap('通知設定'),
            ),

            const SizedBox(height: AppSpacing.md),

            // 語言設定
            _buildFunctionCard(
              title: '語言設定',
              description: '選擇應用程式顯示語言',
              icon: Icons.language_outlined,
              iconColor: Colors.blue,
              onTap: () => _onFunctionTap('語言設定', '選擇應用程式顯示語言'),
              onDoubleTap: () => _onFunctionDoubleTap('語言設定'),
            ),

            const SizedBox(height: AppSpacing.md),

            // 隱私設定
            _buildFunctionCard(
              title: '隱私設定',
              description: '管理您的隱私和資料安全',
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.orange,
              onTap: () => _onFunctionTap('隱私設定', '管理您的隱私和資料安全'),
              onDoubleTap: () => _onFunctionDoubleTap('隱私設定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立功能卡片
  Widget _buildFunctionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required VoidCallback onDoubleTap,
  }) {
    return GestureDetector(
      onTap: onTap, // 單擊播報
      onDoubleTap: onDoubleTap, // 雙擊進入功能
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 圖示區域
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              // 文字區域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text_2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.subtitle_2,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // 箭頭圖示
              const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
