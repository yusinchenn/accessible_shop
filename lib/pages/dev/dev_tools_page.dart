import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/test_data_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

/// 開發工具頁面
/// 用於初始化測試資料和管理資料庫
class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  Map<String, int>? _stats;
  bool _isLoading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// 載入資料庫統計資訊
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final isar = await dbService.isar;
      final testDataService = TestDataService(isar);
      final stats = await testDataService.getDatabaseStats();

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = '載入失敗: $e';
        _isLoading = false;
      });
    }
  }

  /// 重置到乾淨狀態
  Future<void> _resetToCleanState() async {
    // 在 async 操作前先獲取 DatabaseService，避免跨 async 間隔使用 context
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final confirmed = await _showConfirmDialog(
      '確定要重置測試資料嗎？',
      '這將清除訂單、購物車和用戶評論，但保留基礎商家和商品資料。',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _message = '正在重置...';
    });

    try {
      final isar = await dbService.isar;
      final testDataService = TestDataService(isar);

      await testDataService.resetToCleanState();

      setState(() {
        _message = '✅ 測試資料已重置到乾淨狀態！';
      });

      await _loadStats();
    } catch (e) {
      setState(() {
        _message = '❌ 重置失敗: $e';
        _isLoading = false;
      });
    }
  }

  /// 清空所有資料
  Future<void> _clearAllData() async {
    // 在 async 操作前先獲取 DatabaseService，避免跨 async 間隔使用 context
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final confirmed = await _showConfirmDialog('確定要清空所有資料嗎？', '此操作無法復原！');

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _message = '正在清空資料...';
    });

    try {
      final isar = await dbService.isar;
      final testDataService = TestDataService(isar);

      await testDataService.clearAllData();

      setState(() {
        _message = '🗑️ 資料已清空';
      });

      await _loadStats();
    } catch (e) {
      setState(() {
        _message = '❌ 清空失敗: $e';
        _isLoading = false;
      });
    }
  }

  /// 顯示確認對話框
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('確定'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 測試系統通知
  Future<void> _testSystemNotification() async {
    setState(() {
      _message = '正在發送系統通知...';
    });

    try {
      await notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '系統通知測試',
        body: '這是一則系統測試通知',
        type: NotificationType.system,
      );

      setState(() {
        _message = '✅ 系統通知已發送！';
      });
    } catch (e) {
      setState(() {
        _message = '❌ 發送失敗: $e';
      });
    }
  }

  /// 測試訂單通知
  Future<void> _testOrderNotification() async {
    setState(() {
      _message = '正在發送訂單通知...';
    });

    try {
      await notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '訂單通知測試',
        body: '您的訂單 #20250103-0001 已成立，總金額 \$1,234 元',
        type: NotificationType.order,
        payload: 'order_1',
      );

      setState(() {
        _message = '✅ 訂單通知已發送！';
      });
    } catch (e) {
      setState(() {
        _message = '❌ 發送失敗: $e';
      });
    }
  }

  /// 測試促銷通知
  Future<void> _testPromotionNotification() async {
    setState(() {
      _message = '正在發送促銷通知...';
    });

    try {
      await notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '促銷活動通知',
        body: '限時優惠！全館商品8折起，趕快來選購吧！',
        type: NotificationType.promotion,
      );

      setState(() {
        _message = '✅ 促銷通知已發送！';
      });
    } catch (e) {
      setState(() {
        _message = '❌ 發送失敗: $e';
      });
    }
  }

  /// 檢查通知權限
  Future<void> _checkNotificationPermission() async {
    setState(() {
      _message = '正在檢查通知權限...';
    });

    try {
      final hasPermission = await notificationService.checkNotificationPermission();

      setState(() {
        if (hasPermission) {
          _message = '✅ 通知權限已授予';
        } else {
          _message = '⚠️ 通知權限未授予';
        }
      });
    } catch (e) {
      setState(() {
        _message = '❌ 檢查失敗: $e';
      });
    }
  }

  /// 請求通知權限
  Future<void> _requestNotificationPermission() async {
    setState(() {
      _message = '正在請求通知權限...';
    });

    try {
      final granted = await notificationService.requestNotificationPermission();

      setState(() {
        if (granted) {
          _message = '✅ 通知權限已授予';
        } else {
          _message = '❌ 通知權限被拒絕';
        }
      });
    } catch (e) {
      setState(() {
        _message = '❌ 請求失敗: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      appBar: AppBar(
        title: const Text('開發工具'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 資料庫統計卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('資料庫統計', style: AppTextStyles.title),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadStats,
                                tooltip: '重新整理',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_stats != null) ...[
                            _buildStatRow('商家數量', _stats!['stores']!),
                            _buildStatRow('商品數量', _stats!['products']!),
                            _buildStatRow('商品評論', _stats!['reviews']!),
                            _buildStatRow('訂單數量', _stats!['orders']!),
                            _buildStatRow('訂單項目', _stats!['orderItems']!),
                            _buildStatRow('購物車項目', _stats!['cartItems']!),
                            _buildStatRow('用戶設定', _stats!['userSettings']!),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 訊息顯示
                  if (_message.isNotEmpty)
                    Card(
                      color: _message.contains('❌')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          _message,
                          style: AppTextStyles.body.copyWith(
                            color: _message.contains('❌')
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // 操作按鈕
                  Text('資料管理', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: _resetToCleanState,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置測試資料'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary_2,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _clearAllData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('清空所有資料'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 通知測試
                  Text('通知測試', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: _checkNotificationPermission,
                    icon: const Icon(Icons.info),
                    label: const Text('檢查通知權限'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _requestNotificationPermission,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('請求通知權限'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _testSystemNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('測試系統通知'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _testOrderNotification,
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('測試訂單通知'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _testPromotionNotification,
                    icon: const Icon(Icons.local_offer),
                    label: const Text('測試促銷通知'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 測試與示範
                  Text('測試與示範', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/gesture-demo');
                    },
                    icon: const Icon(Icons.touch_app),
                    label: const Text('手勢系統示範'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 說明文字
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '使用說明',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '【資料管理】\n'
                            '• 重置測試資料：清除訂單、購物車和用戶評論，重置商家(3個)、商品(20個)和測試評論。適合重新開始測試。\n'
                            '• 清空所有資料：完全清空資料庫，刪除所有記錄（包括基礎測試資料）。\n\n'
                            '【通知測試】\n'
                            '• 檢查通知權限：查看當前是否已授予通知權限。\n'
                            '• 請求通知權限：向系統請求通知權限（Android 13+ 需要）。\n'
                            '• 測試系統通知：發送一則系統類型的測試通知。\n'
                            '• 測試訂單通知：發送一則訂單類型的測試通知。\n'
                            '• 測試促銷通知：發送一則促銷類型的測試通知。',
                            style: AppTextStyles.small.copyWith(
                              color: Colors.blue.shade900,
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

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            value.toString(),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary_2,
            ),
          ),
        ],
      ),
    );
  }
}
