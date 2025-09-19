// lib/pages/home/home_page.dart
//
// HomePage:
// - 進入/回到首頁時會朗讀「進入首頁」+ 當前卡片名稱
// - 切換卡片時朗讀新卡片名稱（不說 "切換到"）
// - 單擊卡片朗讀卡片名稱；雙擊卡片導航至對應頁面（返回時會再次朗讀「進入首頁 + 卡片名稱」）
// - 使用 TtsHelper.speakQueue 來確保多句按順序播放
//
// 請確保你有安裝並使用 lib/utils/tts_helper.dart（含 speakQueue 實作）

import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

/// 入口卡片資料結構
class ShopEntryItem {
  final String title;
  final IconData icon;
  final String route; // 對應的路由名稱
  final Widget Function(BuildContext) contentBuilder;

  const ShopEntryItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.contentBuilder,
  });
}

/// 首頁（滑動卡片 + 無障礙語音 + 單擊/雙擊操作）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  final TtsHelper _ttsHelper = TtsHelper();

  // 當前顯示的卡片索引（0..n-1）
  int _currentPageIndex = 0;

  // 控制目前是否正在播放「進入首頁」或其他系統性播報
  bool _isAnnouncingHome = false;

  // 控制是否有任何正在進行的 TTS 播放，避免重疊呼叫
  bool _speaking = false;

  // 用來避免 didChangeDependencies 或 frame callback 被重複 schedule
  bool _announceScheduled = false;

  /// 定義入口卡片（與路由綁定）
  final List<ShopEntryItem> _entryItems = <ShopEntryItem>[
    ShopEntryItem(
      title: '搜尋',
      icon: Icons.search,
      route: '/search',
      contentBuilder: (context) => const Center(child: Text('搜尋入口')),
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
  ];

  @override
  void initState() {
    super.initState();

    // 使用一個較大的 offset 以模擬無限滑動
    final int initialPageOffset = _entryItems.length * 1000;
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: initialPageOffset,
    );
    _currentPageIndex = initialPageOffset % _entryItems.length;

    // 監聽 page 變化，用以播報卡片名稱（當不是在首頁系統播報期間）
    _pageController.addListener(_onPageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 當這個 route 成為目前 route（首次顯示或從其他頁返回）時，安排朗讀「進入首頁 + 當前卡片名稱」
    // 使用 schedule flag 避免重複註冊多個 frame callback
    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (routeIsCurrent && !_announceScheduled) {
      _announceScheduled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 非同步執行，不阻塞 UI
        _announceScheduled = false;
        _announceEnter();
      });
    }
  }

  /// 宣告：進入首頁（或回到首頁）時要播的內容
  Future<void> _announceEnter() async {
    if (_isAnnouncingHome) return;

    _isAnnouncingHome = true;

    // 使用 speakQueue，逐句播報
    await _ttsHelper.speakQueue(["進入首頁", _entryItems[_currentPageIndex].title]);

    _isAnnouncingHome = false;
  }

  void _onPageChanged() {
    final int? page = _pageController.page?.round();
    if (page != null && _currentPageIndex != page % _entryItems.length) {
      setState(() {
        _currentPageIndex = page % _entryItems.length;
      });

      if (!_isAnnouncingHome) {
        _ttsHelper.speak(_entryItems[_currentPageIndex].title);
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _ttsHelper.dispose();
    super.dispose();
  }

  /// 單擊：重播卡片名稱
  void _onSingleTap(int actualIndex) {
    // 如果目前正在系統播報（進入首頁），可以忽略，或仍播視需求而定
    if (_isAnnouncingHome || _speaking) return;

    _ttsHelper.speak(_entryItems[actualIndex].title);
  }

  /// 雙擊：導航到路由，並在返回時再次播報「進入首頁 + 當前卡片名稱」
  void _onDoubleTap(String route) {
    Navigator.pushNamed(context, route).then((_) {
      // 回到首頁（pop 回來）時再次公告
      _announceEnter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_entryItems[_currentPageIndex].title),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 999999, // 模擬無限滑動
            itemBuilder: (BuildContext context, int index) {
              final int actualIndex = index % _entryItems.length;

              // Animation 計算（縮放與位移）
              double value = 0.0;
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                value = index.toDouble() - (_pageController.page ?? 0);
                value = value.clamp(-1.0, 1.0);
              }

              final double scale = 1.0 - (value.abs() * 0.1);
              final double translate =
                  value * MediaQuery.of(context).size.width * 0.05;

              return Align(
                alignment: Alignment.center,
                child: Transform(
                  transform: Matrix4.identity()
                    ..scale(scale)
                    ..translate(translate, 0.0),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => _onSingleTap(actualIndex),
                    onDoubleTap: () =>
                        _onDoubleTap(_entryItems[actualIndex].route),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              _entryItems[actualIndex].icon,
                              size: 60,
                              color: Colors.blueGrey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _entryItems[actualIndex].title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _entryItems[actualIndex].contentBuilder(
                                context,
                              ),
                            ),
                          ],
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
