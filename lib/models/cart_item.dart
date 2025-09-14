import 'package:isar/isar.dart';
import 'product.dart';

part 'cart_item.g.dart';

@Collection()
class CartItem {
  Id id = Isar.autoIncrement;

  late int productId;   // 對應 Product 的 id
  late int quantity;    // 數量

  // 關聯 (未來可用 Isar Link)
  final product = IsarLink<Product>();
}
