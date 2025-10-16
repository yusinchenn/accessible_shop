// lib/widgets/global_gesture_wrapper.dart
//
// 全域手勢包裝器：為頁面添加全域導航手勢支援

import 'package:flutter/material.dart';
import '../services/global_gesture_service.dart';
import '../services/accessibility_service.dart';

/// 全域手勢包裝器
///
/// 使用方式：將整個頁面的 body 或 Scaffold 包裝起來
///
/// ```dart
/// Scaffold(
///   appBar: AppBar(...),
///   body: GlobalGestureWrapper(
///     child: YourPageContent(),
///   ),
/// )
/// ```
///
/// 支援的手勢：
/// - 兩指上滑：回首頁
/// - 兩指下滑：回上一頁
class GlobalGestureWrapper extends StatefulWidget {
  /// 子 Widget
  final Widget child;

  /// 是否啟用全域手勢（預設 true）
  final bool enabled;

  /// 是否只在自訂模式下啟用（預設 true，避免與系統無障礙衝突）
  final bool onlyInCustomMode;

  const GlobalGestureWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.onlyInCustomMode = true,
  });

  @override
  State<GlobalGestureWrapper> createState() => _GlobalGestureWrapperState();
}

class _GlobalGestureWrapperState extends State<GlobalGestureWrapper> {
  // 記錄觸控點的起始位置
  final Map<int, Offset> _touchPoints = {};

  // 記錄觸控點的當前位置
  final Map<int, Offset> _currentTouchPoints = {};

  // 記錄最大觸控點數量
  int _maxPointers = 0;

  @override
  Widget build(BuildContext context) {
    // 檢查是否應該啟用手勢
    final shouldEnable = widget.enabled &&
        (!widget.onlyInCustomMode || accessibilityService.shouldUseCustomGestures);

    if (!shouldEnable) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // 記錄觸控點的起始位置
        _touchPoints[event.pointer] = event.position;
        _currentTouchPoints[event.pointer] = event.position;

        // 更新最大觸控點數量
        if (_touchPoints.length > _maxPointers) {
          _maxPointers = _touchPoints.length;
        }

        debugPrint('[GlobalGesture] 觸控點按下: pointer=${event.pointer}, 總數=${_touchPoints.length}');
      },
      onPointerMove: (event) {
        // 更新觸控點的當前位置
        if (_touchPoints.containsKey(event.pointer)) {
          _currentTouchPoints[event.pointer] = event.position;
        }
      },
      onPointerUp: (event) {
        debugPrint('[GlobalGesture] 觸控點放開: pointer=${event.pointer}, 當前總數=${_touchPoints.length}');

        // 在移除觸控點之前，檢查是否為兩指手勢
        if (_maxPointers == 2 && _touchPoints.length == 2) {
          _handleTwoFingerGesture();
        }

        // 移除觸控點記錄
        _touchPoints.remove(event.pointer);
        _currentTouchPoints.remove(event.pointer);

        // 如果所有觸控點都已移除，重置計數器
        if (_touchPoints.isEmpty) {
          _maxPointers = 0;
        }
      },
      onPointerCancel: (event) {
        debugPrint('[GlobalGesture] 觸控點取消: pointer=${event.pointer}');
        // 移除觸控點記錄
        _touchPoints.remove(event.pointer);
        _currentTouchPoints.remove(event.pointer);

        // 如果所有觸控點都已移除，重置計數器
        if (_touchPoints.isEmpty) {
          _maxPointers = 0;
        }
      },
      child: widget.child,
    );
  }

  /// 處理兩指手勢
  void _handleTwoFingerGesture() {
    // 確保有兩個觸控點的完整記錄
    if (_touchPoints.length != 2 || _currentTouchPoints.length != 2) {
      debugPrint('[GlobalGesture] 觸控點數量不符: start=${_touchPoints.length}, current=${_currentTouchPoints.length}');
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
        debugPrint('[GlobalGesture] 觸控點 $pointer: startY=$startY, currentY=$currentY, deltaY=$deltaY');
      }
    }

    if (validPointsCount != 2) {
      debugPrint('[GlobalGesture] 有效觸控點數量不足: $validPointsCount');
      return;
    }

    final averageDeltaY = totalDeltaY / validPointsCount;
    final threshold = globalGestureService.config.swipeThreshold;

    debugPrint('[GlobalGesture] 兩指平均滑動距離: $averageDeltaY (閾值: $threshold)');

    // 判斷滑動方向
    if (averageDeltaY < -threshold) {
      // 向上滑動 - 回首頁
      debugPrint('[GlobalGesture] ✅ 偵測到兩指上滑 - 回首頁');
      globalGestureService.handleTwoFingerSwipeUp(context);
    } else if (averageDeltaY > threshold) {
      // 向下滑動 - 回上一頁
      debugPrint('[GlobalGesture] ✅ 偵測到兩指下滑 - 回上一頁');
      globalGestureService.handleTwoFingerSwipeDown(context);
    } else {
      debugPrint('[GlobalGesture] ❌ 滑動距離未達閾值');
    }
  }
}

/// 簡化版：直接包裝 Scaffold
///
/// 使用方式：
/// ```dart
/// return GlobalGestureScaffold(
///   appBar: AppBar(...),
///   body: YourPageContent(),
/// );
/// ```
class GlobalGestureScaffold extends StatelessWidget {
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

  const GlobalGestureScaffold({
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: enableGlobalGestures && body != null
          ? GlobalGestureWrapper(
              onlyInCustomMode: false, // 始終啟用手勢，不限於自訂模式
              child: body!,
            )
          : body,
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
