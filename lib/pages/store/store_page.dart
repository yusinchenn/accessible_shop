import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../../utils/tts_helper.dart';
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

  /// 語音提示商家頁面資訊
  void _announceStorePage() {
    if (_store == null) return;

    final announcement =
        '商家頁面。'
        '${_store!.name}，'
        '評分 ${_store!.rating.toStringAsFixed(1)} 顆星，'
        '${_store!.followersCount} 位粉絲。'
        '共有 ${_products.length} 項商品。'
        '下方有關注和訊息按鈕。';

    ttsHelper.speak(announcement);
  }

  /// 處理關注按鈕點擊
  void _handleFollowPressed() {
    ttsHelper.speak('關注功能，尚未實作');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('關注功能尚未實作')));
  }

  /// 處理訊息按鈕點擊
  void _handleMessagePressed() {
    ttsHelper.speak('訊息功能，尚未實作');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('訊息功能尚未實作')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_store?.name ?? '商家'),
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
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Text(
                      '商家商品 (${_products.length})',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = _products[index];
                            return GestureDetector(
                              onDoubleTap: () {
                                // 雙擊商品卡片導航到商品詳情頁面
                                Navigator.pushNamed(
                                  context,
                                  '/product',
                                  arguments: product.id,
                                );
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50], // 改為淡藍色背景，更容易辨識
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!, width: 2), // 更明顯的分隔線
        ),
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
                borderRadius: BorderRadius.circular(8),
                child: _store!.imageUrl != null
                    ? Image.network(
                        _store!.imageUrl!,
                        width: 120, // 增大圖片尺寸
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue[100], // 改為藍色系
                              border: Border.all(color: Colors.blue[300]!, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.store,
                              size: 60,
                              color: Colors.blue, // 改為藍色圖示
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          border: Border.all(color: Colors.blue[300]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 60,
                          color: Colors.blue,
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
                        fontSize: 36, // 增大字體
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // 明確設定為黑色
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 星等
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 32), // 改為橘色，更醒目
                        const SizedBox(width: 6),
                        Text(
                          _store!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 30, // 增大字體
                            fontWeight: FontWeight.bold, // 加粗
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 粉絲數
                    Row(
                      children: [
                        const Icon(Icons.people, size: 30, color: Colors.blue), // 改為藍色
                        const SizedBox(width: 6),
                        Text(
                          '${_formatFollowerCount(_store!.followersCount)} 粉絲',
                          style: const TextStyle(
                            fontSize: 28, // 增大字體
                            color: Colors.black87, // 改為深灰色
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
                color: Colors.white, // 白色背景讓文字更清晰
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Text(
                _store!.description!,
                style: const TextStyle(
                  fontSize: 28, // 增大字體
                  color: Colors.black, // 改為純黑色
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 建立關注和訊息按鈕
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 關注按鈕
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleFollowPressed,
              icon: const Icon(Icons.favorite_border, size: 28, color: Colors.white),
              label: const Text('關注', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.red, // 紅色背景
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 訊息按鈕
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleMessagePressed,
              icon: const Icon(Icons.message, size: 28, color: Colors.blue),
              label: const Text('訊息', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: Colors.blue, width: 2), // 藍色邊框
                backgroundColor: Colors.white,
                elevation: 2,
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
