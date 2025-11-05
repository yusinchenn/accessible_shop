// lib/pages/messages/messages_page.dart
//
// 訊息列表頁面 - 顯示所有對話對象

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/voice_control_appbar.dart';
import '../../services/accessibility_service.dart';
import '../../services/database_service.dart';
import '../../models/conversation.dart';

/// 訊息列表頁面
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _isAnnouncingEnter = false;
  bool _announceScheduled = false;
  int _selectedIndex = 0;
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化無障礙服務
    accessibilityService.initialize(context);

    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (routeIsCurrent && !_announceScheduled) {
      _announceScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceScheduled = false;
        _announceEnter();
      });
    }
  }

  /// 初始化默認對話並載入對話列表
  Future<void> _initializeAndLoadConversations() async {
    final db = Provider.of<DatabaseService>(context, listen: false);

    // 確保"小千助手"對話對象存在
    await db.initializeDefaultConversation();

    // 載入所有對話
    await _loadConversations();
  }

  /// 載入對話列表
  Future<void> _loadConversations() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final conversations = await db.getConversations();

    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  /// 執行進入頁面的語音播報
  Future<void> _announceEnter() async {
    if (_isAnnouncingEnter) return;

    // 只在自訂模式播放語音
    if (!accessibilityService.shouldUseCustomTTS) return;

    await ttsHelper.stop();

    _isAnnouncingEnter = true;
    try {
      await ttsHelper.speak('進入訊息頁面');
      await Future.delayed(const Duration(milliseconds: 500));

      final totalUnread = _conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.unreadCount,
      );

      if (totalUnread > 0) {
        await ttsHelper.speak('您有 $totalUnread 則未讀訊息');
      } else {
        await ttsHelper.speak('目前沒有未讀訊息');
      }
    } finally {
      _isAnnouncingEnter = false;
    }
  }

  /// 處理單擊事件 - 播報對話對象信息
  void _onConversationTap(Conversation conversation, int index) {
    if (_isAnnouncingEnter) return;

    setState(() {
      _selectedIndex = index;
    });

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      final lastMessageInfo = conversation.lastMessage != null
          ? '最後訊息：${conversation.lastMessage}'
          : '尚無訊息';

      final unreadInfo = conversation.unreadCount > 0
          ? '有 ${conversation.unreadCount} 則未讀'
          : '無未讀訊息';

      ttsHelper.speak(
        '${conversation.name}，$lastMessageInfo，$unreadInfo',
      );
    }
  }

  /// 處理雙擊事件 - 進入聊天室
  Future<void> _onConversationDoubleTap(
    Conversation conversation,
    int index,
  ) async {
    final db = Provider.of<DatabaseService>(context, listen: false);

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      await ttsHelper.speak('進入 ${conversation.name} 聊天室');
    }

    // 清除未讀數量
    if (conversation.unreadCount > 0) {
      await db.clearUnreadCount(conversation.id);
    }

    // 跳轉到聊天室頁面
    if (mounted) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: conversation.id,
      ).then((_) {
        // 返回後重新載入對話列表
        _loadConversations();
      });
    }
  }

  /// 處理長按事件 - 清空聊天記錄
  Future<void> _onConversationLongPress(
    Conversation conversation,
    int index,
  ) async {
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      await ttsHelper.speak('長按 ${conversation.name}，是否清空聊天記錄？');
    }

    if (!mounted) return;

    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '清空聊天記錄',
          style: TextStyle(fontSize: AppFontSizes.title),
        ),
        content: Text(
          '確定要清空與 ${conversation.name} 的所有聊天記錄嗎？此操作無法復原。',
          style: const TextStyle(fontSize: AppFontSizes.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: AppFontSizes.body),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '確定',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      await db.clearChatMessages(conversation.id);

      // 只在自訂模式播放語音
      if (accessibilityService.shouldUseCustomTTS) {
        await ttsHelper.speak('已清空 ${conversation.name} 的聊天記錄');
      }

      // 重新載入對話列表
      await _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureWrapper(
      child: Scaffold(
        backgroundColor: AppColors.background_2,
        appBar: const VoiceControlAppBar(
          title: '訊息',
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _conversations.isEmpty
                ? Center(
                    child: Text(
                      '尚無對話',
                      style: const TextStyle(
                        fontSize: AppFontSizes.subtitle,
                        color: AppColors.subtitle_2,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final isSelected = index == _selectedIndex;

                      return GestureDetector(
                        onTap: () => _onConversationTap(conversation, index),
                        onDoubleTap: () =>
                            _onConversationDoubleTap(conversation, index),
                        onLongPress: () =>
                            _onConversationLongPress(conversation, index),
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.md,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary_2
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent_2
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 頭像 Emoji
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.blockBackground_2,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Center(
                                  child: Text(
                                    conversation.avatarEmoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),

                              // 對話信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 對話對象名稱
                                        Text(
                                          conversation.name,
                                          style: const TextStyle(
                                            fontSize: AppFontSizes.subtitle,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text_2,
                                          ),
                                        ),

                                        // 時間
                                        if (conversation.lastMessageTime !=
                                            null)
                                          Text(
                                            _formatTime(
                                              conversation.lastMessageTime!,
                                            ),
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.small,
                                              color: AppColors.subtitle_2,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),

                                    // 最後訊息
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conversation.lastMessage ??
                                                '尚無訊息',
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.body,
                                              color: AppColors.subtitle_2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // 未讀數量徽章
                                        if (conversation.unreadCount > 0)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: AppSpacing.sm,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              conversation.unreadCount > 99
                                                  ? '99+'
                                                  : '${conversation.unreadCount}',
                                              style: const TextStyle(
                                                fontSize: AppFontSizes.small,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  /// 格式化時間顯示
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate.isAtSameMomentAs(today)) {
      // 今天：顯示時間
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate.isAtSameMomentAs(
      today.subtract(const Duration(days: 1)),
    )) {
      // 昨天
      return '昨天';
    } else if (dateTime.year == now.year) {
      // 今年：顯示月/日
      return DateFormat('MM/dd').format(dateTime);
    } else {
      // 其他：顯示年/月/日
      return DateFormat('yyyy/MM/dd').format(dateTime);
    }
  }
}
