/// ai_agent_service.dart
/// "大千世界" AI 智能代理服務
/// 整合 DeepSeek 對話，支援語音智能助理功能
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart';

/// AI 代理回應類型
enum AIAgentResponseType {
  /// 純文字回應
  text,

  /// 執行工具中
  executingTool,

  /// 工具執行完成
  toolExecuted,

  /// 錯誤
  error,
}

/// AI 代理回應
class AIAgentResponse {
  final AIAgentResponseType type;
  final String content;
  final String? toolName;
  final Map<String, dynamic>? toolResult;

  AIAgentResponse({
    required this.type,
    required this.content,
    this.toolName,
    this.toolResult,
  });
}

/// AI 智能代理服務
class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  factory AIAgentService() => _instance;
  AIAgentService._internal();

  late final OpenAICompatibleClient _client;
  bool _isInitialized = false;

  /// 對話歷史
  final List<ChatMessage> _conversationHistory = [];

  /// 初始化服務
  void initialize() {
    if (_isInitialized) return;

    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ [AIAgent] DEEPSEEK_API_KEY not found in .env');
    }

    final provider = ProviderConfig(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: apiKey,
      defaultModel: 'deepseek-chat',
    );

    _client = OpenAICompatibleClient(provider);

    // 設置系統提示
    _conversationHistory.clear();
    _conversationHistory.add(
      ChatMessage(
        role: Role.system,
        content: '''你是「大千世界」智能助理，一個友善且樂於助人的購物助手。

你的主要能力：
1. 幫助用戶搜索商品，理解用戶的需求並提供購物建議
2. 解答用戶關於商品、訂單、購物車的疑問
3. 提供友善、專業的購物諮詢服務

重要規則：
- 始終使用繁體中文回答
- 保持友善、專業的態度
- 回答要簡潔明了，避免冗長
- 在了解用戶需求後提供建議
- 如果用戶詢問具體功能操作，引導他們使用應用內的相應功能''',
      ),
    );

    _isInitialized = true;
    debugPrint('✅ [AIAgent] Service initialized');
  }

  /// 獲取對話歷史
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// 清除對話歷史（保留系統提示）
  void clearHistory() {
    if (_conversationHistory.length > 1) {
      _conversationHistory.removeRange(1, _conversationHistory.length);
    }
  }

  /// 發送訊息並獲取流式回應
  Stream<AIAgentResponse> sendMessageStream(String userMessage) async* {
    if (!_isInitialized) {
      initialize();
    }

    // 添加用戶訊息到歷史
    _conversationHistory.add(
      ChatMessage(role: Role.user, content: userMessage),
    );

    try {
      // 調用 AI (目前為簡化版，未使用 Function Calling)
      String fullResponse = '';
      final streamOpts = ChatCompletionOptions(
        messages: _conversationHistory,
        temperature: 0.7,
        stream: true,
      );

      await for (final delta in _client.chatCompletionStream(streamOpts)) {
        fullResponse += delta;
        yield AIAgentResponse(
          type: AIAgentResponseType.text,
          content: delta,
        );
      }

      // 添加 AI 回應到歷史
      _conversationHistory.add(
        ChatMessage(role: Role.assistant, content: fullResponse),
      );
    } catch (e) {
      debugPrint('❌ [AIAgent] Error: $e');
      yield AIAgentResponse(
        type: AIAgentResponseType.error,
        content: '抱歉，處理您的請求時發生錯誤：$e',
      );
    }
  }

}

/// 全局單例
final aiAgentService = AIAgentService();