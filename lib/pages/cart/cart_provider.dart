import 'package:flutter/material.dart';
import '../../models/cart_item.dart';

/// 購物車狀態管理 (Provider)
class ShoppingCartData extends ChangeNotifier {
  final List<CartItem> _items = [
    CartItem()
      ..id = 1
      ..name = '經典運動鞋'
      ..specification = '22cm, 白色'
      ..unitPrice = 1200.0
      ..quantity = 1
      ..isSelected = false,
    CartItem()
      ..id = 2
      ..name = '經典運動鞋'
      ..specification = '23cm, 黑色'
      ..unitPrice = 1250.0
      ..quantity = 2
      ..isSelected = false,
    CartItem()
      ..id = 3
      ..name = '專業慢跑襪'
      ..specification = 'M號, 灰色'
      ..unitPrice = 150.0
      ..quantity = 3
      ..isSelected = false,
  ];

  /// 讀取購物車商品
  List<CartItem> get items => List.unmodifiable(_items);

  /// 查單一商品
  CartItem? getItemById(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 增加數量
  void incrementQuantity(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  /// 減少數量
  void decrementQuantity(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1 && _items[index].quantity > 1) {
      _items[index].quantity--;
      notifyListeners();
    }
  }

  /// 選取商品
  void toggleSelection(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      notifyListeners();
    }
  }

  /// 移除商品
  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// 已選商品數量
  int get totalSelectedCount => _items.where((item) => item.isSelected).length;

  /// 已選商品總價
  double get totalSelectedPrice => _items
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));

  /// 已選商品列表
  List<CartItem> get selectedItems =>
      _items.where((item) => item.isSelected).toList();
}
