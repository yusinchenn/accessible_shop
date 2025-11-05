import 'package:isar/isar.dart';

part 'conversation.g.dart';

/// 對話類型枚舉
enum ConversationType {
  platform, // 平台客服
  store, // 商家客服
}

/// 對話對象資料模型
@Collection()
class Conversation {
  Id id = Isar.autoIncrement;

  /// 對話對象名稱
  late String name;

  /// 對話類型
  @enumerated
  late ConversationType type;

  /// 頭像 Emoji
  late String avatarEmoji;

  /// 最後一條訊息內容
  String? lastMessage;

  /// 最後訊息時間
  DateTime? lastMessageTime;

  /// 未讀數量
  late int unreadCount;

  /// 關聯的商家 ID（僅商家客服有值）
  int? storeId;

  Conversation();
}
