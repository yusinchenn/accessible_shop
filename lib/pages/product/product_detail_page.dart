import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../models/product_review.dart';
import '../../services/database_service.dart';
import '../../services/openai_client.dart';
import '../../providers/cart_provider.dart';
import '../store/store_page.dart';

//暫時的隨機售出數量
int randomSoldCount = Random().nextInt(900) + 100;

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  Store? _store;
  List<ProductReview> _reviews = [];
  bool _loading = true;

  // 規格選擇狀態
  String _selectedSize = '通用尺寸';
  String _selectedColor = '預設顏色';
  int _quantity = 1;

  // 可選的規格選項（可以從商品屬性動態生成）
  final List<String> _sizeOptions = ['通用尺寸', 'S', 'M', 'L', 'XL'];
  final List<String> _colorOptions = ['預設顏色', '黑色', '白色', '灰色', '藍色', '紅色'];

  /// 計算當前選擇的單價（未來可根據規格調整）
  double get _currentUnitPrice {
    if (_product == null) return 0.0;
    // 未來可以根據 _selectedSize 和 _selectedColor 返回不同價格
    // 例如：不同尺寸或顏色可能有不同價格
    return _product!.price;
  }

  /// 計算總價（單價 × 數量，未來可加入多件優惠）
  double get _totalPrice {
    // 未來可以加入多件優惠邏輯
    // 例如：買 3 件打 9 折
    return _currentUnitPrice * _quantity;
  }

  // AI 評論摘要相關狀態
  String? _aiReviewSummary; // AI 生成的評論摘要
  bool _isGeneratingAiSummary = false; // 是否正在生成 AI 摘要
  OpenAICompatibleClient? _aiClient;

  @override
  void initState() {
    super.initState();
    _initAiClient();
  }

  /// 初始化 AI 客戶端
  void _initAiClient() {
    try {
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';

      if (apiKey.isEmpty || apiKey == 'your_deepseek_api_key_here') {
        // API Key 未設置，不初始化客戶端
        return;
      }

      final config = ProviderConfig(
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com',
        apiKey: apiKey,
        defaultModel: 'deepseek-chat',
      );

      _aiClient = OpenAICompatibleClient(config);
    } catch (e) {
      // 初始化失敗，保持 _aiClient 為 null
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    // 從路由參數獲取商品 ID
    final args = ModalRoute.of(context)?.settings.arguments;
    int? productId;

    if (args is int) {
      productId = args;
    }

    if (productId != null) {
      try {
        final db = Provider.of<DatabaseService>(context, listen: false);
        final product = await db.getProductById(productId);

        // 載入商家資料
        Store? store;
        List<ProductReview> reviews = [];
        if (product != null) {
          store = await db.getStoreById(product.storeId);
          reviews = await db.getProductReviews(product.id);
        }

        setState(() {
          _product = product;
          _store = store;
          _reviews = reviews;
          _loading = false;
        });

        // 進入頁面時朗讀商品資訊
        if (_product != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakProductDetail();
          });
        }
      } catch (e) {
        setState(() => _loading = false);
      }
    } else {
      setState(() => _loading = false);
    }
  }

  /// 朗讀商品詳情
  Future<void> _speakProductDetail() async {
    if (_product == null) return;
    final category = _product!.category != null
        ? '，分類${_product!.category}'
        : '';
    final storeName = _store?.name;
    final storeInfo = storeName != null ? '，商家$storeName' : '';
    final ratingInfo = _product!.reviewCount > 0
        ? '，評分${_product!.averageRating.toStringAsFixed(1)}顆星，共${_product!.reviewCount}則評論'
        : '';
    final text =
        '商品詳情，${_product!.name}，價格 ${_product!.price.toStringAsFixed(0)} 元$ratingInfo$storeInfo$category';
    await ttsHelper.speak(text);
  }

  /// AppBar 點擊時朗讀頁面說明
  Future<void> _speakAppBarInfo() async {
    if (_product == null) return;
    final text =
        '商品詳情，${_product!.name}，頁面由上到下依序為商品圖片、售價、標籤、商品描述、規格、價格、加入購物車按鈕與直接購買按鈕、商家、商品評論';
    await ttsHelper.speak(text);
  }

  /// 生成 AI 評論摘要
  Future<void> _generateAiReviewSummary() async {
    if (_aiClient == null) {
      ttsHelper.speak('AI 功能未啟用，請檢查設定');
      return;
    }

    // 過濾出有文字內容的評論
    final reviewsWithText = _reviews
        .where((r) => r.comment.trim().isNotEmpty)
        .toList();

    if (reviewsWithText.length < 10) {
      ttsHelper.speak('評論數量不足，無法生成 AI 摘要');
      return;
    }

    setState(() {
      _isGeneratingAiSummary = true;
    });

    ttsHelper.speak('正在生成 AI 評論摘要，請稍候');

    try {
      // 準備評論資料給 AI
      final reviewsText = StringBuffer();
      for (var i = 0; i < reviewsWithText.length; i++) {
        final review = reviewsWithText[i];
        reviewsText.writeln('評論 ${i + 1}：');
        reviewsText.writeln('評分：${review.rating.toStringAsFixed(1)} 星');
        reviewsText.writeln('內容：${review.comment}');
        reviewsText.writeln('---');
      }

      // 構建 AI 提示詞
      final prompt =
          '''
你是一位專業的電商評論分析師。請分析以下商品評論，並提供一份簡潔的摘要（約100-150字），重點包括：

1. 商品的主要優點（客戶最滿意的地方）
2. 商品的主要缺點或需要改進的地方（如果有）
3. 整體評價趨勢

商品名稱：${_product!.name}
評論總數：${reviewsWithText.length} 則

評論內容：
$reviewsText

請用繁體中文回答，語氣親切專業，適合朗讀給視障使用者聽。直接提供摘要內容，不需要額外的標題或前綴。
''';

      // 調用 DeepSeek API
      final response = await _aiClient!.chatCompletion(
        ChatCompletionOptions(
          messages: [
            ChatMessage(
              role: Role.system,
              content: '你是一位專業的電商評論分析助手，擅長從大量評論中提取關鍵資訊。',
            ),
            ChatMessage(role: Role.user, content: prompt),
          ],
          temperature: 0.7,
          maxTokens: 500,
        ),
      );

      setState(() {
        _aiReviewSummary = response.trim();
        _isGeneratingAiSummary = false;
      });

      // 朗讀 AI 摘要
      if (_aiReviewSummary != null && _aiReviewSummary!.isNotEmpty) {
        await ttsHelper.speak('AI 評論摘要：$_aiReviewSummary');
      }
    } catch (e) {
      setState(() {
        _isGeneratingAiSummary = false;
      });

      ttsHelper.speak('生成 AI 摘要失敗，請稍後再試');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '生成 AI 摘要失敗: $e',
              style: const TextStyle(fontSize: 24),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 加入購物車
  Future<void> _addToCart() async {
    if (_product == null || _store == null) return;

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final specification = '尺寸: $_selectedSize / 顏色: $_selectedColor';

      await db.addToCart(
        productId: _product!.id,
        productName: _product!.name,
        price: _product!.price,
        specification: specification,
        storeId: _store!.id,
        storeName: _store!.name,
        quantity: _quantity,
      );

      ttsHelper.speak('已加入購物車，$_quantity 項');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已加入購物車: ${_product!.name} x$_quantity',
              style: const TextStyle(fontSize: 24),
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '查看購物車',
              onPressed: () {
                Navigator.pushNamed(context, '/cart').then((_) {
                  // 從購物車頁面返回時，重新朗讀商品詳情
                  _speakProductDetail();
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      ttsHelper.speak('加入購物車失敗');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加入購物車失敗: $e', style: const TextStyle(fontSize: 24)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 直接購買
  Future<void> _buyNow() async {
    if (_product == null || _store == null) return;

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final cartProvider = Provider.of<ShoppingCartData>(context, listen: false);
      final specification = '尺寸: $_selectedSize / 顏色: $_selectedColor';

      if (kDebugMode) {
        print('🛒 [ProductDetail] 直接購買 - 規格: $specification');
      }

      // 先加入購物車
      await db.addToCart(
        productId: _product!.id,
        productName: _product!.name,
        price: _product!.price,
        specification: specification,
        storeId: _store!.id,
        storeName: _store!.name,
        quantity: _quantity,
      );

      // 等待購物車 provider 重新載入
      await cartProvider.reload();

      // 清除所有購物車項目的選取狀態
      await db.clearAllCartItemSelections();

      // 再次重新載入以確保狀態更新
      await cartProvider.reload();

      // 獲取剛加入的購物車項目並設為選取
      final cartItems = await db.getCartItems();

      if (kDebugMode) {
        print('🛒 [ProductDetail] 購物車項目數量: ${cartItems.length}');
        for (var item in cartItems) {
          print('  - ${item.name}, 規格: ${item.specification}, 選取: ${item.isSelected}');
        }
      }

      // 查找匹配的項目（使用 where 來處理可能找不到的情況）
      final matchingItems = cartItems.where(
        (item) =>
            item.productId == _product!.id &&
            item.specification == specification,
      ).toList();

      if (matchingItems.isEmpty) {
        throw Exception('找不到剛加入的購物車項目');
      }

      final newItem = matchingItems.first;

      // 設置該項目為選取狀態
      if (!newItem.isSelected) {
        await db.toggleCartItemSelection(newItem.id);
        // 等待購物車 provider 重新載入以確保選取狀態更新
        await cartProvider.reload();
      }

      if (kDebugMode) {
        print('🛒 [ProductDetail] 已選取項目: ${newItem.name}, id: ${newItem.id}');
      }

      ttsHelper.speak('前往結帳');

      // 導航到結帳頁面
      if (mounted) {
        await Navigator.pushNamed(context, '/checkout').then((_) {
          // 從結帳頁面返回時，重新朗讀商品詳情
          _speakProductDetail();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductDetail] 直接購買失敗: $e');
      }
      ttsHelper.speak('直接購買失敗');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('直接購買失敗: $e', style: const TextStyle(fontSize: 24)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 建立規格選擇區域
  Widget _buildSpecificationSection() {
    return GestureDetector(
      onTap: () {
        // 點擊規格區域時朗讀所有可選樣式
        final sizeOptions = _sizeOptions.join('、');
        final colorOptions = _colorOptions.join('、');
        ttsHelper.speak('規格，尺寸可選：$sizeOptions，顏色可選：$colorOptions');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 規格主標題
          const Text(
            '規格',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.text_2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 尺寸選擇（副標題）
          GestureDetector(
            onTap: () => ttsHelper.speak('尺寸'),
            child: const Text(
              '尺寸',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.text_2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _sizeOptions.map((size) {
              final isSelected = size == _selectedSize;
              return GestureDetector(
                onTap: () => ttsHelper.speak('尺寸 $size'),
                onDoubleTap: () {
                  setState(() => _selectedSize = size);
                  ttsHelper.speak('已選擇尺寸 $size');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.text_2 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.text_2 : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected ? Colors.white : AppColors.text_2,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // 顏色選擇（副標題）
          GestureDetector(
            onTap: () => ttsHelper.speak('顏色'),
            child: const Text(
              '顏色',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.text_2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _colorOptions.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => ttsHelper.speak('顏色 $color'),
                onDoubleTap: () {
                  setState(() => _selectedColor = color);
                  ttsHelper.speak('已選擇顏色 $color');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.text_2 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.text_2 : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    color,
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected ? Colors.white : AppColors.text_2,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 建立單價顯示區域
  Widget _buildPriceDisplay() {
    return GestureDetector(
      onTap: () {
        // 朗讀單價和總價
        final unitPriceText = '單價 ${_currentUnitPrice.toStringAsFixed(0)} 元';
        final totalPriceText = _quantity > 1
            ? '，總價 ${_totalPrice.toStringAsFixed(0)} 元'
            : '';
        ttsHelper.speak('$unitPriceText$totalPriceText');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 單價標題
          const Text(
            '單價',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text_2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 單價金額
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '\$${_currentUnitPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary_2,
                ),
              ),
              if (_quantity > 1) ...[
                Text(
                  '× $_quantity',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '= \$${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent_2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 建立數量選擇器
  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => ttsHelper.speak('選擇數量'),
          child: const Text(
            '選擇數量',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text_2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // 減少按鈕
            GestureDetector(
              onTap: () => ttsHelper.speak('減少數量按鈕'),
              onDoubleTap: () {
                if (_quantity > 1) {
                  setState(() => _quantity--);
                  ttsHelper.speak('數量 $_quantity');
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _quantity > 1 ? Colors.grey[400] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove,
                  color: _quantity > 1 ? Colors.white : Colors.grey[600],
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 數量顯示
            GestureDetector(
              onTap: () => ttsHelper.speak('數量 $_quantity'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text_2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 增加按鈕
            GestureDetector(
              onTap: () => ttsHelper.speak('增加數量按鈕'),
              onDoubleTap: () {
                if (_quantity < 99) {
                  setState(() => _quantity++);
                  ttsHelper.speak('數量 $_quantity');
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _quantity < 99 ? Colors.grey[400] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: _quantity < 99 ? Colors.white : Colors.grey[600],
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 不要 dispose 全域 ttsHelper，因為它是全域資源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _speakAppBarInfo,
          child: Text(
            _product?.name ?? '商品詳情',
            style: TextStyle(
              color: AppColors.text_2, // 設定文字顏色
            ),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background_2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text('找不到商品資料', style: TextStyle(fontSize: 28)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品圖片（寬度適應父元素）
                    GestureDetector(
                      onTap: () => ttsHelper.speak('商品圖片'),
                      child: SizedBox(
                        width: double.infinity,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: _product!.imageUrl != null
                                ? Image.network(
                                    _product!.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 商品名稱（寬度100%適應父元素）
                    GestureDetector(
                      onTap: () => ttsHelper.speak('商品名稱，${_product!.name}'),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          _product!.name,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text_2,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 價格（置左）+ 已售出數量（置右）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 價格（置左）
                        GestureDetector(
                          onTap: () => ttsHelper.speak(
                            '價格 ${_product!.price.toStringAsFixed(0)} 元',
                          ),
                          child: Text(
                            '\$${_product!.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              color: AppColors.primary_2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 已售出數量（置右）
                        GestureDetector(
                          onTap: () =>
                              ttsHelper.speak('已售出 $randomSoldCount 件'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 18,
                                  color: AppColors.accent_2,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '已售 $randomSoldCount',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: AppColors.accent_2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 分隔線
                    const Divider(thickness: 1),
                    const SizedBox(height: AppSpacing.md),

                    // 標籤（類別標籤，未來可加入多個標籤）（置左排列）
                    if (_product!.category != null)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                ttsHelper.speak('分類，${_product!.category}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent_1,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _product!.category!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_product!.category != null)
                      const SizedBox(height: AppSpacing.md),

                    // 分隔線
                    const Divider(thickness: 1),
                    const SizedBox(height: AppSpacing.md),

                    // 商品描述（標題與內容合併為同一個觸控範圍）
                    GestureDetector(
                      onTap: () {
                        final description = _product!.description ?? '無描述';
                        ttsHelper.speak('商品描述，$description');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '商品描述',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text_2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _product!.description ?? '無描述',
                            style: const TextStyle(
                              fontSize: 28,
                              color: AppColors.text_2,
                              height: 1.5,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 規格選擇區域
                    _buildSpecificationSection(),

                    const SizedBox(height: AppSpacing.lg),

                    // 數量選擇
                    _buildQuantitySelector(),

                    const SizedBox(height: AppSpacing.lg),

                    // 單價顯示（動態）
                    _buildPriceDisplay(),

                    const SizedBox(height: AppSpacing.xl),

                    // 按鈕區域（加入購物車 + 直接購買）
                    Row(
                      children: [
                        // 加入購物車按鈕
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ttsHelper.speak('加入購物車按鈕'),
                            onDoubleTap: _addToCart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.botton_2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  '加入購物車',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // 直接購買按鈕
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ttsHelper.speak('直接購買按鈕'),
                            onDoubleTap: _buyNow,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary_2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  '直接購買',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 商店（含商店名稱和商店評分）（寬度適應父元素）
                    if (_store != null)
                      GestureDetector(
                        onTap: () {
                          ttsHelper.speak(
                            '商家，${_store!.name}，評分${_store!.rating.toStringAsFixed(1)}顆星。雙擊可進入商家頁面。',
                          );
                        },
                        onDoubleTap: () {
                          // 語音提示導航
                          ttsHelper.speak('前往${_store!.name}商家頁面');

                          // 導航到商家頁面（使用直接導航）
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StorePage(storeId: _store!.id),
                            ),
                          ).then((_) {
                            // 從商家頁面返回時，重新朗讀商品詳情
                            _speakProductDetail();
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.text_2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.store,
                                size: 24,
                                color: AppColors.bottonText_2,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _store!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: AppColors.bottonText_2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_store!.rating > 0) ...[
                                const Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _store!.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: AppColors.bottonText_2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                size: 24,
                                color: AppColors.bottonText_2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_store != null) const SizedBox(height: AppSpacing.xl),

                    // 評論區域
                    _buildReviewsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 建立評論區域
  Widget _buildReviewsSection() {
    // 計算有文字內容的評論數量
    final reviewsWithText = _reviews
        .where((r) => r.comment.trim().isNotEmpty)
        .toList();
    final canGenerateAiSummary =
        reviewsWithText.length >= 10 && _aiClient != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分隔線
        const Divider(thickness: 1),
        const SizedBox(height: AppSpacing.md),

        // 評論標題與統計
        GestureDetector(
          onTap: () {
            if (_reviews.isEmpty) {
              ttsHelper.speak('商品評價，尚無評論');
            } else {
              ttsHelper.speak(
                '商品評價，平均${_product!.averageRating.toStringAsFixed(1)}顆星，共${_reviews.length}則評論',
              );
            }
          },
          child: _reviews.isEmpty
              ? const Text(
                  '商品評價',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text_2,
                  ),
                )
              : Row(
                  children: [
                    const Text(
                      '商品評價',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text_2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 4),
                    Text(
                      _product!.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text_2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_reviews.length}則評論)',
                      style: const TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 如果沒有評論，顯示「尚無評論」
        if (_reviews.isEmpty)
          GestureDetector(
            onTap: () => ttsHelper.speak('尚無評論'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Center(
                child: Text(
                  '尚無評論',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),

        // 如果有評論，顯示 AI 整理按鈕和評論列表
        if (_reviews.isNotEmpty) ...[
          // AI 整理按鈕（當有超過 10 則有文字的評論時顯示）
          if (canGenerateAiSummary && _aiReviewSummary == null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () => ttsHelper.speak('AI 整理評論按鈕'),
                onDoubleTap: _isGeneratingAiSummary
                    ? null
                    : _generateAiReviewSummary,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _isGeneratingAiSummary
                        ? AppColors.blockBackground_2
                        : AppColors.secondery_2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGeneratingAiSummary)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.auto_awesome,
                          size: 28,
                          color: Colors.white,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _isGeneratingAiSummary ? '正在生成 AI 摘要...' : 'AI 整理評論',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // AI 摘要卡片（如果已生成）
          if (_aiReviewSummary != null) _buildAiSummaryCard(),

          // 評論列表
          ..._reviews.map((review) => _buildReviewCard(review)),
        ],
      ],
    );
  }

  /// 建立 AI 摘要卡片
  Widget _buildAiSummaryCard() {
    return GestureDetector(
      onTap: () {
        if (_aiReviewSummary != null) {
          ttsHelper.speak('AI 評論摘要：$_aiReviewSummary');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.aiBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondery_2, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI 摘要標題
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondery_2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'AI 評論摘要',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondery_2,
                    ),
                  ),
                ),
                // 重新生成按鈕
                GestureDetector(
                  onTap: () => ttsHelper.speak('重新生成摘要按鈕'),
                  onDoubleTap: () {
                    setState(() {
                      _aiReviewSummary = null;
                    });
                    _generateAiReviewSummary();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondery_2,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: AppColors.secondery_2,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // AI 摘要內容
            Text(
              _aiReviewSummary ?? '',
              style: const TextStyle(
                fontSize: 26,
                color: AppColors.text_2,
                height: 1.5,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: AppSpacing.sm),

            // 提示文字
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '此摘要由 AI 自動生成，供參考使用',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 建立單則評論卡片
  Widget _buildReviewCard(ProductReview review) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final formattedDate = dateFormat.format(review.createdAt);

    return GestureDetector(
      onTap: () {
        final reviewText =
            '${review.userName}，評分${review.rating.toStringAsFixed(1)}顆星，${review.comment}';
        ttsHelper.speak(reviewText);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 評論者資訊與評分
            Row(
              children: [
                // 使用者頭像
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary_2,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // 使用者名稱和評分
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text_2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            if (index < review.rating.floor()) {
                              return const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              );
                            } else if (index < review.rating) {
                              return const Icon(
                                Icons.star_half,
                                color: Colors.amber,
                                size: 18,
                              );
                            } else {
                              return const Icon(
                                Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 評論日期
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // 評論內容
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 24,
                color: AppColors.text_2,
                height: 1.4,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}
