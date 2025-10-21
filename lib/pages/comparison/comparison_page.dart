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
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
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
                      onDoubleTap: () {
                        comparisonProvider.clearAll();
                        ttsHelper.speak("已清空比較清單");
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

              // 商品卡片列表
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    ttsHelper.speak(items[index].name);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: ComparisonItemCard(
                        item: item,
                        onRemove: () {
                          comparisonProvider.removeFromComparison(item.productId);
                          ttsHelper.speak("已移除${item.name}");
                        },
                      ),
                    );
                  },
                ),
              ),

              // 提示文字
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GestureDetector(
                  onTap: () => ttsHelper.speak("左右滑動查看不同商品，長按商品卡片可移除商品"),
                  child: const Text(
                    "左右滑動查看不同商品\n長按商品卡片可移除商品",
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
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
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 規格
              Row(
                children: [
                  const Icon(
                    Icons.style,
                    color: AppColors.subtitle,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "規格: ${item.specification}",
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.text,
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
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "單價: \$${item.unitPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                    color: AppColors.subtitle,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "購物車數量: ${item.quantity}",
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: AppColors.text,
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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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