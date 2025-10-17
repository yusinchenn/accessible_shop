import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/database_service.dart';

/// 購物車狀態管理 (Provider)
class ShoppingCartData extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<CartItem> _items = [];
  bool _isLoading = false;

  ShoppingCartData(this._databaseService) {
    _loadCartItems();
  }

  /// 載入購物車項目
  Future<void> _loadCartItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _databaseService.getCartItems();
    } catch (e) {
      debugPrint('載入購物車失敗: $e');
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 重新載入購物車資料
  Future<void> reload() async {
    await _loadCartItems();
  }

  /// 是否正在載入
  bool get isLoading => _isLoading;

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
  Future<void> incrementQuantity(int id) async {
    final item = getItemById(id);
    if (item != null) {
      await _databaseService.updateCartItemQuantity(id, item.quantity + 1);
      await reload();
    }
  }

  /// 減少數量
  Future<void> decrementQuantity(int id) async {
    final item = getItemById(id);
    if (item != null && item.quantity > 1) {
      await _databaseService.updateCartItemQuantity(id, item.quantity - 1);
      await reload();
    }
  }

  /// 選取商品
  Future<void> toggleSelection(int id) async {
    await _databaseService.toggleCartItemSelection(id);
    await reload();
  }

  /// 移除商品
  Future<void> removeItem(int id) async {
    await _databaseService.removeFromCart(id);
    await reload();
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
