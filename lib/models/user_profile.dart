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

  // ==================== Firestore 轉換方法 ====================

  /// 從 Firestore 文檔資料轉換為 UserProfile
  static UserProfile fromFirestore(Map<String, dynamic> data) {
    return UserProfile()
      ..userId = data['userId'] as String
      ..displayName = data['displayName'] as String?
      ..email = data['email'] as String?
      ..birthday = data['birthday'] != null
          ? DateTime.parse(data['birthday'] as String)
          : null
      ..phoneNumber = data['phoneNumber'] as String?
      ..membershipLevel = data['membershipLevel'] as String?
      ..membershipPoints = data['membershipPoints'] as int?
      ..walletBalance = (data['walletBalance'] as num?)?.toDouble()
      ..lastDailyRewardDate = data['lastDailyLogin'] != null
          ? (data['lastDailyLogin'] as dynamic).toDate()
          : null
      ..createdAt = data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : null
      ..updatedAt = data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null;
  }

  /// 轉換為 Firestore 文檔資料
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'birthday': birthday?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'membershipLevel': membershipLevel,
      'membershipPoints': membershipPoints,
      'walletBalance': walletBalance,
      'lastDailyLogin': lastDailyRewardDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
