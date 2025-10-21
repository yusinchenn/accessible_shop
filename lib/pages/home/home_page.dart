// lib/pages/home/home_page.dart
//
// 使用全域 ttsHelper (在 lib/utils/tts_helper.dart 定義)
// 注意此檔案使用相對路徑 import，確保位置為 lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import '../../utils/tts_helper.dart'; // 使用相對路徑匯入全域的文字轉語音工具（TTS Helper）
import '../../utils/app_constants.dart'; // 匯入全域樣式常數
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器
import '../../services/accessibility_service.dart'; // 匯入無障礙服務

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
  final TextEditingController _searchController = TextEditingController(); // 搜尋輸入控制器
  final FocusNode _searchFocusNode = FocusNode(); // 搜尋輸入框焦點節點

  int _currentPageIndex = 0; // 當前顯示的卡片索引（對應 _entryItems 的實際索引）
  bool _isAnnouncingHome = false; // 標記是否正在進行首頁進入的語音播報
  bool _speaking = false; // 標記是否正在進行語音播報
  bool _announceScheduled = false; // 標記是否已排程首頁進入的播報

  /// 取得首頁的卡片清單，包含搜尋、購物車、訂單、帳號、短影音和通知六個入口
  List<ShopEntryItem> get _entryItems => <ShopEntryItem>[
    ShopEntryItem(
      title: '搜尋', // 卡片標題
      icon: Icons.search, // 搜尋圖示
      route: '/search', // 導航路由
      contentBuilder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(fontSize: 28),
            decoration: const InputDecoration(
              hintText: '輸入商品名稱...',
              hintStyle: TextStyle(fontSize: 28),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(AppSpacing.md),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _onSearchSubmit(value.trim());
              }
            },
          ),
        ),
      ),
    ),
    ShopEntryItem(
      title: '購物車',
      icon: Icons.shopping_cart,
      route: '/cart',
      contentBuilder: (context) => const Center(child: Text('購物車入口')),
    ),
    ShopEntryItem(
      title: '訂單',
      icon: Icons.list_alt,
      route: '/orders',
      contentBuilder: (context) => const Center(child: Text('訂單入口')),
    ),
    ShopEntryItem(
      title: '帳號',
      icon: Icons.person,
      route: '/settings',
      contentBuilder: (context) => const Center(child: Text('帳號入口')),
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
      contentBuilder: (context) => const Center(child: Text('通知入口')),
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
      });
    }
  }

  /// 執行首頁進入的語音播報，播報「進入首頁」和當前卡片標題
  Future<void> _announceEnter() async {
    if (_isAnnouncingHome) return; // 如果正在播報首頁，則跳過

    // 只在自訂模式播放語音
    if (!accessibilityService.shouldUseCustomTTS) return;

    await ttsHelper.stop(); // 停止任何正在進行的語音播報，確保乾淨的播報環境

    _isAnnouncingHome = true; // 標記正在播報首頁
    _speaking = true; // 標記正在語音播報
    try {
      await ttsHelper.speak('進入首頁'); // 播報「進入首頁」
      await Future.delayed(const Duration(seconds: 1)); // 等待 1 秒
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

  /// 清理資源，釋放 PageController 和搜尋相關控制器
  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged); // 移除頁面變化監聽器
    _pageController.dispose(); // 釋放 PageController
    _searchController.dispose(); // 釋放搜尋輸入控制器
    _searchFocusNode.dispose(); // 釋放搜尋輸入框焦點節點
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

  /// 處理雙擊事件，導航到指定路由或開啟搜尋輸入
  void _onDoubleTap(String route, int actualIndex) {
    // 如果是搜尋卡片，開啟鍵盤輸入
    if (actualIndex == 0) {
      // 使用更穩健的方式請求焦點
      // 先取消焦點，再在下一幀重新請求，確保焦點狀態正確
      _searchFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
          // 只在自訂模式播放語音
          if (accessibilityService.shouldUseCustomTTS) {
            ttsHelper.speak('請輸入商品名稱');
          }
        }
      });
    } else {
      Navigator.pushNamed(context, route).then((_) {
        // 導航返回後，didChangeDependencies 會觸發 _announceEnter
      });
    }
  }

  /// 處理搜尋提交事件
  void _onSearchSubmit(String keyword) {
    _searchFocusNode.unfocus(); // 關閉鍵盤
    Navigator.pushNamed(
      context,
      '/search',
      arguments: keyword,
    ).then((_) {
      // 清空搜尋框
      _searchController.clear();
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
                        actualIndex,
                      ), // 雙擊導航到對應路由或開啟搜尋輸入
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
