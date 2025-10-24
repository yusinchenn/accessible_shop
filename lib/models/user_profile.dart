import 'package:isar/isar.dart';

part 'user_profile.g.dart';

/// 使用者資料模型
/// 儲存使用者的個人資料，與 Firebase Auth 的 UID 關聯
@Collection()
class UserProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId; // Firebase Auth UID，用於關聯使用者

  String? displayName; // 使用者名稱（可更改）
  String? email; // 電子郵件（從 Firebase Auth 同步）
  DateTime? birthday; // 生日
  String? phoneNumber; // 手機號碼

  // 會員等級相關（未來擴充）
  String? membershipLevel; // 會員等級：'regular', 'silver', 'gold', 'platinum'
  int? membershipPoints; // 會員點數

  // 錢包相關（未來擴充）
  double? walletBalance; // 錢包餘額
  DateTime? lastDailyRewardDate; // 上次領取每日獎勵的日期

  // 時間戳記
  DateTime? createdAt; // 建立時間
  DateTime? updatedAt; // 更新時間
}
