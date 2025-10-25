import 'package:isar/isar.dart';

part 'product.g.dart';

@Collection()
class Product {
  Id id = Isar.autoIncrement;

  late String name;
  late double price;
  String? description;
  String? imageUrl;   // 商品圖片 (未來可擴充)
  String? category;   // 商品分類
  late int storeId;   // 所屬商家 ID
  int stock = 999;    // 庫存數量，預設999

  // 評分相關欄位
  double averageRating = 0.0;  // 平均評分
  int reviewCount = 0;         // 評論數量

  // 銷售相關欄位
  int soldCount = 0;           // 售出次數
}
