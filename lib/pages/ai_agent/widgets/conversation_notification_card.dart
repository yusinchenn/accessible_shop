/// conversation_notification_card.dart
/// AI Agent 對話中的通知卡片元件
library;

import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import 'package:intl/intl.dart';

/// 通知卡片（用於對話中）
class ConversationNotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const ConversationNotificationCard({
    super.key,
    required this.notification,
  });

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.reward:
        return Icons.card_giftcard;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Colors.blue;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.reward:
        return Colors.purple;
    }
  }

  String _getNotificationTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return '訂單通知';
      case NotificationType.promotion:
        return '促銷通知';
      case NotificationType.system:
        return '系統通知';
      case NotificationType.reward:
        return '獎勵通知';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: notification.isRead
              ? null
              : Border.all(color: Colors.blue.withAlpha(100), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            // 點擊可導航到通知詳情或相關頁面
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 圖示
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type)
                        .withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // 內容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 標題與未讀標記
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 內容
                      Text(
                        notification.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 類型與時間
                      Row(
                        children: [
                          Text(
                            _getNotificationTypeText(notification.type),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getNotificationColor(notification.type),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeFormat.format(notification.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
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
        ),
      ),
    );
  }
}

/// 通知列表卡片（顯示多個通知）
class ConversationNotificationListCard extends StatelessWidget {
  final List<NotificationModel> notifications;
  final String? title;

  const ConversationNotificationListCard({
    super.key,
    required this.notifications,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ...notifications.map((notification) =>
              ConversationNotificationCard(notification: notification)),
        ],
      ),
    );
  }
}
