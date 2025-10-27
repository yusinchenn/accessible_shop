import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/app_constants.dart';

/// 單一商品卡片
/// 可用於搜尋結果、商品列表等多個頁面
class ProductCard extends StatelessWidget {
  final Product product;
  final String? tag; // 可選的標籤（例如：隔日到貨）
  final String? storeName; // 商家名稱
  final VoidCallback? onStoreDoubleTap; // 雙擊商家時的回調

  const ProductCard({
    super.key,
    required this.product,
    this.tag,
    this.storeName,
    this.onStoreDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 商品名稱
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: AppColors.text_1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 價格
            Text(
              '\$${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 30,
                color: AppColors.text_1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 評分顯示
            if (product.reviewCount > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 24, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    product.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text_1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${product.reviewCount}則評論)',
                    style: const TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                ],
              ),
            if (product.reviewCount > 0) const SizedBox(height: AppSpacing.sm),

            // 商家名稱（如果有）
            if (storeName != null)
              GestureDetector(
                onDoubleTap: onStoreDoubleTap,
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 22, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      storeName!,
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.grey,
                        decoration: onStoreDoubleTap != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            if (storeName != null) const SizedBox(height: AppSpacing.sm),

            // 商品描述
            Text(
              product.description ?? '無描述',
              style: const TextStyle(fontSize: 30, color: AppColors.text_1),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),

            // 標籤（如果有）
            if (tag != null || product.category != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent_1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag ?? product.category ?? '',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
