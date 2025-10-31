import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart'; // 使用相對路徑匯入全域的文字轉語音工具（TTS Helper）
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/voice_control_appbar.dart';
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
  bool _hasLoadedProducts = false; // 是否已載入商品（防止重複載入）

  // 分頁相關
  static const int _pageSize = 20; // 每次載入的商品數量
  int _currentLoadedCount = 0; // 已載入的商品數量

  // 自動朗讀相關
  bool _isAutoReading = false; // 是否正在自動朗讀
  int _autoReadIndex = 0; // 自動朗讀的當前索引
  bool _isSpeakingSearchResult = false; // 是否正在朗讀搜尋結果

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
    if (args != null && args is String && !_hasLoadedProducts) {
      _searchKeyword = args;
      // 檢查是否為推薦商品模式
      if (_searchKeyword == '__recommended__') {
        _isRecommendedMode = true;
        _searchKeyword = ''; // 清空關鍵字
      }
      _hasLoadedProducts = true; // 標記已載入
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
      if (kDebugMode) {
        print(
          '📄 [SearchPage] 頁面變更: $_currentPageIndex -> $currentPage (自動朗讀: $_isAutoReading, 自動索引: $_autoReadIndex)',
        );
      }

      _currentPageIndex = currentPage;

      // 檢查是否為手動滑動（不是自動朗讀觸發的）
      // 條件：正在自動朗讀 且 當前頁面不等於自動朗讀索引
      final isManualSwipe = _isAutoReading && currentPage != _autoReadIndex;

      if (isManualSwipe) {
        // 手動滑動時停止自動朗讀
        if (kDebugMode) {
          print(
            '👆 [SearchPage] 偵測到手動滑動（頁面=$currentPage, 預期=$_autoReadIndex），停止自動朗讀',
          );
        }
        _stopAutoRead();
      }

      // 只有在非自動朗讀且非搜尋結果朗讀狀態下才朗讀（避免打斷）
      if (!_isAutoReading && !_isSpeakingSearchResult) {
        if (kDebugMode) {
          print('🔊 [SearchPage] 手動模式，朗讀頁面 $currentPage');
        }
        _speakProductCard(currentPage);
      } else {
        if (kDebugMode) {
          print('🤖 [SearchPage] 自動朗讀或搜尋結果朗讀模式，跳過手動朗讀');
        }
      }

      // 當滑到接近末尾時，載入下一頁
      if (currentPage >= _products.length - 5 &&
          _currentLoadedCount < _allProducts.length) {
        _loadNextPage();
      }
    }
  }

  Future<void> _speakSearchResult() async {
    // 如果已經在朗讀搜尋結果，直接返回
    if (_isSpeakingSearchResult) {
      if (kDebugMode) {
        print('🔊 [SearchPage] 已在朗讀搜尋結果，跳過');
      }
      return;
    }

    _isSpeakingSearchResult = true; // 標記正在朗讀搜尋結果

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

    if (kDebugMode) {
      print('🔊 [SearchPage] 開始朗讀搜尋結果: $searchText');
    }

    await ttsHelper.speak(searchText);

    // 使用 Future.delayed 並在延遲後清除標記
    // 這樣即使頁面切換，標記也會在合理時間後被清除
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _isSpeakingSearchResult = false;
        if (kDebugMode) {
          print('🔊 [SearchPage] 搜尋結果朗讀標記已清除');
        }
      }
    });
  }

  /// AppBar 點擊時朗讀頁面說明和使用方式
  Future<void> _speakAppBarInfo() async {
    String searchInfo;

    if (_isRecommendedMode) {
      // 推薦商品模式
      searchInfo = '推薦商品';
    } else if (_isNoResultRecommend) {
      // 搜尋無結果，顯示推薦商品
      searchInfo = '$_searchKeyword，沒有結果，以下為推薦商品';
    } else {
      // 一般搜尋結果
      final keyword = _searchKeyword.isEmpty ? '商品' : _searchKeyword;
      searchInfo = keyword;
    }

    final appBarText =
        '搜尋$searchInfo的結果。單擊朗讀商品，雙擊進入商品，左滑下一項商品。左下角有自動朗讀按鈕，雙擊可自動朗讀';

    await ttsHelper.speak(appBarText);
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
    Navigator.pushNamed(context, '/product', arguments: product.id).then((_) {
      // 從商品詳情頁面返回時，清除標記並重新朗讀搜尋結果
      _isSpeakingSearchResult = false; // 清除標記
      _speakSearchResult();
    });
  }

  /// 開始自動朗讀（從第一個商品開始）
  Future<void> _startAutoRead() async {
    if (_products.isEmpty) return;

    setState(() {
      _isAutoReading = true;
      _autoReadIndex = 0;
    });

    if (kDebugMode) {
      print('🎬 [SearchPage] 開始自動朗讀，共 ${_products.length} 個商品');
    }

    // 跳轉到第一個商品
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );

    // 等待頁面切換完成
    await Future.delayed(const Duration(milliseconds: 50));

    // 使用循環方式依序朗讀每個商品
    await _autoReadLoop();
  }

  /// 自動朗讀循環（依序朗讀所有商品）
  Future<void> _autoReadLoop() async {
    try {
      // 從第一個商品開始，依序朗讀到最後一個
      for (int i = 0; i < _products.length; i++) {
        // 檢查是否被中斷
        if (!_isAutoReading) {
          if (kDebugMode) {
            print('⚠️ [SearchPage] 自動朗讀被中斷於商品 $i');
          }
          break;
        }

        _autoReadIndex = i;
        final product = _products[i];
        final productText = _getProductCardText(product);

        if (kDebugMode) {
          print(
            '🔊 [SearchPage] 正在朗讀商品 $i/${_products.length}: ${product.name}',
          );
        }

        // 朗讀當前商品（使用 speakQueue，會等待朗讀真正完成）
        await ttsHelper.speakQueue([productText]);

        // 再次檢查是否被中斷
        if (!_isAutoReading) {
          if (kDebugMode) {
            print('⚠️ [SearchPage] 朗讀完成後發現被中斷');
          }
          break;
        }

        if (kDebugMode) {
          print('✅ [SearchPage] 商品 $i 朗讀完成');
        }

        // 如果不是最後一個商品，則切換到下一個
        if (i < _products.length - 1) {
          if (kDebugMode) {
            print('➡️ [SearchPage] 切換到商品 ${i + 1}');
          }

          // 在切換頁面之前先更新索引，讓 _onPageChanged 知道這是自動切換
          _autoReadIndex = i + 1;

          await _pageController.animateToPage(
            i + 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );

          // 等待頁面切換動畫完成（縮短等待時間，因為 TTS 已經確保完成）
          await Future.delayed(const Duration(milliseconds: 150));

          // 檢查是否在頁面切換過程中被中斷
          if (!_isAutoReading) {
            if (kDebugMode) {
              print('⚠️ [SearchPage] 頁面切換後發現被中斷');
            }
            break;
          }
        }
      }

      // 如果完成所有商品朗讀（沒有被中斷）
      if (_isAutoReading) {
        if (kDebugMode) {
          print('🎉 [SearchPage] 所有商品自動朗讀完成');
        }
        _stopAutoRead();
      }
    } catch (e) {
      // 朗讀被打斷（手動操作）
      if (kDebugMode) {
        print('❌ [SearchPage] 自動朗讀發生錯誤: $e');
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

  /// 處理自動朗讀按鈕的點擊（單擊朗讀按鈕文字，雙擊從頭開始自動朗讀）
  Future<void> _onAutoReadButtonTap() async {
    await ttsHelper.speak('自動朗讀按鈕');
  }

  void _onAutoReadButtonDoubleTap() {
    // 雙擊總是從頭開始自動朗讀
    // 先停止並清空所有現有的朗讀（包括自動和手動）
    if (_isAutoReading) {
      _stopAutoRead();
    }
    ttsHelper.stop(); // 清空所有朗讀佇列

    if (kDebugMode) {
      print('🎬 [SearchPage] 雙擊自動朗讀按鈕，從頭開始');
    }

    // 從頭開始自動朗讀
    _startAutoRead();
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
      resizeToAvoidBottomInset: false,
      appBar: VoiceControlAppBar(
        title: title,
        onTap: _speakAppBarInfo,
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
                        color: AppColors.secondery_1,
                        border: Border.all(
                          color: AppColors.secondery_1,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isAutoReading ? Icons.pause : Icons.play_arrow,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
