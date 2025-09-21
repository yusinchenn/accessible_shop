import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import 'cart_provider.dart';
import '../../utils/tts_helper.dart'; // ✅ 改用全域 ttsHelper

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
    return Scaffold(
      appBar: AppBar(title: const Text('購物車')),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "購物車",
                      style: Theme.of(context).textTheme.headlineMedium,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.grey[200],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("選取商品總數: ${cartData.totalSelectedCount}"),
                          Text(
                            "總價: \$${cartData.totalSelectedPrice.toStringAsFixed(0)}",
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("結帳"),
                      onDoubleTap: () {
                        ttsHelper.speak("轉跳結帳頁面 checkout_page");
                        Navigator.pushNamed(context, "/checkout");
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "結帳",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
      onDoubleTap: () {
        cartData.toggleSelection(item.id);
        ttsHelper.speak("${item.isSelected ? '選取' : '取消選取'}${item.name}");
      },
      onLongPress: () => onShowMoreActions(item),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: item.isSelected
              ? const BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleLarge),
              Text("規格: ${item.specification}"),
              Text("單價: \$${item.unitPrice.toStringAsFixed(0)}"),
              Text("數量: ${item.quantity}"),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak("減少商品${item.name}"),
                      onDoubleTap: () {
                        cartData.decrementQuantity(item.id);
                        ttsHelper.speak("已減少商品${item.name}，共${item.quantity}項");
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
                      onDoubleTap: () {
                        cartData.incrementQuantity(item.id);
                        ttsHelper.speak("已增加商品${item.name}，共${item.quantity}項");
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
        onTap: onDismiss,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => ttsHelper.speak("瀏覽商品頁面"),
                  child: const Text("瀏覽商品頁面"),
                ),
                ElevatedButton(
                  onPressed: () => ttsHelper.speak("加入比較"),
                  child: const Text("加入比較"),
                ),
                ElevatedButton(
                  onPressed: () {
                    cartData.removeItem(item.id);
                    ttsHelper.speak("刪除商品");
                    onDismiss();
                  },
                  child: const Text("刪除商品"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
