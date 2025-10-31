import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_constants.dart';
import '../utils/tts_helper.dart';
import '../models/order.dart';
import '../models/product_review.dart';
import '../services/order_review_service.dart';
import 'accessible_star_rating.dart';
import 'global_gesture_wrapper.dart';

/// 商品評論對話框
class ProductReviewDialog extends StatefulWidget {
  final OrderItem orderItem;
  final OrderReviewService reviewService;
  final ProductReview? existingReview; // 已存在的評論（用於編輯模式）

  const ProductReviewDialog({
    super.key,
    required this.orderItem,
    required this.reviewService,
    this.existingReview,
  });

  @override
  State<ProductReviewDialog> createState() => _ProductReviewDialogState();
}

class _ProductReviewDialogState extends State<ProductReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0; // 0 表示未評分
  bool _isSubmitting = false;
  bool get _isEditMode => widget.existingReview != null;

  @override
  void initState() {
    super.initState();

    // 如果是編輯模式，載入現有評論資料
    if (_isEditMode) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = _isEditMode ? '編輯' : '新增';
      ttsHelper.speak('$mode商品評論，請在評分區域滑動來選擇評分');
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 朗讀評論對話框完整內容
  void _speakDialogContent() {
    final mode = _isEditMode ? '編輯' : '新增';
    String content = '評論撰寫區，$mode商品評論。';
    content += '商品名稱：${widget.orderItem.productName}，';
    content += '規格：${widget.orderItem.specification}。';

    if (_rating > 0) {
      content += '當前評分：${_rating.toInt()} 分，滿分 5 分。';
    } else {
      content += '尚未評分。';
    }

    content += '請先選擇評分，在評分區域按住螢幕並左右滑動來改變評分，1分最低，5分最高。';
    content += '評分後可以選擇性輸入評論內容，最多500字。';
    content += '完成後雙擊發布評論按鈕即可提交。';

    ttsHelper.speak(content);
  }

  Future<void> _submitReview() async {
    // 檢查是否已選擇評分
    if (_rating == 0) {
      ttsHelper.speak('請先選擇評分');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先選擇評分（1-5星）', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success;
    if (_isEditMode) {
      // 更新現有評論
      success = await widget.reviewService.updateProductReview(
        reviewId: widget.existingReview!.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
    } else {
      // 創建新評論
      success = await widget.reviewService.createProductReview(
        orderId: widget.orderItem.orderId,
        productId: widget.orderItem.productId,
        rating: _rating,
        comment: _commentController.text.trim(),
        userName: '用戶', // 可以從用戶資料中獲取
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        final action = _isEditMode ? '更新' : '發布';
        ttsHelper.speak('評論$action成功');
        Navigator.of(context).pop(true); // 返回 true 表示成功
      } else {
        final action = _isEditMode ? '更新' : '發布';
        ttsHelper.speak('評論$action失敗');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '評論$action失敗，請稍後再試',
              style: const TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GlobalGestureWrapper(
        enabled: true,
        onlyInCustomMode: false,
        child: GestureDetector(
          onTap: () {
            // 點擊非輸入區域時，取消輸入框焦點
            FocusScope.of(context).unfocus();
            // 朗讀對話框內容
            _speakDialogContent();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditMode ? '編輯商品評論' : '商品評論',
                        style: const TextStyle(
                          fontSize: AppFontSizes.title,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ttsHelper.speak('關閉');
                          Navigator.of(context).pop();
                        },
                        tooltip: '關閉',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 商品資訊
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background_2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.orderItem.productName,
                          style: const TextStyle(
                            fontSize: AppFontSizes.subtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.orderItem.specification,
                          style: const TextStyle(
                            color: AppColors.subtitle_2,
                            fontSize: AppFontSizes.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 評分選擇
                  const Text(
                    '評分 *',
                    style: TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AccessibleStarRating(
                    rating: _rating,
                    onRatingChanged: (value) {
                      setState(() => _rating = value);
                    },
                    starSize: 48,
                    spacing: 12,
                    enableHapticFeedback: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 評論內容（選填）
                  const Text(
                    '評論內容（選填）',
                    style: TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    textField: true,
                    label: '評論內容輸入框，選填，最多500字',
                    hint: '輸入您的使用心得',
                    child: TextField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: '分享您的使用心得...',
                        hintStyle: const TextStyle(
                          color: AppColors.subtitle_2,
                          fontSize: AppFontSizes.body,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.background_2,
                        counterStyle: const TextStyle(
                          fontSize: AppFontSizes.body,
                          color: AppColors.subtitle_2,
                        ),
                      ),
                      style: const TextStyle(fontSize: AppFontSizes.body),
                      onTap: () {
                        ttsHelper.speak('輸入評論內容，最多500字');
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 提交按鈕
                  Semantics(
                    button: true,
                    label: _isEditMode ? '更新評論按鈕' : '發布評論按鈕',
                    hint: _isSubmitting ? '提交中' : '雙擊提交評論',
                    enabled: !_isSubmitting,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              final buttonText = _isEditMode ? '更新評論' : '發布評論';
                              String announcement = '$buttonText按鈕，';
                              announcement +=
                                  '商品：${widget.orderItem.productName}，';

                              if (_rating > 0) {
                                announcement +=
                                    '評分：${_rating.toInt()} 分，滿分 5 分，';
                              } else {
                                announcement += '尚未評分，';
                              }

                              final comment = _commentController.text.trim();
                              if (comment.isNotEmpty) {
                                announcement += '評論內容：$comment，';
                              } else {
                                announcement += '無評論內容，';
                              }

                              announcement += '雙擊提交';

                              ttsHelper.speak(announcement);
                              HapticFeedback.lightImpact();
                            },
                      onDoubleTap: _isSubmitting ? null : _submitReview,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: null, // 禁用默認行為，改用 GestureDetector
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubmitting
                                ? AppColors.primary_2.withValues(alpha: 0.6)
                                : AppColors.primary_2,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _isSubmitting
                                ? AppColors.primary_2.withValues(alpha: 0.6)
                                : AppColors.primary_2,
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditMode ? '更新評論' : '發布評論',
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.subtitle,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
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

/// 顯示商品評論對話框的便利方法
Future<bool?> showProductReviewDialog({
  required BuildContext context,
  required OrderItem orderItem,
  required OrderReviewService reviewService,
  ProductReview? existingReview,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ProductReviewDialog(
      orderItem: orderItem,
      reviewService: reviewService,
      existingReview: existingReview,
    ),
  );
}
