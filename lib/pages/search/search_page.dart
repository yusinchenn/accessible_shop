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
  List<Product> _products = []; // 當前顯示的商品列表
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

    final endIndex = (_currentLoadedCount + _pageSize).clamp(0, _allProducts.length);
    final nextPageProducts = _allProducts.sublist(_currentLoadedCount, endIndex);

    setState(() {
      _products.addAll(nextPageProducts);
      _currentLoadedCount = endIndex;
    });

    if (kDebugMode) {
      print('📄 [SearchPage] 已載入 $_currentLoadedCount / ${_allProducts.length} 個商品');
    }
  }

  void _onPageChanged() {
    final int? currentPage = _pageController.page?.round();
    if (currentPage != null && currentPage != _currentPageIndex) {
      _currentPageIndex = currentPage;
      _speakProductCard(currentPage);

      // 當滑到接近末尾時，載入下一頁
      if (currentPage >= _products.length - 5 && _currentLoadedCount < _allProducts.length) {
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
    Navigator.pushNamed(
      context,
      '/product',
      arguments: product.id,
    );
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '找不到相關商品',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '請嘗試其他關鍵字',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final storeName = _storesMap[product.storeId]?.name;
                    return GestureDetector(
                      onTap: () => _speakProductCard(index),
                      onDoubleTap: () => _navigateToProductDetail(product),
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
    );
  }
}
