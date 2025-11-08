/// ai_agent_page.dart
/// "大千世界" AI 智能代理頁面
/// 整合語音輸入和 AI 對話的智能助理界面
library;

import 'package:flutter/material.dart';
import '../../services/ai_agent_service.dart';
import '../../services/stt_service.dart';
import '../../utils/tts_helper.dart';
import '../../widgets/voice_control_appbar.dart';
import '../../widgets/golden_lotus_animation.dart';

// 導入 VoiceFeatureState enum
// (已經在 voice_control_appbar.dart 中定義，但需要確保可以訪問)

/// AI 代理頁面
class AIAgentPage extends StatefulWidget {
  const AIAgentPage({super.key});

  @override
  State<AIAgentPage> createState() => _AIAgentPageState();
}

class _AIAgentPageState extends State<AIAgentPage> with TickerProviderStateMixin {
  /// 是否顯示開場動畫
  bool _showAnimation = true;

  /// 頁面淡入透明度
  double _pageOpacity = 0.0;

  /// 對話訊息列表（用於顯示）
  final List<_ChatMessage> _messages = [];

  /// 是否正在監聽語音
  bool _isListening = false;

  /// 當前用戶語音輸入（轉文字）
  String _currentUserInput = '';

  /// AI 是否正在回應
  bool _isAIResponding = false;

  /// 當前 AI 回應文字
  String _currentAIResponse = '';

  /// 滾動控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    sttService.stopListening();
    super.dispose();
  }

  /// 初始化
  Future<void> _initialize() async {
    // 初始化 AI Agent 服務
    aiAgentService.initialize();

    // 設置 STT 回調
    sttService.onResult = _handleSttResult;
    sttService.onError = (error) {
      debugPrint('❌ [AIAgent] STT Error: $error');
    };

    // 動畫播放到 2.5 秒（一半）時開始淡入頁面
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _showAnimation) {
        setState(() {
          _pageOpacity = 1.0;
        });
      }
    });
  }

  /// 動畫完成處理
  Future<void> _onAnimationComplete() async {
    setState(() {
      _showAnimation = false;
    });

    // 動畫完成後播放語音歡迎
    await ttsHelper.speak('歡迎來到大千世界！我是您的智能助理，您可以按住麥克風按鈕與我對話。');
  }

  /// 處理語音識別結果（最終結果）
  void _handleSttResult(String text) {
    setState(() {
      _currentUserInput = text;
    });

    // 發送給 AI
    if (text.trim().isNotEmpty) {
      _sendMessageToAI(text);
    }
  }

  /// 發送訊息給 AI
  Future<void> _sendMessageToAI(String message) async {
    // 添加用戶訊息到列表
    setState(() {
      _messages.add(_ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _currentUserInput = '';
      _isAIResponding = true;
      _currentAIResponse = '';
    });

    // 滾動到底部
    _scrollToBottom();

    try {
      // 使用流式獲取 AI 回應
      await for (final response in aiAgentService.sendMessageStream(message)) {
        if (response.type == AIAgentResponseType.text) {
          setState(() {
            _currentAIResponse += response.content;
          });

          // 實時滾動到底部
          _scrollToBottom();
        } else if (response.type == AIAgentResponseType.error) {
          setState(() {
            _currentAIResponse = response.content;
          });
        }
      }

      // AI 回應完成，添加到訊息列表
      if (_currentAIResponse.isNotEmpty) {
        setState(() {
          _messages.add(_ChatMessage(
            content: _currentAIResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isAIResponding = false;
          _currentAIResponse = '';
        });

        // 朗讀 AI 回應
        await ttsHelper.speak(_messages.last.content);
      }
    } catch (e) {
      debugPrint('❌ [AIAgent] Error: $e');
      setState(() {
        _isAIResponding = false;
        _currentAIResponse = '';
      });

      await ttsHelper.speak('抱歉，發生錯誤，請稍後再試。');
    }
  }

  /// 滾動到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 開始語音輸入
  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _currentUserInput = '';
    });

    await sttService.startListening();
  }

  /// 停止語音輸入
  Future<void> _stopListening() async {
    if (!_isListening) return;

    setState(() {
      _isListening = false;
    });

    await sttService.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    // 構建聊天界面
    final chatInterface = Scaffold(
      appBar: VoiceControlAppBar(
        title: '大千世界',
        automaticallyImplyLeading: false, // 不顯示返回按鈕
        initialState: VoiceFeatureState.voiceAgent, // 設置初始狀態為語音代理人
        onTap: () {
          ttsHelper.speak('大千世界智能助理頁面。您可以按住麥克風按鈕開始對話。');
        },
      ),
      body: Column(
        children: [
          // 對話區域
          Expanded(
            child: _messages.isEmpty && !_isAIResponding
                ? _buildEmptyState()
                : _buildMessageList(),
          ),

          // 當前用戶輸入顯示
          if (_isListening && _currentUserInput.isNotEmpty)
            _buildCurrentInput(),

          // 當前 AI 回應顯示
          if (_isAIResponding && _currentAIResponse.isNotEmpty)
            _buildCurrentAIResponse(),

          // 麥克風按鈕
          _buildMicrophoneButton(),
        ],
      ),
    );

    // 如果正在顯示動畫，使用 Stack 疊加
    if (_showAnimation) {
      return Stack(
        children: [
          // 底層：全屏蓮花動畫
          Positioned.fill(
            child: GoldenLotusAnimation(
              onComplete: _onAnimationComplete,
              durationSeconds: 5, // 5秒動畫
            ),
          ),
          // 上層：聊天界面（動畫播放到一半後淡入）
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _pageOpacity,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              child: chatInterface,
            ),
          ),
        ],
      );
    }

    // 動畫完成後只顯示聊天界面
    return chatInterface;
  }

  /// 構建空狀態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '按住麥克風按鈕開始對話',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '我可以幫助您搜索商品、解答疑問',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 構建訊息列表
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// 構建訊息氣泡
  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: message.isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 構建當前用戶輸入
  Widget _buildCurrentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentUserInput,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 構建當前 AI 回應
  Widget _buildCurrentAIResponse() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentAIResponse,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 構建麥克風按鈕
  Widget _buildMicrophoneButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onLongPressStart: (_) => _startListening(),
        onLongPressEnd: (_) => _stopListening(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: _isListening
                ? Colors.red
                : Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 聊天訊息
class _ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}