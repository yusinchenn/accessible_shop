/// conversation_cart_card.dart
/// AI Agent 對話中的購物車卡片元件
library;

import 'package:flutter/material.dart';
import '../../../models/cart_item.dart';

/// 購物車摘要卡片（顯示購物車概覽）
class ConversationCartCard extends StatelessWidget {
  final List<CartItem> cartItems;

  const ConversationCartCard({
    super.key,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  '購物車是空的',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalPrice = cartItems
        .where((item) => item.isSelected)
        .fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity));
    final selectedCount = cartItems.where((item) => item.isSelected).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                const Icon(Icons.shopping_cart, size: 20),
                const SizedBox(width: 8),
                Text(
                  '購物車 (${cartItems.length} 項)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 商品列表（最多顯示3項）
            ...cartItems.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // 選取標記
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isSelected
                              ? Colors.blue
                              : Colors.grey[300],
                        ),
                        child: item.isSelected
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // 商品資訊
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.specification,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 數量與價格
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '\$${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            if (cartItems.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '還有 ${cartItems.length - 3} 項...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const Divider(height: 20),
            // 總計
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已選 $selectedCount 項',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '總計',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
