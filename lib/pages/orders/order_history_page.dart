import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final orders = await db.getOrders();

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // 朗讀進入頁面訊息
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_orders.isEmpty) {
          ttsHelper.speak('進入訂單頁面，目前沒有訂單');
        } else {
          ttsHelper.speak('進入訂單頁面，共有 ${_orders.length} 筆訂單');
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ttsHelper.speak('載入訂單失敗');
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
        title: const Text('歷史訂單'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: '重新載入訂單',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.list_alt, size: 80, color: AppColors.primary),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        '目前沒有訂單',
                        style: AppTextStyles.subtitle,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '你的訂單紀錄會出現在這裡。',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final statusText = _getStatusText(order.status);
                    final statusColor = _getStatusColor(order.status);
                    final dateStr = '${order.createdAt.year}-'
                        '${order.createdAt.month.toString().padLeft(2, '0')}-'
                        '${order.createdAt.day.toString().padLeft(2, '0')} '
                        '${order.createdAt.hour.toString().padLeft(2, '0')}:'
                        '${order.createdAt.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
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
                      child: Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                      border: Border.all(
                                        color: statusColor,
                                        width: 1,
                                      ),
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
                                  color: AppColors.subtitle,
                                  fontSize: AppFontSizes.body,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Divider(),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '訂單金額',
                                    style: AppTextStyles.body,
                                  ),
                                  Text(
                                    '\$${order.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: AppFontSizes.subtitle,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}