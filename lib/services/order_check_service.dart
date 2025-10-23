import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';
import 'order_status_service.dart';

/// 訂單檢查服務 - 每分鐘檢查訂單狀態，基於時間戳自動更新
///
/// 訂單狀態轉換規則（每個狀態持續5分鐘）：
/// - 待付款 -> 待出貨（5分鐘後）
/// - 待出貨 -> 待收貨/運送中（5分鐘後）
/// - 運送中 -> 已抵達超商（5分鐘後，僅超商取貨）
/// - 運送中 -> 已簽收（5分鐘後，宅配）
/// - 已抵達超商 -> 已簽收（5分鐘後）
class OrderCheckService {
  final DatabaseService _db;
  final OrderStatusService _orderStatusService;
  Timer? _checkTimer;

  /// 狀態轉換間隔時間（5分鐘）
  static const Duration statusTransitionDuration = Duration(minutes: 5);

  /// 檢查間隔時間（1分鐘）
  static const Duration checkInterval = Duration(minutes: 1);

  OrderCheckService(this._db, this._orderStatusService);

  /// 啟動定期檢查
  void startPeriodicCheck() {
    // 取消現有的計時器
    _checkTimer?.cancel();

    // 立即執行一次檢查
    _checkAllOrders();

    // 設定每分鐘檢查一次
    _checkTimer = Timer.periodic(checkInterval, (_) {
      _checkAllOrders();
    });

    if (kDebugMode) {
      print('⏰ [OrderCheckService] 已啟動定期檢查服務（每1分鐘檢查一次）');
    }
  }

  /// 停止定期檢查
  void stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;

    if (kDebugMode) {
      print('⏰ [OrderCheckService] 已停止定期檢查服務');
    }
  }

  /// 檢查所有訂單
  Future<void> _checkAllOrders() async {
    final now = DateTime.now();

    if (kDebugMode) {
      print('⏰ [OrderCheckService] 開始檢查訂單狀態...');
    }

    try {
      // 檢查待付款訂單
      await _checkPendingPaymentOrders(now);

      // 檢查待出貨訂單
      await _checkPendingShipmentOrders(now);

      // 檢查待收貨訂單
      await _checkPendingDeliveryOrders(now);

      if (kDebugMode) {
        print('✅ [OrderCheckService] 訂單檢查完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OrderCheckService] 訂單檢查時發生錯誤: $e');
      }
    }
  }

  /// 檢查待付款訂單（5分鐘後轉為待出貨）
  Future<void> _checkPendingPaymentOrders(DateTime now) async {
    final isar = await _db.isar;

    // 查找所有待付款訂單
    final orders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingPayment)
        .findAll();

    for (var order in orders) {
      // 獲取訂單的時間戳記錄
      final timestamps = await isar.orderStatusTimestamps
          .filter()
          .orderIdEqualTo(order.id)
          .findFirst();

      if (timestamps == null) continue;

      // 計算從訂單建立到現在的時間
      final elapsedTime = now.difference(timestamps.createdAt);

      // 如果已經超過5分鐘，自動確認訂單
      if (elapsedTime >= statusTransitionDuration) {
        await _confirmOrder(order);
      } else if (kDebugMode) {
        final remainingMinutes = (statusTransitionDuration - elapsedTime).inMinutes;
        print('⏳ [OrderCheckService] 訂單 #${order.orderNumber} 還有 $remainingMinutes 分鐘轉為待出貨');
      }
    }
  }

  /// 檢查待出貨訂單（5分鐘後轉為待收貨/運送中）
  Future<void> _checkPendingShipmentOrders(DateTime now) async {
    final isar = await _db.isar;

    // 查找所有待出貨訂單
    final orders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingShipment)
        .findAll();

    for (var order in orders) {
      // 獲取訂單的時間戳記錄
      final timestamps = await isar.orderStatusTimestamps
          .filter()
          .orderIdEqualTo(order.id)
          .findFirst();

      if (timestamps?.pendingShipmentAt == null) continue;

      // 計算從待出貨狀態到現在的時間
      final elapsedTime = now.difference(timestamps!.pendingShipmentAt!);

      // 如果已經超過5分鐘，自動出貨
      if (elapsedTime >= statusTransitionDuration) {
        await _shipOrder(order);
      } else if (kDebugMode) {
        final remainingMinutes = (statusTransitionDuration - elapsedTime).inMinutes;
        print('⏳ [OrderCheckService] 訂單 #${order.orderNumber} 還有 $remainingMinutes 分鐘轉為待收貨');
      }
    }
  }

  /// 檢查待收貨訂單（5分鐘後更新物流狀態）
  Future<void> _checkPendingDeliveryOrders(DateTime now) async {
    final isar = await _db.isar;

    // 查找所有待收貨訂單
    final orders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingDelivery)
        .findAll();

    for (var order in orders) {
      // 獲取訂單的時間戳記錄
      final timestamps = await isar.orderStatusTimestamps
          .filter()
          .orderIdEqualTo(order.id)
          .findFirst();

      if (timestamps == null) continue;

      // 根據物流狀態處理
      if (order.logisticsStatus == LogisticsStatus.inTransit) {
        await _checkInTransitOrder(order, timestamps, now);
      } else if (order.logisticsStatus == LogisticsStatus.arrivedAtPickupPoint) {
        await _checkArrivedOrder(order, timestamps, now);
      }
    }
  }

  /// 檢查運送中的訂單
  Future<void> _checkInTransitOrder(
    Order order,
    OrderStatusTimestamps timestamps,
    DateTime now,
  ) async {
    if (timestamps.inTransitAt == null) return;

    final elapsedTime = now.difference(timestamps.inTransitAt!);
    final isConvenienceStore = order.deliveryType == 'convenience_store';

    // 如果已經超過5分鐘
    if (elapsedTime >= statusTransitionDuration) {
      if (isConvenienceStore) {
        // 超商取貨：轉為已抵達超商
        await _arriveAtPickupPoint(order);
      } else {
        // 宅配：直接簽收
        await _signOrder(order);
      }
    } else if (kDebugMode) {
      final remainingMinutes = (statusTransitionDuration - elapsedTime).inMinutes;
      if (isConvenienceStore) {
        print('⏳ [OrderCheckService] 訂單 #${order.orderNumber} 還有 $remainingMinutes 分鐘抵達超商');
      } else {
        print('⏳ [OrderCheckService] 訂單 #${order.orderNumber} 還有 $remainingMinutes 分鐘簽收');
      }
    }
  }

  /// 檢查已抵達超商的訂單
  Future<void> _checkArrivedOrder(
    Order order,
    OrderStatusTimestamps timestamps,
    DateTime now,
  ) async {
    if (timestamps.arrivedAtPickupPointAt == null) return;

    final elapsedTime = now.difference(timestamps.arrivedAtPickupPointAt!);

    // 如果已經超過5分鐘，自動簽收
    if (elapsedTime >= statusTransitionDuration) {
      await _signOrder(order);
    } else if (kDebugMode) {
      final remainingMinutes = (statusTransitionDuration - elapsedTime).inMinutes;
      print('⏳ [OrderCheckService] 訂單 #${order.orderNumber} 還有 $remainingMinutes 分鐘簽收');
    }
  }

  /// 確認訂單（待付款 -> 待出貨）
  Future<void> _confirmOrder(Order order) async {
    await _orderStatusService.updateOrderStatus(
      orderId: order.id,
      mainStatus: OrderMainStatus.pendingShipment,
      description: '賣家已確認訂單',
    );

    // 創建通知
    await _db.createOrderNotification(
      title: '訂單已確認',
      content: '您的訂單 #${order.orderNumber} 已由賣家確認，準備出貨',
      orderId: order.id,
      orderNumber: order.orderNumber,
    );

    if (kDebugMode) {
      print('✅ [OrderCheckService] 訂單已確認: #${order.orderNumber} -> 待出貨');
    }
  }

  /// 出貨（待出貨 -> 待收貨/運送中）
  Future<void> _shipOrder(Order order) async {
    await _orderStatusService.updateOrderStatus(
      orderId: order.id,
      mainStatus: OrderMainStatus.pendingDelivery,
      logisticsStatus: LogisticsStatus.inTransit,
      description: '賣家已出貨，開始運送',
    );

    // 創建通知
    await _db.createOrderNotification(
      title: '訂單已出貨',
      content: '您的訂單 #${order.orderNumber} 已出貨，正在運送中',
      orderId: order.id,
      orderNumber: order.orderNumber,
    );

    if (kDebugMode) {
      print('📦 [OrderCheckService] 訂單已出貨: #${order.orderNumber} -> 待收貨/運送中');
    }
  }

  /// 抵達超商取貨點
  Future<void> _arriveAtPickupPoint(Order order) async {
    await _orderStatusService.updateLogisticsStatus(
      orderId: order.id,
      logisticsStatus: LogisticsStatus.arrivedAtPickupPoint,
      description: '商品已抵達超商取貨點',
    );

    // 創建通知
    await _db.createOrderNotification(
      title: '商品已到店',
      content: '您的訂單 #${order.orderNumber} 已抵達超商，請前往取貨',
      orderId: order.id,
      orderNumber: order.orderNumber,
    );

    if (kDebugMode) {
      print('📍 [OrderCheckService] 商品已抵達超商: #${order.orderNumber}');
    }
  }

  /// 簽收訂單
  Future<void> _signOrder(Order order) async {
    await _orderStatusService.updateLogisticsStatus(
      orderId: order.id,
      logisticsStatus: LogisticsStatus.signed,
      description: '商品已簽收',
    );

    // 創建通知
    await _db.createOrderNotification(
      title: '商品已簽收',
      content: '您的訂單 #${order.orderNumber} 已簽收，請確認商品無誤後完成訂單',
      orderId: order.id,
      orderNumber: order.orderNumber,
    );

    if (kDebugMode) {
      print('✅ [OrderCheckService] 商品已簽收: #${order.orderNumber}');
    }
  }

  /// 清理資源
  void dispose() {
    stopPeriodicCheck();
  }
}
