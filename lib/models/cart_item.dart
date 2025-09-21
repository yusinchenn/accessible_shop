import 'package:isar/isar.dart';

part 'cart_item.g.dart';

@Collection()
class CartItem {
  Id id = Isar.autoIncrement;
  late String name;
  late String specification;
  late double unitPrice;
  late int quantity;
  late bool isSelected;

  CartItem();
}
