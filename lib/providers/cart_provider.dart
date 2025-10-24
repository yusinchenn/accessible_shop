import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/database_service.dart';

/// 購物車狀態管理 (Provider)
class ShoppingCartData extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<CartItem> _items = [];
  bool _isLoading = false;

  ShoppingCartData(this._databaseService) {
    _loadCartItems();
    // 監聽 DatabaseService 的變化，當資料庫有更新時自動重新載入
    _databaseService.addListener(_onDatabaseChanged);
  }

  /// 當資料庫變化時重新載入購物車
  void _onDatabaseChanged() {
    _loadCartItems();
  }

  @override
  void dispose() {
    _databaseService.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  bool _isReloading = false;

  /// 載入購物車項目
  Future<void> _loadCartItems() async {
    // 防止同時執行多個載入操作
    if (_isReloading) return;

    _isReloading = true;
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _databaseService.getCartItems();
      if (kDebugMode) {
        print('🛒 [ShoppingCartData] 已載入 ${_items.length} 個購物車項目');
      }
    } catch (e) {
      debugPrint('載入購物車失敗: $e');
      _items = [];
    }

    _isLoading = false;
    _isReloading = false;
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

  /// 清除所有商品的選取狀態
  Future<void> clearAllSelections() async {
    await _databaseService.clearAllCartItemSelections();
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
