import 'package:isar/isar.dart';

part 'notification.g.dart';

/// 通知類型枚舉
enum NotificationType {
  order, // 訂單通知
  promotion, // 促銷通知
  system, // 系統通知
}

/// 通知項目資料模型
@Collection()
class NotificationModel {
  Id id = Isar.autoIncrement;

  /// 通知標題
  late String title;

  /// 通知內容
  late String content;

  /// 通知類型（使用枚舉索引儲存）
  @enumerated
  late NotificationType type;

  /// 建立時間
  late DateTime timestamp;

  /// 是否已讀
  @Index()
  late bool isRead;

  /// 關聯的訂單 ID（可為 null，僅訂單通知有值）
  int? orderId;

  /// 關聯的訂單編號（可為 null，僅訂單通知有值）
  String? orderNumber;

  NotificationModel();
}
