// lib/widgets/custom_card.dart
//
// CustomCard：接收 productMap (id, name, price, imageUrl) 並顯示
// 提供 onAddToCart callback 與整張卡片的點擊行為由父層處理 (例如首頁會包 GestureDetector)

import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Map<String, dynamic> productMap;
  final VoidCallback onAddToCart;

  const CustomCard({super.key, required this.productMap, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final String name = productMap['name'] ?? 'Unknown';
    final double price = (productMap['price'] is num) ? (productMap['price'] as num).toDouble() : 0.0;
    final String imageUrl = (productMap['imageUrl'] as String?) ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖片區（若失敗顯示 icon）
          Expanded(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  )
                : Center(child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('\$${price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[700])),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.teal),
                    onPressed: onAddToCart,
                    tooltip: '加入購物車',
                  ),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
