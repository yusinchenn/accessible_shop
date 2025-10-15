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

  @override
  Widget build(BuildContext context) {
    // 檢查是否應該啟用手勢
    final shouldEnable = widget.enabled &&
        (!widget.onlyInCustomMode || accessibilityService.shouldUseCustomGestures);

    if (!shouldEnable) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (event) {
        // 記錄觸控點的起始位置
        _touchPoints[event.pointer] = event.position;
        _currentTouchPoints[event.pointer] = event.position;
      },
      onPointerMove: (event) {
        // 更新觸控點的當前位置
        _currentTouchPoints[event.pointer] = event.position;
      },
      onPointerUp: (event) {
        // 移除觸控點記錄
        _touchPoints.remove(event.pointer);
        _currentTouchPoints.remove(event.pointer);
      },
      onPointerCancel: (event) {
        // 移除觸控點記錄
        _touchPoints.remove(event.pointer);
        _currentTouchPoints.remove(event.pointer);
      },
      child: GestureDetector(
        // 偵測垂直拖曳（用於兩指滑動）
        onVerticalDragEnd: (details) {
          _handleVerticalDragEnd(details);
        },
        child: widget.child,
      ),
    );
  }

  /// 處理垂直拖曳結束
  void _handleVerticalDragEnd(DragEndDetails details) {
    // 檢查是否有兩個觸控點
    if (_touchPoints.length != 2 || _currentTouchPoints.length != 2) {
      return;
    }

    // 計算平均滑動距離
    double totalDeltaY = 0;
    int validPointsCount = 0;

    for (final pointer in _touchPoints.keys) {
      if (_currentTouchPoints.containsKey(pointer)) {
        final startY = _touchPoints[pointer]!.dy;
        final currentY = _currentTouchPoints[pointer]!.dy;
        totalDeltaY += (currentY - startY);
        validPointsCount++;
      }
    }

    if (validPointsCount != 2) {
      return;
    }

    final averageDeltaY = totalDeltaY / validPointsCount;
    final threshold = globalGestureService.config.swipeThreshold;

    debugPrint('[GlobalGesture] 兩指滑動距離: $averageDeltaY');

    // 判斷滑動方向
    if (averageDeltaY < -threshold) {
      // 向上滑動 - 回首頁
      globalGestureService.handleTwoFingerSwipeUp(context);
    } else if (averageDeltaY > threshold) {
      // 向下滑動 - 回上一頁
      globalGestureService.handleTwoFingerSwipeDown(context);
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
          ? GlobalGestureWrapper(child: body!)
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
