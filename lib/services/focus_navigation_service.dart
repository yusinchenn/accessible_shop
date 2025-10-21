// lib/services/focus_navigation_service.dart
//
// 焦點導航服務：管理頁面內元素的焦點切換

import 'package:flutter/material.dart';
import '../utils/tts_helper.dart';
import 'accessibility_service.dart';

/// 可聚焦元素的配置
class FocusableItem {
  /// 元素標識符
  final String id;

  /// 語音朗讀文本
  final String label;

  /// 元素類型描述（如：按鈕、輸入欄、文字等）
  final String type;

  /// 元素的 FocusNode
  final FocusNode focusNode;

  /// 單擊時的動作（朗讀）
  final VoidCallback? onRead;

  /// 雙擊時的動作（使用/選取）
  final VoidCallback? onActivate;

  /// 元素的 GlobalKey（用於滾動定位）
  final GlobalKey? key;

  FocusableItem({
    required this.id,
    required this.label,
    required this.type,
    required this.focusNode,
    this.onRead,
    this.onActivate,
    this.key,
  });

  /// 獲取完整的朗讀文本
  String get fullLabel => '$type，$label';
}

/// 焦點導航服務
class FocusNavigationService extends ChangeNotifier {
  static final FocusNavigationService _instance = FocusNavigationService._internal();
  factory FocusNavigationService() => _instance;
  FocusNavigationService._internal();

  /// 當前頁面的可聚焦元素列表
  final List<FocusableItem> _items = [];

  /// 當前聚焦的元素索引
  int _currentIndex = 0;

  /// 獲取當前聚焦的元素
  FocusableItem? get currentItem {
    if (_items.isEmpty || _currentIndex < 0 || _currentIndex >= _items.length) {
      return null;
    }
    return _items[_currentIndex];
  }

  /// 獲取當前索引
  int get currentIndex => _currentIndex;

  /// 獲取元素總數
  int get itemCount => _items.length;

  /// 註冊頁面的可聚焦元素
  void registerItems(List<FocusableItem> items) {
    debugPrint('[FocusNavigation] 註冊 ${items.length} 個可聚焦元素');
    _items.clear();
    _items.addAll(items);
    _currentIndex = items.isEmpty ? 0 : 0;
    notifyListeners();
  }

  /// 清除所有元素
  void clear() {
    debugPrint('[FocusNavigation] 清除所有元素');
    _items.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  /// 移動到下一個元素（右往左滑）
  void moveToNext() {
    if (_items.isEmpty) {
      debugPrint('[FocusNavigation] 無可聚焦元素');
      return;
    }

    _currentIndex = (_currentIndex + 1) % _items.length;
    _focusCurrentItem();
    debugPrint('[FocusNavigation] 移至下一個: $_currentIndex/${_items.length}');
  }

  /// 移動到上一個元素（左往右滑）
  void moveToPrevious() {
    if (_items.isEmpty) {
      debugPrint('[FocusNavigation] 無可聚焦元素');
      return;
    }

    _currentIndex = (_currentIndex - 1 + _items.length) % _items.length;
    _focusCurrentItem();
    debugPrint('[FocusNavigation] 移至上一個: $_currentIndex/${_items.length}');
  }

  /// 朗讀當前元素（單擊）
  void readCurrent() {
    final item = currentItem;
    if (item == null) {
      debugPrint('[FocusNavigation] 無當前元素可朗讀');
      return;
    }

    debugPrint('[FocusNavigation] 朗讀: ${item.fullLabel}');

    // 只在自訂模式下使用 TTS
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(item.fullLabel);
    }

    // 執行自訂朗讀動作
    item.onRead?.call();
  }

  /// 激活當前元素（雙擊）
  void activateCurrent() {
    final item = currentItem;
    if (item == null) {
      debugPrint('[FocusNavigation] 無當前元素可激活');
      return;
    }

    debugPrint('[FocusNavigation] 激活: ${item.label}');

    // 語音反饋
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak('${item.type}，${item.label}，已選取');
    }

    // 執行激活動作
    item.onActivate?.call();
  }

  /// 移動到指定索引
  void moveToIndex(int index) {
    if (index < 0 || index >= _items.length) {
      debugPrint('[FocusNavigation] 索引超出範圍: $index');
      return;
    }

    _currentIndex = index;
    _focusCurrentItem();
    notifyListeners();
  }

  /// 聚焦當前元素並朗讀
  void _focusCurrentItem() {
    final item = currentItem;
    if (item == null) return;

    // 請求焦點
    item.focusNode.requestFocus();

    // 滾動到可見區域（如果有提供 key）
    if (item.key?.currentContext != null) {
      Scrollable.ensureVisible(
        item.key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // 朗讀元素
    readCurrent();

    notifyListeners();
  }

  /// 根據 ID 查找元素索引
  int? findIndexById(String id) {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].id == id) return i;
    }
    return null;
  }

  /// 移動到指定 ID 的元素
  void moveToId(String id) {
    final index = findIndexById(id);
    if (index != null) {
      moveToIndex(index);
    }
  }
}

/// 全域實例
final focusNavigationService = FocusNavigationService();
