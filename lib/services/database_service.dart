import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// 匯入模型
import '../models/product.dart';
import '../models/cart_item.dart' show CartItemSchema;
import '../models/user_settings.dart';

class DatabaseService extends ChangeNotifier {
  late Future<Isar> _isarFuture;

  DatabaseService() {
    _isarFuture = _initIsar();
  }

  /// 初始化 Isar（非同步，不阻塞 UI）
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([
      ProductSchema,
      CartItemSchema,
      UserSettingsSchema,
    ], directory: dir.path);
  }

  /// 外部存取 Isar 實例
  Future<Isar> get isar async => await _isarFuture;

  /// 取得所有商品
  Future<List<Product>> getProducts() async {
    final isar = await _isarFuture; // ✅ 先取得 Isar 實例
    return await isar.products.where().findAll();
  }

  /// 用 id 查詢商品
  Future<Product?> getProductById(int id) async {
    final isar = await _isarFuture; // ✅ 先取得 Isar 實例
    return await isar.products.get(id);
  }

  /// 智能搜尋商品（支援模糊搜尋與優先級排序）
  /// 排序優先級：
  /// 1. 商品名稱完全匹配
  /// 2. 商品名稱包含關鍵字
  /// 3. 描述包含關鍵字
  /// 4. 分類包含關鍵字
  Future<List<Product>> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      return await getProducts();
    }

    final isar = await _isarFuture;
    final allProducts = await isar.products.where().findAll();

    if (kDebugMode) {
      print('🔍 [DatabaseService] 資料庫總商品數: ${allProducts.length}');
      print('🔍 [DatabaseService] 搜尋關鍵字: "$keyword"');
    }

    final searchKeyword = keyword.toLowerCase().trim();

    // 使用評分系統進行排序
    final scoredProducts = allProducts.map((product) {
      int score = 0;
      final name = product.name.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      final category = (product.category ?? '').toLowerCase();

      // 商品名稱完全匹配 - 最高分 100
      if (name == searchKeyword) {
        score = 100;
      }
      // 商品名稱開頭匹配 - 90 分
      else if (name.startsWith(searchKeyword)) {
        score = 90;
      }
      // 商品名稱包含關鍵字 - 80 分
      else if (name.contains(searchKeyword)) {
        score = 80;
      }
      // 描述完全匹配 - 70 分
      else if (description == searchKeyword) {
        score = 70;
      }
      // 描述包含關鍵字 - 60 分
      else if (description.contains(searchKeyword)) {
        score = 60;
      }
      // 分類完全匹配 - 50 分
      else if (category == searchKeyword) {
        score = 50;
      }
      // 分類包含關鍵字 - 40 分
      else if (category.contains(searchKeyword)) {
        score = 40;
      }

      // 模糊匹配：檢查是否包含關鍵字的部分字符（至少 2 個字）
      if (score == 0 && searchKeyword.length >= 2) {
        // 檢查名稱中是否包含關鍵字的連續子字串
        for (int i = 0; i <= searchKeyword.length - 2; i++) {
          final substring = searchKeyword.substring(i, i + 2);
          if (name.contains(substring)) {
            score = 20;
            break;
          }
          if (description.contains(substring)) {
            score = 10;
            break;
          }
        }
      }

      return MapEntry(product, score);
    }).where((entry) => entry.value > 0).toList();

    // 按分數排序（高到低）
    scoredProducts.sort((a, b) => b.value.compareTo(a.value));

    if (kDebugMode) {
      print('🔍 [DatabaseService] 找到 ${scoredProducts.length} 筆符合的商品');
      if (scoredProducts.isNotEmpty) {
        print('🔍 [DatabaseService] 前 3 筆結果（含分數）:');
        for (var i = 0; i < scoredProducts.length && i < 3; i++) {
          final entry = scoredProducts[i];
          print('   ${i + 1}. ${entry.key.name} (分數: ${entry.value}, 分類: ${entry.key.category})');
        }
      }
    }

    // 返回排序後的商品列表
    return scoredProducts.map((entry) => entry.key).toList();
  }

  // 這裡還可以擴充其他 CRUD 方法...
}
