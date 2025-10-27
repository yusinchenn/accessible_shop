import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/tts_helper.dart';
import '../models/order.dart';
import '../models/product_review.dart';
import '../services/order_review_service.dart';

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
      ttsHelper.speak('$mode商品評論，請選擇星級評分');
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  final isFilled = starValue <= _rating;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _rating = starValue);
                      ttsHelper.speak('$starValue 星');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isFilled ? Icons.star : Icons.star_border,
                        size: 48,
                        color: isFilled ? Colors.amber : Colors.grey,
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0)
                Center(
                  child: Text(
                    '$_rating 星',
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.subtitle_2,
                    ),
                  ),
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
              TextField(
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
                ),
                style: const TextStyle(fontSize: AppFontSizes.body),
                onTap: () {
                  ttsHelper.speak('輸入評論內容');
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 提交按鈕
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary_2,
                    foregroundColor: Colors.white,
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
            ],
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
