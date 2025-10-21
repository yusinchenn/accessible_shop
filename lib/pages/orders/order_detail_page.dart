import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadOrderDetail();
    }
  }

  Future<void> _loadOrderDetail() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    int? orderId;

    if (args is int) {
      orderId = args;
    }

    if (orderId != null) {
      try {
        final db = Provider.of<DatabaseService>(context, listen: false);
        final order = await db.getOrderById(orderId);
        final items = await db.getOrderItems(orderId);

        setState(() {
          _order = order;
          _orderItems = items;
          _isLoading = false;
        });

        // 朗讀訂單資訊
        if (_order != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ttsHelper.speak(
              '訂單詳情，訂單編號 ${_order!.orderNumber}，'
              '共 ${_orderItems.length} 項商品，'
              '總金額 ${_order!.total.toStringAsFixed(0)} 元',
            );
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// 取得訂單狀態的顯示文字
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待處理';
      case 'processing':
        return '處理中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  /// 取得訂單狀態的顏色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_order?.orderNumber ?? '訂單詳情'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(
                  child: Text(
                    '找不到訂單資料',
                    style: AppTextStyles.title,
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 訂單狀態卡片
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '訂單狀態',
                                      style: AppTextStyles.subtitle,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_order!.status)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _getStatusColor(_order!.status),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(_order!.status),
                                        style: TextStyle(
                                          color: _getStatusColor(_order!.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                GestureDetector(
                                  onTap: () => ttsHelper.speak('訂單編號 ${_order!.orderNumber}'),
                                  child: _buildInfoRow('訂單編號', _order!.orderNumber),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                GestureDetector(
                                  onTap: () {
                                    final dateStr = '${_order!.createdAt.year} 年 '
                                        '${_order!.createdAt.month} 月 '
                                        '${_order!.createdAt.day} 日';
                                    ttsHelper.speak('訂單日期 $dateStr');
                                  },
                                  child: _buildInfoRow(
                                    '訂單日期',
                                    '${_order!.createdAt.year}-'
                                        '${_order!.createdAt.month.toString().padLeft(2, '0')}-'
                                        '${_order!.createdAt.day.toString().padLeft(2, '0')} '
                                        '${_order!.createdAt.hour.toString().padLeft(2, '0')}:'
                                        '${_order!.createdAt.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 商品列表
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '商品明細',
                                  style: AppTextStyles.subtitle,
                                ),
                                const Divider(),
                                ..._orderItems.map((item) {
                                  return GestureDetector(
                                    onTap: () {
                                      ttsHelper.speak(
                                        '${item.productName}，'
                                        '${item.specification}，'
                                        '單價 ${item.unitPrice.toStringAsFixed(0)} 元，'
                                        '數量 ${item.quantity}，'
                                        '小計 ${item.subtotal.toStringAsFixed(0)} 元',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.divider,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            item.specification,
                                            style: const TextStyle(
                                              color: AppColors.subtitle,
                                              fontSize: AppFontSizes.small,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '\$${item.unitPrice.toStringAsFixed(0)} x ${item.quantity}',
                                              ),
                                              Text(
                                                '\$${item.subtotal.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 付款與配送資訊
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '付款與配送',
                                  style: AppTextStyles.subtitle,
                                ),
                                const Divider(),
                                GestureDetector(
                                  onTap: () => ttsHelper.speak('付款方式 ${_order!.paymentMethodName}'),
                                  child: _buildInfoRow('付款方式', _order!.paymentMethodName),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                GestureDetector(
                                  onTap: () => ttsHelper.speak('配送方式 ${_order!.shippingMethodName}'),
                                  child: _buildInfoRow('配送方式', _order!.shippingMethodName),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 費用明細
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '費用明細',
                                  style: AppTextStyles.subtitle,
                                ),
                                const Divider(),
                                GestureDetector(
                                  onTap: () => ttsHelper.speak(
                                    '商品小計 ${_order!.subtotal.toStringAsFixed(0)} 元',
                                  ),
                                  child: _buildInfoRow(
                                    '商品小計',
                                    '\$${_order!.subtotal.toStringAsFixed(0)}',
                                  ),
                                ),
                                if (_order!.discount > 0) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  GestureDetector(
                                    onTap: () => ttsHelper.speak(
                                      '優惠折扣 ${_order!.discount.toStringAsFixed(0)} 元',
                                    ),
                                    child: _buildInfoRow(
                                      '優惠折扣 (${_order!.couponName ?? ""})',
                                      '-\$${_order!.discount.toStringAsFixed(0)}',
                                      valueColor: Colors.red,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.xs),
                                GestureDetector(
                                  onTap: () => ttsHelper.speak(
                                    '運費 ${_order!.shippingFee.toStringAsFixed(0)} 元',
                                  ),
                                  child: _buildInfoRow(
                                    '運費',
                                    '\$${_order!.shippingFee.toStringAsFixed(0)}',
                                  ),
                                ),
                                const Divider(),
                                GestureDetector(
                                  onTap: () => ttsHelper.speak(
                                    '訂單總額 ${_order!.total.toStringAsFixed(0)} 元',
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '訂單總額',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.subtitle,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$${_order!.total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.subtitle,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// 建立資訊列
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}