import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../services/database_service.dart';
import '../../services/order_review_service.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../widgets/product_review_dialog.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;
  OrderReviewService? _reviewService;
  bool _canReview = false;
  int? _remainingDays;

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

        // 初始化評論服務
        _reviewService = OrderReviewService(db);

        // 檢查是否可以評論
        final canReview = await _reviewService!.canReviewOrder(orderId);
        final remainingDays = await _reviewService!.getRemainingDaysToReview(
          orderId,
        );

        setState(() {
          _order = order;
          _orderItems = items;
          _canReview = canReview;
          _remainingDays = remainingDays;
          _isLoading = false;
        });

        // 朗讀訂單資訊
        if (_order != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            String message =
                '訂單詳情，訂單編號 ${_order!.orderNumber}，'
                '共 ${_orderItems.length} 項商品，'
                '總金額 ${_order!.total.toStringAsFixed(0)} 元';

            if (_canReview && _remainingDays != null) {
              message += '，可評論，剩餘 $_remainingDays 天';
            }

            ttsHelper.speak(message);
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// 顯示商品評論對話框
  Future<void> _showReviewDialog(OrderItem item) async {
    if (_reviewService == null || _order == null || !mounted) return;

    // 檢查是否已有評論
    final existingReview = await _reviewService!.getProductReview(
      _order!.id,
      item.productId,
    );

    if (!mounted) return;

    final result = await showProductReviewDialog(
      context: context,
      orderItem: item,
      reviewService: _reviewService!,
      existingReview: existingReview,
    );

    if (result == true && mounted) {
      // 評論成功後重新載入訂單資訊
      setState(() {});
    }
  }

  /// 取得訂單狀態的詳細文字（包含物流狀態）
  String _getDetailedStatusText(Order order) {
    final mainStatus = order.mainStatus.displayName;

    if (order.mainStatus == OrderMainStatus.pendingDelivery &&
        order.logisticsStatus != LogisticsStatus.none) {
      // 只顯示物流狀態，避免文字過長導致 overflow
      return order.logisticsStatus.displayName;
    }

    return mainStatus;
  }

  /// 取得訂單狀態的顏色
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
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_1,
      appBar: AppBar(
        title: Text(_order?.orderNumber ?? '訂單詳情'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background_1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? const Center(child: Text('找不到訂單資料', style: AppTextStyles.title))
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
                                    color: _getStatusColor(
                                      _order!.mainStatus,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        _order!.mainStatus,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getDetailedStatusText(_order!),
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        _order!.mainStatus,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppFontSizes.small,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            GestureDetector(
                              onTap: () => ttsHelper.speak(
                                '訂單編號 ${_order!.orderNumber}',
                              ),
                              child: _buildInfoRow('訂單編號', _order!.orderNumber),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            GestureDetector(
                              onTap: () {
                                final dateStr =
                                    '${_order!.createdAt.year} 年 '
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

                    // 評論提示（僅限可評論的訂單）
                    if (_canReview && _remainingDays != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '訂單已完成！您可以在 $_remainingDays 天內評論商品',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.body,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // 商品列表
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('商品明細', style: AppTextStyles.subtitle),
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
                                        color: AppColors.subtitle_1,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color: AppColors.subtitle_1,
                                          fontSize: AppFontSizes.small,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                      // 評論按鈕（僅限已完成的訂單且在30天內）
                                      if (_canReview) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        FutureBuilder<bool>(
                                          future: _reviewService!
                                              .hasReviewedProduct(
                                                _order!.id,
                                                item.productId,
                                              ),
                                          builder: (context, snapshot) {
                                            final hasReviewed =
                                                snapshot.data ?? false;
                                            return OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showReviewDialog(item),
                                              icon: Icon(
                                                hasReviewed
                                                    ? Icons.edit
                                                    : Icons.rate_review,
                                                size: 18,
                                              ),
                                              label: Text(
                                                hasReviewed ? '編輯評論' : '評論此商品',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.botton_1,
                                                side: const BorderSide(
                                                  color: AppColors.botton_1,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.sm,
                                                      vertical: AppSpacing.xs,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
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
                            const Text('付款與配送', style: AppTextStyles.subtitle),
                            const Divider(),
                            GestureDetector(
                              onTap: () => ttsHelper.speak(
                                '付款方式 ${_order!.paymentMethodName}',
                              ),
                              child: _buildInfoRow(
                                '付款方式',
                                _order!.paymentMethodName,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => ttsHelper.speak(
                                '配送方式 ${_order!.shippingMethodName}',
                              ),
                              child: _buildInfoRow(
                                '配送方式',
                                _order!.shippingMethodName,
                              ),
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
                            const Text('費用明細', style: AppTextStyles.subtitle),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      color: AppColors.primary_1,
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
        Text(value, style: AppTextStyles.body.copyWith(color: valueColor)),
      ],
    );
  }
}
