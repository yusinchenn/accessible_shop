// lib/pages/home/home_page.dart
//
// HomePage：
// - 會嘗試從已註冊的 DatabaseService 讀取商品（若 Provider 存在且 DB 有資料）
// - 如果沒有 Provider 或 DB 無資料，會使用檔案內的假資料（方便快速預覽）
// - 支援搜尋（本地過濾）
// - 商品卡點擊會使用 Navigator.pushNamed('/product', arguments: {...})
//
// 注意：為避免與 Isar 的 model 直接耦合，這裡用 Map<String,dynamic> 作為輕量的 UI 商品表示。
// 若未來你要改用 Data Model，請在 DatabaseService 裡提供一個轉換方法。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accessible_shop/services/database_service.dart';
import '../../widgets/custom_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 本頁面的資料形式：List of Map (id, name, price, imageUrl)
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _query = '';

  // 假資料：開發 / 預覽用（若 DB 沒資料會使用這些）
  static const List<Map<String, dynamic>> _fakeProducts = [
    {
      'id': 1,
      'name': 'Vintage Camera',
      'price': 299.99,
      'imageUrl': 'https://picsum.photos/400/300?image=1',
    },
    {
      'id': 2,
      'name': 'Wireless Headphones',
      'price': 149.99,
      'imageUrl': 'https://picsum.photos/400/300?image=2',
    },
    {
      'id': 3,
      'name': 'Smart Watch',
      'price': 199.99,
      'imageUrl': 'https://picsum.photos/400/300?image=3',
    },
    {
      'id': 4,
      'name': 'Gaming Mouse',
      'price': 79.99,
      'imageUrl': 'https://picsum.photos/400/300?image=4',
    },
    {
      'id': 5,
      'name': 'Portable Speaker',
      'price': 89.99,
      'imageUrl': 'https://picsum.photos/400/300?image=5',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // 嘗試從 DatabaseService 讀取商品；若失敗則使用假資料
  Future<void> _loadProducts() async {
    setState(() => _loading = true);

    try {
      // 嘗試從 Provider 取得 DatabaseService（若 main.dart 已註冊）
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dbProducts = await dbService.getProducts(); // 這會回傳 Isar model list

      if (dbProducts.isNotEmpty) {
        // 將 Isar model 轉成 Map<String,dynamic> 供 UI 使用
        _products = dbProducts.map((p) {
          return <String, dynamic>{
            'id': p.id, // Isar 的 Id
            'name': p.name,
            'price': p.price,
            'imageUrl': p.imageUrl ?? '',
            'description': p.description ?? '',
          };
        }).toList();
      } else {
        // DB 有但沒有記錄 → 使用假資料
        _products = List<Map<String, dynamic>>.from(_fakeProducts);
      }
    } catch (e) {
      // Provider 不存在 / DB 失敗 -> 使用假資料（可以在開發階段這樣安全回退）
      _products = List<Map<String, dynamic>>.from(_fakeProducts);
    }

    // 套用搜尋（若有）
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List<Map<String, dynamic>>.from(_products);
    } else {
      _filtered = _products
          .where((p) => (p['name'] as String).toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
  }

  void _onSearchChanged(String q) {
    setState(() {
      _query = q;
      _applyFilter();
    });
  }

  void _onAddToCart(Map<String, dynamic> productMap) {
    // 目前示範以 snackbar 提示；實際可呼叫 DatabaseService 或 Cart provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入購物車：${productMap['name']}')),
    );
  }

  void _openProductDetail(Map<String, dynamic> productMap) {
    // 使用 pushNamed 並傳遞 arguments（Map），ProductDetailPage 會嘗試讀取 arguments
    Navigator.pushNamed(context, '/product', arguments: productMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessible Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            tooltip: '購物車',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.pushNamed(context, '/orders'),
            tooltip: '訂單',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '設定',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜尋列
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜尋商品（支援輸入）',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // 內容區
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('找不到商品。請更換關鍵字或稍後再試。'))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, idx) {
                          final product = _filtered[idx];
                          return GestureDetector(
                            onTap: () => _openProductDetail(product),
                            child: CustomCard(
                              productMap: product,
                              onAddToCart: () => _onAddToCart(product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
