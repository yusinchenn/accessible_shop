import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/services/connectivity_service.dart';

/// 無網路連線提醒對話框
///
/// 特性：
/// - 在畫面中央顯示提醒
/// - 半透明黑色背景遮罩（暫停當前畫面效果）
/// - 自動語音朗讀「請確認連線狀態」
/// - 提供重試和關閉按鈕
/// - 符合無障礙設計（大字體、高對比）
class NoConnectionDialog extends StatefulWidget {
  /// 當使用者點擊關閉按鈕時的回調
  final VoidCallback? onClose;

  /// 當使用者點擊重試按鈕且網路已恢復時的回調
  final VoidCallback? onRetry;

  const NoConnectionDialog({
    super.key,
    this.onClose,
    this.onRetry,
  });

  @override
  State<NoConnectionDialog> createState() => _NoConnectionDialogState();
}

class _NoConnectionDialogState extends State<NoConnectionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();

    // 淡入縮放動畫
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();

    // 延遲朗讀，確保對話框已顯示
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_hasSpoken) {
        _hasSpoken = true;
        ttsHelper.speak('請確認連線狀態');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 處理重試按鈕點擊
  Future<void> _handleRetry() async {
    // 檢查網路連線
    final bool isConnected = await connectivityService.checkConnectivity();

    if (isConnected) {
      // 網路已恢復，關閉對話框
      ttsHelper.speak('網路已連線');
      if (mounted) {
        Navigator.of(context).pop();
        widget.onRetry?.call();
      }
    } else {
      // 仍然沒有網路
      ttsHelper.speak('仍無法連線，請檢查網路設定');
    }
  }

  /// 處理關閉按鈕點擊
  void _handleClose() {
    ttsHelper.speak('對話框已關閉');
    Navigator.of(context).pop();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 防止用戶按返回鍵關閉對話框
      canPop: false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.7), // 半透明黑色遮罩
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.background_2,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 無網路圖示
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent_2.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: AppColors.accent_2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 標題
                  const Text(
                    '無法連線',
                    style: TextStyle(
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text_2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 提示訊息
                  const Text(
                    '請確認連線狀態',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      color: AppColors.subtitle_2,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 按鈕區域
                  Row(
                    children: [
                      // 關閉按鈕
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleClose,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: AppColors.subtitle_2,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '關閉',
                            style: TextStyle(
                              fontSize: AppFontSizes.body,
                              color: AppColors.text_2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 重試按鈕
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleRetry,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.botton_2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            '重試',
                            style: TextStyle(
                              fontSize: AppFontSizes.body,
                              color: AppColors.bottonText_2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 顯示無網路連線對話框
///
/// 使用方式：
/// ```dart
/// showNoConnectionDialog(context);
/// ```
Future<void> showNoConnectionDialog(
  BuildContext context, {
  VoidCallback? onClose,
  VoidCallback? onRetry,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // 禁止點擊外部關閉
    barrierColor: Colors.transparent, // 透明，因為對話框自己有背景
    builder: (context) => NoConnectionDialog(
      onClose: onClose,
      onRetry: onRetry,
    ),
  );
}
