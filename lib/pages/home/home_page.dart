// lib/pages/home/home_page.dart
//
// 使用全域 ttsHelper (在 lib/utils/tts_helper.dart 定義)
// 注意此檔案使用相對路徑 import，確保位置為 lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart'; // 使用相對路徑匯入全域的文字轉語音工具（TTS Helper）
import '../../utils/app_constants.dart'; // 匯入全域樣式常數
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器
import '../../services/accessibility_service.dart'; // 匯入無障礙服務
import '../../services/database_service.dart'; // 匯入資料庫服務
import '../../models/order_status.dart'; // 匯入訂單狀態枚舉
import '../../models/notification.dart'; // 匯入通知模型
import '../../models/cart_item.dart'; // 匯入購物車項目模型

/// 定義商店入口卡片的資料結構，用於儲存每個卡片的標題、圖示、路由和內容建構函數
class ShopEntryItem {
  final String title; // 卡片顯示的標題文字
  final IconData icon; // 卡片顯示的圖示
  final String route; // 點擊卡片後導航的路由名稱
  final Widget Function(BuildContext) contentBuilder; // 動態生成卡片內容的函數，返回一個 Widget

  const ShopEntryItem({
    required this.title, // 標題為必要參數
    required this.icon, // 圖示為必要參數
    required this.route, // 路由名稱為必要參數
    required this.contentBuilder, // 內容生成函數為必要參數
  });
}

/// HomePage 是應用程式的首頁，是一個有狀態的 Widget（StatefulWidget）
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // 建構函數，接受一個可選的 key 參數

  @override
  State<HomePage> createState() => _HomePageState(); // 創建對應的狀態物件
}

/// HomePage 的狀態類，管理頁面的動態行為和狀態
class _HomePageState extends State<HomePage> {
  late final PageController _pageController; // 控制 PageView 的滾動控制器，延遲初始化

  int _currentPageIndex = 0; // 當前顯示的卡片索引（對應 _entryItems 的實際索引）
  bool _isAnnouncingHome = false; // 標記是否正在進行首頁進入的語音播報
  bool _speaking = false; // 標記是否正在進行語音播報
  bool _announceScheduled = false; // 標記是否已排程首頁進入的播報

  // 訂單統計數據
  int _pendingPaymentCount = 0; // 待付款訂單數量
  int _pendingShipmentCount = 0; // 待出貨訂單數量
  int _pendingReceiptCount = 0; // 待收貨訂單數量

  // 通知數據
  List<NotificationModel> _notifications = []; // 所有通知列表
  int _totalNotificationCount = 0; // 通知總數

  // 購物車數據
  List<CartItem> _cartItems = []; // 購物車商品列表
  int _totalCartItemCount = 0; // 購物車商品總數

  /// 取得首頁的卡片清單，包含搜尋、購物車、訂單、帳號、短影音和通知六個入口
  List<ShopEntryItem> get _entryItems => <ShopEntryItem>[
    ShopEntryItem(
      title: '搜尋', // 卡片標題
      icon: Icons.search, // 搜尋圖示
      route: '/search_input', // 導航到搜尋輸入頁面
      contentBuilder: (context) => const Center(
        child: Text(
          '搜尋商品',
          style: TextStyle(fontSize: 24, color: AppColors.subtitle),
        ),
      ),
    ),
    ShopEntryItem(
      title: '購物車',
      icon: Icons.shopping_cart,
      route: '/cart',
      contentBuilder: (context) => Center(
        child: _buildCartSummary(),
      ),
    ),
    ShopEntryItem(
      title: '訂單',
      icon: Icons.list_alt,
      route: '/orders',
      contentBuilder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '待付款：$_pendingPaymentCount',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '待出貨：$_pendingShipmentCount',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '待收貨：$_pendingReceiptCount',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
    ShopEntryItem(
      title: '帳號',
      icon: Icons.person,
      route: '/settings',
      contentBuilder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '帳號資訊',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'APP設定',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '幫助與客服',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    ),
    ShopEntryItem(
      title: '短影音',
      icon: Icons.video_library,
      route: '/short_videos',
      contentBuilder: (context) => const Center(child: Text('短影音入口')),
    ),
    ShopEntryItem(
      title: '通知',
      icon: Icons.notifications,
      route: '/notifications',
      contentBuilder: (context) => Center(
        child: _buildNotificationSummary(),
      ),
    ),
  ];

  /// 初始化狀態，設置 PageView 控制器並監聽頁面變化
  @override
  void initState() {
    super.initState();

    final int initialPageOffset =
        _entryItems.length * 1000; // 設置初始頁面偏移，實現無限滾動效果
    _pageController = PageController(
      viewportFraction: 0.85, // 每個卡片佔據視窗寬度的 85%，營造間距效果
      initialPage: initialPageOffset, // 設置初始頁面索引
    );
    _currentPageIndex = initialPageOffset % _entryItems.length; // 計算實際的卡片索引
    _pageController.addListener(_onPageChanged); // 監聽頁面變化事件
  }

  /// 構建購物車摘要 Widget
  Widget _buildCartSummary() {
    if (_cartItems.isEmpty) {
      return const Text(
        '購物車是空的',
        style: TextStyle(fontSize: 20, color: AppColors.subtitle),
      );
    }

    // 如果購物車商品數量 <= 3，顯示所有商品
    if (_totalCartItemCount <= 3) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _cartItems.map((cartItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              cartItem.name,
              style: const TextStyle(fontSize: 20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      );
    }

    // 如果購物車商品數量 > 3，顯示前兩筆 + 剩餘數量
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            _cartItems[0].name,
            style: const TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            _cartItems[1].name,
            style: const TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '+${_totalCartItemCount - 2}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 構建通知摘要 Widget
  Widget _buildNotificationSummary() {
    if (_notifications.isEmpty) {
      return const Text(
        '目前沒有通知',
        style: TextStyle(fontSize: 20, color: AppColors.subtitle),
      );
    }

    // 如果通知數量 <= 3，顯示所有通知
    if (_totalNotificationCount <= 3) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _notifications.map((notification) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              notification.title,
              style: const TextStyle(fontSize: 20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      );
    }

    // 如果通知數量 > 3，顯示前兩筆 + 剩餘數量
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            _notifications[0].title,
            style: const TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            _notifications[1].title,
            style: const TextStyle(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '+${_totalNotificationCount - 2}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 加載訂單統計數據
  Future<void> _loadOrderStats() async {
    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final orders = await db.getOrders();

      int pendingPayment = 0;
      int pendingShipment = 0;
      int pendingReceipt = 0;

      for (var order in orders) {
        // 根據訂單的 mainStatus 分類統計
        switch (order.mainStatus) {
          case OrderMainStatus.pendingPayment:
            pendingPayment++;
            break;
          case OrderMainStatus.pendingShipment:
            pendingShipment++;
            break;
          case OrderMainStatus.pendingDelivery:
            pendingReceipt++;
            break;
          case OrderMainStatus.completed:
          case OrderMainStatus.returnRefund:
          case OrderMainStatus.invalid:
            // 不計入統計
            break;
        }
      }

      setState(() {
        _pendingPaymentCount = pendingPayment;
        _pendingShipmentCount = pendingShipment;
        _pendingReceiptCount = pendingReceipt;
      });
    } catch (e) {
      // 載入失敗時保持預設值 0
      if (mounted) {
        setState(() {
          _pendingPaymentCount = 0;
          _pendingShipmentCount = 0;
          _pendingReceiptCount = 0;
        });
      }
    }
  }

  /// 加載通知數據
  Future<void> _loadNotifications() async {
    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final notifications = await db.getNotifications();

      setState(() {
        _totalNotificationCount = notifications.length;
        // 只取前三筆用於顯示
        _notifications = notifications.take(3).toList();
      });
    } catch (e) {
      // 載入失敗時保持預設值
      if (mounted) {
        setState(() {
          _notifications = [];
          _totalNotificationCount = 0;
        });
      }
    }
  }

  /// 加載購物車數據
  Future<void> _loadCartItems() async {
    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final cartItems = await db.getCartItems();

      setState(() {
        _totalCartItemCount = cartItems.length;
        // 只取前三筆用於顯示
        _cartItems = cartItems.take(3).toList();
      });
    } catch (e) {
      // 載入失敗時保持預設值
      if (mounted) {
        setState(() {
          _cartItems = [];
          _totalCartItemCount = 0;
        });
      }
    }
  }

  /// 當依賴項變更時（例如導航狀態變化），檢查是否需要播報首頁進入語音
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化無障礙服務
    accessibilityService.initialize(context);

    final routeIsCurrent =
        ModalRoute.of(context)?.isCurrent ?? false; // 檢查當前頁面是否為活躍路由
    if (routeIsCurrent && !_announceScheduled) {
      // 如果是活躍頁面且未排程播報
      _announceScheduled = true; // 標記已排程
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 在框架繪製完成後執行
        _announceScheduled = false; // 重置排程標記
        _announceEnter(); // 執行首頁進入語音播報
        _loadOrderStats(); // 加載訂單統計數據
        _loadNotifications(); // 加載通知數據
        _loadCartItems(); // 加載購物車數據
      });
    }
  }

  /// 執行首頁進入的語音播報，播報「進入首頁」和當前卡片標題
  Future<void> _announceEnter() async {
    if (_isAnnouncingHome) return; // 如果正在播報首頁，則跳過

    // 只在自訂模式播放語音
    if (!accessibilityService.shouldUseCustomTTS) return;

    // 先設置標記，防止 _onPageChanged 打斷
    _isAnnouncingHome = true; // 標記正在播報首頁
    _speaking = true; // 標記正在語音播報

    try {
      await ttsHelper.stop(); // 停止任何正在進行的語音播報，確保乾淨的播報環境

      await ttsHelper.speak('進入首頁'); // 播報「進入首頁」
      if (!_isAnnouncingHome || !_speaking) return; // 檢查是否被中斷

      await Future.delayed(const Duration(seconds: 1)); // 等待 1 秒
      if (!_isAnnouncingHome || !_speaking) return; // 檢查是否被中斷

      await ttsHelper.speak(_entryItems[_currentPageIndex].title); // 播報當前卡片標題
    } finally {
      _isAnnouncingHome = false; // 重置首頁播報標記
      _speaking = false; // 重置語音播報標記
    }
  }

  /// 監聽 PageView 頁面變化，當卡片切換時更新索引並播報新卡片標題
  void _onPageChanged() {
    final int? page = _pageController.page?.round(); // 獲取當前頁面索引（四捨五入）
    if (page == null) return; // 如果頁面索引無效，則跳過
    final int actual = page % _entryItems.length; // 計算實際的卡片索引（處理無限滾動）
    if (actual == _currentPageIndex) return; // 如果索引未變，則跳過

    setState(() {
      _currentPageIndex = actual; // 更新當前卡片索引
    });

    // 如果正在進行系統播報或語音播報，則不進行新播報
    if (_isAnnouncingHome || _speaking) return;

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(_entryItems[_currentPageIndex].title); // 播報新卡片的標題
    }
  }

  /// 清理資源，釋放 PageController
  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged); // 移除頁面變化監聽器
    _pageController.dispose(); // 釋放 PageController
    // 不要 dispose 全域 ttsHelper，因為它是全域資源
    super.dispose();
  }

  /// 處理單次點擊事件，播報當前卡片的標題
  void _onSingleTap(int index) {
    if (_isAnnouncingHome || _speaking) return; // 如果正在播報，則跳過
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(_entryItems[index].title); // 播報點擊的卡片標題
    }
  }

  /// 處理雙擊事件，導航到指定路由
  void _onDoubleTap(String route) {
    Navigator.pushNamed(context, route).then((_) {
      // 導航返回後，didChangeDependencies 會觸發 _announceEnter
    });
  }

  /// 構建頁面 UI，使用 Scaffold 和 PageView 顯示卡片
  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(
        title: const Text('首頁'), // 顯示固定文字「首頁」
        centerTitle: true, // 標題居中
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75, // 卡片區域高度為螢幕高度的 75%
          child: PageView.builder(
            controller: _pageController, // 使用 PageController 控制滾動
            itemCount: 999999, // 設置大量項目數以實現無限滾動
            itemBuilder: (context, index) {
              final actualIndex = index % _entryItems.length; // 計算實際卡片索引

              // 計算卡片的透明度，營造淡出淡入效果
              double opacity = 1.0;
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                final double value =
                    (index.toDouble() - (_pageController.page ?? 0)).abs(); // 計算與當前頁面的距離
                // 當前卡片 (value < 0.5) 完全不透明(1.0)，旁邊的卡片半透明(0.3)
                opacity = value < 0.5 ? 1.0 : 0.3;
              }

              return Align(
                alignment: Alignment.center, // 卡片居中對齊
                child: Opacity(
                  opacity: opacity, // 應用淡出淡入效果
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // 增加卡片間距
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85, // 設定卡片寬度為螢幕寬度的 85%
                      child: GestureDetector(
                      onTap: () => _onSingleTap(actualIndex), // 單次點擊觸發語音播報
                      onDoubleTap: () => _onDoubleTap(
                        _entryItems[actualIndex].route,
                      ), // 雙擊導航到對應路由
                      child: Card(
                      elevation: 8, // 卡片陰影效果
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // 圓角邊框
                      ),
                      clipBehavior: Clip.antiAlias, // 裁剪溢出內容
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md), // 卡片內邊距
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, // 內容垂直居中
                          children: [
                            Icon(
                              _entryItems[actualIndex].icon, // 顯示卡片圖示
                              size: 60, // 圖示大小
                              color: AppColors.text, // 圖示顏色
                            ),
                            const SizedBox(height: AppSpacing.md), // 間距
                            Text(
                              _entryItems[actualIndex].title, // 顯示卡片標題
                              style: AppTextStyles.title,
                            ),
                            const SizedBox(height: AppSpacing.md), // 間距
                            Expanded(
                              child: _entryItems[actualIndex].contentBuilder(
                                context,
                              ), // 動態生成卡片內容
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
