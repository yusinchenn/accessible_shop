import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

/// 等待網路連線畫面
///
/// 當應用啟動時沒有網路連線，顯示此畫面提示用戶開啟網路
/// 會持續監聽網路狀態，一旦恢復連線就自動關閉
class WaitingForNetworkScreen extends StatefulWidget {
  /// 當網路連線恢復時的回調
  final VoidCallback? onConnected;

  const WaitingForNetworkScreen({
    super.key,
    this.onConnected,
  });

  @override
  State<WaitingForNetworkScreen> createState() =>
      _WaitingForNetworkScreenState();
}

class _WaitingForNetworkScreenState extends State<WaitingForNetworkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();

    // 旋轉動畫
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 延遲朗讀，確保畫面已顯示
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasSpoken) {
        _hasSpoken = true;
        ttsHelper.speak('請開啟網路連線');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background_2,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 旋轉的網路圖示
                RotationTransition(
                  turns: _animationController,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accent_2.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: AppColors.accent_2,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // 標題
                const Text(
                  '無網路連線',
                  style: TextStyle(
                    fontSize: AppFontSizes.extraLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text_2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // 說明文字
                const Text(
                  '請開啟 WiFi 或行動網路\n應用程式需要網路連線才能使用',
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: AppColors.subtitle_2,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
