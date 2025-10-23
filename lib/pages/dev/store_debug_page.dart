import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/store.dart';
import '../../models/product.dart';

/// 商家功能調試頁面
/// 用於檢查商家和商品資料是否正確
class StoreDebugPage extends StatefulWidget {
  const StoreDebugPage({super.key});

  @override
  State<StoreDebugPage> createState() => _StoreDebugPageState();
}

class _StoreDebugPageState extends State<StoreDebugPage> {
  List<Store> _stores = [];
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      final stores = await db.getStores();
      final products = await db.getProducts();

      setState(() {
        _stores = stores;
        _products = products;
        _loading = false;
      });

      _printDebugInfo();
    } catch (e) {
      setState(() => _loading = false);
      print('❌ 載入資料失敗: $e');
    }
  }

  void _printDebugInfo() {
    print('\n========== 商家功能調試資訊 ==========');
    print('📊 商家總數: ${_stores.length}');
    print('📊 商品總數: ${_products.length}');

    if (_stores.isEmpty) {
      print('⚠️  警告: 沒有找到任何商家資料！');
      print('   請執行測試資料初始化。');
    } else {
      print('\n商家列表:');
      for (var store in _stores) {
        final storeProducts = _products.where((p) => p.storeId == store.id).length;
        print('  ${store.id}. ${store.name} - ${store.rating}星 - ${storeProducts}個商品');
      }
    }

    if (_products.isEmpty) {
      print('\n⚠️  警告: 沒有找到任何商品資料！');
    } else {
      print('\n商品列表（前5個）:');
      for (var i = 0; i < _products.length && i < 5; i++) {
        final product = _products[i];
        final store = _stores.where((s) => s.id == product.storeId).firstOrNull;
        final storeName = store?.name ?? '未知商家(ID:${product.storeId})';
        print('  ${product.id}. ${product.name} - \$${product.price} - 商家: $storeName');
      }
    }

    // 檢查是否有商品沒有對應的商家
    final orphanProducts = _products.where((p) {
      return !_stores.any((s) => s.id == p.storeId);
    }).toList();

    if (orphanProducts.isNotEmpty) {
      print('\n⚠️  警告: 發現 ${orphanProducts.length} 個商品沒有對應的商家:');
      for (var product in orphanProducts.take(3)) {
        print('  - ${product.name} (storeId: ${product.storeId})');
      }
    }

    print('=====================================\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商家功能調試'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 統計資訊
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '資料統計',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('商家數量: ${_stores.length}',
                              style: const TextStyle(fontSize: 20)),
                          Text('商品數量: ${_products.length}',
                              style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 商家列表
                  const Text(
                    '商家列表',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_stores.isEmpty)
                    const Card(
                      color: Colors.orange,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ 沒有商家資料',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '請到 Dev Tools 頁面執行「初始化測試資料」',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._stores.map((store) {
                      final storeProducts =
                          _products.where((p) => p.storeId == store.id).toList();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.store, size: 32),
                          title: Text(
                            store.name,
                            style: const TextStyle(fontSize: 20),
                          ),
                          subtitle: Text(
                            '⭐ ${store.rating} - ${storeProducts.length} 個商品',
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: Text(
                            'ID: ${store.id}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 16),

                  // 商品列表（前10個）
                  const Text(
                    '商品列表（前10個）',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_products.isEmpty)
                    const Card(
                      color: Colors.orange,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '⚠️ 沒有商品資料',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._products.take(10).map((product) {
                      final store = _stores
                          .where((s) => s.id == product.storeId)
                          .firstOrNull;
                      final storeName = store?.name ?? '⚠️ 未知商家';
                      final hasStore = store != null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: hasStore ? null : Colors.red.shade50,
                        child: ListTile(
                          leading: Icon(
                            Icons.shopping_bag,
                            size: 32,
                            color: hasStore ? null : Colors.red,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: 16,
                                    color: hasStore ? Colors.grey : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    storeName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: hasStore ? Colors.grey : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            'ID: ${product.id}\nStore: ${product.storeId}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 32),

                  // 重新載入按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新載入資料', style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}