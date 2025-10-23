import 'package:isar/isar.dart';

part 'product_review.g.dart';

@Collection()
class ProductReview {
  Id id = Isar.autoIncrement;

  late int productId;       // 商品 ID
  late int orderId;         // 訂單 ID（用於區分同一商品在不同訂單的評論）
  late String userName;     // 評論者名稱
  late double rating;       // 評分 (1.0 - 5.0)
  late String comment;      // 評論內容
  late DateTime createdAt;  // 評論時間
  DateTime? updatedAt;      // 最後更新時間（修改評論時使用）

  String? userAvatar;       // 使用者頭像（選填）
}
