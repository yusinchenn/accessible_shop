import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';
import 'order_status_service.dart';

/// 物流服務 - 模擬物流對訂單的操作
class LogisticsService {
  final DatabaseService _db;
  final OrderStatusService _orderStatusService;
  final Map<int, Timer> _inTransitTimers = {};
  final Map<int, Timer> _arrivedTimers = {};

  LogisticsService(this._db, this._orderStatusService);

  /// 開始監控運送中的訂單
  void startMonitoringInTransitOrder(Order order) {
    if (order.mainStatus != OrderMainStatus.pendingDelivery ||
        order.logisticsStatus != LogisticsStatus.inTransit) {
      return;
    }

    // 取消已存在的計時器
    _inTransitTimers[order.id]?.cancel();

    // 判斷配送方式
    final isConvenienceStore = order.deliveryType == 'convenience_store';

    if (isConvenienceStore) {
      // 超商取貨：5 分鐘後抵達收貨地點
      _inTransitTimers[order.id] = Timer(const Duration(minutes: 5), () async {
        await _arriveAtPickupPoint(order.id);
        _inTransitTimers.remove(order.id);
      });

      if (kDebugMode) {
        print('🚚 [LogisticsService] 開始監控超商取貨訂單: #${order.orderNumber} (5分鐘後抵達超商)');
      }
    } else {
      // 宅配：5 分鐘後直接簽收
      _inTransitTimers[order.id] = Timer(const Duration(minutes: 5), () async {
        await _signOrder(order.id);
        _inTransitTimers.remove(order.id);
      });

      if (kDebugMode) {
        print('🚚 [LogisticsService] 開始監控宅配訂單: #${order.orderNumber} (5分鐘後簽收)');
      }
    }
  }

  /// 抵達超商取貨點
  Future<void> _arriveAtPickupPoint(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null ||
        order.mainStatus != OrderMainStatus.pendingDelivery ||
        order.logisticsStatus != LogisticsStatus.inTransit) {
      return;
    }

    await _orderStatusService.updateLogisticsStatus(
      orderId: orderId,
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
      print('📍 [LogisticsService] 商品已抵達超商: #${order.orderNumber}');
    }

    // 開始監控已抵達的訂單
    final updatedOrder = await isar.orders.get(orderId);
    if (updatedOrder != null) {
      startMonitoringArrivedOrder(updatedOrder);
    }
  }

  /// 開始監控已抵達超商的訂單（5 分鐘後自動簽收）
  void startMonitoringArrivedOrder(Order order) {
    if (order.mainStatus != OrderMainStatus.pendingDelivery ||
        order.logisticsStatus != LogisticsStatus.arrivedAtPickupPoint) {
      return;
    }

    // 取消已存在的計時器
    _arrivedTimers[order.id]?.cancel();

    // 創建新的計時器：5 分鐘後自動簽收
    _arrivedTimers[order.id] = Timer(const Duration(minutes: 5), () async {
      await _signOrder(order.id);
      _arrivedTimers.remove(order.id);
    });

    if (kDebugMode) {
      print('🚚 [LogisticsService] 開始監控已抵達訂單: #${order.orderNumber} (5分鐘後簽收)');
    }
  }

  /// 簽收訂單
  Future<void> _signOrder(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null || order.mainStatus != OrderMainStatus.pendingDelivery) {
      return;
    }

    await _orderStatusService.updateLogisticsStatus(
      orderId: orderId,
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
      print('✅ [LogisticsService] 商品已簽收: #${order.orderNumber}');
    }
  }

  /// 手動抵達超商
  Future<void> manualArriveAtPickupPoint(int orderId) async {
    _inTransitTimers[orderId]?.cancel();
    _inTransitTimers.remove(orderId);
    await _arriveAtPickupPoint(orderId);
  }

  /// 手動簽收
  Future<void> manualSignOrder(int orderId) async {
    _inTransitTimers[orderId]?.cancel();
    _inTransitTimers.remove(orderId);
    _arrivedTimers[orderId]?.cancel();
    _arrivedTimers.remove(orderId);
    await _signOrder(orderId);
  }

  /// 取消訂單監控
  void cancelMonitoring(int orderId) {
    _inTransitTimers[orderId]?.cancel();
    _inTransitTimers.remove(orderId);
    _arrivedTimers[orderId]?.cancel();
    _arrivedTimers.remove(orderId);

    if (kDebugMode) {
      print('🚚 [LogisticsService] 取消訂單監控: #$orderId');
    }
  }

  /// 重新掃描並開始監控所有符合條件的訂單
  Future<void> rescanAndMonitorOrders() async {
    final isar = await _db.isar;

    // 監控所有運送中的訂單
    final inTransitOrders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingDelivery)
        .logisticsStatusEqualTo(LogisticsStatus.inTransit)
        .findAll();

    for (var order in inTransitOrders) {
      startMonitoringInTransitOrder(order);
    }

    // 監控所有已抵達的訂單
    final arrivedOrders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingDelivery)
        .logisticsStatusEqualTo(LogisticsStatus.arrivedAtPickupPoint)
        .findAll();

    for (var order in arrivedOrders) {
      startMonitoringArrivedOrder(order);
    }

    if (kDebugMode) {
      print('🚚 [LogisticsService] 重新掃描訂單: 運送中 ${inTransitOrders.length} 筆, 已抵達 ${arrivedOrders.length} 筆');
    }
  }

  /// 清理所有計時器
  void dispose() {
    for (var timer in _inTransitTimers.values) {
      timer.cancel();
    }
    for (var timer in _arrivedTimers.values) {
      timer.cancel();
    }
    _inTransitTimers.clear();
    _arrivedTimers.clear();

    if (kDebugMode) {
      print('🚚 [LogisticsService] 已清理所有計時器');
    }
  }
}