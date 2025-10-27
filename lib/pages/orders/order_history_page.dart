import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../services/database_service.dart';
import '../../services/order_status_service.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  late TabController _tabController;
  late OrderStatusService _orderStatusService;

  // 訂單狀態分類
  final List<OrderMainStatus> _statusTabs = [
    OrderMainStatus.pendingPayment,
    OrderMainStatus.pendingShipment,
    OrderMainStatus.pendingDelivery,
    OrderMainStatus.completed,
    OrderMainStatus.returnRefund,
    OrderMainStatus.invalid,
  ];

  bool _isInitialized = false;
  bool _hasSpokenInitialMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      _orderStatusService = OrderStatusService(db);
      _isInitialized = true;
      _loadOrders();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final currentStatus = _statusTabs[_tabController.index];
      final orders = await _orderStatusService.getOrdersByMainStatus(
        currentStatus,
      );

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // 朗讀進入頁面訊息
      if (_isInitialized && !_hasSpokenInitialMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ttsHelper.speak('進入訂單頁面');
        });
        _hasSpokenInitialMessage = true;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ttsHelper.speak('載入訂單失敗');
    }
  }

  /// 取得訂單狀態的詳細文字（包含物流狀態）
  String _getDetailedStatusText(Order order) {
    final mainStatus = order.mainStatus.displayName;

    if (order.mainStatus == OrderMainStatus.pendingDelivery &&
        order.logisticsStatus != LogisticsStatus.none) {
      return '$mainStatus - ${order.logisticsStatus.displayName}';
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

  /// 完成訂單（僅限已簽收的訂單）
  Future<void> _completeOrder(Order order) async {
    final success = await _orderStatusService.completeOrder(order.id);

    if (success) {
      ttsHelper.speak('訂單已完成');
      _loadOrders();
    } else {
      ttsHelper.speak('無法完成訂單，請確認商品已簽收');
    }
  }

  /// 判斷是否可以完成訂單
  bool _canCompleteOrder(Order order) {
    return order.mainStatus == OrderMainStatus.pendingDelivery &&
        order.logisticsStatus == LogisticsStatus.signed;
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_1,
      appBar: AppBar(
        title: const Text('歷史訂單'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: '重新載入訂單',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((status) {
            return Tab(text: status.displayName);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // 禁用左右滑動
        children: _statusTabs.map((status) {
          return _buildOrderList();
        }).toList(),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.list_alt, size: 80, color: AppColors.primary_1),
            SizedBox(height: AppSpacing.md),
            Text('目前沒有訂單', style: AppTextStyles.subtitle),
            SizedBox(height: AppSpacing.sm),
            Text(
              '此狀態的訂單會出現在這裡。',
              style: TextStyle(color: AppColors.subtitle_1),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final statusText = _getDetailedStatusText(order);
        final statusColor = _getStatusColor(order.mainStatus);
        final dateStr =
            '${order.createdAt.year}-'
            '${order.createdAt.month.toString().padLeft(2, '0')}-'
            '${order.createdAt.day.toString().padLeft(2, '0')} '
            '${order.createdAt.hour.toString().padLeft(2, '0')}:'
            '${order.createdAt.minute.toString().padLeft(2, '0')}';
        final canComplete = _canCompleteOrder(order);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            onTap: () {
              ttsHelper.speak(
                '訂單編號 ${order.orderNumber}，'
                '日期 $dateStr，'
                '金額 ${order.total.toStringAsFixed(0)} 元，'
                '狀態 $statusText',
              );
            },
            onDoubleTap: () {
              ttsHelper.speak('查看訂單詳情');
              Navigator.pushNamed(
                context,
                '/order-detail',
                arguments: order.id,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '訂單 #${order.orderNumber}',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: AppFontSizes.small,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppColors.subtitle_1,
                      fontSize: AppFontSizes.body,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('訂單金額', style: AppTextStyles.body),
                      Text(
                        '\$${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.subtitle,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary_1,
                        ),
                      ),
                    ],
                  ),
                  // 操作按鈕
                  if (canComplete) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _completeOrder(order),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('完成訂單'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
