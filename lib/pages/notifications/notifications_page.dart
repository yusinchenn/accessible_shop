// lib/pages/notifications/notifications_page.dart
//
// 通知頁面 - 提供系統通知與訊息查看功能

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/voice_control_appbar.dart';
import '../../services/accessibility_service.dart';
import '../../services/database_service.dart';
import '../../models/notification.dart';

/// 通知頁面
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isAnnouncingEnter = false;
  bool _announceScheduled = false;
  int _selectedIndex = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  // 自動朗讀相關
  bool _isAutoReading = false; // 是否正在自動朗讀
  int _autoReadIndex = 0; // 當前朗讀的通知索引

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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

  /// 載入通知資料
  Future<void> _loadNotifications() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final notifications = await db.getNotifications();

    setState(() {
      _notifications = notifications;
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
      await ttsHelper.speak('進入通知頁面');
      await Future.delayed(const Duration(milliseconds: 500));
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      if (unreadCount > 0) {
        await ttsHelper.speak('您有 $unreadCount 則未讀通知');
      } else {
        await ttsHelper.speak('目前沒有未讀通知');
      }
    } finally {
      _isAnnouncingEnter = false;
    }
  }

  /// 處理單擊事件 - 播報通知內容
  void _onNotificationTap(NotificationModel notification, int index) {
    if (_isAnnouncingEnter) return;

    // 手動點擊時停止自動朗讀
    if (_isAutoReading) {
      _stopAutoRead();
    }

    setState(() {
      _selectedIndex = index;
    });

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      final readStatus = notification.isRead ? '已讀' : '未讀';
      ttsHelper.speak(
        '$readStatus，${notification.title}，${notification.content}',
      );
    }
  }

  /// 處理雙擊事件 - 如果是訂單通知則跳轉到訂單詳情，否則切換已讀狀態
  Future<void> _onNotificationDoubleTap(
    NotificationModel notification,
    int index,
  ) async {
    // 手動雙擊時停止自動朗讀
    if (_isAutoReading) {
      _stopAutoRead();
    }

    final db = Provider.of<DatabaseService>(context, listen: false);

    // 如果是訂單通知且有訂單 ID，跳轉到訂單詳情
    if (notification.type == NotificationType.order &&
        notification.orderId != null) {
      // 標記為已讀
      if (!notification.isRead) {
        await db.markNotificationAsRead(notification.id);
      }

      // 只在自訂模式播放語音
      if (accessibilityService.shouldUseCustomTTS) {
        await ttsHelper.speak('前往訂單詳情');
      }

      // 跳轉到訂單詳情頁面
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/order-detail',
          arguments: notification.orderId,
        ).then((_) {
          // 返回後重新載入通知
          _loadNotifications();
        });
      }
    } else {
      // 非訂單通知，切換已讀狀態
      await db.toggleNotificationReadStatus(notification.id);
      await _loadNotifications();

      // 只在自訂模式播放語音
      if (accessibilityService.shouldUseCustomTTS) {
        final newStatus = !notification.isRead ? '已標記為已讀' : '已標記為未讀';
        ttsHelper.speak(newStatus);
      }
    }
  }

  /// 全部標記為已讀
  Future<void> _markAllAsRead() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.markAllNotificationsAsRead();
    await _loadNotifications();

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak('所有通知已標記為已讀');
    }
  }

  /// 取得通知類型對應的圖示
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  /// 格式化時間顯示
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
    }
  }

  /// 獲取未讀通知列表
  List<NotificationModel> _getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// 開始自動朗讀未讀通知
  Future<void> _startAutoRead() async {
    final unreadNotifications = _getUnreadNotifications();

    if (unreadNotifications.isEmpty) {
      // 沒有未讀通知時，朗讀提示訊息
      await ttsHelper.speak('目前沒有未讀通知');
      return;
    }

    setState(() {
      _isAutoReading = true;
      _autoReadIndex = 0;
    });

    // 開始自動朗讀循環
    await _autoReadLoop(unreadNotifications);
  }

  /// 自動朗讀循環
  Future<void> _autoReadLoop(List<NotificationModel> unreadNotifications) async {
    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      for (int i = 0; i < unreadNotifications.length; i++) {
        // 檢查是否被中斷
        if (!_isAutoReading) break;

        _autoReadIndex = i;
        final notification = unreadNotifications[i];

        // 朗讀通知內容
        final notificationText = '未讀，${notification.title}，${notification.content}';
        await ttsHelper.speakQueue([notificationText]);

        // 再次檢查是否被中斷
        if (!_isAutoReading) break;

        // 標記為已讀
        await db.markNotificationAsRead(notification.id);

        // 等待一小段時間後繼續下一個
        if (i < unreadNotifications.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // 檢查是否在等待過程中被中斷
        if (!_isAutoReading) break;
      }

      // 朗讀完成後重新載入通知列表並停止自動朗讀
      if (_isAutoReading) {
        await _loadNotifications();
        _stopAutoRead();
      }
    } catch (e) {
      _stopAutoRead();
    }
  }

  /// 停止自動朗讀
  void _stopAutoRead() {
    setState(() {
      _isAutoReading = false;
    });
    ttsHelper.stop();
  }

  /// 處理自動朗讀按鈕的單擊事件
  Future<void> _onAutoReadButtonTap() async {
    await ttsHelper.speak('自動朗讀未讀通知按鈕');
  }

  /// 處理自動朗讀按鈕的雙擊事件
  void _onAutoReadButtonDoubleTap() {
    // 如果正在朗讀，先停止
    if (_isAutoReading) {
      _stopAutoRead();
    }
    ttsHelper.stop(); // 清空所有朗讀佇列

    // 開始自動朗讀
    _startAutoRead();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      appBar: VoiceControlAppBar(
        title: '通知',
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background_2,
        titleTextStyle: const TextStyle(color: AppColors.text_2),
        actions: [
          // 全部標記為已讀按鈕
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: '全部標記為已讀',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要內容
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(child: Text('暫無通知', style: AppTextStyles.body))
              : ListView.builder(
                  itemCount: _notifications.length,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () => _onNotificationTap(notification, index),
                  onDoubleTap: () =>
                      _onNotificationDoubleTap(notification, index),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    color: AppColors.botton_2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(
                              color: AppColors.primary_2,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 通知圖示
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.background_2,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: AppColors.text_2,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // 通知內容
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: AppTextStyles.subtitle.copyWith(
                                          color: AppColors.bottonText_2,
                                          fontWeight: notification.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent_2,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  notification.content,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.bottonText_2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Text(
                                      _formatTimestamp(notification.timestamp),
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.bottonText_2,
                                      ),
                                    ),
                                    if (notification.type ==
                                            NotificationType.order &&
                                        notification.orderNumber != null) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color: AppColors.bottonText_2,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '查看訂單',
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.bottonText_2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          // 自動朗讀按鈕 - 左下角
          if (!_isLoading && _notifications.isNotEmpty)
            Positioned(
              left: 16,
              bottom: 50,
              child: GestureDetector(
                onTap: _onAutoReadButtonTap,
                onDoubleTap: _onAutoReadButtonDoubleTap,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondery_2,
                    border: Border.all(
                      color: AppColors.secondery_2,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _isAutoReading ? Icons.pause : Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
