import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// 匯入模型
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/user_settings.dart';

class DatabaseService extends ChangeNotifier {
  late Future<Isar> _isarFuture;

  DatabaseService() {
    _isarFuture = _initIsar();
  }

  /// 初始化 Isar（非同步，不阻塞 UI）
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [ProductSchema, CartItemSchema, OrderSchema, UserSettingsSchema],
      directory: dir.path,
    );
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

  // 這裡還可以擴充其他 CRUD 方法...
}
