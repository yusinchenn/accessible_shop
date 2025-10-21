import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// 商品比較 Provider
/// 管理商品比較清單，最多支援 5 個商品
class ComparisonProvider extends ChangeNotifier {
  final List<CartItem> _comparisonItems = [];
  static const int maxItems = 5;

  /// 取得比較清單中的所有商品
  List<CartItem> get items => List.unmodifiable(_comparisonItems);

  /// 取得比較清單中的商品數量
  int get itemCount => _comparisonItems.length;

  /// 檢查商品是否已在比較清單中
  bool isInComparison(int productId) {
    return _comparisonItems.any((item) => item.productId == productId);
  }

  /// 加入商品到比較清單
  /// 如果超過最大數量，會自動移除最先加入的商品
  void addToComparison(CartItem item) {
    // 檢查是否已存在
    if (isInComparison(item.productId)) {
      return;
    }

    // 如果已達上限，移除最先加入的商品
    if (_comparisonItems.length >= maxItems) {
      _comparisonItems.removeAt(0);
    }

    _comparisonItems.add(item);
    notifyListeners();
  }

  /// 從比較清單中移除商品
  void removeFromComparison(int productId) {
    _comparisonItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  /// 清除所有比較商品
  void clearAll() {
    _comparisonItems.clear();
    notifyListeners();
  }

  /// 檢查比較清單是否為空
  bool get isEmpty => _comparisonItems.isEmpty;

  /// 檢查比較清單是否已滿
  bool get isFull => _comparisonItems.length >= maxItems;
}