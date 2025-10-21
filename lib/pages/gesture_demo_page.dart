// lib/pages/gesture_demo_page.dart
//
// 手勢系統示範頁面：展示如何使用統一手勢系統

import 'package:flutter/material.dart';
import '../widgets/unified_gesture_wrapper.dart';
import '../services/focus_navigation_service.dart';
import '../utils/app_constants.dart';

/// 手勢系統示範頁面
class GestureDemoPage extends StatefulWidget {
  const GestureDemoPage({super.key});

  @override
  State<GestureDemoPage> createState() => _GestureDemoPageState();
}

class _GestureDemoPageState extends State<GestureDemoPage> {
  // 為每個項目創建 FocusNode 和 GlobalKey
  final List<FocusNode> _focusNodes = [];
  final List<GlobalKey> _itemKeys = [];

  // 模擬商品數據
  final List<Map<String, dynamic>> _demoItems = [
    {'name': '蘋果', 'price': 50, 'icon': Icons.apple},
    {'name': '香蕉', 'price': 30, 'icon': Icons.water_drop},
    {'name': '橘子', 'price': 40, 'icon': Icons.circle},
    {'name': '草莓', 'price': 80, 'icon': Icons.favorite},
    {'name': '西瓜', 'price': 100, 'icon': Icons.sports_basketball},
  ];

  @override
  void initState() {
    super.initState();

    // 為每個項目創建 FocusNode 和 GlobalKey
    for (int i = 0; i < _demoItems.length; i++) {
      _focusNodes.add(FocusNode());
      _itemKeys.add(GlobalKey());
    }

    // 註冊可聚焦元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFocusableItems();
    });
  }

  @override
  void dispose() {
    // 清理資源
    for (var node in _focusNodes) {
      node.dispose();
    }
    focusNavigationService.clear();
    super.dispose();
  }

  /// 註冊可聚焦元素到焦點導航服務
  void _registerFocusableItems() {
    final items = <FocusableItem>[];

    for (int i = 0; i < _demoItems.length; i++) {
      final item = _demoItems[i];
      items.add(
        FocusableItem(
          id: 'item-$i',
          label: '${item['name']}，價格 ${item['price']} 元',
          type: '商品',
          focusNode: _focusNodes[i],
          key: _itemKeys[i],
          onActivate: () => _onItemActivated(i),
        ),
      );
    }

    focusNavigationService.registerItems(items);
  }

  /// 處理項目激活（雙擊）
  void _onItemActivated(int index) {
    final item = _demoItems[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已選取：${item['name']}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('手勢系統示範'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 說明卡片
          _buildInstructionCard(),

          const SizedBox(height: 16),

          // 商品列表
          Expanded(
            child: ListView.builder(
              itemCount: _demoItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return _buildDemoItem(index);
              },
            ),
          ),

          // 當前焦點指示器
          _buildFocusIndicator(),
        ],
      ),
    );
  }

  /// 構建說明卡片
  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '手勢操作說明',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('• 左往右滑：上一個項目'),
          const Text('• 右往左滑：下一個項目'),
          const Text('• 單擊：朗讀當前項目'),
          const Text('• 雙擊：選取/使用項目'),
          const Text('• 雙指上滑：回首頁'),
          const Text('• 雙指下滑：回上一頁'),
        ],
      ),
    );
  }

  /// 構建示範項目
  Widget _buildDemoItem(int index) {
    final item = _demoItems[index];

    return Container(
      key: _itemKeys[index],
      margin: const EdgeInsets.only(bottom: 12),
      child: Focus(
        focusNode: _focusNodes[index],
        child: AnimatedBuilder(
          animation: _focusNodes[index],
          builder: (context, child) {
            final hasFocus = _focusNodes[index].hasFocus;

            return Card(
              elevation: hasFocus ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: hasFocus
                    ? BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      )
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  size: 40,
                  color: hasFocus
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  item['name'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('價格：\$${item['price']}'),
                trailing: hasFocus
                    ? Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 構建焦點指示器
  Widget _buildFocusIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade200,
      child: ListenableBuilder(
        listenable: focusNavigationService,
        builder: (context, child) {
          final currentItem = focusNavigationService.currentItem;
          final currentIndex = focusNavigationService.currentIndex;
          final totalCount = focusNavigationService.itemCount;

          if (currentItem == null) {
            return const Text('無焦點項目');
          }

          return Column(
            children: [
              Text(
                '當前焦點：${currentItem.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '項目 ${currentIndex + 1} / $totalCount',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
