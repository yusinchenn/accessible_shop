import 'package:isar/isar.dart';

part 'cart_item.g.dart';

@Collection()
class CartItem {
  Id id = Isar.autoIncrement;

  /// 關聯的商品 ID
  late int productId;

  /// 商品所屬商家 ID
  late int storeId;

  /// 商品所屬商家名稱
  late String storeName;

  late String name;
  late String specification;
  late double unitPrice;
  late int quantity;
  late bool isSelected;

  CartItem();
}
