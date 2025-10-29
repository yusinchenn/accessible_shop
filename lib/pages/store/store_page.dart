import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/product_card.dart';

/// 商家頁面
/// 顯示商家資訊、關注/訊息按鈕，以及該商家的所有商品
class StorePage extends StatefulWidget {
  final int storeId;

  const StorePage({super.key, required this.storeId});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  Store? _store;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  /// 載入商家資料和商品
  Future<void> _loadStoreData() async {
    if (kDebugMode) {
      print('🏪 [StorePage] 開始載入商家資料，storeId: ${widget.storeId}');
    }

    final dbService = context.read<DatabaseService>();

    try {
      final store = await dbService.getStoreById(widget.storeId);
      final products = await dbService.getProductsByStoreId(widget.storeId);

      if (kDebugMode) {
        print(
          '🏪 [StorePage] 載入完成 - 商家: ${store?.name}, 商品數: ${products.length}',
        );
      }

      setState(() {
        _store = store;
        _products = products;
        _isLoading = false;
      });

      // 語音提示
      if (_store != null) {
        _announceStorePage();
      } else {
        if (kDebugMode) {
          print('⚠️  [StorePage] 找不到商家資料！storeId: ${widget.storeId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [StorePage] 載入失敗: $e');
      }
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('載入商家資料失敗: $e')));
      }
    }
  }

  /// 語音提示商家頁面資訊（進入頁面時自動播放）
  void _announceStorePage() {
    if (_store == null) return;

    final announcement =
        '商家頁面。'
        '${_store!.name}，'
        '評分 ${_store!.rating.toStringAsFixed(1)} 顆星，'
        '${_store!.followersCount} 位粉絲。'
        '共有 ${_products.length} 項商品。'
        '下方有關注和搜尋按鈕。';

    ttsHelper.speak(announcement);
  }

  /// AppBar 點擊時朗讀頁面說明
  void _speakAppBarInfo() {
    if (_store == null) return;

    final announcement =
        '商家頁面，${_store!.name}，'
        '頁面由上到下包含商家資訊、關注與搜尋按鈕、商家商品，'
        '單擊朗讀，雙擊商家商品項目可進入商品詳情頁面';

    ttsHelper.speak(announcement);
  }

  /// 朗讀商家資訊區塊
  void _speakStoreInfo() {
    if (_store == null) return;

    final description = _store!.description != null && _store!.description!.isNotEmpty
        ? _store!.description!
        : '';

    final announcement =
        '${_store!.name}，'
        '評分 ${_store!.rating.toStringAsFixed(1)} 顆星，'
        '粉絲數 ${_store!.followersCount}${description.isNotEmpty ? "，$description" : ""}';

    ttsHelper.speak(announcement);
  }

  /// 處理關注按鈕點擊
  void _handleFollowPressed() {
    ttsHelper.speak('關注功能，尚未實作');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('關注功能尚未實作')));
  }

  /// 處理搜尋按鈕點擊
  void _handleSearchPressed() {
    ttsHelper.speak('搜尋功能，尚未實作');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('搜尋功能尚未實作')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background_1,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _speakAppBarInfo,
          child: Text(_store?.name ?? '商家'),
        ),
        automaticallyImplyLeading: false, // 移除返回按鈕和關閉按鈕
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _store == null
          ? const Center(child: Text('找不到商家資料'))
          : CustomScrollView(
              slivers: [
                // 商家資訊區塊
                SliverToBoxAdapter(child: _buildStoreHeader()),

                // 關注和訊息按鈕
                SliverToBoxAdapter(child: _buildActionButtons()),

                // 商品列表標題
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      '商家商品 (${_products.length})',
                      style: const TextStyle(
                        fontSize: 26,
                        color: AppColors.text_1,
                      ),
                    ),
                  ),
                ),

                // 商品列表
                _products.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('此商家目前沒有商品'),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.zero,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = _products[index];
                            return GestureDetector(
                              onTap: () {
                                // 單擊朗讀商品資訊
                                final priceText = '價格 ${product.price.toStringAsFixed(0)} 元';
                                final ratingText = product.reviewCount > 0
                                    ? '，評分 ${product.averageRating.toStringAsFixed(1)} 顆星，${product.reviewCount} 則評論'
                                    : '';
                                final descriptionText = product.description != null && product.description!.isNotEmpty
                                    ? '，${product.description}'
                                    : '';

                                ttsHelper.speak(
                                  '${product.name}，$priceText$ratingText$descriptionText',
                                );
                              },
                              onDoubleTap: () {
                                // 雙擊商品卡片導航到商品詳情頁面
                                ttsHelper.stop(); // 停止當前語音
                                Navigator.pushNamed(
                                  context,
                                  '/product',
                                  arguments: product.id,
                                ).then((_) {
                                  // 從商品詳情頁返回時，停止舊語音並朗讀商家頁面
                                  ttsHelper.stop();
                                  _announceStorePage();
                                });
                              },
                              child: ProductCard(
                                product: product,
                                storeName: _store?.name, // 傳遞商家名稱
                              ),
                            );
                          }, childCount: _products.length),
                        ),
                      ),

                // 底部間距
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
    );
  }

  /// 建立商家資訊標題區塊
  Widget _buildStoreHeader() {
    return GestureDetector(
      onTap: _speakStoreInfo,
      child: Container(
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.botton_1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商家圖片和基本資訊
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商家圖片
              ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: _store!.imageUrl != null
                    ? Image.network(
                        _store!.imageUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.bottonText_1,
                              border: Border.all(
                                color: AppColors.bottonText_1,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: const Icon(
                              Icons.store,
                              size: 35,
                              color: AppColors.botton_1,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.bottonText_1,
                          border: Border.all(
                            color: AppColors.bottonText_1,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 35,
                          color: AppColors.botton_1,
                        ),
                      ),
              ),

              const SizedBox(width: 16),

              // 商家資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商家名稱
                    Text(
                      _store!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bottonText_1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 評分和粉絲數併排
                    Row(
                      children: [
                        // 星等
                        const Icon(
                          Icons.star,
                          color: AppColors.bottonText_1,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _store!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.bottonText_1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 粉絲數
                        const Icon(
                          Icons.people,
                          size: 18,
                          color: AppColors.bottonText_1,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatFollowerCount(_store!.followersCount)} 粉絲',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.bottonText_1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 商家描述
          if (_store!.description != null &&
              _store!.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.botton_1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.bottonText_1, width: 1),
              ),
              child: Text(
                _store!.description!,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.bottonText_1,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// 建立關注和訊息按鈕
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // 關注按鈕
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleFollowPressed,
              icon: const Icon(
                Icons.favorite_border,
                size: 20,
                color: AppColors.botton_1,
              ),
              label: const Text(
                '關注',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.botton_1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.botton_1, width: 2),
                backgroundColor: AppColors.bottonText_1,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 搜尋按鈕
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleSearchPressed,
              icon: const Icon(
                Icons.search,
                size: 20,
                color: AppColors.botton_1,
              ),
              label: const Text(
                '搜尋',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.botton_1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.botton_1, width: 2),
                backgroundColor: AppColors.bottonText_1,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化粉絲數量顯示
  String _formatFollowerCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}萬';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
