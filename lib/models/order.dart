import 'package:isar/isar.dart';
import 'cart_item.dart';

part 'order.g.dart';

@Collection()
class Order {
  Id id = Isar.autoIncrement;

  late DateTime createdAt;        // 訂單建立時間
  late double totalPrice;         // 總金額
  String? status;                 // 狀態 (ex: 已付款、已出貨)

  // 訂單項目
  final items = IsarLinks<CartItem>();
}
