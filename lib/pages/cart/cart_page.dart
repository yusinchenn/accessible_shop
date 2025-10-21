import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart'; // Updated import path
import '../../providers/comparison_provider.dart'; // 匯入比較 Provider
import '../../utils/tts_helper.dart'; // ✅ 改用全域 ttsHelper
import '../../utils/app_constants.dart'; // ✅ 匯入全域樣式常數
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

/// 購物車頁面
class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final PageController _pageController = PageController();
  bool _showMoreActionsOverlay = false;
  CartItem? _overlayTargetItem;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入購物車頁面");
    });
  }

  void _showMoreActions(CartItem item) {
    setState(() {
      _overlayTargetItem = item;
      _showMoreActionsOverlay = true;
    });
    ttsHelper.speak("更多操作");
  }

  void _hideMoreActions() {
    setState(() {
      _overlayTargetItem = null;
      _showMoreActionsOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(
        title: const Text('購物車'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ShoppingCartData>(
        builder: (context, cartData, _) {
          final items = cartData.items;
          if (items.isEmpty) {
            return const Center(child: Text("購物車是空的！"));
          }

          return Stack(
            children: [
              Column(
                children: [
                  // 查看比較按鈕
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Consumer<ComparisonProvider>(
                      builder: (context, comparisonProvider, _) {
                        return GestureDetector(
                          onTap: () {
                            ttsHelper.speak(
                              "查看比較，目前有${comparisonProvider.itemCount}項商品",
                            );
                          },
                          onDoubleTap: () {
                            ttsHelper.speak("進入商品比較頁面");
                            Navigator.pushNamed(context, '/comparison');
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.compare_arrows,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  "查看比較 (${comparisonProvider.itemCount})",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: AppFontSizes.body,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                          child: ShoppingCartItemCard(
                            item: item,
                            cartData: cartData,
                            onShowMoreActions: _showMoreActions,
                          ),
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ttsHelper.speak(
                        "選取商品${cartData.totalSelectedCount}項，總價${cartData.totalSelectedPrice.toStringAsFixed(0)}元",
                      );
                    },
                    onDoubleTap: () {
                      final selected = cartData.selectedItems;
                      final details = selected.isEmpty
                          ? "沒有選取商品"
                          : selected
                                .map(
                                  (item) =>
                                      "${item.name} ${item.specification} ${item.quantity}項",
                                )
                                .join("，");
                      ttsHelper.speak(
                        "$details，總價${cartData.totalSelectedPrice.toStringAsFixed(0)}元",
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.background,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "選取商品總數: ${cartData.totalSelectedCount}",
                            style: AppTextStyles.body,
                          ),
                          Text(
                            "總價: \$${cartData.totalSelectedPrice.toStringAsFixed(0)}",
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("結帳"),
                      onDoubleTap: () {
                        ttsHelper.speak("轉跳結帳頁面 checkout_page");
                        Navigator.pushNamed(context, "/checkout");
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "結帳",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppFontSizes.subtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showMoreActionsOverlay && _overlayTargetItem != null)
                MoreActionsOverlay(
                  item: _overlayTargetItem!,
                  cartData: cartData,
                  onDismiss: _hideMoreActions,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 單一商品卡片
class ShoppingCartItemCard extends StatelessWidget {
  final CartItem item;
  final ShoppingCartData cartData;
  final ValueChanged<CartItem> onShowMoreActions;

  const ShoppingCartItemCard({
    super.key,
    required this.item,
    required this.cartData,
    required this.onShowMoreActions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ttsHelper.speak(
        "${item.name}，${item.specification}，單價${item.unitPrice.toStringAsFixed(0)}元，數量${item.quantity}",
      ),
      onDoubleTap: () async {
        await cartData.toggleSelection(item.id);
        ttsHelper.speak("${item.isSelected ? '選取' : '取消選取'}${item.name}");
      },
      onLongPress: () => onShowMoreActions(item),
      child: Card(
        elevation: item.isSelected ? 10 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: item.isSelected
              ? const BorderSide(color: Colors.blue, width: 6)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              Text("規格: ${item.specification}", style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.xs),
              Text("單價: \$${item.unitPrice.toStringAsFixed(0)}", style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.xs),
              Text("數量: ${item.quantity}", style: AppTextStyles.body),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("減少商品${item.name}"),
                      onDoubleTap: () async {
                        await cartData.decrementQuantity(item.id);
                        ttsHelper.speak("已減少商品${item.name}");
                      },
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.remove),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("增加商品${item.name}"),
                      onDoubleTap: () async {
                        await cartData.incrementQuantity(item.id);
                        ttsHelper.speak("已增加商品${item.name}");
                      },
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add),
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
}

/// 更多操作 Overlay
class MoreActionsOverlay extends StatelessWidget {
  final CartItem item;
  final ShoppingCartData cartData;
  final VoidCallback onDismiss;

  const MoreActionsOverlay({
    super.key,
    required this.item,
    required this.cartData,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          ttsHelper.speak("關閉更多操作");
          onDismiss();
        },
        child: Container(
          color: Colors.black87,
          child: Center(
            child: GestureDetector(
              // 防止點擊按鈕區域時關閉 overlay
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 標題提示
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${item.name} - 更多操作",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSizes.title,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // 瀏覽商品頁面按鈕
                    _buildLargeActionButton(
                      label: "瀏覽商品頁面",
                      icon: Icons.visibility,
                      color: AppColors.primary,
                      onTap: () => ttsHelper.speak("瀏覽商品頁面"),
                      onDoubleTap: () {
                        ttsHelper.speak("開啟${item.name}商品頁面");
                        onDismiss();
                        Navigator.pushNamed(
                          context,
                          '/product_detail',
                          arguments: item.productId,
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 加入比較按鈕
                    Consumer<ComparisonProvider>(
                      builder: (context, comparisonProvider, _) {
                        final isInComparison = comparisonProvider.isInComparison(item.productId);

                        return _buildLargeActionButton(
                          label: isInComparison ? "已加入比較" : "加入比較",
                          icon: isInComparison ? Icons.check_circle : Icons.compare_arrows,
                          color: isInComparison ? Colors.green : Colors.orange,
                          onTap: () => ttsHelper.speak(isInComparison ? "已加入比較" : "加入比較"),
                          onDoubleTap: () {
                            if (isInComparison) {
                              // 移除商品比較
                              comparisonProvider.removeFromComparison(item.productId);
                              ttsHelper.speak("移除${item.name}商品比較");
                            } else {
                              // 加入商品比較
                              comparisonProvider.addToComparison(item);
                              ttsHelper.speak("已將${item.name}加入比較");
                            }
                            onDismiss();
                          },
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 刪除商品按鈕
                    _buildLargeActionButton(
                      label: "刪除商品",
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () => ttsHelper.speak("刪除商品"),
                      onDoubleTap: () async {
                        await cartData.removeItem(item.id);
                        ttsHelper.speak("已刪除${item.name}");
                        onDismiss();
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 取消按鈕
                    _buildLargeActionButton(
                      label: "取消",
                      icon: Icons.close,
                      color: Colors.grey,
                      onTap: () => ttsHelper.speak("取消"),
                      onDoubleTap: () {
                        ttsHelper.speak("關閉更多操作");
                        onDismiss();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 建立大面積的操作按鈕
  Widget _buildLargeActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onDoubleTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.title,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
