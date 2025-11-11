/// conversation_order_card.dart
/// AI Agent 對話中的訂單卡片元件
library;

import 'package:flutter/material.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';

/// 訂單卡片（用於對話中）
class ConversationOrderCard extends StatelessWidget {
  final Order order;

  const ConversationOrderCard({
    super.key,
    required this.order,
  });

  String _getStatusText(OrderMainStatus status) {
    switch (status) {
      case OrderMainStatus.pendingPayment:
        return '待付款';
      case OrderMainStatus.pendingShipment:
        return '待出貨';
      case OrderMainStatus.pendingDelivery:
        return '待收貨';
      case OrderMainStatus.completed:
        return '已完成';
      case OrderMainStatus.returnRefund:
        return '退貨/退款';
      case OrderMainStatus.invalid:
        return '不成立';
    }
  }

  String _getLogisticsStatusText(LogisticsStatus status) {
    switch (status) {
      case LogisticsStatus.none:
        return '';
      case LogisticsStatus.inTransit:
        return '運送中';
      case LogisticsStatus.arrivedAtPickupPoint:
        return '已抵達收貨地點';
      case LogisticsStatus.signed:
        return '已簽收';
    }
  }

  Color _getStatusColor(OrderMainStatus status) {
    switch (status) {
      case OrderMainStatus.pendingPayment:
        return Colors.orange;
      case OrderMainStatus.pendingShipment:
        return Colors.blue;
      case OrderMainStatus.pendingDelivery:
        return Colors.purple;
      case OrderMainStatus.completed:
        return Colors.green;
      case OrderMainStatus.returnRefund:
        return Colors.red;
      case OrderMainStatus.invalid:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logisticsText = _getLogisticsStatusText(order.logisticsStatus);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: () {
          // 點擊可導航到訂單詳情頁（可選）
          // Navigator.pushNamed(context, '/order-detail', arguments: order);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 訂單編號與狀態
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '訂單 ${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.mainStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(order.mainStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(order.mainStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 商家名稱
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.storeName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (logisticsText.isNotEmpty) ...[
                const SizedBox(height: 6),
                // 物流狀態
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      logisticsText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // 配送與付款資訊
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.shippingMethodName} • ${order.paymentMethodName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 總金額
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '總金額',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 訂單列表卡片（顯示多個訂單）
class ConversationOrderListCard extends StatelessWidget {
  final List<Order> orders;
  final String? title;

  const ConversationOrderListCard({
    super.key,
    required this.orders,
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
          ...orders.map((order) => ConversationOrderCard(order: order)),
        ],
      ),
    );
  }
}
