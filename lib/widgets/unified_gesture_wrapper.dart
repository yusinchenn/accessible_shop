// lib/widgets/unified_gesture_wrapper.dart
//
// 統一手勢包裝器：整合頁面級和全局手勢功能

import 'package:flutter/material.dart';
import '../services/global_gesture_service.dart';
import '../services/focus_navigation_service.dart';
import '../services/accessibility_service.dart';

/// 統一手勢包裝器
///
/// 支援所有頁面的統一手勢：
/// 1. 左往右滑 = 上個項目
/// 2. 右往左滑 = 下個項目
/// 3. 單擊 = 朗讀元素
/// 4. 雙擊 = 選取/使用元素
/// 5. 雙指上滑 = 回首頁
/// 6. 雙指下滑 = 回上一頁
///
/// 使用方式：
/// ```dart
/// Scaffold(
///   body: UnifiedGestureWrapper(
///     child: YourPageContent(),
///   ),
/// )
/// ```
class UnifiedGestureWrapper extends StatefulWidget {
  /// 子 Widget
  final Widget child;

  /// 是否啟用全局手勢（雙指上/下滑）
  final bool enableGlobalGestures;

  /// 是否啟用頁面級手勢（左右滑、單擊、雙擊）
  final bool enablePageGestures;

  /// 是否只在自訂模式下啟用（預設 true，避免與系統無障礙衝突）
  final bool onlyInCustomMode;

  /// 水平滑動閾值（單位：邏輯像素）
  final double horizontalSwipeThreshold;

  /// 垂直滑動閾值（單位：邏輯像素）
  final double verticalSwipeThreshold;

  /// 雙擊間隔時間（毫秒）
  final int doubleTapInterval;

  const UnifiedGestureWrapper({
    super.key,
    required this.child,
    this.enableGlobalGestures = true,
    this.enablePageGestures = true,
    this.onlyInCustomMode = true,
    this.horizontalSwipeThreshold = 50.0,
    this.verticalSwipeThreshold = 50.0,
    this.doubleTapInterval = 300,
  });

  @override
  State<UnifiedGestureWrapper> createState() => _UnifiedGestureWrapperState();
}

class _UnifiedGestureWrapperState extends State<UnifiedGestureWrapper> {
  // === 觸控點追蹤 ===
  /// 記錄觸控點的起始位置
  final Map<int, Offset> _touchPoints = {};

  /// 記錄觸控點的當前位置
  final Map<int, Offset> _currentTouchPoints = {};

  /// 記錄最大觸控點數量
  int _maxPointers = 0;

  // === 雙擊檢測 ===
  /// 上次點擊時間
  DateTime? _lastTapTime;

  /// 上次點擊位置
  Offset? _lastTapPosition;

  @override
  Widget build(BuildContext context) {
    // 檢查是否應該啟用手勢
    final shouldEnable = (!widget.onlyInCustomMode ||
        accessibilityService.shouldUseCustomGestures);

    if (!shouldEnable) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.child,
    );
  }

  /// 處理觸控點按下
  void _handlePointerDown(PointerDownEvent event) {
    // 記錄觸控點的起始位置
    _touchPoints[event.pointer] = event.position;
    _currentTouchPoints[event.pointer] = event.position;

    // 更新最大觸控點數量
    if (_touchPoints.length > _maxPointers) {
      _maxPointers = _touchPoints.length;
    }

    debugPrint('[UnifiedGesture] 觸控點按下: pointer=${event.pointer}, 總數=${_touchPoints.length}');
  }

  /// 處理觸控點移動
  void _handlePointerMove(PointerMoveEvent event) {
    // 更新觸控點的當前位置
    if (_touchPoints.containsKey(event.pointer)) {
      _currentTouchPoints[event.pointer] = event.position;
    }
  }

  /// 處理觸控點放開
  void _handlePointerUp(PointerUpEvent event) {
    debugPrint('[UnifiedGesture] 觸控點放開: pointer=${event.pointer}, maxPointers=$_maxPointers, 當前總數=${_touchPoints.length}');

    // 處理不同的手勢
    if (_maxPointers == 1 && _touchPoints.length == 1) {
      // 單指手勢
      _handleSingleFingerGesture(event);
    } else if (_maxPointers == 2 && _touchPoints.length == 2) {
      // 雙指手勢
      if (widget.enableGlobalGestures) {
        _handleTwoFingerGesture();
      }
    }

    // 移除觸控點記錄
    _touchPoints.remove(event.pointer);
    _currentTouchPoints.remove(event.pointer);

    // 如果所有觸控點都已移除，重置計數器
    if (_touchPoints.isEmpty) {
      _maxPointers = 0;
    }
  }

  /// 處理觸控點取消
  void _handlePointerCancel(PointerCancelEvent event) {
    debugPrint('[UnifiedGesture] 觸控點取消: pointer=${event.pointer}');
    _touchPoints.remove(event.pointer);
    _currentTouchPoints.remove(event.pointer);

    if (_touchPoints.isEmpty) {
      _maxPointers = 0;
    }
  }

  /// 處理單指手勢（左右滑、單擊、雙擊）
  void _handleSingleFingerGesture(PointerUpEvent event) {
    if (!widget.enablePageGestures) return;

    final pointer = event.pointer;
    if (!_touchPoints.containsKey(pointer) ||
        !_currentTouchPoints.containsKey(pointer)) {
      return;
    }

    final startPos = _touchPoints[pointer]!;
    final endPos = _currentTouchPoints[pointer]!;
    final deltaX = endPos.dx - startPos.dx;
    final deltaY = endPos.dy - startPos.dy;

    debugPrint('[UnifiedGesture] 單指手勢: deltaX=$deltaX, deltaY=$deltaY');

    // 判斷是否為滑動手勢（水平移動大於閾值且大於垂直移動）
    if (deltaX.abs() > widget.horizontalSwipeThreshold &&
        deltaX.abs() > deltaY.abs()) {
      if (deltaX > 0) {
        // 左往右滑 - 上個項目
        debugPrint('[UnifiedGesture] ✅ 左往右滑 - 上個項目');
        focusNavigationService.moveToPrevious();
      } else {
        // 右往左滑 - 下個項目
        debugPrint('[UnifiedGesture] ✅ 右往左滑 - 下個項目');
        focusNavigationService.moveToNext();
      }
      return;
    }

    // 判斷是否為點擊手勢（移動距離很小）
    if (deltaX.abs() < 10 && deltaY.abs() < 10) {
      _handleTapGesture(endPos);
    }
  }

  /// 處理點擊手勢（單擊/雙擊）
  void _handleTapGesture(Offset position) {
    final now = DateTime.now();

    // 檢查是否為雙擊
    if (_lastTapTime != null && _lastTapPosition != null) {
      final timeDiff = now.difference(_lastTapTime!).inMilliseconds;
      final distance = (position - _lastTapPosition!).distance;

      if (timeDiff <= widget.doubleTapInterval && distance < 50) {
        // 雙擊 - 選取/使用元素
        debugPrint('[UnifiedGesture] ✅ 雙擊 - 激活元素');
        focusNavigationService.activateCurrent();

        // 重置雙擊檢測
        _lastTapTime = null;
        _lastTapPosition = null;
        return;
      }
    }

    // 單擊 - 朗讀元素
    debugPrint('[UnifiedGesture] ✅ 單擊 - 朗讀元素');
    focusNavigationService.readCurrent();

    // 記錄此次點擊
    _lastTapTime = now;
    _lastTapPosition = position;
  }

  /// 處理雙指手勢（上滑/下滑）
  void _handleTwoFingerGesture() {
    // 確保有兩個觸控點的完整記錄
    if (_touchPoints.length != 2 || _currentTouchPoints.length != 2) {
      debugPrint('[UnifiedGesture] 觸控點數量不符: start=${_touchPoints.length}, current=${_currentTouchPoints.length}');
      return;
    }

    // 計算平均滑動距離
    double totalDeltaY = 0;
    int validPointsCount = 0;

    for (final pointer in _touchPoints.keys) {
      if (_currentTouchPoints.containsKey(pointer)) {
        final startY = _touchPoints[pointer]!.dy;
        final currentY = _currentTouchPoints[pointer]!.dy;
        final deltaY = currentY - startY;
        totalDeltaY += deltaY;
        validPointsCount++;
      }
    }

    if (validPointsCount != 2) {
      debugPrint('[UnifiedGesture] 有效觸控點數量不足: $validPointsCount');
      return;
    }

    final averageDeltaY = totalDeltaY / validPointsCount;
    final threshold = widget.verticalSwipeThreshold;

    debugPrint('[UnifiedGesture] 雙指平均滑動距離: $averageDeltaY (閾值: $threshold)');

    // 判斷滑動方向
    if (averageDeltaY < -threshold) {
      // 向上滑動 - 回首頁
      debugPrint('[UnifiedGesture] ✅ 雙指上滑 - 回首頁');
      globalGestureService.handleTwoFingerSwipeUp(context);
    } else if (averageDeltaY > threshold) {
      // 向下滑動 - 回上一頁
      debugPrint('[UnifiedGesture] ✅ 雙指下滑 - 回上一頁');
      globalGestureService.handleTwoFingerSwipeDown(context);
    } else {
      debugPrint('[UnifiedGesture] ❌ 滑動距離未達閾值');
    }
  }
}

/// 簡化版：直接包裝 Scaffold
///
/// 使用方式：
/// ```dart
/// return UnifiedGestureScaffold(
///   appBar: AppBar(...),
///   body: YourPageContent(),
/// );
/// ```
class UnifiedGestureScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool enableGlobalGestures;
  final bool enablePageGestures;

  const UnifiedGestureScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.enableGlobalGestures = true,
    this.enablePageGestures = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body != null
          ? UnifiedGestureWrapper(
              enableGlobalGestures: enableGlobalGestures,
              enablePageGestures: enablePageGestures,
              onlyInCustomMode: false, // 始終啟用手勢
              child: body!,
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
