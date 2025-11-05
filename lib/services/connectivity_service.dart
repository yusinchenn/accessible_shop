import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// 網路連線檢查服務
///
/// 提供網路狀態監聽和即時檢查功能
/// 使用單例模式，類似 ttsHelper
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// 網路連線狀態 Stream
  /// true = 有網路, false = 無網路
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// 當前網路連線狀態
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 初始化網路監聽
  Future<void> initialize() async {
    // 檢查初始網路狀態
    await checkConnectivity();

    // 監聽網路狀態變化
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  /// 檢查當前網路連線狀態
  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isConnected;
    } catch (e) {
      debugPrint('⚠️ [ConnectivityService] 檢查網路連線時發生錯誤: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
      return false;
    }
  }

  /// 更新網路連線狀態
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // 判斷是否有網路連線
    // ConnectivityResult.none 表示沒有網路
    final bool hasConnection = results.isNotEmpty &&
        !results.every((result) => result == ConnectivityResult.none);

    // 只有當狀態改變時才發送通知
    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectionStatusController.add(_isConnected);

      debugPrint('🌐 [ConnectivityService] 網路連線狀態變更: ${_isConnected ? "已連線" : "已斷線"}');
      debugPrint('📡 [ConnectivityService] 連線類型: ${results.map((r) => r.toString()).join(", ")}');
    }
  }

  /// 釋放資源
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}

/// 全域單例實例
final connectivityService = ConnectivityService();
