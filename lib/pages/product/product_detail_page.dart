import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/database_service.dart';
import '../store/store_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  Store? _store;
  bool _loading = true;
  final TtsHelper _ttsHelper = TtsHelper();

  // 規格選擇狀態
  String _selectedSize = '通用尺寸';
  String _selectedColor = '預設顏色';
  int _quantity = 1;

  // 可選的規格選項（可以從商品屬性動態生成）
  final List<String> _sizeOptions = ['通用尺寸', 'S', 'M', 'L', 'XL'];
  final List<String> _colorOptions = ['預設顏色', '黑色', '白色', '灰色', '藍色', '紅色'];

  @override
  void initState() {
    super.initState();
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
        if (product != null) {
          store = await db.getStoreById(product.storeId);
        }

        setState(() {
          _product = product;
          _store = store;
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
    final category = _product!.category != null ? '，分類${_product!.category}' : '';
    final storeName = _store?.name;
    final storeInfo = storeName != null ? '，商家$storeName' : '';
    final text = '商品詳情，${_product!.name}，價格 ${_product!.price.toStringAsFixed(0)} 元$storeInfo$category';
    await _ttsHelper.speak(text);
  }

  /// 加入購物車
  Future<void> _addToCart() async {
    if (_product == null) return;

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final specification = '尺寸: $_selectedSize / 顏色: $_selectedColor';

      await db.addToCart(
        productId: _product!.id,
        productName: _product!.name,
        price: _product!.price,
        specification: specification,
        quantity: _quantity,
      );

      _ttsHelper.speak('已加入購物車，$_quantity 項');

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
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      _ttsHelper.speak('加入購物車失敗');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '加入購物車失敗: $e',
              style: const TextStyle(fontSize: 24),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 建立規格選擇區域
  Widget _buildSpecificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 尺寸選擇
        GestureDetector(
          onTap: () => _ttsHelper.speak('選擇尺寸'),
          child: const Text(
            '選擇尺寸',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
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
              onTap: () => _ttsHelper.speak('尺寸 $size'),
              onDoubleTap: () {
                setState(() => _selectedSize = size);
                _ttsHelper.speak('已選擇尺寸 $size');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    fontSize: 24,
                    color: isSelected ? Colors.white : AppColors.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // 顏色選擇
        GestureDetector(
          onTap: () => _ttsHelper.speak('選擇顏色'),
          child: const Text(
            '選擇顏色',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
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
              onTap: () => _ttsHelper.speak('顏色 $color'),
              onDoubleTap: () {
                setState(() => _selectedColor = color);
                _ttsHelper.speak('已選擇顏色 $color');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  color,
                  style: TextStyle(
                    fontSize: 24,
                    color: isSelected ? Colors.white : AppColors.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 建立數量選擇器
  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _ttsHelper.speak('選擇數量'),
          child: const Text(
            '選擇數量',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // 減少按鈕
            GestureDetector(
              onTap: () => _ttsHelper.speak('減少數量'),
              onDoubleTap: () {
                if (_quantity > 1) {
                  setState(() => _quantity--);
                  _ttsHelper.speak('數量 $_quantity');
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _quantity > 1 ? AppColors.primary : Colors.grey[300],
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
              onTap: () => _ttsHelper.speak('數量 $_quantity'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 增加按鈕
            GestureDetector(
              onTap: () => _ttsHelper.speak('增加數量'),
              onDoubleTap: () {
                if (_quantity < 99) {
                  setState(() => _quantity++);
                  _ttsHelper.speak('數量 $_quantity');
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _quantity < 99 ? AppColors.primary : Colors.grey[300],
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
    _ttsHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_product?.name ?? '商品詳情'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(
                  child: Text(
                    '找不到商品資料',
                    style: TextStyle(fontSize: 28),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 商品圖片
                        GestureDetector(
                          onTap: () => _ttsHelper.speak('商品圖片'),
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
                        const SizedBox(height: AppSpacing.lg),

                        // 商品名稱
                        GestureDetector(
                          onTap: () => _ttsHelper.speak('商品名稱，${_product!.name}'),
                          child: Text(
                            _product!.name,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // 商家名稱
                        if (_store != null)
                          GestureDetector(
                            onTap: () {
                              _ttsHelper.speak('商家，${_store!.name}，評分${_store!.rating.toStringAsFixed(1)}顆星。雙擊可進入商家頁面。');
                            },
                            onDoubleTap: () {
                              // 語音提示導航
                              _ttsHelper.speak('前往${_store!.name}商家頁面');

                              // 導航到商家頁面（使用直接導航）
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StorePage(storeId: _store!.id),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.store,
                                    size: 24,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _store!.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w500,
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
                                        fontSize: 24,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 24,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_store != null) const SizedBox(height: AppSpacing.md),

                        // 價格和分類標籤
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _ttsHelper.speak('價格 ${_product!.price.toStringAsFixed(0)} 元'),
                              child: Text(
                                '\$${_product!.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_product!.category != null) ...[
                              const SizedBox(width: AppSpacing.md),
                              GestureDetector(
                                onTap: () => _ttsHelper.speak('分類，${_product!.category}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _product!.category!,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 分隔線
                        const Divider(thickness: 1),
                        const SizedBox(height: AppSpacing.md),

                        // 商品描述標題
                        GestureDetector(
                          onTap: () => _ttsHelper.speak('商品描述'),
                          child: const Text(
                            '商品描述',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // 商品描述內容
                        GestureDetector(
                          onTap: () => _ttsHelper.speak(_product!.description ?? '無描述'),
                          child: Text(
                            _product!.description ?? '無描述',
                            style: const TextStyle(
                              fontSize: 28,
                              color: AppColors.text,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 規格選擇區域
                        _buildSpecificationSection(),

                        const SizedBox(height: AppSpacing.lg),

                        // 數量選擇
                        _buildQuantitySelector(),

                        const SizedBox(height: AppSpacing.xl),

                        // 加入購物車按鈕
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '加入購物車',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
