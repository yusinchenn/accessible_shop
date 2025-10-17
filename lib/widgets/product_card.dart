import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/app_constants.dart';

/// 單一商品卡片
/// 可用於搜尋結果、商品列表等多個頁面
class ProductCard extends StatelessWidget {
  final Product product;
  final String? tag; // 可選的標籤（例如：隔日到貨）

  const ProductCard({
    super.key,
    required this.product,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 價格
            Text(
              '\$${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 30,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 商品描述
            Expanded(
              child: Text(
                product.description ?? '無描述',
                style: const TextStyle(
                  fontSize: 30,
                  color: AppColors.text,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
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
                    color: AppColors.accent,
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