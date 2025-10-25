import 'package:accessible_shop/models/product.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';

/// 訂單狀態管理服務
class OrderStatusService {
  final DatabaseService _db;

  OrderStatusService(this._db);

  /// 創建訂單狀態歷史記錄
  Future<void> _addStatusHistory({
    required int orderId,
    required OrderMainStatus mainStatus,
    required LogisticsStatus logisticsStatus,
    required String description,
    String? note,
  }) async {
    final isar = await _db.isar;

    final history = OrderStatusHistory()
      ..orderId = orderId
      ..mainStatus = mainStatus
      ..logisticsStatus = logisticsStatus
      ..description = description
      ..timestamp = DateTime.now()
      ..note = note;

    await isar.writeTxn(() async {
      await isar.orderStatusHistorys.put(history);
    });

    if (kDebugMode) {
      print('📊 [OrderStatusService] 新增狀態歷史: 訂單 #$orderId - $description');
    }
  }

  /// 更新訂單狀態時間戳
  Future<void> _updateTimestamps({
    required int orderId,
    DateTime? pendingPaymentAt,
    DateTime? paidAt,
    DateTime? pendingShipmentAt,
    DateTime? pendingDeliveryAt,
    DateTime? completedAt,
    DateTime? returnRefundAt,
    DateTime? invalidAt,
    DateTime? inTransitAt,
    DateTime? arrivedAtPickupPointAt,
    DateTime? signedAt,
  }) async {
    final isar = await _db.isar;

    // 查找現有的時間戳記錄
    var timestamps = await isar.orderStatusTimestamps
        .filter()
        .orderIdEqualTo(orderId)
        .findFirst();

    if (timestamps == null) {
      // 如果時間戳記錄不存在，創建一個新的
      // 這通常發生在舊訂單或資料遷移時
      timestamps = OrderStatusTimestamps()
        ..orderId = orderId
        ..createdAt = DateTime.now();

      if (kDebugMode) {
        print('⚠️ [OrderStatusService] 為訂單 #$orderId 創建時間戳記錄（補救措施）');
      }
    }

    // 更新時間戳（只更新非 null 的值）
    if (pendingPaymentAt != null) {
      timestamps.pendingPaymentAt = pendingPaymentAt;
    }
    if (paidAt != null) timestamps.paidAt = paidAt;
    if (pendingShipmentAt != null) {
      timestamps.pendingShipmentAt = pendingShipmentAt;
    }
    if (pendingDeliveryAt != null) {
      timestamps.pendingDeliveryAt = pendingDeliveryAt;
    }
    if (completedAt != null) timestamps.completedAt = completedAt;
    if (returnRefundAt != null) timestamps.returnRefundAt = returnRefundAt;
    if (invalidAt != null) timestamps.invalidAt = invalidAt;
    if (inTransitAt != null) timestamps.inTransitAt = inTransitAt;
    if (arrivedAtPickupPointAt != null) {
      timestamps.arrivedAtPickupPointAt = arrivedAtPickupPointAt;
    }
    if (signedAt != null) timestamps.signedAt = signedAt;

    await isar.writeTxn(() async {
      await isar.orderStatusTimestamps.put(timestamps!);
    });
  }

  /// 更新訂單主要狀態和物流狀態
  Future<void> updateOrderStatus({
    required int orderId,
    required OrderMainStatus mainStatus,
    LogisticsStatus logisticsStatus = LogisticsStatus.none,
    required String description,
    String? note,
  }) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null) {
      if (kDebugMode) {
        print('❌ [OrderStatusService] 訂單不存在: #$orderId');
      }
      return;
    }

    await isar.writeTxn(() async {
      order.mainStatus = mainStatus;
      order.logisticsStatus = logisticsStatus;
      await isar.orders.put(order);
    });

    // 記錄狀態歷史
    await _addStatusHistory(
      orderId: orderId,
      mainStatus: mainStatus,
      logisticsStatus: logisticsStatus,
      description: description,
      note: note,
    );

    // 更新時間戳
    final now = DateTime.now();
    switch (mainStatus) {
      case OrderMainStatus.pendingPayment:
        await _updateTimestamps(orderId: orderId, pendingPaymentAt: now);
        break;
      case OrderMainStatus.pendingShipment:
        await _updateTimestamps(orderId: orderId, pendingShipmentAt: now);
        break;
      case OrderMainStatus.pendingDelivery:
        await _updateTimestamps(orderId: orderId, pendingDeliveryAt: now);
        // 同時更新物流狀態時間戳
        if (logisticsStatus == LogisticsStatus.inTransit) {
          await _updateTimestamps(orderId: orderId, inTransitAt: now);
        } else if (logisticsStatus == LogisticsStatus.arrivedAtPickupPoint) {
          await _updateTimestamps(
            orderId: orderId,
            arrivedAtPickupPointAt: now,
          );
        } else if (logisticsStatus == LogisticsStatus.signed) {
          await _updateTimestamps(orderId: orderId, signedAt: now);
        }
        break;
      case OrderMainStatus.completed:
        await _updateTimestamps(orderId: orderId, completedAt: now);
        break;
      case OrderMainStatus.returnRefund:
        await _updateTimestamps(orderId: orderId, returnRefundAt: now);
        break;
      case OrderMainStatus.invalid:
        await _updateTimestamps(orderId: orderId, invalidAt: now);
        break;
    }

    if (kDebugMode) {
      print(
        '📦 [OrderStatusService] 更新訂單狀態: 訂單 #${order.orderNumber} -> ${mainStatus.displayName} (${logisticsStatus.displayName})',
      );
    }
  }

  /// 更新物流狀態（僅用於待收貨訂單）
  Future<void> updateLogisticsStatus({
    required int orderId,
    required LogisticsStatus logisticsStatus,
    required String description,
    String? note,
  }) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null) {
      if (kDebugMode) {
        print('❌ [OrderStatusService] 訂單不存在: #$orderId');
      }
      return;
    }

    if (order.mainStatus != OrderMainStatus.pendingDelivery) {
      if (kDebugMode) {
        print('⚠️ [OrderStatusService] 訂單不在待收貨狀態，無法更新物流狀態');
      }
      return;
    }

    await isar.writeTxn(() async {
      order.logisticsStatus = logisticsStatus;
      await isar.orders.put(order);
    });

    // 記錄狀態歷史
    await _addStatusHistory(
      orderId: orderId,
      mainStatus: order.mainStatus,
      logisticsStatus: logisticsStatus,
      description: description,
      note: note,
    );

    // 更新物流時間戳
    final now = DateTime.now();
    switch (logisticsStatus) {
      case LogisticsStatus.inTransit:
        await _updateTimestamps(orderId: orderId, inTransitAt: now);
        break;
      case LogisticsStatus.arrivedAtPickupPoint:
        await _updateTimestamps(orderId: orderId, arrivedAtPickupPointAt: now);
        break;
      case LogisticsStatus.signed:
        await _updateTimestamps(orderId: orderId, signedAt: now);
        break;
      case LogisticsStatus.none:
        break;
    }

    if (kDebugMode) {
      print(
        '🚚 [OrderStatusService] 更新物流狀態: 訂單 #${order.orderNumber} -> ${logisticsStatus.displayName}',
      );
    }
  }

  /// 取得訂單狀態歷史
  Future<List<OrderStatusHistory>> getOrderStatusHistory(int orderId) async {
    final isar = await _db.isar;
    final results = await isar.orderStatusHistorys
        .filter()
        .orderIdEqualTo(orderId)
        .findAll();

    // 在 Dart 層排序
    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return results;
  }

  /// 取得訂單狀態時間戳
  Future<OrderStatusTimestamps?> getOrderStatusTimestamps(int orderId) async {
    final isar = await _db.isar;
    return await isar.orderStatusTimestamps
        .filter()
        .orderIdEqualTo(orderId)
        .findFirst();
  }

  /// 根據主要狀態篩選訂單
  Future<List<Order>> getOrdersByMainStatus(OrderMainStatus status) async {
    final isar = await _db.isar;
    final results = await isar.orders
        .filter()
        .mainStatusEqualTo(status)
        .findAll();

    // 在 Dart 層排序（時間倒序）
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// 完成訂單（僅限已簽收的待收貨訂單）
  Future<bool> completeOrder(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null) {
      if (kDebugMode) {
        print('❌ [OrderStatusService] 訂單不存在: #$orderId');
      }
      return false;
    }

    if (order.mainStatus != OrderMainStatus.pendingDelivery ||
        order.logisticsStatus != LogisticsStatus.signed) {
      if (kDebugMode) {
        print('⚠️ [OrderStatusService] 訂單未簽收，無法完成訂單');
      }
      return false;
    }

    await updateOrderStatus(
      orderId: orderId,
      mainStatus: OrderMainStatus.completed,
      logisticsStatus: LogisticsStatus.none,
      description: '買家確認完成訂單',
    );

    // 更新商品售出次數
    await _updateProductSoldCount(orderId);

    // 創建訂單完成通知
    await _db.createOrderNotification(
      title: '訂單已完成',
      content: '您的訂單 #${order.orderNumber} 已完成',
      orderId: order.id,
      orderNumber: order.orderNumber,
    );

    return true;
  }

  /// 更新商品售出次數（訂單完成時）
  Future<void> _updateProductSoldCount(int orderId) async {
    try {
      // 獲取訂單項目
      final orderItems = await _db.getOrderItems(orderId);

      // 更新每個商品的售出次數
      for (var item in orderItems) {
        final product = await _db.getProductById(item.productId);
        if (product != null) {
          final isar = await _db.isar;
          await isar.writeTxn(() async {
            product.soldCount += item.quantity;
            await isar.products.put(product);
          });

          if (kDebugMode) {
            print(
              '📈 [OrderStatusService] 更新商品售出次數: ${product.name} +${item.quantity} (總計: ${product.soldCount})',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OrderStatusService] 更新商品售出次數失敗: $e');
      }
    }
  }
}
