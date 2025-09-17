import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  late PageController _pageController;
  int _currentPageIndex = 0;
  final FlutterTts _flutterTts = FlutterTts();

  /// 定義入口卡片（與路由綁定）
  final List<ShopEntryItem> _entryItems = <ShopEntryItem>[
    ShopEntryItem(
      title: '搜尋',
      icon: Icons.search,
      route: '/search', // 對應 search_page.dart
      contentBuilder: (context) => const Center(child: Text('搜尋入口')),
    ),
    ShopEntryItem(
      title: '購物車',
      icon: Icons.shopping_cart,
      route: '/cart', // 對應 cart_page.dart
      contentBuilder: (context) => const Center(child: Text('購物車入口')),
    ),
    ShopEntryItem(
      title: '訂單',
      icon: Icons.list_alt,
      route: '/orders', // 對應 order_history_page.dart
      contentBuilder: (context) => const Center(child: Text('訂單入口')),
    ),
    ShopEntryItem(
      title: '帳號',
      icon: Icons.person,
      route: '/settings', // 對應 settings_page.dart
      contentBuilder: (context) => const Center(child: Text('帳號入口')),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final int initialPageOffset = _entryItems.length * 1000;
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: initialPageOffset,
    );
    _currentPageIndex = initialPageOffset % _entryItems.length;
    _pageController.addListener(_onPageChanged);

    _initTts();
  }

  /// 初始化 TTS
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("zh-TW");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    _speak(_entryItems[_currentPageIndex].title); // 首次播報首頁名稱
  }

  /// 語音播報
  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _onPageChanged() {
    final int? page = _pageController.page?.round();
    if (page != null && _currentPageIndex != page % _entryItems.length) {
      setState(() {
        _currentPageIndex = page % _entryItems.length;
      });
      _speak(_entryItems[_currentPageIndex].title); // 切換卡片時播報名稱
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
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
            itemCount: 999999,
            itemBuilder: (BuildContext context, int index) {
              final int actualIndex = index % _entryItems.length;
              double value = 0.0;
              if (_pageController.position.haveDimensions) {
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
                    onTap: () {
                      // 點擊一下：語音重播名稱
                      _speak(_entryItems[actualIndex].title);
                    },
                    onDoubleTap: () {
                      // 點擊兩下：導航到對應頁面
                      Navigator.pushNamed(
                        context,
                        _entryItems[actualIndex].route,
                      );
                    },
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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
