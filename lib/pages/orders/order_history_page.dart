import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/voice_control_appbar.dart';
import '../../services/database_service.dart';
import '../../services/order_status_service.dart';
import '../../services/order_review_service.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../main.dart' show routeObserver;

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin, RouteAware {
  List<Order> _orders = [];
  final Map<int, List<OrderItem>> _orderItems = {}; // 訂單項目快取
  bool _isLoading = true;
  late TabController _tabController;
  late OrderStatusService _orderStatusService;
  late OrderReviewService _reviewService;
  late DatabaseService _db;

  // 訂單狀態分類（null 表示全部）
  final List<OrderMainStatus?> _statusTabs = [
    null, // 全部
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
      _db = Provider.of<DatabaseService>(context, listen: false);
      _orderStatusService = OrderStatusService(_db);
      _reviewService = OrderReviewService(_db);
      _isInitialized = true;
      _loadOrders();

      // 訂閱路由觀察器
      routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // 取消訂閱路由觀察器
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 當其他頁面彈出並返回到此頁面時調用
  @override
  void didPopNext() {
    // 停止所有正在播放的語音
    ttsHelper.stop();

    // 朗讀返回訊息
    Future.delayed(const Duration(milliseconds: 100), () async {
      final incompleteCount = await _countIncompleteOrders();
      final unreviewedCount = await _countUnreviewedOrders();
      ttsHelper.speak('返回訂單頁面。有$incompleteCount個未完成項目，有$unreviewedCount個未評論項目');
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final currentStatus = _statusTabs[_tabController.index];
      final statusName = currentStatus?.displayName ?? '全部';
      ttsHelper.speak('切換至$statusName訂單');
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final currentStatus = _statusTabs[_tabController.index];
      final List<Order> orders;

      // 如果是 null（全部），獲取所有訂單
      if (currentStatus == null) {
        orders = await _db.getOrders();
      } else {
        orders = await _orderStatusService.getOrdersByMainStatus(currentStatus);
      }

      // 載入所有訂單的項目
      _orderItems.clear();
      for (var order in orders) {
        final items = await _db.getOrderItems(order.id);
        _orderItems[order.id] = items;
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // 朗讀進入頁面訊息
      if (_isInitialized && !_hasSpokenInitialMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final incompleteCount = await _countIncompleteOrders();
          final unreviewedCount = await _countUnreviewedOrders();
          ttsHelper.speak(
            '進入訂單頁面。有$incompleteCount個未完成項目，有$unreviewedCount個未評論項目',
          );
        });
        _hasSpokenInitialMessage = true;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ttsHelper.speak('載入訂單失敗');
    }
  }

  /// 統計未完成訂單數量
  Future<int> _countIncompleteOrders() async {
    final allOrders = await _db.getOrders();
    return allOrders
        .where(
          (order) =>
              order.mainStatus != OrderMainStatus.completed &&
              order.mainStatus != OrderMainStatus.invalid,
        )
        .length;
  }

  /// 統計未評論訂單數量
  Future<int> _countUnreviewedOrders() async {
    final allOrders = await _db.getOrders();
    int count = 0;

    for (var order in allOrders) {
      if (await _reviewService.canReviewOrder(order.id)) {
        final items = await _db.getOrderItems(order.id);
        for (var item in items) {
          final hasReview = await _reviewService.hasReviewedProduct(
            order.id,
            item.productId,
          );
          if (!hasReview) {
            count++;
            break; // 這個訂單有未評論商品，計數後跳出
          }
        }
      }
    }

    return count;
  }

  /// 取得訂單狀態的詳細文字
  String _getDetailedStatusText(Order order) {
    return order.mainStatus.displayName;
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
      backgroundColor: AppColors.primary_2,
      appBar: VoiceControlAppBar(
        title: '訂單',
        onTap: () {
          ttsHelper.speak(
            '訂單頁面。上方可以切換訂單分類，單擊朗讀分類，雙擊進入分類。下方陳列訂單項目，單擊朗讀訂單，雙擊進入訂單詳情頁面',
          );
        },
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background_2,
        titleTextStyle: const TextStyle(color: AppColors.text_2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: '重新載入訂單',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: const TextStyle(fontSize: 24),
            unselectedLabelStyle: const TextStyle(fontSize: 24),
            tabs: _statusTabs.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final tabName = status?.displayName ?? '全部';

              return Tab(
                child: GestureDetector(
                  onTap: () {
                    ttsHelper.speak(tabName);
                  },
                  onDoubleTap: () {
                    _tabController.animateTo(index);
                  },
                  child: Text(tabName),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: _buildOrderList(),
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
          children: [
            Icon(Icons.list_alt, size: 80, color: AppColors.primary_1),
            SizedBox(height: AppSpacing.md),
            Text('目前沒有訂單', style: TextStyle(color: AppColors.primary_1)),
            SizedBox(height: AppSpacing.sm),
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
        final canComplete = _canCompleteOrder(order);

        // 構建語音朗讀內容
        final items = _orderItems[order.id] ?? [];
        final itemsText = items
            .map((item) {
              return '${item.productName}，'
                  '規格${item.specification}，'
                  '數量${item.quantity}，'
                  '單價${item.unitPrice.toStringAsFixed(0)}元';
            })
            .join('，');

        final orderSpeech =
            '訂單，商家${order.storeName}，'
            '$itemsText，'
            '總價${order.total.toStringAsFixed(0)}元'
            '${canComplete ? '，此訂單等待完成確認' : ''}';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            onTap: () {
              ttsHelper.speak(orderSpeech);
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
                  // 商家名稱 - 訂單狀態
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.storeName,
                        style: const TextStyle(
                          fontSize: AppFontSizes.body,
                          color: AppColors.text_2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: AppColors.secondery_2,
                          fontSize: AppFontSizes.body,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  // 商品項目列表
                  ...(_orderItems[order.id] ?? []).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 商品名稱
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: AppFontSizes.body,
                              color: AppColors.text_2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // 商品規格 - 商品數量
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.specification,
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.body,
                                    color: AppColors.subtitle_2,
                                  ),
                                ),
                              ),
                              Text(
                                'x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.body,
                                  color: AppColors.subtitle_2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // 商品單價
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '\$${item.unitPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.body,
                                  color: AppColors.text_2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  // 訂單金額
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        '訂單金額',
                        style: TextStyle(
                          fontSize: AppFontSizes.body,
                          color: AppColors.text_2,
                        ),
                      ),
                      Text(
                        '\$${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text_2,
                        ),
                      ),
                    ],
                  ),
                  // 操作按鈕
                  if (canComplete) ...[
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        ttsHelper.speak('完成訂單按鈕');
                      },
                      onDoubleTap: () {
                        _completeOrder(order);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: null, // 禁用默認點擊，使用 GestureDetector
                          icon: const Icon(Icons.check_circle),
                          label: const Text('完成訂單'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondery_2,
                            foregroundColor: AppColors.bottonText_2,
                            disabledBackgroundColor: AppColors.secondery_2,
                            disabledForegroundColor: AppColors.bottonText_2,
                          ),
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
