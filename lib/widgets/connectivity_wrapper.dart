import 'dart:async';
import 'package:flutter/material.dart';
import 'package:accessible_shop/services/connectivity_service.dart';
import 'package:accessible_shop/widgets/no_connection_dialog.dart';

/// 全域網路連線監聽包裹器
///
/// 功能：
/// - 包裹整個應用，監聽網路狀態變化
/// - 當網路斷線時自動彈出無網路提醒對話框
/// - 當網路恢復時自動關閉對話框
/// - 避免重複顯示對話框
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _connectionSubscription;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // 註冊應用生命週期觀察者
    WidgetsBinding.instance.addObserver(this);

    // 延遲監聽，確保 MaterialApp 已完全初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startListening();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 當應用從背景恢復到前景時，主動檢查網路狀態
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 [ConnectivityWrapper] 應用恢復到前景，檢查網路狀態');
      _recheckConnectivity();
    }
  }

  /// 重新檢查網路連線狀態
  Future<void> _recheckConnectivity() async {
    if (!mounted) return;

    final bool isConnected = await connectivityService.checkConnectivity();
    debugPrint('🔍 [ConnectivityWrapper] 重新檢查網路狀態: $isConnected');

    if (!isConnected && !_isDialogShowing) {
      debugPrint('📵 [ConnectivityWrapper] 檢測到無網路，顯示對話框');
      _showDialog();
    } else if (isConnected && _isDialogShowing) {
      debugPrint('📶 [ConnectivityWrapper] 檢測到網路恢復，關閉對話框');
      _hideDialog();
    }
  }

  /// 開始監聽網路狀態
  ///
  /// 注意：初始網路檢查已在 FirebaseInitializer 層級處理
  /// 這裡只監聽應用運行期間的網路狀態變化
  void _startListening() {
    debugPrint('✅ [ConnectivityWrapper] 開始監聽網路狀態（僅監聽變化，不主動檢查初始狀態）');

    // 監聽網路狀態變更
    _connectionSubscription =
        connectivityService.connectionStatus.listen((bool isConnected) {
      debugPrint('🔔 [ConnectivityWrapper] 收到網路狀態變更: $isConnected');

      if (!mounted) {
        debugPrint('⚠️ [ConnectivityWrapper] Widget 已卸載，忽略網路狀態變更');
        return;
      }

      if (!isConnected && !_isDialogShowing) {
        // 網路斷線且對話框未顯示，顯示對話框
        debugPrint('📵 [ConnectivityWrapper] 顯示無網路對話框');
        _showDialog();
      } else if (isConnected && _isDialogShowing) {
        // 網路恢復且對話框正在顯示，關閉對話框
        debugPrint('📶 [ConnectivityWrapper] 關閉無網路對話框');
        _hideDialog();
      }
    });
  }

  /// 顯示無網路對話框
  void _showDialog() {
    if (!mounted || _isDialogShowing) {
      debugPrint('⚠️ [ConnectivityWrapper] 無法顯示對話框 (mounted: $mounted, showing: $_isDialogShowing)');
      return;
    }

    setState(() {
      _isDialogShowing = true;
    });

    showNoConnectionDialog(
      context,
      onClose: () {
        debugPrint('🔴 [ConnectivityWrapper] 使用者點擊關閉按鈕');
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
      },
      onRetry: () {
        debugPrint('🔄 [ConnectivityWrapper] 使用者點擊重試按鈕');
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
      },
    ).then((_) {
      // 當對話框被關閉時（無論何種方式），更新狀態
      if (mounted && _isDialogShowing) {
        setState(() {
          _isDialogShowing = false;
        });
      }
    });
  }

  /// 隱藏無網路對話框
  void _hideDialog() {
    if (!mounted || !_isDialogShowing) {
      debugPrint('⚠️ [ConnectivityWrapper] 無法關閉對話框 (mounted: $mounted, showing: $_isDialogShowing)');
      return;
    }

    setState(() {
      _isDialogShowing = false;
    });

    // 關閉對話框
    try {
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint('✅ [ConnectivityWrapper] 成功關閉無網路對話框');
    } catch (e) {
      debugPrint('⚠️ [ConnectivityWrapper] 關閉對話框時發生錯誤: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
