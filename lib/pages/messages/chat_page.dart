// lib/pages/messages/chat_page.dart
//
// 聊天室頁面 - 與 AI 助手對話

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/voice_control_appbar.dart';
import '../../widgets/message_bubble.dart';
import '../../services/database_service.dart';
import '../../services/openai_client.dart';
import '../../models/conversation.dart';
import '../../models/chat_message.dart' as chat_model;

/// 聊天室頁面
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Conversation? _conversation;
  List<chat_model.ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // OpenAI 客戶端
  late OpenAICompatibleClient _aiClient;

  @override
  void initState() {
    super.initState();
    _initializeAIClient();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 獲取傳遞的對話 ID
    final conversationId = ModalRoute.of(context)?.settings.arguments as int?;
    if (conversationId != null && _conversation == null) {
      _loadConversation(conversationId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化 AI 客戶端
  void _initializeAIClient() {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      debugPrint('⚠️ [ChatPage] DeepSeek API Key 未設定');
    }

    final provider = ProviderConfig(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: apiKey,
      defaultModel: 'deepseek-chat',
    );

    _aiClient = OpenAICompatibleClient(provider);
  }

  /// 載入對話和消息
  Future<void> _loadConversation(int conversationId) async {
    final db = Provider.of<DatabaseService>(context, listen: false);

    final conversation = await db.getConversationById(conversationId);
    final messages = await db.getChatMessages(conversationId);

    setState(() {
      _conversation = conversation;
      _messages = messages;
      _isLoading = false;
    });

    // 滾動到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// 滾動到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 發送訊息
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_conversation == null) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      // 保存用戶訊息到數據庫
      final userMsg = await db.addChatMessage(
        conversationId: _conversation!.id,
        content: userMessage,
        isUserMessage: true,
      );

      setState(() {
        _messages.add(userMsg);
      });

      _scrollToBottom();

      // 構建對話歷史
      final chatHistory = _messages.map((msg) {
        return ChatMessage(
          role: msg.isUserMessage ? Role.user : Role.assistant,
          content: msg.content,
        );
      }).toList();

      // 添加系統提示
      final systemPrompt = ChatMessage(
        role: Role.system,
        content: '你是小千助手，一個友善且樂於助人的 AI 聊天助手。請用繁體中文回答。',
      );

      final messages = [systemPrompt, ...chatHistory];

      // 調用 AI API（流式回復）
      String aiResponse = '';
      chat_model.ChatMessage? aiMsg;

      await for (final delta in _aiClient.chatCompletionStream(
        ChatCompletionOptions(
          messages: messages,
          temperature: 0.7,
          stream: true,
        ),
      )) {
        aiResponse += delta;

        // 如果是第一個字元，創建 AI 訊息
        if (aiMsg == null) {
          aiMsg = await db.addChatMessage(
            conversationId: _conversation!.id,
            content: aiResponse,
            isUserMessage: false,
          );

          setState(() {
            _messages.add(aiMsg!);
          });

          _scrollToBottom();
        } else {
          // 更新現有訊息
          setState(() {
            final index = _messages.indexWhere((m) => m.id == aiMsg!.id);
            if (index != -1) {
              _messages[index].content = aiResponse;
            }
          });
        }
      }

      // 更新數據庫中的 AI 訊息（由於代碼生成未完成，暫時跳過）
      if (aiMsg != null) {
        final isar = await db.isar;
        await isar.writeTxn(() async {
          aiMsg!.content = aiResponse;
          await isar.chatMessages.put(aiMsg);
        });

        // 更新對話的最後訊息
        await db.updateConversationLastMessage(
          conversationId: _conversation!.id,
          lastMessage: aiResponse.length > 30
              ? '${aiResponse.substring(0, 30)}...'
              : aiResponse,
          lastMessageTime: DateTime.now(),
        );
      }

      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ [ChatPage] 發送訊息失敗: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '發送失敗：$e',
              style: const TextStyle(fontSize: AppFontSizes.body),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureWrapper(
      child: Scaffold(
        backgroundColor: AppColors.background_2,
        appBar: VoiceControlAppBar(title: _conversation?.name ?? '聊天室'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 訊息列表
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _conversation?.avatarEmoji ?? '🤖',
                                  style: const TextStyle(fontSize: 64),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '開始與 ${_conversation?.name ?? "小千助手"} 對話吧！',
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.subtitle,
                                    color: AppColors.subtitle_2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return MessageBubble(
                                content: message.content,
                                isUserMessage: message.isUserMessage,
                                timestamp: message.timestamp,
                              );
                            },
                          ),
                  ),

                  // 輸入框區域
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // 輸入框
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: !_isSending,
                              maxLines: null,
                              style: const TextStyle(
                                fontSize: AppFontSizes.body,
                              ),
                              decoration: InputDecoration(
                                hintText: '輸入訊息...',
                                hintStyle: const TextStyle(
                                  fontSize: AppFontSizes.body,
                                  color: AppColors.subtitle_2,
                                ),
                                filled: true,
                                fillColor: AppColors.background_2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // 發送按鈕
                          Material(
                            color: _isSending
                                ? AppColors.subtitle_2
                                : AppColors.secondery_2,
                            borderRadius: BorderRadius.circular(28),
                            child: InkWell(
                              onTap: _isSending ? null : _sendMessage,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                child: _isSending
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
