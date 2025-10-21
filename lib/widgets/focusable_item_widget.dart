// lib/widgets/focusable_item_widget.dart
//
// 可聚焦元素組件：自動註冊到焦點導航系統

import 'package:flutter/material.dart';
import '../services/focus_navigation_service.dart';

/// 可聚焦元素組件
///
/// 自動將元素註冊到焦點導航系統，支持手勢操作
///
/// 使用方式：
/// ```dart
/// FocusableItemWidget(
///   id: 'product-1',
///   label: '商品名稱 - 100元',
///   type: '商品',
///   onActivate: () { /* 雙擊動作 */ },
///   child: ProductCard(...),
/// )
/// ```
class FocusableItemWidget extends StatefulWidget {
  /// 元素 ID（用於識別）
  final String id;

  /// 朗讀文本
  final String label;

  /// 元素類型（按鈕、輸入欄、商品等）
  final String type;

  /// 雙擊激活動作
  final VoidCallback? onActivate;

  /// 單擊朗讀動作（可選，預設使用 label）
  final VoidCallback? onRead;

  /// 子組件
  final Widget child;

  /// 是否自動聚焦（當此項目被聚焦時自動滾動到可見區域）
  final bool autoScroll;

  const FocusableItemWidget({
    super.key,
    required this.id,
    required this.label,
    required this.type,
    this.onActivate,
    this.onRead,
    required this.child,
    this.autoScroll = true,
  });

  @override
  State<FocusableItemWidget> createState() => _FocusableItemWidgetState();
}

class _FocusableItemWidgetState extends State<FocusableItemWidget> {
  late final FocusNode _focusNode;
  late final GlobalKey _itemKey;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _itemKey = widget.autoScroll ? GlobalKey() : GlobalKey();

    // 監聽焦點變化
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      // 當此元素被聚焦時，高亮顯示
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 為有焦點的元素添加視覺效果
    final hasFocus = _focusNode.hasFocus;

    return Container(
      key: _itemKey,
      decoration: hasFocus
          ? BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Focus(
        focusNode: _focusNode,
        child: widget.child,
      ),
    );
  }

  /// 創建 FocusableItem（給外部使用）
  FocusableItem toFocusableItem() {
    return FocusableItem(
      id: widget.id,
      label: widget.label,
      type: widget.type,
      focusNode: _focusNode,
      onRead: widget.onRead,
      onActivate: widget.onActivate,
      key: widget.autoScroll ? _itemKey : null,
    );
  }
}

/// 可聚焦列表頁面基類
///
/// 簡化列表類頁面的手勢集成
///
/// 使用方式：
/// ```dart
/// class MyListPage extends FocusableListPage {
///   @override
///   List<FocusableItem> buildFocusableItems() {
///     return [
///       FocusableItem(...),
///       FocusableItem(...),
///     ];
///   }
///
///   @override
///   Widget buildContent(BuildContext context) {
///     return ListView(...);
///   }
/// }
/// ```
abstract class FocusableListPage extends StatefulWidget {
  const FocusableListPage({super.key});
}

abstract class FocusableListPageState<T extends FocusableListPage> extends State<T> {
  @override
  void initState() {
    super.initState();

    // 在下一幀註冊可聚焦元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFocusableItems();
    });
  }

  @override
  void dispose() {
    // 清除焦點導航
    focusNavigationService.clear();
    super.dispose();
  }

  /// 構建可聚焦元素列表（需要子類實現）
  List<FocusableItem> buildFocusableItems();

  /// 構建頁面內容（需要子類實現）
  Widget buildContent(BuildContext context);

  /// 註冊可聚焦元素
  void _registerFocusableItems() {
    final items = buildFocusableItems();
    focusNavigationService.registerItems(items);
    debugPrint('[FocusableListPage] 註冊了 ${items.length} 個可聚焦元素');
  }

  /// 刷新可聚焦元素（當列表內容變化時調用）
  void refreshFocusableItems() {
    _registerFocusableItems();
  }
}
