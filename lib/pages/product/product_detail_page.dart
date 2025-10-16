import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/product.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

class ProductDetailPage extends StatefulWidget {
  final int? productId;
  final Map<String, dynamic>? productArguments;

  // ✅ 使用 super.key
  const ProductDetailPage({super.key, this.productId, this.productArguments});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (widget.productArguments != null) {
      _product = widget.productArguments;
    } else if (widget.productId != null) {
      try {
        final db = Provider.of<DatabaseService>(context, listen: false);
        final Product? p = await db.getProductById(widget.productId!);
        if (p != null) {
          _product = {
            'id': p.id,
            'name': p.name,
            'price': p.price,
            'imageUrl': p.imageUrl ?? '',
            'description': p.description ?? '',
          };
        }
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(
        title: Text(_product?['name'] ?? '商品詳情'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('找不到商品資料'))
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          _product!['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _product!['name'],
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '\$${_product!['price'].toStringAsFixed(2)}',
                        style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _product!['description'] ?? '沒有描述',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
    );
  }
}
