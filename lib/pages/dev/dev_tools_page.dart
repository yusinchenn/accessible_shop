import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/test_data_service.dart';
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

  /// 初始化所有測試資料
  Future<void> _initializeAllData() async {
    final confirmed = await _showConfirmDialog(
      '確定要初始化所有測試資料嗎？',
      '這將清空現有資料並建立新的測試資料。',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _message = '正在初始化...';
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final isar = await dbService.isar;
      final testDataService = TestDataService(isar);

      await testDataService.initializeAllTestData();

      setState(() {
        _message = '✅ 測試資料初始化成功！';
      });

      await _loadStats();
    } catch (e) {
      setState(() {
        _message = '❌ 初始化失敗: $e';
        _isLoading = false;
      });
    }
  }

  /// 只初始化商品資料
  Future<void> _initializeProducts() async {
    setState(() {
      _isLoading = true;
      _message = '正在初始化商品資料...';
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final isar = await dbService.isar;
      final testDataService = TestDataService(isar);

      await testDataService.initializeProducts();

      setState(() {
        _message = '✅ 商品資料初始化成功！';
      });

      await _loadStats();
    } catch (e) {
      setState(() {
        _message = '❌ 初始化失敗: $e';
        _isLoading = false;
      });
    }
  }

  /// 初始化購物車測試資料
  Future<void> _initializeCartItems() async {
    setState(() {
      _isLoading = true;
      _message = '正在初始化購物車資料...';
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final isar = await dbService.isar;
      final testDataService = TestDataService(isar);

      await testDataService.initializeCartItems();

      setState(() {
        _message = '✅ 購物車資料初始化成功！';
      });

      await _loadStats();
    } catch (e) {
      setState(() {
        _message = '❌ 初始化失敗: $e';
        _isLoading = false;
      });
    }
  }

  /// 清空所有資料
  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmDialog(
      '確定要清空所有資料嗎？',
      '此操作無法復原！',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _message = '正在清空資料...';
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
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
                              Text(
                                '資料庫統計',
                                style: AppTextStyles.title,
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadStats,
                                tooltip: '重新整理',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_stats != null) ...[
                            _buildStatRow('商品數量', _stats!['products']!),
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
                  Text(
                    '資料初始化',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: _initializeAllData,
                    icon: const Icon(Icons.all_inclusive),
                    label: const Text('初始化所有測試資料'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _initializeProducts,
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('只初始化商品資料'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton.icon(
                    onPressed: _initializeCartItems,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('初始化購物車測試資料'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    '資料管理',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),

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

                  // 測試與示範
                  Text(
                    '測試與示範',
                    style: AppTextStyles.subtitle,
                  ),
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
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
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
                            '• 初始化所有測試資料：清空並建立完整的測試資料\n'
                            '• 只初始化商品資料：保留其他資料，僅更新商品\n'
                            '• 初始化購物車：建立範例購物車項目\n'
                            '• 清空所有資料：刪除資料庫中的所有記錄',
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
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
