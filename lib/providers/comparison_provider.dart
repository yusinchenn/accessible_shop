import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/product_comparison_service.dart';
import '../services/database_service.dart';

/// 商品比較 Provider
/// 管理商品比較清單，最多支援 5 個商品
class ComparisonProvider extends ChangeNotifier {
  final List<CartItem> _comparisonItems = [];
  static const int maxItems = 5;

  // AI 比較相關狀態
  String? _comparisonResult;
  bool _isComparing = false;
  String? _comparisonError;

  // 追蹤上次比較的商品 ID 列表
  List<int> _lastComparedProductIds = [];

  // 依賴服務
  ProductComparisonService? _comparisonService;

  /// 初始化比較服務（需在使用前調用）
  void initComparisonService(DatabaseService databaseService) {
    _comparisonService = ProductComparisonService(databaseService);
  }

  /// 取得 AI 比較結果
  String? get comparisonResult => _comparisonResult;

  /// 是否正在比較中
  bool get isComparing => _isComparing;

  /// 取得比較錯誤訊息
  String? get comparisonError => _comparisonError;

  /// 取得比較清單中的所有商品
  List<CartItem> get items => List.unmodifiable(_comparisonItems);

  /// 取得比較清單中的商品數量
  int get itemCount => _comparisonItems.length;

  /// 檢查購物車項目是否已在比較清單中
  /// 使用購物車項目的唯一 ID，支援同一商品的不同規格分別比較
  bool isInComparison(int cartItemId) {
    return _comparisonItems.any((item) => item.id == cartItemId);
  }

  /// 加入商品到比較清單
  /// 如果超過最大數量，會自動移除最先加入的商品
  void addToComparison(CartItem item) {
    // 檢查是否已存在（使用購物車項目 ID）
    if (isInComparison(item.id)) {
      return;
    }

    // 如果已達上限，移除最先加入的商品
    if (_comparisonItems.length >= maxItems) {
      _comparisonItems.removeAt(0);
    }

    _comparisonItems.add(item);

    // 標記需要重新比較
    _markNeedsRecompare();

    notifyListeners();
  }

  /// 從比較清單中移除購物車項目
  /// 使用購物車項目 ID，支援移除特定規格的商品
  void removeFromComparison(int cartItemId) {
    _comparisonItems.removeWhere((item) => item.id == cartItemId);

    // 標記需要重新比較
    _markNeedsRecompare();

    notifyListeners();
  }

  /// 清除所有比較商品
  void clearAll() {
    _comparisonItems.clear();
    _lastComparedProductIds.clear();
    notifyListeners();
  }

  /// 標記需要重新比較（當商品列表改變時）
  void _markNeedsRecompare() {
    // 清除舊的比較結果和錯誤訊息
    _comparisonResult = null;
    _comparisonError = null;
  }

  /// 檢查是否需要重新比較
  /// 當商品列表改變或沒有比較結果時返回 true
  bool needsRecompare() {
    // 如果正在比較中，不需要重新觸發
    if (_isComparing) return false;

    // 如果沒有比較結果且商品數量 >= 2，需要比較
    if (_comparisonResult == null && _comparisonItems.length >= 2) {
      return true;
    }

    // 檢查商品列表是否改變
    final currentProductIds = _comparisonItems.map((item) => item.productId).toList();
    currentProductIds.sort();

    final lastIds = List<int>.from(_lastComparedProductIds)..sort();

    // 如果商品 ID 列表不同，需要重新比較
    if (currentProductIds.length != lastIds.length) {
      return true;
    }

    for (int i = 0; i < currentProductIds.length; i++) {
      if (currentProductIds[i] != lastIds[i]) {
        return true;
      }
    }

    return false;
  }

  /// 檢查比較清單是否為空
  bool get isEmpty => _comparisonItems.isEmpty;

  /// 檢查比較清單是否已滿
  bool get isFull => _comparisonItems.length >= maxItems;

  /// 使用 AI 比較商品
  /// 回傳值：成功返回 true，失敗返回 false
  Future<bool> compareItems() async {
    if (_comparisonService == null) {
      if (kDebugMode) {
        print('❌ [ComparisonProvider] 比較服務未初始化');
      }
      _comparisonError = '比較服務未初始化';
      notifyListeners();
      return false;
    }

    if (_comparisonItems.length < 2) {
      _comparisonError = '需要至少兩個商品才能進行比較';
      notifyListeners();
      return false;
    }

    try {
      // 設置比較中狀態
      _isComparing = true;
      _comparisonError = null;
      _comparisonResult = null;
      notifyListeners();

      if (kDebugMode) {
        print('🔍 [ComparisonProvider] 開始比較 ${_comparisonItems.length} 個商品...');
      }

      // 調用比較服務
      final result = await _comparisonService!.compareProducts(_comparisonItems);

      // 更新結果
      _comparisonResult = result;
      _isComparing = false;

      // 記錄已比較的商品 ID
      _lastComparedProductIds = _comparisonItems.map((item) => item.productId).toList();

      notifyListeners();

      if (kDebugMode) {
        print('✅ [ComparisonProvider] 比較完成');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ComparisonProvider] 比較失敗: $e');
      }

      _comparisonError = '比較失敗：$e';
      _isComparing = false;
      notifyListeners();
      return false;
    }
  }

  /// 清除比較結果
  void clearComparisonResult() {
    _comparisonResult = null;
    _comparisonError = null;
    notifyListeners();
  }

  /// 重新比較（清除舊結果後重新執行）
  Future<bool> recompare() async {
    clearComparisonResult();
    return await compareItems();
  }
}