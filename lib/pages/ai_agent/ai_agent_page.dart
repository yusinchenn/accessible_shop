/// ai_agent_page.dart
/// "大千世界" AI 智能代理頁面
/// 整合語音輸入和 AI 對話的智能助理界面
library;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/ai_agent_service.dart';
import '../../services/stt_service.dart';
import '../../utils/tts_helper.dart';
import '../../widgets/golden_lotus_animation.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../models/notification.dart';
import 'widgets/conversation_product_card.dart';
import 'widgets/conversation_order_card.dart';
import 'widgets/conversation_cart_card.dart';
import 'widgets/conversation_notification_card.dart';

/// 對話訊息類型
enum ConversationMessageType {
  user,
  assistant,
  card,
}

/// 對話訊息
class ConversationMessage {
  final ConversationMessageType type;
  final String? text;
  final AIAgentResponseType? cardType;
  final dynamic cardData;

  ConversationMessage({
    required this.type,
    this.text,
    this.cardType,
    this.cardData,
  });
}

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

  /// 是否正在監聽語音
  bool _isListening = false;

  /// 當前用戶語音輸入（轉文字）
  String _currentUserInput = '';

  /// AI 是否正在回應
  bool _isAIResponding = false;

  /// 當前 AI 回應文字
  String _currentAIResponse = '';

  /// 最後一次的訊息（用於在沒有新輸入時顯示）
  String _lastMessage = '';

  /// 長按持續時間（秒）
  int _longPressDuration = 0;

  /// 長按階段計時器
  Timer? _durationTimer;

  /// 對話歷史
  final List<ConversationMessage> _conversationHistory = [];

  /// 滾動控制器
  final ScrollController _scrollController = ScrollController();

  /// 是否顯示對話歷史
  bool _showConversationHistory = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _scrollController.dispose();
    sttService.stopListening();
    _closeAgent();
    super.dispose();
  }

  /// 初始化
  Future<void> _initialize() async {
    // 初始化 AI Agent 服務
    aiAgentService.initialize();

    // 設置 STT 回調
    sttService.onResult = _handleSttResult;
    sttService.onPartialResult = _handleSttPartialResult;
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

  /// 處理語音識別部分結果（即時顯示）
  void _handleSttPartialResult(String text) {
    setState(() {
      _currentUserInput = text;
    });
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
    setState(() {
      _currentUserInput = '';
      _isAIResponding = true;
      _currentAIResponse = '';
    });

    // 將用戶訊息添加到歷史
    _conversationHistory.add(ConversationMessage(
      type: ConversationMessageType.user,
      text: message,
    ));

    try {
      // 使用流式獲取 AI 回應
      await for (final response in aiAgentService.sendMessageStream(message)) {
        if (response.type == AIAgentResponseType.text) {
          setState(() {
            _currentAIResponse += response.content;
          });
        } else if (response.type == AIAgentResponseType.error) {
          setState(() {
            _currentAIResponse = response.content;
          });
        } else if (response.type == AIAgentResponseType.displayProductCard ||
            response.type == AIAgentResponseType.displayOrderCard ||
            response.type == AIAgentResponseType.displayCartCard ||
            response.type == AIAgentResponseType.displayNotificationCard) {
          // 收到卡片資料，添加到對話歷史
          setState(() {
            _conversationHistory.add(ConversationMessage(
              type: ConversationMessageType.card,
              cardType: response.type,
              cardData: response.cardData,
            ));
          });
        }
      }

      // AI 回應完成
      if (_currentAIResponse.isNotEmpty) {
        final aiResponse = _currentAIResponse;

        // 將 AI 回應添加到歷史
        _conversationHistory.add(ConversationMessage(
          type: ConversationMessageType.assistant,
          text: aiResponse,
        ));

        setState(() {
          _isAIResponding = false;
          _currentAIResponse = '';
          _lastMessage = aiResponse; // 保存最後一次訊息
        });

        // 朗讀 AI 回應
        await ttsHelper.speak(aiResponse);

        // 自動滾動到底部（如果顯示對話歷史）
        if (_showConversationHistory) {
          _scrollToBottom();
        }
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

  /// 滾動到對話底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// 切換對話歷史顯示
  void _toggleConversationHistory() {
    setState(() {
      _showConversationHistory = !_showConversationHistory;
    });

    if (_showConversationHistory) {
      _scrollToBottom();
    }
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

  /// 關閉 Agent（導航回首頁）
  void _closeAgent() {
    if (!mounted) return;

    // 靜默停止 TTS
    ttsHelper.stop();

    // 導航回首頁
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  /// 處理 AppBar 長按開始
  void _onAppBarLongPressStart(LongPressStartDetails details) {
    // 取消之前的計時器（如果有）
    _durationTimer?.cancel();

    // 重置長按持續時間
    setState(() {
      _longPressDuration = 0;
    });

    // 啟動持續時間計時器
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _longPressDuration += 1;
      });

      // 長按 1 秒後關閉
      if (_longPressDuration >= 1) {
        timer.cancel();
        _closeAgent();
      }
    });
  }

  /// 處理 AppBar 長按結束
  void _onAppBarLongPressEnd(LongPressEndDetails details) {
    _durationTimer?.cancel();
    _durationTimer = null;

    if (mounted) {
      setState(() {
        _longPressDuration = 0;
      });
    }
  }

  /// 處理 AppBar 長按取消
  void _onAppBarLongPressCancel() {
    _durationTimer?.cancel();
    _durationTimer = null;

    if (mounted) {
      setState(() {
        _longPressDuration = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 構建主界面
    final mainInterface = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 主要內容區域
          Positioned.fill(
            child: _showConversationHistory
                ? _buildConversationHistory()
                : GestureDetector(
                    onLongPressStart: (_) => _startListening(),
                    onLongPressEnd: (_) => _stopListening(),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: _buildCurrentMessage(),
                      ),
                    ),
                  ),
          ),

          // 玻璃感 AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGlassAppBar(context),
          ),

          // 切換視圖按鈕（僅在有對話記錄時顯示）
          if (_conversationHistory.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _toggleConversationHistory,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  _showConversationHistory
                      ? Icons.mic
                      : Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
              ),
            ),
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
          // 上層：主界面（動畫播放到一半後淡入）
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _pageOpacity,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              child: mainInterface,
            ),
          ),
        ],
      );
    }

    // 動畫完成後只顯示主界面
    return mainInterface;
  }

  /// 構建玻璃感 AppBar
  Widget _buildGlassAppBar(BuildContext context) {
    return SafeArea(
      child: Center(
        child: GestureDetector(
          onLongPressStart: _onAppBarLongPressStart,
          onLongPressEnd: _onAppBarLongPressEnd,
          onLongPressCancel: _onAppBarLongPressCancel,
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 標題
                      const Text(
                        'agent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // beta 標籤
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'beta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // 長按進度指示器
                      if (_longPressDuration > 0) ...[
                        const SizedBox(width: 12),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                value: _longPressDuration / 1,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                backgroundColor: Colors.white38,
                              ),
                            ),
                            Text(
                              '$_longPressDuration',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 構建當前訊息顯示
  Widget _buildCurrentMessage() {
    String displayText = '';
    bool showPlaceholder = false;

    // 優先顯示 AI 回應
    if (_isAIResponding && _currentAIResponse.isNotEmpty) {
      displayText = _currentAIResponse;
    }
    // 其次顯示用戶輸入
    else if (_isListening && _currentUserInput.isNotEmpty) {
      displayText = _currentUserInput;
    }
    // 顯示上一個訊息（如果有）
    else if (_lastMessage.isNotEmpty) {
      displayText = _lastMessage;
    }
    // 空狀態
    else {
      showPlaceholder = true;
    }

    if (showPlaceholder) {
      return const Text(
        '按住螢幕開始對話',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 構建對話歷史列表
  Widget _buildConversationHistory() {
    if (_conversationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white30),
            const SizedBox(height: 16),
            const Text(
              '還沒有對話記錄',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '按住螢幕開始對話',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      itemCount: _conversationHistory.length,
      itemBuilder: (context, index) {
        final message = _conversationHistory[index];
        return _buildConversationMessageWidget(message);
      },
    );
  }

  /// 構建單個對話訊息 Widget
  Widget _buildConversationMessageWidget(ConversationMessage message) {
    switch (message.type) {
      case ConversationMessageType.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        );

      case ConversationMessageType.assistant:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        );

      case ConversationMessageType.card:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildCardWidget(message.cardType!, message.cardData),
        );
    }
  }

  /// 構建卡片 Widget
  Widget _buildCardWidget(AIAgentResponseType cardType, dynamic cardData) {
    switch (cardType) {
      case AIAgentResponseType.displayProductCard:
        final products = (cardData as List).cast<Product>();
        return ConversationProductListCard(products: products);

      case AIAgentResponseType.displayOrderCard:
        final orders = (cardData as List).cast<Order>();
        return ConversationOrderListCard(orders: orders);

      case AIAgentResponseType.displayCartCard:
        final cartItems = (cardData as List).cast<CartItem>();
        return ConversationCartCard(cartItems: cartItems);

      case AIAgentResponseType.displayNotificationCard:
        final notifications = (cardData as List).cast<NotificationModel>();
        return ConversationNotificationListCard(notifications: notifications);

      default:
        return const SizedBox.shrink();
    }
  }

}