import 'package:flutter/material.dart';
import 'package:accessible_shop/services/connectivity_service.dart';

/// 網路連線檢查 Navigator Observer
///
/// 在頁面切換時主動檢查網路連線狀態
/// 如果沒有網路，會觸發 ConnectivityService 發送斷線通知
class ConnectivityNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkConnectivity('didPush', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _checkConnectivity('didPop', previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkConnectivity('didReplace', newRoute);
    }
  }

  /// 檢查網路連線狀態
  void _checkConnectivity(String action, Route<dynamic> route) {
    // 只在頁面路由（PageRoute）時檢查，忽略對話框等
    if (route is PageRoute) {
      final routeName = route.settings.name ?? 'unknown';
      debugPrint('🔍 [ConnectivityNavigatorObserver] 頁面切換 ($action): $routeName');

      // 主動觸發網路檢查
      connectivityService.checkConnectivity().then((isConnected) {
        debugPrint('📡 [ConnectivityNavigatorObserver] 網路狀態: ${isConnected ? "已連線" : "已斷線"}');
      });
    }
  }
}
