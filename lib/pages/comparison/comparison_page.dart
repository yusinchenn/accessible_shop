import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import '../../providers/comparison_provider.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';

/// 商品比較頁面
class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入商品比較頁面");
      _autoCompareIfNeeded();
    });
  }

  /// 自動觸發比較（如果有 2+ 商品且需要更新）
  Future<void> _autoCompareIfNeeded() async {
    final comparisonProvider = Provider.of<ComparisonProvider>(
      context,
      listen: false,
    );

    if (comparisonProvider.items.length >= 2 &&
        comparisonProvider.needsRecompare() &&
        !comparisonProvider.isComparing) {
      ttsHelper.speak("開始 AI 智能比較分析");
      await comparisonProvider.compareItems();

      // 比較完成後朗讀結果
      if (!mounted) return;

      if (comparisonProvider.comparisonResult != null) {
        await ttsHelper.speak("比較完成");
        await Future.delayed(const Duration(milliseconds: 500));
        await ttsHelper.speak(comparisonProvider.comparisonResult!);
      } else if (comparisonProvider.comparisonError != null) {
        await ttsHelper.speak("比較失敗：${comparisonProvider.comparisonError}");
      }
    }
  }

  /// 手動重新比較
  Future<void> _handleRecompare() async {
    final comparisonProvider = Provider.of<ComparisonProvider>(
      context,
      listen: false,
    );

    ttsHelper.speak("重新開始 AI 比較分析");
    await comparisonProvider.recompare();

    // 比較完成後朗讀結果
    if (!mounted) return;

    if (comparisonProvider.comparisonResult != null) {
      await ttsHelper.speak("比較完成");
      await Future.delayed(const Duration(milliseconds: 500));
      await ttsHelper.speak(comparisonProvider.comparisonResult!);
    } else if (comparisonProvider.comparisonError != null) {
      await ttsHelper.speak("比較失敗：${comparisonProvider.comparisonError}");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      appBar: AppBar(
        title: const Text('商品比較'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ComparisonProvider>(
        builder: (context, comparisonProvider, _) {
          final items = comparisonProvider.items;

          if (items.isEmpty) {
            return Center(
              child: GestureDetector(
                onTap: () => ttsHelper.speak("比較清單是空的，請從購物車長按商品加入比較"),
                child: const Text(
                  "比較清單是空的！\n請從購物車長按商品加入比較",
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              // 標題區域
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => ttsHelper.speak("商品比較，共${items.length}項商品"),
                      child: Text(
                        "商品比較 (${items.length}/${ComparisonProvider.maxItems})",
                        style: AppTextStyles.title,
                      ),
                    ),
                    // 全部移除按鈕
                    GestureDetector(
                      onTap: () => ttsHelper.speak("全部移除"),
                      onDoubleTap: () async {
                        final navigator = Navigator.of(context);
                        comparisonProvider.clearAll();
                        comparisonProvider.clearComparisonResult();
                        await ttsHelper.speak("已清空比較清單，返回購物車");
                        if (!mounted) return;
                        navigator.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              "全部移除",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppFontSizes.body,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 橫向滑動區域：AI 比較結果（第一張）+ 商品卡片
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  // 總數 = AI 比較卡片(1) + 商品數量
                  itemCount: items.length + 1,
                  onPageChanged: (index) {
                    if (index == 0) {
                      ttsHelper.speak("AI 比較結果");
                    } else {
                      ttsHelper.speak(items[index - 1].name);
                    }
                  },
                  itemBuilder: (context, index) {
                    // 第一張卡片：AI 比較結果
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _buildComparisonCard(comparisonProvider),
                      );
                    }

                    // 後續卡片：商品資訊
                    final item = items[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: ComparisonItemCard(
                        item: item,
                        onRemove: () {
                          final navigator = Navigator.of(context);
                          comparisonProvider.removeFromComparison(item.id);
                          ttsHelper.speak(
                            "已移除${item.name}，${item.specification}",
                          );

                          // 如果移除後商品少於 2 項，自動返回購物車
                          if (comparisonProvider.itemCount < 2) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (mounted) {
                                  ttsHelper.speak("商品少於兩項，返回購物車");
                                  navigator.pop();
                                }
                              },
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // 提示文字 + 重新比較按鈕
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => ttsHelper.speak("左右滑動查看 AI 比較結果和商品資訊"),
                      child: const Text(
                        "左右滑動查看 AI 比較結果和商品資訊\n長按商品卡片可移除商品",
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (items.length >= 2) ...[
                      const SizedBox(height: AppSpacing.md),
                      GestureDetector(
                        onTap: () => ttsHelper.speak("重新 AI 比較"),
                        onDoubleTap: _handleRecompare,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.white),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                "重新 AI 比較",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFontSizes.body,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 建立 AI 比較結果卡片（作為第一張橫向卡片）
  Widget _buildComparisonCard(ComparisonProvider provider) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.blue, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 標題
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue, size: 32),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => ttsHelper.speak("AI 智能比較分析"),
                  child: const Text(
                    "AI 智能比較分析",
                    style: TextStyle(
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 內容區域（根據狀態顯示不同內容）
            Expanded(child: _buildComparisonContent(provider)),
          ],
        ),
      ),
    );
  }

  /// 建立比較內容（根據狀態）
  Widget _buildComparisonContent(ComparisonProvider provider) {
    // 載入中
    if (provider.isComparing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => ttsHelper.speak("AI 正在智能分析比較中，請稍候"),
              child: const Text(
                "AI 正在智能分析比較中...\n請稍候",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // 錯誤狀態
    if (provider.comparisonError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => ttsHelper.speak("比較失敗：${provider.comparisonError}"),
              child: Text(
                "比較失敗\n\n${provider.comparisonError}",
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // 有比較結果
    if (provider.comparisonResult != null) {
      return SingleChildScrollView(
        child: GestureDetector(
          onTap: () => ttsHelper.speak(provider.comparisonResult!),
          child: Text(
            provider.comparisonResult!,
            style: const TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.text_2,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    // 等待比較（初始狀態）
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pending, color: Colors.grey, size: 60),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => ttsHelper.speak("等待 AI 比較分析"),
            child: const Text(
              "等待 AI 比較分析...\n請稍候",
              style: TextStyle(fontSize: AppFontSizes.body, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// 比較商品卡片
class ComparisonItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const ComparisonItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ttsHelper.speak(
        "${item.name}，${item.specification}，單價${item.unitPrice.toStringAsFixed(0)}元",
      ),
      onDoubleTap: () {
        ttsHelper.speak("查看${item.name}商品詳情");
        Navigator.pushNamed(
          context,
          '/product_detail',
          arguments: item.productId,
        );
      },
      onLongPress: () {
        ttsHelper.speak("移除${item.name}");
        _showRemoveDialog(context);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.orange, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 商品名稱
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text_2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 規格
              Row(
                children: [
                  const Icon(
                    Icons.style,
                    color: AppColors.subtitle_2,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "規格: ${item.specification}",
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.text_2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // 單價
              Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: AppColors.primary_2,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "單價: \$${item.unitPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary_2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // 數量
              Row(
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: AppColors.subtitle_2,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "購物車數量: ${item.quantity}",
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.text_2,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 操作按鈕
              Row(
                children: [
                  // 查看詳情按鈕
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("查看商品詳情"),
                      onDoubleTap: () {
                        Navigator.pushNamed(
                          context,
                          '/product_detail',
                          arguments: item.productId,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary_2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "查看詳情",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // 移除按鈕
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("移除商品"),
                      onDoubleTap: () => _showRemoveDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "移除",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示移除確認對話框
  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            "確認移除",
            style: TextStyle(fontSize: AppFontSizes.title),
          ),
          content: Text(
            "確定要將 ${item.name} 從比較清單中移除嗎？",
            style: const TextStyle(fontSize: AppFontSizes.body),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ttsHelper.speak("取消移除");
              },
              child: const Text(
                "取消",
                style: TextStyle(fontSize: AppFontSizes.body),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRemove();
              },
              child: const Text(
                "確定",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
