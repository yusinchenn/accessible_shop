import 'package:isar/isar.dart';
import 'order_status.dart';

part 'order.g.dart';

/// 訂單主表
@Collection()
class Order {
  Id id = Isar.autoIncrement;

  /// 訂單編號（如 "20250117-0001"）
  late String orderNumber;

  /// 訂單建立時間
  late DateTime createdAt;

  /// 訂單狀態（舊版，保留以便兼容）
  /// pending - 待處理
  /// processing - 處理中
  /// completed - 已完成
  /// cancelled - 已取消
  late String status;

  /// 訂單主要狀態（新版）
  @Enumerated(EnumType.name)
  late OrderMainStatus mainStatus;

  /// 物流狀態（新版）
  @Enumerated(EnumType.name)
  late LogisticsStatus logisticsStatus;

  /// 商品小計
  late double subtotal;

  /// 優惠折扣
  late double discount;

  /// 運費
  late double shippingFee;

  /// 訂單總金額
  late double total;

  /// 優惠券 ID（可為 null）
  int? couponId;

  /// 優惠券名稱（可為 null）
  String? couponName;

  /// 配送方式 ID
  late int shippingMethodId;

  /// 配送方式名稱
  late String shippingMethodName;

  /// 付款方式 ID
  late int paymentMethodId;

  /// 付款方式名稱
  late String paymentMethodName;

  /// 配送方式類型（用於判斷超商取貨或宅配）
  /// 'convenience_store' - 超商取貨
  /// 'home_delivery' - 宅配
  String? deliveryType;

  Order();
}

/// 訂單項目
@Collection()
class OrderItem {
  Id id = Isar.autoIncrement;

  /// 關聯的訂單 ID
  late int orderId;

  /// 商品 ID
  late int productId;

  /// 商品名稱
  late String productName;

  /// 規格
  late String specification;

  /// 單價
  late double unitPrice;

  /// 數量
  late int quantity;

  /// 小計（unitPrice × quantity）
  late double subtotal;

  OrderItem();
}