import 'package:flutter/material.dart';

/// 語音助手動畫類型
enum VoiceAssistantAnimationType {
  /// 開啟動畫（從下往上冒出，停留1秒，然後下降）
  enable,

  /// 關閉動畫（從右側滑入，停留1秒，往右側滑出）
  disable,
}

/// 語音助手動畫 Widget
/// 顯示語音助手開啟/關閉的動畫效果
class VoiceAssistantAnimation extends StatefulWidget {
  /// 動畫類型
  final VoiceAssistantAnimationType type;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const VoiceAssistantAnimation({
    super.key,
    required this.type,
    this.onComplete,
  });

  @override
  State<VoiceAssistantAnimation> createState() =>
      _VoiceAssistantAnimationState();
}

class _VoiceAssistantAnimationState extends State<VoiceAssistantAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 根據動畫類型設置持續時間
    final duration = widget.type == VoiceAssistantAnimationType.enable
        ? const Duration(milliseconds: 3000) // 開啟動畫：2秒
        : const Duration(milliseconds: 3000); // 關閉動畫：2秒

    _controller = AnimationController(vsync: this, duration: duration);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 開始動畫
    _controller.forward().then((_) {
      // 動畫完成後回調
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (widget.type == VoiceAssistantAnimationType.enable) {
      // 開啟動畫：從下往上冒出，水平轉一圈，然後下降
      return _buildEnableAnimation(screenSize);
    } else {
      // 關閉動畫：從右往左冒出，停留1秒，往右隱藏
      return _buildDisableAnimation(screenSize);
    }
  }

  /// 構建開啟動畫 (總長 3 秒)
  Widget _buildEnableAnimation(Size screenSize) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 動畫分為三個階段（總共3秒）：
        // 0.0 - 0.17: 從下往上冒出 (0.5秒)
        // 0.17 - 0.84: 停留在中間 (2秒)
        // 0.84 - 1.0: 下降消失 (0.5秒)

        double verticalOffset;
        double rotation = 0.0;

        if (_animation.value < 0.17) {
          // 階段1：上升（從螢幕底部到中間）- 0.5秒
          final progress = _animation.value / 0.17;
          verticalOffset =
              screenSize.height * (1 - progress * 0.5); // 從底部到50%位置
        } else if (_animation.value < 0.84) {
          // 階段2：停留（不旋轉）- 2秒
          verticalOffset = screenSize.height * 0.5; // 保持在50%位置
          rotation = 0.0;
        } else {
          // 階段3：下降 - 0.5秒
          final progress = (_animation.value - 0.84) / 0.16;
          verticalOffset =
              screenSize.height * (0.5 + progress * 0.5); // 從50%下降到底部
        }

        // 計算圖片寬度（螢幕寬度的70%）
        final imageWidth = screenSize.width * 0.7;

        return Positioned(
          left: (screenSize.width - imageWidth) / 2, // 水平置中
          top: verticalOffset - imageWidth * 0.5, // 調整垂直位置
          child: Transform.rotate(
            angle: rotation,
            child: Image.asset(
              'assets/images/agent_on.png',
              width: imageWidth,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 如果圖片不存在，顯示占位符
                return Container(
                  width: imageWidth,
                  height: imageWidth,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 100, color: Colors.white),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 構建關閉動畫 (總長 3 秒)
  Widget _buildDisableAnimation(Size screenSize) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 動畫分為三個階段（總共3秒）：
        // 0.0 - 0.17: 從右側滑入（右邊緣貼齊螢幕右邊）(0.5秒)
        // 0.17 - 0.84: 停留在右側 (2秒)
        // 0.84 - 1.0: 往右側滑出（完全離開螢幕）(0.5秒)

        final imageHeight = screenSize.height * 0.7;
        final imageWidth = imageHeight; // 假設接近正方形

        double rightPosition;

        if (_animation.value < 0.17) {
          // 階段1：從螢幕外滑入
          final progress = _animation.value / 0.17;
          // 起點：圖片完全在螢幕外 (right = -imageWidth)
          // 終點：圖片右邊緣貼齊螢幕右邊 (right = 0)
          rightPosition = -imageWidth * (1 - progress);
        } else if (_animation.value < 0.84) {
          // 階段2：停留在右側
          rightPosition = 0;
        } else {
          // 階段3：往右側滑出
          final progress = (_animation.value - 0.84) / 0.16;
          // 起點：right = 0（貼齊螢幕右側）
          // 終點：right = -imageWidth（完全滑出）
          rightPosition = -imageWidth * progress;
        }

        return Positioned(
          right: rightPosition, // 使用 right 控制位置
          top: (screenSize.height - imageHeight) / 2, // 垂直置中
          child: Image.asset(
            'assets/images/agent_off.png',
            height: imageHeight,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // 如果圖片不存在，顯示占位符
              return Container(
                width: imageHeight,
                height: imageHeight,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_off,
                  size: 100,
                  color: Colors.white,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 顯示語音助手動畫的 Overlay
class VoiceAssistantAnimationOverlay {
  static OverlayEntry? _currentOverlay;

  /// 顯示動畫
  static void show(
    BuildContext context, {
    required VoiceAssistantAnimationType type,
    VoidCallback? onComplete,
  }) {
    // 如果已有動畫在顯示，先移除
    hide();

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            VoiceAssistantAnimation(
              type: type,
              onComplete: () {
                // 動畫完成後自動移除
                hide();
                onComplete?.call();
              },
            ),
          ],
        ),
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  /// 隱藏動畫
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
