import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  bool _loading = true;
  final TtsHelper _ttsHelper = TtsHelper();

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

        setState(() {
          _product = product;
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
    final text = '商品詳情，${_product!.name}，價格 ${_product!.price.toStringAsFixed(0)} 元$category';
    await _ttsHelper.speak(text);
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
                        const SizedBox(height: AppSpacing.md),

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

                        // 加入購物車按鈕
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _ttsHelper.speak('已加入購物車');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('已加入購物車', style: TextStyle(fontSize: 24)),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
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
