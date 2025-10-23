import 'package:isar/isar.dart';

part 'product_review.g.dart';

@Collection()
class ProductReview {
  Id id = Isar.autoIncrement;

  late int productId;       // 商品 ID
  late String userName;     // 評論者名稱
  late double rating;       // 評分 (1.0 - 5.0)
  late String comment;      // 評論內容
  late DateTime createdAt;  // 評論時間

  String? userAvatar;       // 使用者頭像（選填）
}
