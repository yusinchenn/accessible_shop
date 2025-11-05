import 'package:isar/isar.dart';

part 'chat_message.g.dart';

/// 聊天消息資料模型
@Collection()
class ChatMessage {
  Id id = Isar.autoIncrement;

  /// 關聯的對話 ID
  @Index()
  late int conversationId;

  /// 訊息內容
  late String content;

  /// 是否為用戶訊息（true=用戶, false=AI）
  late bool isUserMessage;

  /// 訊息時間戳
  late DateTime timestamp;

  ChatMessage();
}
