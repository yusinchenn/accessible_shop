import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/tts_helper.dart';

/// 無障礙友善的星星評分元件（滑動操作版本）
///
/// 特點：
/// - 按住螢幕左右滑動來升降評分
/// - 滑動時即時朗讀當前分數
/// - 星星僅用於視覺顯示，不可觸碰
/// - 單擊元件朗讀操作說明
/// - 完整的語音反饋和震動反饋
class AccessibleStarRating extends StatefulWidget {
  /// 當前評分（0-5）
  final double rating;

  /// 評分改變回調
  final ValueChanged<double> onRatingChanged;

  /// 星星數量
  final int starCount;

  /// 星星大小
  final double starSize;

  /// 星星間距
  final double spacing;

  /// 已選中顏色
  final Color activeColor;

  /// 未選中顏色
  final Color inactiveColor;

  /// 是否啟用
  final bool enabled;

  /// 是否顯示當前評分文字
  final bool showRatingText;

  /// 是否添加震動反饋
  final bool enableHapticFeedback;

  const AccessibleStarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starCount = 5,
    this.starSize = 20.0,
    this.spacing = 5.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.enabled = true,
    this.showRatingText = true,
    this.enableHapticFeedback = true,
  });

  @override
  State<AccessibleStarRating> createState() => _AccessibleStarRatingState();
}

class _AccessibleStarRatingState extends State<AccessibleStarRating> {
  // 記錄上次朗讀的評分，避免重複朗讀
  double? _lastSpokenRating;

  // 記錄拖曳區域的寬度
  double? _containerWidth;

  /// 朗讀操作說明
  void _speakInstructions() {
    String instructions = '評分選擇區域。';
    if (widget.rating > 0) {
      instructions +=
          '當前評分 ${widget.rating.toInt()} 分，滿分 ${widget.starCount} 分。';
    } else {
      instructions += '尚未評分。';
    }
    instructions += '請按住螢幕並向右滑動增加評分，向左滑動減少評分。';
    ttsHelper.speak(instructions);
  }

  /// 朗讀當前評分
  void _speakRating(double rating) {
    // 避免重複朗讀相同的評分
    if (_lastSpokenRating == rating) return;

    _lastSpokenRating = rating;
    final ratingInt = rating.toInt();

    if (ratingInt > 0) {
      ttsHelper.speak('$ratingInt 分，滿分 ${widget.starCount} 分');
    } else {
      ttsHelper.speak('未評分');
    }
  }

  /// 根據水平位置計算評分
  double _calculateRating(double localX, double width) {
    if (width <= 0) return widget.rating;

    // 計算相對位置 (0.0 到 1.0)
    final ratio = (localX / width).clamp(0.0, 1.0);

    // 轉換為評分 (1 到 starCount)
    // 如果點擊在最左側 20% 以內，設為 0（未評分）
    if (ratio < 0.1) {
      return 0;
    }

    // 否則映射到 1 到 starCount
    final rating = ((ratio * widget.starCount).ceil()).toDouble();
    return rating.clamp(1.0, widget.starCount.toDouble());
  }

  /// 處理滑動開始
  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled) return;

    // 重置上次朗讀的評分
    _lastSpokenRating = null;

    // 震動反饋
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }

    // 計算初始評分
    if (_containerWidth != null) {
      final newRating = _calculateRating(
        details.localPosition.dx,
        _containerWidth!,
      );
      widget.onRatingChanged(newRating);
      _speakRating(newRating);
    }
  }

  /// 處理滑動更新
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _containerWidth == null) return;

    final newRating = _calculateRating(
      details.localPosition.dx,
      _containerWidth!,
    );

    // 只有評分改變時才更新和朗讀
    if (newRating != widget.rating) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
      widget.onRatingChanged(newRating);
      _speakRating(newRating);
    }
  }

  /// 處理滑動結束
  void _handleDragEnd(DragEndDetails details) {
    // 重置上次朗讀的評分
    _lastSpokenRating = null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '評分選擇區域，當前評分 ${widget.rating > 0 ? "${widget.rating.toInt()} 分" : "未評分"}，滿分 ${widget.starCount} 分',
      hint: '點擊聽取操作說明，按住並左右滑動來改變評分',
      enabled: widget.enabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 說明文字
          const Text(
            '按住螢幕並左右滑動來選擇評分',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // 評分滑動區域
          GestureDetector(
            onTap: widget.enabled ? _speakInstructions : null,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 記錄容器寬度供計算使用
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_containerWidth != constraints.maxWidth) {
                    setState(() {
                      _containerWidth = constraints.maxWidth;
                    });
                  }
                });

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? Colors.blue.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.enabled
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 星星顯示區域（僅用於視覺顯示）
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: widget.spacing,
                        children: List.generate(widget.starCount, (index) {
                          final starValue = index + 1.0;
                          final isFilled = starValue <= widget.rating;

                          return Icon(
                            isFilled ? Icons.star : Icons.star_border,
                            size: widget.starSize,
                            color: widget.enabled
                                ? (isFilled
                                      ? widget.activeColor
                                      : widget.inactiveColor)
                                : Colors.grey.shade400,
                          );
                        }),
                      ),

                      // 當前評分顯示
                      if (widget.showRatingText && widget.rating > 0) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            '${widget.rating.toInt()} 分，滿分 ${widget.starCount} 分',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
