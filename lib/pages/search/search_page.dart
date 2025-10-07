import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:provider/provider.dart';

/// 商品資料模型
class Product {
  final String name;
  final double price;
  final String description;
  final String tag;

  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.tag,
  });
}

/// 狀態管理：管理商品清單與目前頁面索引
class ProductBrowserData extends ChangeNotifier {
  final List<Product> _products;
  int _currentPageIndex;

  ProductBrowserData({required List<Product> products})
    : _products = products,
      _currentPageIndex = 0;

  List<Product> get products => _products;
  int get currentPageIndex => _currentPageIndex;
  Product get currentProduct => _products[_currentPageIndex];

  void setCurrentPageIndex(int index) {
    if (_currentPageIndex != index && index >= 0 && index < _products.length) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }
}

/// 單一商品卡片
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              product.name,
              style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 30,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                product.description,
                style: const TextStyle(fontSize: 30, color: AppColors.text),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.tag,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 搜尋頁面

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final PageController _pageController;
  late final List<Product> _products;
  final TtsHelper _ttsHelper = TtsHelper();
  String _searchKeyword = '商品名稱'; // 模擬用戶搜尋關鍵字

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    /// 建立假資料（10 筆）
    _products = List<Product>.generate(
      10,
      (int index) => Product(
        name: '商品名稱 ${index + 1}',
        price: 100.0,
        description: '商品敘述商品敘述商品敘述商品敘述商品敘述',
        tag: '隔日到貨',
      ),
    );

    _pageController.addListener(_onPageChanged);
    // 進入頁面時朗讀搜尋結果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakSearchResult();
    });
  }

  void _onPageChanged() {
    final int? currentPage = _pageController.page?.round();
    if (currentPage != null) {
      Provider.of<ProductBrowserData>(
        context,
        listen: false,
      ).setCurrentPageIndex(currentPage);
      _speakProductCard(currentPage);
    }
  }

  Future<void> _speakSearchResult() async {
    final searchText = '搜尋$_searchKeyword 的結果';
    await _ttsHelper.speak(searchText);
  }

  Future<void> _speakProductCard(int index) async {
    if (index < 0 || index >= _products.length) return;
    final product = _products[index];
    final productText = _getProductCardText(product);
    await _ttsHelper.speak(productText);
  }

  String _getProductCardText(Product product) {
    return '${product.name}，價格${product.price.toStringAsFixed(2)}元，${product.description}，標籤${product.tag}';
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
    return ChangeNotifierProvider<ProductBrowserData>(
      create: (_) => ProductBrowserData(products: _products),
      builder: (context, _) {
        final productBrowserData = Provider.of<ProductBrowserData>(context);

        return Scaffold(
          backgroundColor: AppColors.background, // 套用背景色
          appBar: AppBar(title: Text('搜尋 $_searchKeyword'), centerTitle: true),
          body: NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              // 切換卡片時朗讀目前卡片內容
              final currentPage = _pageController.page?.round() ?? 0;
              _speakProductCard(currentPage);
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: productBrowserData.products.length,
              itemBuilder: (context, index) {
                final product = productBrowserData.products[index];
                return GestureDetector(
                  onTap: () => _speakProductCard(index),
                  child: ProductCard(product: product),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
