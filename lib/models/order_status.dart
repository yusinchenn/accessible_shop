import 'package:isar/isar.dart';

part 'order_status.g.dart';

/// 訂單主要狀態
enum OrderMainStatus {
  /// 待付款
  pendingPayment,

  /// 待出貨
  pendingShipment,

  /// 待收貨
  pendingDelivery,

  /// 訂單已完成
  completed,

  /// 退貨/退款
  returnRefund,

  /// 不成立
  invalid,
}

/// 物流狀態（僅適用於待收貨訂單）
enum LogisticsStatus {
  /// 無（非待收貨狀態）
  none,

  /// 運送中
  inTransit,

  /// 已抵達收貨地點（超商取貨）
  arrivedAtPickupPoint,

  /// 已簽收
  signed,
}

/// 訂單狀態歷史記錄
@Collection()
class OrderStatusHistory {
  Id id = Isar.autoIncrement;

  /// 關聯的訂單 ID
  late int orderId;

  /// 主要狀態
  @Enumerated(EnumType.name)
  late OrderMainStatus mainStatus;

  /// 物流狀態
  @Enumerated(EnumType.name)
  late LogisticsStatus logisticsStatus;

  /// 狀態描述（例如："訂單成立"、"賣家已確認"、"物流已取件"等）
  late String description;

  /// 狀態變更時間
  late DateTime timestamp;

  /// 備註（可選）
  String? note;

  OrderStatusHistory();
}

/// 訂單狀態時間戳記錄
@Collection()
class OrderStatusTimestamps {
  /// 使用訂單 ID 作為主鍵（一對一關係）
  Id id = Isar.autoIncrement;

  /// 關聯的訂單 ID
  @Index(unique: true)
  late int orderId;

  // ==================== 主要狀態時間戳 ====================

  /// 訂單建立時間
  late DateTime createdAt;

  /// 待付款時間（貨到付款訂單會有此時間）
  DateTime? pendingPaymentAt;

  /// 付款完成時間（線上付款訂單）
  DateTime? paidAt;

  /// 待出貨時間（賣家確認訂單）
  DateTime? pendingShipmentAt;

  /// 待收貨時間（賣家已出貨）
  DateTime? pendingDeliveryAt;

  /// 訂單完成時間
  DateTime? completedAt;

  /// 退貨/退款時間
  DateTime? returnRefundAt;

  /// 訂單不成立時間
  DateTime? invalidAt;

  // ==================== 物流狀態時間戳 ====================

  /// 開始運送時間
  DateTime? inTransitAt;

  /// 抵達收貨地點時間（超商取貨）
  DateTime? arrivedAtPickupPointAt;

  /// 簽收時間
  DateTime? signedAt;

  OrderStatusTimestamps();
}

/// 訂單狀態擴展方法
extension OrderMainStatusExtension on OrderMainStatus {
  /// 取得狀態的中文顯示名稱
  String get displayName {
    switch (this) {
      case OrderMainStatus.pendingPayment:
        return '待付款';
      case OrderMainStatus.pendingShipment:
        return '待出貨';
      case OrderMainStatus.pendingDelivery:
        return '待收貨';
      case OrderMainStatus.completed:
        return '訂單已完成';
      case OrderMainStatus.returnRefund:
        return '退貨/退款';
      case OrderMainStatus.invalid:
        return '不成立';
    }
  }
}

extension LogisticsStatusExtension on LogisticsStatus {
  /// 取得狀態的中文顯示名稱
  String get displayName {
    switch (this) {
      case LogisticsStatus.none:
        return '無';
      case LogisticsStatus.inTransit:
        return '運送中';
      case LogisticsStatus.arrivedAtPickupPoint:
        return '已抵達收貨地點';
      case LogisticsStatus.signed:
        return '已簽收';
    }
  }
}