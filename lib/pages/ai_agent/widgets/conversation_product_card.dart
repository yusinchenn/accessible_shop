/// conversation_product_card.dart
/// AI Agent 對話中的商品卡片元件
library;

import 'package:flutter/material.dart';
import '../../../models/product.dart';

/// 商品卡片（用於對話中）
class ConversationProductCard extends StatelessWidget {
  final Product product;

  const ConversationProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: () {
          // 點擊可導航到商品詳情頁（可選）
          // Navigator.pushNamed(context, '/product-detail', arguments: product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品圖片
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 40);
                          },
                        ),
                      )
                    : const Icon(Icons.image, size: 40),
              ),
              const SizedBox(width: 12),
              // 商品資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名稱
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 商品描述
                    if (product.description != null)
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // 價格與評分
                    Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (product.reviewCount > 0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            ' (${product.reviewCount})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 庫存
                    Text(
                      '庫存: ${product.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: product.stock > 10
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 商品列表卡片（顯示多個商品）
class ConversationProductListCard extends StatelessWidget {
  final List<Product> products;
  final String? title;

  const ConversationProductListCard({
    super.key,
    required this.products,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ...products.map((product) => ConversationProductCard(product: product)),
        ],
      ),
    );
  }
}
