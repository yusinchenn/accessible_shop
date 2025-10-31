import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart'; // Updated import path
import '../../providers/comparison_provider.dart'; // 匯入比較 Provider
import '../../services/database_service.dart';
import '../../utils/tts_helper.dart'; // ✅ 改用全域 ttsHelper
import '../../utils/app_constants.dart'; // ✅ 匯入全域樣式常數
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器
import '../../widgets/voice_control_appbar.dart'; // 匯入語音控制 AppBar

/// 購物車頁面
class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  bool _showMoreActionsOverlay = false;
  CartItem? _overlayTargetItem;
  bool _announceScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (routeIsCurrent && !_announceScheduled) {
      _announceScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceScheduled = false;
        _announceEnter();
      });
    }
  }

  /// 執行進入頁面的語音播報
  Future<void> _announceEnter() async {
    final cartData = Provider.of<ShoppingCartData>(context, listen: false);

    // 先清除所有商品的選取狀態
    await cartData.clearAllSelections();

    // 確保購物車資料已載入完成
    await cartData.reload();

    // 等待一小段時間確保所有狀態更新完成，避免語音被打斷
    await Future.delayed(const Duration(milliseconds: 100));

    // 確保組件仍然存在
    if (!mounted) return;

    if (cartData.items.isEmpty) {
      // 使用 speakQueue 確保依序播放，不會打斷
      await ttsHelper.speakQueue(["進入購物車頁面", "目前無商品"]);
    } else {
      // 有商品時播報商品數量
      await ttsHelper.speakQueue(["進入購物車頁面", "有${cartData.items.length}項商品"]);
    }
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
      backgroundColor: AppColors.background_1, // 套用背景色
      appBar: VoiceControlAppBar(
        title: '購物車',
        onTap: () {
          ttsHelper.speak(
            '購物車頁面。上方為查看比較按紐，中間為購物車商品項目，可以上下滑動，下方為結帳按紐。購物車項目下方包含減少和增加數量按紐。購物車項目單擊朗讀內容，雙擊選取結帳，長按更多功能。更多功能包含瀏覽商品頁面、加入/移除比較、刪除商品',
          );
        },
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ShoppingCartData>(
        builder: (context, cartData, _) {
          final items = cartData.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                "購物車跟胃一樣！\n都需要被填滿",
                textAlign: TextAlign.left, // 文字置中
                style: TextStyle(
                  color: AppColors.text_1, // 文字顏色
                  fontSize: 26, // 文字大小（可自行調整）
                  fontWeight: FontWeight.w500, // 可選：讓字體稍微加粗
                ),
              ),
            );
          }

          // 按商家分組
          final Map<int, List<CartItem>> itemsByStore = {};
          for (var item in items) {
            if (!itemsByStore.containsKey(item.storeId)) {
              itemsByStore[item.storeId] = [];
            }
            itemsByStore[item.storeId]!.add(item);
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
                              "查看比較按鈕，目前有${comparisonProvider.itemCount}項商品",
                            );
                          },
                          onDoubleTap: () {
                            // 檢查商品數量
                            if (comparisonProvider.itemCount < 2) {
                              ttsHelper.speak(
                                "需要至少兩個商品才能進行比較，目前只有${comparisonProvider.itemCount}項商品",
                              );
                            } else {
                              ttsHelper.speak("進入商品比較頁面");
                              Navigator.pushNamed(context, '/comparison');
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondery_1,
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
                  // 按商家分組顯示商品
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: itemsByStore.length,
                      itemBuilder: (context, storeIndex) {
                        final storeEntry = itemsByStore.entries.elementAt(
                          storeIndex,
                        );
                        final storeItems = storeEntry.value;
                        final storeName = storeItems.first.storeName;
                        final storeSubtotal = storeItems.fold<double>(
                          0.0,
                          (sum, item) => sum + (item.unitPrice * item.quantity),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 商家標題
                              GestureDetector(
                                onTap: () {
                                  ttsHelper.speak(
                                    '商家 $storeName，共 ${storeItems.length} 項商品，小計 ${storeSubtotal.toStringAsFixed(0)} 元',
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: const BoxDecoration(
                                    color: AppColors.botton_1,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.store,
                                        size: 20,
                                        color: AppColors.bottonText_1,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          storeName,
                                          style: const TextStyle(
                                            fontSize: AppFontSizes.body,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.bottonText_1,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '\$${storeSubtotal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.body,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.bottonText_1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 商家的商品列表
                              ...storeItems.map(
                                (item) => ShoppingCartItemCard(
                                  item: item,
                                  cartData: cartData,
                                  onShowMoreActions: _showMoreActions,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Opacity(
                      opacity: cartData.totalSelectedCount == 0 ? 0.4 : 1.0,
                      child: GestureDetector(
                        onTap: () {
                          if (cartData.totalSelectedCount == 0) {
                            ttsHelper.speak("結帳按鈕，尚未選取商品");
                          } else {
                            final selectedItems = cartData.selectedItems
                                .map((item) => "${item.name}數量${item.quantity}")
                                .join("、");
                            ttsHelper.speak(
                              "結帳按鈕，已選取商品：$selectedItems，總價${cartData.totalSelectedPrice.toStringAsFixed(0)}元",
                            );
                          }
                        },
                        onDoubleTap: () {
                          if (cartData.totalSelectedCount > 0) {
                            ttsHelper.speak("轉跳結帳頁面");
                            Navigator.pushNamed(context, "/checkout");
                          } else {
                            ttsHelper.speak("結帳按鈕，尚未選取商品");
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: cartData.totalSelectedCount == 0
                                ? Colors.grey
                                : Colors.green,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "選取商品總數: ${cartData.totalSelectedCount}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: AppFontSizes.body,
                                    ),
                                  ),
                                  Text(
                                    "總價: \$${cartData.totalSelectedPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: AppFontSizes.body,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Text(
                                "結帳",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFontSizes.subtitle,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
class ShoppingCartItemCard extends StatefulWidget {
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
  State<ShoppingCartItemCard> createState() => _ShoppingCartItemCardState();
}

class _ShoppingCartItemCardState extends State<ShoppingCartItemCard> {
  Product? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final product = await dbService.getProductById(widget.item.productId);
    if (mounted) {
      setState(() {
        _product = product;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cartData = widget.cartData;
    return GestureDetector(
      onTap: () => ttsHelper.speak(
        "${item.name}，${item.specification}，單價${item.unitPrice.toStringAsFixed(0)}元，數量${item.quantity}",
      ),
      onDoubleTap: () async {
        final wasSelected = item.isSelected; // 記錄切換前的狀態
        await cartData.toggleSelection(item.id);
        ttsHelper.speak(
          "${wasSelected ? '取消選取' : '選取'}${item.name}，數量${item.quantity}",
        );
      },
      onLongPress: () => widget.onShowMoreActions(item),
      child: Card(
        elevation: item.isSelected ? 10 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: item.isSelected
              ? const BorderSide(color: Colors.green, width: 6)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              Text("規格: ${item.specification}", style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "單價: \$${item.unitPrice.toStringAsFixed(0)}",
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text("數量: ${item.quantity}", style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("減少按鈕"),
                      onDoubleTap: () async {
                        if (item.quantity <= 1) {
                          ttsHelper.speak("商品僅剩一件");
                        } else {
                          await cartData.decrementQuantity(item.id);
                          final newQuantity = item.quantity - 1;
                          ttsHelper.speak("已減少${item.name}，目前數量$newQuantity件");
                        }
                      },
                      child: Container(
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.remove, size: 32),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("增加按鈕"),
                      onDoubleTap: () async {
                        final stock = _product?.stock ?? 999;
                        if (item.quantity >= stock) {
                          ttsHelper.speak("商品已達購買上限");
                        } else {
                          await cartData.incrementQuantity(item.id);
                          final newQuantity = item.quantity + 1;
                          ttsHelper.speak("已增加${item.name}，目前數量$newQuantity件");
                        }
                      },
                      child: Container(
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, size: 32),
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
                        color: AppColors.primary_1.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${item.name} - 更多操作",
                        style: const TextStyle(
                          color: AppColors.text_1,
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
                      color: AppColors.background_1,
                      onTap: () => ttsHelper.speak("瀏覽商品頁面按鈕"),
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
                        final isInComparison = comparisonProvider
                            .isInComparison(item.id);

                        return _buildLargeActionButton(
                          label: isInComparison ? "已加入比較" : "加入比較",
                          icon: isInComparison
                              ? Icons.check_circle
                              : Icons.compare_arrows,
                          color: isInComparison
                              ? Colors.green
                              : AppColors.secondery_1,
                          onTap: () => ttsHelper.speak(
                            isInComparison ? "加入比較按鈕，目前已加入，雙擊移除" : "加入比較按鈕",
                          ),
                          onDoubleTap: () {
                            if (isInComparison) {
                              // 移除商品比較
                              comparisonProvider.removeFromComparison(item.id);
                              ttsHelper.speak(
                                "移除${item.name}，${item.specification}商品比較",
                              );
                            } else {
                              // 加入商品比較
                              comparisonProvider.addToComparison(item);
                              ttsHelper.speak(
                                "已將${item.name}，${item.specification}加入比較",
                              );
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
                      color: AppColors.accent_1,
                      onTap: () => ttsHelper.speak("刪除商品按鈕"),
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
                      color: AppColors.subtitle_1,
                      onTap: () => ttsHelper.speak("取消按鈕"),
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
            Icon(icon, color: Colors.white, size: 32),
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
