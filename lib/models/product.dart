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
}
