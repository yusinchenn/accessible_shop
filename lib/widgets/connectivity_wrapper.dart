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

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  StreamSubscription<bool>? _connectionSubscription;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  /// 開始監聽網路狀態
  void _startListening() {
    _connectionSubscription =
        connectivityService.connectionStatus.listen((bool isConnected) {
      if (!isConnected && !_isDialogShowing) {
        // 網路斷線且對話框未顯示，顯示對話框
        _showDialog();
      } else if (isConnected && _isDialogShowing) {
        // 網路恢復且對話框正在顯示，關閉對話框
        _hideDialog();
      }
    });
  }

  /// 顯示無網路對話框
  void _showDialog() {
    if (!mounted || _isDialogShowing) return;

    setState(() {
      _isDialogShowing = true;
    });

    showNoConnectionDialog(
      context,
      onClose: () {
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
      },
      onRetry: () {
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
      },
    );
  }

  /// 隱藏無網路對話框
  void _hideDialog() {
    if (!mounted || !_isDialogShowing) return;

    setState(() {
      _isDialogShowing = false;
    });

    // 關閉對話框
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      // 找到並關閉對話框
      return route.isFirst || !route.willHandlePopInternally;
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
