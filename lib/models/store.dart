import 'package:isar/isar.dart';

part 'store.g.dart';

@Collection()
class Store {
  Id id = Isar.autoIncrement;

  late String name;           // 商家名稱
  late double rating;         // 商家星等 (0-5)
  late int followersCount;    // 粉絲數
  String? imageUrl;           // 商家圖片
  String? description;        // 商家描述
}