import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'order_status_service.dart';
import 'seller_service.dart';
import 'logistics_service.dart';
import '../models/order.dart';
import '../models/order_status.dart';

/// 訂單自動化服務 - 統一管理賣家和物流服務
class OrderAutomationService {
  final DatabaseService _db;
  late final OrderStatusService _orderStatusService;
  late final SellerService _sellerService;
  late final LogisticsService _logisticsService;

  OrderAutomationService(this._db) {
    _orderStatusService = OrderStatusService(_db);
    _sellerService = SellerService(_db, _orderStatusService);
    _logisticsService = LogisticsService(_db, _orderStatusService);
  }

  /// 初始化服務 - 掃描並開始監控所有現有訂單
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🤖 [OrderAutomationService] 初始化自動化服務...');
    }

    await _sellerService.rescanAndMonitorOrders();
    await _logisticsService.rescanAndMonitorOrders();

    if (kDebugMode) {
      print('✅ [OrderAutomationService] 自動化服務已啟動');
    }
  }

  /// 當新訂單建立時調用此方法
  Future<void> onOrderCreated(Order order) async {
    if (kDebugMode) {
      print('🤖 [OrderAutomationService] 新訂單建立: #${order.orderNumber}, 狀態: ${order.mainStatus.displayName}');
    }

    // 根據訂單狀態決定如何處理
    if (order.mainStatus == OrderMainStatus.pendingPayment) {
      // 待付款訂單：開始監控，1分鐘後自動確認
      _sellerService.startMonitoringPendingPaymentOrder(order);
    } else if (order.mainStatus == OrderMainStatus.pendingShipment) {
      // 待出貨訂單（線上付款）：開始監控，1小時後自動出貨
      _sellerService.startMonitoringPendingShipmentOrder(order);
    }
  }

  /// 當訂單狀態變更時調用此方法
  Future<void> onOrderStatusChanged(Order order) async {
    if (kDebugMode) {
      print('🤖 [OrderAutomationService] 訂單狀態變更: #${order.orderNumber}, 新狀態: ${order.mainStatus.displayName} (${order.logisticsStatus.displayName})');
    }

    // 根據新狀態決定如何處理
    switch (order.mainStatus) {
      case OrderMainStatus.pendingPayment:
        _sellerService.startMonitoringPendingPaymentOrder(order);
        break;

      case OrderMainStatus.pendingShipment:
        _sellerService.startMonitoringPendingShipmentOrder(order);
        break;

      case OrderMainStatus.pendingDelivery:
        // 待收貨訂單：交給物流服務處理
        if (order.logisticsStatus == LogisticsStatus.inTransit) {
          _logisticsService.startMonitoringInTransitOrder(order);
        } else if (order.logisticsStatus == LogisticsStatus.arrivedAtPickupPoint) {
          _logisticsService.startMonitoringArrivedOrder(order);
        }
        break;

      case OrderMainStatus.completed:
      case OrderMainStatus.returnRefund:
      case OrderMainStatus.invalid:
        // 這些狀態不需要自動化處理，取消監控
        _sellerService.cancelMonitoring(order.id);
        _logisticsService.cancelMonitoring(order.id);
        break;
    }
  }

  /// 手動觸發賣家確認訂單
  Future<void> manualConfirmOrder(int orderId) async {
    await _sellerService.manualConfirmOrder(orderId);
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);
    if (order != null) {
      await onOrderStatusChanged(order);
    }
  }

  /// 手動觸發賣家出貨
  Future<void> manualShipOrder(int orderId) async {
    await _sellerService.manualShipOrder(orderId);
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);
    if (order != null) {
      await onOrderStatusChanged(order);
    }
  }

  /// 手動觸發物流抵達超商
  Future<void> manualArriveAtPickupPoint(int orderId) async {
    await _logisticsService.manualArriveAtPickupPoint(orderId);
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);
    if (order != null) {
      await onOrderStatusChanged(order);
    }
  }

  /// 手動觸發物流簽收
  Future<void> manualSignOrder(int orderId) async {
    await _logisticsService.manualSignOrder(orderId);
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);
    if (order != null) {
      await onOrderStatusChanged(order);
    }
  }

  /// 清理所有服務
  void dispose() {
    _sellerService.dispose();
    _logisticsService.dispose();

    if (kDebugMode) {
      print('🤖 [OrderAutomationService] 自動化服務已停止');
    }
  }

  // Getters for accessing individual services
  OrderStatusService get orderStatusService => _orderStatusService;
  SellerService get sellerService => _sellerService;
  LogisticsService get logisticsService => _logisticsService;
}