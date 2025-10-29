import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart'; // 使用相對路徑匯入全域的文字轉語音工具（TTS Helper）
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/product_card.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/database_service.dart';

/// 搜尋頁面
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final PageController _pageController;
  final List<Product> _products = []; // 當前顯示的商品列表
  List<Product> _allProducts = []; // 所有可用的商品列表（用於分頁載入）
  Map<int, Store> _storesMap = {}; // 商家資料 Map (storeId -> Store)
  String _searchKeyword = ''; // 用戶搜尋關鍵字
  int _currentPageIndex = 0; // 當前頁面索引
  bool _loading = true;
  bool _isRecommendedMode = false; // 是否為推薦商品模式
  bool _isNoResultRecommend = false; // 是否為搜尋無結果後顯示推薦商品

  // 分頁相關
  static const int _pageSize = 20; // 每次載入的商品數量
  int _currentLoadedCount = 0; // 已載入的商品數量

  // 自動朗讀相關
  bool _isAutoReading = false; // 是否正在自動朗讀
  int _autoReadIndex = 0; // 自動朗讀的當前索引

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 從路由參數獲取搜尋關鍵字
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String && _searchKeyword.isEmpty) {
      _searchKeyword = args;
      // 檢查是否為推薦商品模式
      if (_searchKeyword == '__recommended__') {
        _isRecommendedMode = true;
        _searchKeyword = ''; // 清空關鍵字
      }
      _loadProducts();
    }
  }

  /// 從資料庫載入商品
  Future<void> _loadProducts() async {
    setState(() => _loading = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      // 載入所有商家資料
      final stores = await db.getStores();
      final storesMap = {for (var store in stores) store.id: store};

      List<Product> searchResults;

      if (_isRecommendedMode) {
        // 推薦商品模式：載入所有商品並隨機排序
        if (kDebugMode) {
          print('🔍 [SearchPage] 推薦商品模式');
        }
        searchResults = await db.getProducts();
        searchResults.shuffle(); // 隨機排序
      } else {
        // 一般搜尋模式
        if (kDebugMode) {
          print('🔍 [SearchPage] 開始搜尋關鍵字: "$_searchKeyword"');
        }
        searchResults = await db.searchProducts(_searchKeyword);

        // 如果搜尋無結果，則顯示隨機推薦商品
        if (searchResults.isEmpty && _searchKeyword.isNotEmpty) {
          if (kDebugMode) {
            print('🔍 [SearchPage] 搜尋無結果，顯示推薦商品');
          }
          searchResults = await db.getProducts();
          searchResults.shuffle(); // 隨機排序
          _isNoResultRecommend = true;
        }
      }

      if (kDebugMode) {
        print('🔍 [SearchPage] 總商品數量: ${searchResults.length}');
        print('🔍 [SearchPage] 載入商家數量: ${stores.length}');
      }

      // 儲存所有商品，並只載入第一頁
      _allProducts = searchResults;
      _currentLoadedCount = 0;
      _loadNextPage(); // 載入第一頁

      setState(() {
        _storesMap = storesMap;
        _loading = false;
      });

      // 進入頁面時朗讀結果
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _speakSearchResult();
      });
    } catch (e) {
      setState(() => _loading = false);
      if (kDebugMode) {
        print('❌ [SearchPage] 載入商品失敗: $e');
      }
    }
  }

  /// 載入下一頁商品
  void _loadNextPage() {
    if (_currentLoadedCount >= _allProducts.length) return;

    final endIndex = (_currentLoadedCount + _pageSize).clamp(
      0,
      _allProducts.length,
    );
    final nextPageProducts = _allProducts.sublist(
      _currentLoadedCount,
      endIndex,
    );

    setState(() {
      _products.addAll(nextPageProducts);
      _currentLoadedCount = endIndex;
    });

    if (kDebugMode) {
      print(
        '📄 [SearchPage] 已載入 $_currentLoadedCount / ${_allProducts.length} 個商品',
      );
    }
  }

  void _onPageChanged() {
    final int? currentPage = _pageController.page?.round();
    if (currentPage != null && currentPage != _currentPageIndex) {
      _currentPageIndex = currentPage;

      // 檢查是否為手動滑動（不是自動朗讀觸發的）
      final isManualSwipe = _isAutoReading && currentPage != _autoReadIndex;

      if (isManualSwipe) {
        // 手動滑動時停止自動朗讀
        if (kDebugMode) {
          print('👆 [SearchPage] 偵測到手動滑動，停止自動朗讀');
        }
        _stopAutoRead();
      }

      // 只有在非自動朗讀狀態下才朗讀（避免打斷自動朗讀）
      if (!_isAutoReading) {
        _speakProductCard(currentPage);
      }

      // 當滑到接近末尾時，載入下一頁
      if (currentPage >= _products.length - 5 &&
          _currentLoadedCount < _allProducts.length) {
        _loadNextPage();
      }
    }
  }

  Future<void> _speakSearchResult() async {
    String searchText;

    if (_isRecommendedMode) {
      // 推薦商品模式
      searchText = '推薦商品搜尋結果';
    } else if (_isNoResultRecommend) {
      // 搜尋無結果，顯示推薦商品
      searchText = '搜尋$_searchKeyword的商品，沒有結果，以下為推薦商品';
    } else {
      // 一般搜尋結果
      final keyword = _searchKeyword.isEmpty ? '商品' : _searchKeyword;
      searchText = '搜尋 $keyword 的結果';
    }

    await ttsHelper.speak(searchText);
  }

  Future<void> _speakProductCard(int index) async {
    if (index < 0 || index >= _products.length) return;
    final product = _products[index];
    final productText = _getProductCardText(product);
    await ttsHelper.speak(productText);
  }

  String _getProductCardText(Product product) {
    final category = product.category != null ? '，分類${product.category}' : '';
    final storeName = _storesMap[product.storeId]?.name;
    final storeInfo = storeName != null ? '，商家$storeName' : '';
    final ratingInfo = product.reviewCount > 0
        ? '，評分${product.averageRating.toStringAsFixed(1)}顆星，共${product.reviewCount}則評論'
        : '';
    return '${product.name}，價格${product.price.toStringAsFixed(0)}元$ratingInfo$storeInfo，${product.description ?? "無描述"}$category';
  }

  /// 導航到商品詳情頁面
  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(context, '/product', arguments: product.id);
  }

  /// 開始自動朗讀（從第一個商品開始）
  Future<void> _startAutoRead() async {
    if (_products.isEmpty) return;

    setState(() {
      _isAutoReading = true;
      _autoReadIndex = 0;
    });

    // 跳轉到第一個商品
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _autoReadNext();
  }

  /// 自動朗讀下一個商品
  Future<void> _autoReadNext() async {
    if (!_isAutoReading || _autoReadIndex >= _products.length) {
      _stopAutoRead();
      return;
    }

    try {
      // 朗讀當前商品（使用 speakQueue 確保朗讀完成後再繼續）
      final product = _products[_autoReadIndex];
      final productText = _getProductCardText(product);

      if (kDebugMode) {
        print('🔊 [SearchPage] 自動朗讀商品 $_autoReadIndex: ${product.name}');
      }

      await ttsHelper.speakQueue([productText]);

      // 檢查是否被中斷
      if (!_isAutoReading) return;

      // 等待較長時間後再切換，確保 TTS 真正完成播放
      await Future.delayed(const Duration(milliseconds: 800));

      // 再次檢查是否被中斷
      if (!_isAutoReading) return;

      // 移動到下一個商品
      _autoReadIndex++;
      if (_autoReadIndex < _products.length) {
        await _pageController.animateToPage(
          _autoReadIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        // 繼續朗讀下一個
        _autoReadNext();
      } else {
        // 所有商品朗讀完成
        if (kDebugMode) {
          print('✅ [SearchPage] 自動朗讀完成');
        }
        _stopAutoRead();
      }
    } catch (e) {
      // 朗讀被打斷（手動操作）
      if (kDebugMode) {
        print('⚠️ [SearchPage] 自動朗讀被打斷: $e');
      }
      _stopAutoRead();
    }
  }

  /// 停止自動朗讀
  void _stopAutoRead() {
    setState(() {
      _isAutoReading = false;
    });
    ttsHelper.stop();
  }

  /// 處理自動朗讀按鈕的點擊（單擊朗讀按鈕文字，雙擊開始自動朗讀）
  Future<void> _onAutoReadButtonTap() async {
    await ttsHelper.speak('自動朗讀按鈕');
  }

  void _onAutoReadButtonDoubleTap() {
    if (_isAutoReading) {
      _stopAutoRead();
    } else {
      _startAutoRead();
    }
  }

  /// 處理商品卡片的手勢（添加自動朗讀打斷功能）
  Future<void> _onProductCardTap(int index) async {
    // 手動點擊時停止自動朗讀
    if (_isAutoReading) {
      _stopAutoRead();
    }
    await _speakProductCard(index);
  }

  void _onProductCardDoubleTap(Product product) {
    // 手動雙擊時停止自動朗讀
    if (_isAutoReading) {
      _stopAutoRead();
    }
    _navigateToProductDetail(product);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    // 不要 dispose 全域 ttsHelper，因為它是全域資源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根據不同模式顯示不同標題
    String title;
    if (_isRecommendedMode) {
      title = '推薦商品';
    } else if (_isNoResultRecommend) {
      title = '搜尋 $_searchKeyword';
    } else {
      final keyword = _searchKeyword.isEmpty ? '商品' : _searchKeyword;
      title = '搜尋 $keyword';
    }

    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_1,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '找不到相關商品',
                    style: const TextStyle(fontSize: 32, color: Colors.grey),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '請嘗試其他關鍵字',
                    style: const TextStyle(fontSize: 28, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // 商品列表
                PageView.builder(
                  controller: _pageController,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final storeName = _storesMap[product.storeId]?.name;
                    return GestureDetector(
                      onTap: () => _onProductCardTap(index),
                      onDoubleTap: () => _onProductCardDoubleTap(product),
                      child: ProductCard(
                        product: product,
                        tag: '隔日到貨', // 固定標籤
                        storeName: storeName,
                        // 移除商家連結，只顯示商家名稱
                        onStoreDoubleTap: null,
                      ),
                    );
                  },
                ),
                // 自動朗讀按鈕 - 左下角
                Positioned(
                  left: 16,
                  bottom: 50,
                  child: GestureDetector(
                    onTap: _onAutoReadButtonTap,
                    onDoubleTap: _onAutoReadButtonDoubleTap,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blockBackground_1,
                        border: Border.all(
                          color: AppColors.secondery_1,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isAutoReading ? Icons.pause : Icons.play_arrow,
                        size: 48,
                        color: AppColors.secondery_1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
