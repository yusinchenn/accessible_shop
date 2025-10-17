import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart';
import 'package:accessible_shop/widgets/product_card.dart';
import 'package:accessible_shop/models/product.dart';
import 'package:accessible_shop/services/database_service.dart';

/// 搜尋頁面
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final PageController _pageController;
  List<Product> _products = [];
  final TtsHelper _ttsHelper = TtsHelper();
  String _searchKeyword = ''; // 用戶搜尋關鍵字
  int _currentPageIndex = 0; // 當前頁面索引
  bool _loading = true;

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
      _loadProducts();
    }
  }

  /// 從資料庫載入商品
  Future<void> _loadProducts() async {
    setState(() => _loading = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      // 使用智能搜尋方法（支援模糊搜尋與優先級排序）
      List<Product> searchResults = await db.searchProducts(_searchKeyword);

      setState(() {
        _products = searchResults;
        _loading = false;
      });

      // 進入頁面時朗讀搜尋結果
      if (_products.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _speakSearchResult();
        });
      } else {
        // 沒有搜尋結果時也播報
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ttsHelper.speak('找不到相關商品，請嘗試其他關鍵字');
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (kDebugMode) {
        print('載入商品失敗: $e');
      }
    }
  }

  void _onPageChanged() {
    final int? currentPage = _pageController.page?.round();
    if (currentPage != null && currentPage != _currentPageIndex) {
      _currentPageIndex = currentPage;
      _speakProductCard(currentPage);
    }
  }

  Future<void> _speakSearchResult() async {
    final keyword = _searchKeyword.isEmpty ? '商品' : _searchKeyword;
    final searchText = '搜尋 $keyword 的結果';
    await _ttsHelper.speak(searchText);
  }

  Future<void> _speakProductCard(int index) async {
    if (index < 0 || index >= _products.length) return;
    final product = _products[index];
    final productText = _getProductCardText(product);
    await _ttsHelper.speak(productText);
  }

  String _getProductCardText(Product product) {
    final category = product.category != null ? '，分類${product.category}' : '';
    return '${product.name}，價格${product.price.toStringAsFixed(0)}元，${product.description ?? "無描述"}$category';
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
    _ttsHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchKeyword.isEmpty ? '商品' : _searchKeyword;
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('搜尋 $keyword'), centerTitle: true),
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
              : NotificationListener<ScrollEndNotification>(
                  onNotification: (notification) {
                    final currentPage = _pageController.page?.round() ?? 0;
                    _speakProductCard(currentPage);
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return GestureDetector(
                        onTap: () => _speakProductCard(index),
                        onDoubleTap: () => _navigateToProductDetail(product),
                        child: ProductCard(
                          product: product,
                          tag: '隔日到貨', // 固定標籤
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
