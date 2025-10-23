import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';
import 'order_status_service.dart';

/// 賣家服務 - 模擬賣場對訂單的操作
class SellerService {
  final DatabaseService _db;
  final OrderStatusService _orderStatusService;
  final Map<int, Timer> _pendingTimers = {};
  final Map<int, Timer> _shipmentTimers = {};

  SellerService(this._db, this._orderStatusService);

  /// 開始監控待付款訂單（5分鐘後自動確認）
  void startMonitoringPendingPaymentOrder(Order order) {
    if (order.mainStatus != OrderMainStatus.pendingPayment) {
      return;
    }

    // 取消已存在的計時器
    _pendingTimers[order.id]?.cancel();

    // 創建新的計時器：5 分鐘後自動確認訂單
    _pendingTimers[order.id] = Timer(const Duration(minutes: 5), () async {
      await _confirmOrder(order.id);
      _pendingTimers.remove(order.id);
    });

    if (kDebugMode) {
      print('🏪 [SellerService] 開始監控待付款訂單: #${order.orderNumber} (5分鐘後自動確認)');
    }
  }

  /// 確認訂單（待付款 -> 待出貨）
  Future<void> _confirmOrder(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null || order.mainStatus != OrderMainStatus.pendingPayment) {
      return;
    }

    await _orderStatusService.updateOrderStatus(
      orderId: orderId,
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
      print('✅ [SellerService] 訂單已確認: #${order.orderNumber} -> 待出貨');
    }

    // 開始監控待出貨訂單
    final updatedOrder = await isar.orders.get(orderId);
    if (updatedOrder != null) {
      startMonitoringPendingShipmentOrder(updatedOrder);
    }
  }

  /// 開始監控待出貨訂單（5分鐘後自動出貨）
  void startMonitoringPendingShipmentOrder(Order order) {
    if (order.mainStatus != OrderMainStatus.pendingShipment) {
      return;
    }

    // 取消已存在的計時器
    _shipmentTimers[order.id]?.cancel();

    // 創建新的計時器：5 分鐘後自動出貨
    _shipmentTimers[order.id] = Timer(const Duration(minutes: 5), () async {
      await _shipOrder(order.id);
      _shipmentTimers.remove(order.id);
    });

    if (kDebugMode) {
      print('🏪 [SellerService] 開始監控待出貨訂單: #${order.orderNumber} (5分鐘後自動出貨)');
    }
  }

  /// 出貨（待出貨 -> 待收貨/運送中）
  Future<void> _shipOrder(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null || order.mainStatus != OrderMainStatus.pendingShipment) {
      return;
    }

    await _orderStatusService.updateOrderStatus(
      orderId: orderId,
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
      print('📦 [SellerService] 訂單已出貨: #${order.orderNumber} -> 待收貨/運送中');
    }
  }

  /// 手動確認訂單
  Future<void> manualConfirmOrder(int orderId) async {
    _pendingTimers[orderId]?.cancel();
    _pendingTimers.remove(orderId);
    await _confirmOrder(orderId);
  }

  /// 手動出貨
  Future<void> manualShipOrder(int orderId) async {
    _shipmentTimers[orderId]?.cancel();
    _shipmentTimers.remove(orderId);
    await _shipOrder(orderId);
  }

  /// 取消訂單監控
  void cancelMonitoring(int orderId) {
    _pendingTimers[orderId]?.cancel();
    _pendingTimers.remove(orderId);
    _shipmentTimers[orderId]?.cancel();
    _shipmentTimers.remove(orderId);

    if (kDebugMode) {
      print('🏪 [SellerService] 取消訂單監控: #$orderId');
    }
  }

  /// 重新掃描並開始監控所有符合條件的訂單
  Future<void> rescanAndMonitorOrders() async {
    final isar = await _db.isar;

    // 監控所有待付款訂單
    final pendingPaymentOrders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingPayment)
        .findAll();

    for (var order in pendingPaymentOrders) {
      startMonitoringPendingPaymentOrder(order);
    }

    // 監控所有待出貨訂單
    final pendingShipmentOrders = await isar.orders
        .filter()
        .mainStatusEqualTo(OrderMainStatus.pendingShipment)
        .findAll();

    for (var order in pendingShipmentOrders) {
      startMonitoringPendingShipmentOrder(order);
    }

    if (kDebugMode) {
      print('🏪 [SellerService] 重新掃描訂單: 待付款 ${pendingPaymentOrders.length} 筆, 待出貨 ${pendingShipmentOrders.length} 筆');
    }
  }

  /// 清理所有計時器
  void dispose() {
    for (var timer in _pendingTimers.values) {
      timer.cancel();
    }
    for (var timer in _shipmentTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _shipmentTimers.clear();

    if (kDebugMode) {
      print('🏪 [SellerService] 已清理所有計時器');
    }
  }
}