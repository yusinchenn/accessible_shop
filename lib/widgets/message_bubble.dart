import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_constants.dart';

/// 聊天訊息氣泡組件
class MessageBubble extends StatelessWidget {
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI 訊息：時間戳在左邊
          if (!isUserMessage)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs, bottom: 2),
              child: Text(
                timeFormat.format(timestamp),
                style: const TextStyle(
                  fontSize: AppFontSizes.small - 2,
                  color: AppColors.subtitle_2,
                ),
              ),
            ),

          // 訊息氣泡
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? AppColors.secondery_2 // 用戶訊息：藍綠色
                    : AppColors.aiBackground, // AI 訊息：淺灰藍色
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUserMessage ? 16 : 4),
                  bottomRight: Radius.circular(isUserMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: isUserMessage
                      ? AppColors.bottonText_2 // 用戶訊息：淺色文字
                      : AppColors.text_2, // AI 訊息：深色文字
                  height: 1.4,
                ),
              ),
            ),
          ),

          // 用戶訊息：時間戳在右邊
          if (isUserMessage)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 2),
              child: Text(
                timeFormat.format(timestamp),
                style: const TextStyle(
                  fontSize: AppFontSizes.small - 2,
                  color: AppColors.subtitle_2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
