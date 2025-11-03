// lib/pages/home/home_page.dart
//
// 使用全域 ttsHelper (在 lib/utils/tts_helper.dart 定義)
// 注意此檔案使用相對路徑 import，確保位置為 lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart'; // 使用相對路徑匯入全域的文字轉語音工具（TTS Helper）
import '../../utils/app_constants.dart'; // 匯入全域樣式常數
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器
import '../../widgets/voice_control_appbar.dart'; // 匯入語音控制 AppBar
import '../../services/accessibility_service.dart'; // 匯入無障礙服務
import '../../services/database_service.dart'; // 匯入資料庫服務
import '../../services/notification_service.dart'; // 匯入通知服務
import '../../models/order_status.dart'; // 匯入訂單狀態枚舉
import '../../models/notification.dart'; // 匯入通知模型
import '../../models/cart_item.dart'; // 匯入購物車項目模型

/// 文字變色波浪動畫 Widget，由前往後輪流高亮每個字符
class ColorWaveText extends StatefulWidget {
  final String text; // 要顯示的完整文字
  final TextStyle? baseStyle; // 基礎文字樣式
  final Color baseColor; // 基礎文字顏色
  final Color highlightColor; // 高亮文字顏色
  final Duration duration; // 每個字符高亮的持續時間

  const ColorWaveText({
    super.key,
    required this.text,
    this.baseStyle,
    this.baseColor = AppColors.subtitle_1,
    this.highlightColor = AppColors.accent_1,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ColorWaveText> createState() => _ColorWaveTextState();
}

class _ColorWaveTextState extends State<ColorWaveText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _highlightIndex;

  @override
  void initState() {
    super.initState();

    // 計算總動畫時長 = 字符數 * 每個字符的持續時間
    final totalDuration = widget.duration * widget.text.length;

    _controller = AnimationController(
      duration: totalDuration,
      vsync: this,
    );

    // 創建高亮索引動畫（從 0 到文字長度-1）
    _highlightIndex = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // 循環播放動畫
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightIndex,
      builder: (context, child) {
        final currentIndex = _highlightIndex.value % widget.text.length;

        return RichText(
          text: TextSpan(
            children: List.generate(widget.text.length, (index) {
              final isHighlight = index == currentIndex;
              return TextSpan(
                text: widget.text[index],
                style: (widget.baseStyle ?? const TextStyle(fontSize: 24))
                    .copyWith(
                  color: isHighlight ? widget.highlightColor : widget.baseColor,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// 打字機動畫 Widget，逐字顯示文字並帶有閃爍游標
class TypingAnimationText extends StatefulWidget {
  final String text; // 要顯示的完整文字
  final TextStyle? style; // 文字樣式
  final Duration typingSpeed; // 每個字符的顯示速度
  final Duration pauseDuration; // 完整顯示後的暫停時間

  const TypingAnimationText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 300),
    this.pauseDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<TypingAnimationText> createState() => _TypingAnimationTextState();
}

class _TypingAnimationTextState extends State<TypingAnimationText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();

    // 計算總動畫時長 = (字符數 * 打字速度) + 暫停時間
    final totalDuration =
        widget.typingSpeed * widget.text.length + widget.pauseDuration;

    _controller = AnimationController(duration: totalDuration, vsync: this);

    // 創建字符數量動畫（從 0 到文字長度）
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0,
          widget.typingSpeed.inMilliseconds *
              widget.text.length /
              totalDuration.inMilliseconds,
          curve: Curves.linear,
        ),
      ),
    );

    // 循環播放動畫
    _controller.repeat();

    // 游標閃爍效果
    _startCursorBlink();
  }

  void _startCursorBlink() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
        _startCursorBlink();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        final displayText = widget.text.substring(0, _characterCount.value);
        final cursor = _showCursor ? '│' : '    ';

        return Text('$displayText$cursor', style: widget.style);
      },
    );
  }
}

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
  int _unreadNotificationCount = 0; // 未讀通知數量

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
        child: TypingAnimationText(
          text: '搜尋商品',
          style: TextStyle(fontSize: 24, color: AppColors.accent_1),
          typingSpeed: Duration(milliseconds: 300),
          pauseDuration: Duration(milliseconds: 2000),
        ),
      ),
    ),
    ShopEntryItem(
      title: '購物車',
      icon: Icons.shopping_cart,
      route: '/cart',
      contentBuilder: (context) => Center(child: _buildCartSummary()),
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: _pendingPaymentCount > 0
                    ? AppColors.accent_1
                    : AppColors.subtitle_1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '待出貨：$_pendingShipmentCount',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: _pendingShipmentCount > 0
                    ? AppColors.accent_1
                    : AppColors.subtitle_1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '待收貨：$_pendingReceiptCount',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: _pendingReceiptCount > 0
                    ? AppColors.accent_1
                    : AppColors.subtitle_1,
              ),
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
            Text('帳號資訊', style: TextStyle(fontSize: 24)),
            SizedBox(height: AppSpacing.sm),
            Text('APP設定', style: TextStyle(fontSize: 24)),
            SizedBox(height: AppSpacing.sm),
            Text('幫助與客服', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    ),
    ShopEntryItem(
      title: '短影音',
      icon: Icons.video_library,
      route: '/short_videos',
      contentBuilder: (context) => const Center(
        child: ColorWaveText(
          text: '短影音入口',
          baseStyle: TextStyle(fontSize: 24),
          baseColor: AppColors.subtitle_1,
          highlightColor: AppColors.accent_1,
          duration: Duration(milliseconds: 500),
        ),
      ),
    ),
    ShopEntryItem(
      title: '通知',
      icon: Icons.notifications,
      route: '/notifications',
      contentBuilder: (context) => Center(child: _buildNotificationSummary()),
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

    // 請求通知權限
    _requestNotificationPermission();
  }

  /// 請求通知權限
  Future<void> _requestNotificationPermission() async {
    final hasPermission = await notificationService.checkNotificationPermission();
    if (!hasPermission) {
      await notificationService.requestNotificationPermission();
    }
  }

  /// 構建購物車摘要 Widget
  Widget _buildCartSummary() {
    if (_cartItems.isEmpty) {
      return const Text(
        '購物車是空的',
        style: TextStyle(fontSize: 24, color: AppColors.text_1),
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
              style: const TextStyle(fontSize: 24, color: AppColors.accent_1),
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
            style: const TextStyle(fontSize: 24, color: AppColors.accent_1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            _cartItems[1].name,
            style: const TextStyle(fontSize: 24, color: AppColors.accent_1),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accent_1,
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
        style: TextStyle(fontSize: 24, color: AppColors.subtitle_1),
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
              style: TextStyle(
                fontSize: 24,
                color: notification.isRead
                    ? AppColors.subtitle_1
                    : AppColors.accent_1,
              ),
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
            style: TextStyle(
              fontSize: 24,
              color: _notifications[0].isRead
                  ? AppColors.subtitle_1
                  : AppColors.accent_1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            _notifications[1].title,
            style: TextStyle(
              fontSize: 24,
              color: _notifications[1].isRead
                  ? AppColors.subtitle_1
                  : AppColors.accent_1,
            ),
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
              color: AppColors.text_1,
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
        // 統計未讀通知數量
        _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
        // 只取前三筆用於顯示
        _notifications = notifications.take(3).toList();
      });
    } catch (e) {
      // 載入失敗時保持預設值
      if (mounted) {
        setState(() {
          _notifications = [];
          _totalNotificationCount = 0;
          _unreadNotificationCount = 0;
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
      // 等待一小段時間，確保手勢導航的語音播報已完成
      await Future.delayed(const Duration(milliseconds: 100));

      await ttsHelper.stop(); // 停止任何正在進行的語音播報，確保乾淨的播報環境

      // 使用 speakQueue 連續播放，避免多次 timeout 延遲
      await ttsHelper.speakQueue([
        '進入首頁',
        '${_entryItems[_currentPageIndex].title}入口',
      ]);
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
      ttsHelper.speak('${_entryItems[_currentPageIndex].title}入口'); // 播報新卡片的標題
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
      String announcement;

      // 根據不同的入口類型，播報不同的詳細信息
      switch (index) {
        case 1: // 購物車
          announcement = '購物車入口，有$_totalCartItemCount項商品';
          break;
        case 2: // 訂單
          announcement =
              '訂單入口，有待付款$_pendingPaymentCount筆、待出貨$_pendingShipmentCount筆、待收貨$_pendingReceiptCount筆';
          break;
        case 5: // 通知
          announcement = '通知入口，有$_unreadNotificationCount項未讀通知';
          break;
        default:
          announcement = '${_entryItems[index].title}入口';
      }

      ttsHelper.speak(announcement); // 播報點擊的卡片標題及詳細信息
    }
  }

  /// 處理雙擊事件，導航到指定路由
  void _onDoubleTap(String route) {
    Navigator.pushNamed(context, route).then((_) {
      // 導航返回後，didChangeDependencies 會觸發 _announceEnter
    });
  }

  /// 處理 AppBar 點擊事件，朗讀頁面指引
  void _onAppBarTap() {
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak('首頁，包含搜尋、購物車、訂單、帳號、短影音、通知入口，左右滑動切換項目，單擊朗讀項目，雙擊進入項目');
    }
  }

  /// 構建頁面 UI，使用 Scaffold 和 PageView 顯示卡片
  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_1, // 套用背景色
      appBar: VoiceControlAppBar(
        title: '首頁', // 顯示固定文字「首頁」
        onTap: _onAppBarTap, // 短按時朗讀頁面指引，長按2秒開啟/關閉語音控制
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
                    (index.toDouble() - (_pageController.page ?? 0))
                        .abs(); // 計算與當前頁面的距離
                // 當前卡片 (value < 0.5) 完全不透明(1.0)，旁邊的卡片半透明(0.3)
                opacity = value < 0.5 ? 1.0 : 0.3;
              }

              return Align(
                alignment: Alignment.center, // 卡片居中對齊
                child: Opacity(
                  opacity: opacity, // 應用淡出淡入效果
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ), // 增加卡片間距
                    child: SizedBox(
                      width:
                          MediaQuery.of(context).size.width *
                          0.85, // 設定卡片寬度為螢幕寬度的 85%
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
                            padding: const EdgeInsets.all(
                              AppSpacing.md,
                            ), // 卡片內邊距
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center, // 內容垂直居中
                              children: [
                                const SizedBox(height: AppSpacing.md), // 增加圖示與卡片上邊的間隔
                                Icon(
                                  _entryItems[actualIndex].icon, // 顯示卡片圖示
                                  size: 60, // 圖示大小
                                  color: AppColors.text_1, // 圖示顏色
                                ),
                                const SizedBox(height: AppSpacing.md), // 間距
                                Text(
                                  _entryItems[actualIndex].title, // 顯示卡片標題
                                  style: AppTextStyles.title,
                                ),
                                const SizedBox(height: AppSpacing.md), // 間距
                                Expanded(
                                  child: _entryItems[actualIndex]
                                      .contentBuilder(context), // 動態生成卡片內容
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
