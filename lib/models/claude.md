# Models 資料夾架構文件

本文件說明 `lib/models/` 資料夾中各個資料模型的用途、欄位結構與使用方式。

## 目錄

1. [資料庫模型 (Isar Collections)](#資料庫模型-isar-collections)
2. [簡單資料模型 (Plain Dart Classes)](#簡單資料模型-plain-dart-classes)
3. [枚舉與擴展](#枚舉與擴展)
4. [模型關聯圖](#模型關聯圖)

---

## 資料庫模型 (Isar Collections)

這些模型使用 Isar 資料庫進行持久化儲存，透過 `@Collection()` 註解標記。

### Store
**檔案**: [store.dart](store.dart)

**用途**: 商家/店鋪資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `name` | `String` | 商家名稱 |
| `rating` | `double` | 商家星等 (0-5) |
| `followersCount` | `int` | 粉絲數 |
| `imageUrl` | `String?` | 商家圖片 URL |
| `description` | `String?` | 商家描述 |

**使用範例**:
```dart
final store = Store()
  ..name = '運動世界專賣店'
  ..rating = 4.8
  ..followersCount = 15230
  ..imageUrl = 'https://example.com/store.jpg'
  ..description = '專營各大運動品牌';
```

**位置**: [store.dart:6](store.dart#L6)

---

### Product
**檔案**: [product.dart](product.dart)

**用途**: 商品資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `name` | `String` | 商品名稱 |
| `price` | `double` | 商品價格 |
| `description` | `String?` | 商品描述 |
| `imageUrl` | `String?` | 商品圖片 URL |
| `category` | `String?` | 商品分類 |
| `storeId` | `int` | 所屬商家 ID（外鍵） |

**關聯**:
- 多對一關聯 `Store`（一個商家有多個商品）

**使用範例**:
```dart
final product = Product()
  ..name = 'Nike Air Max 270'
  ..price = 4500
  ..description = '經典氣墊運動鞋'
  ..category = '運動鞋'
  ..storeId = 1;
```

**位置**: [product.dart:6](product.dart#L6)

---

### CartItem
**檔案**: [cart_item.dart](cart_item.dart)

**用途**: 購物車項目資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `productId` | `int` | 關聯的商品 ID |
| `name` | `String` | 商品名稱（快照） |
| `specification` | `String` | 規格（如：尺寸、顏色） |
| `unitPrice` | `double` | 單價（快照） |
| `quantity` | `int` | 數量 |
| `isSelected` | `bool` | 是否選取（用於結帳） |

**設計說明**:
- 儲存商品名稱和價格的快照，避免商品資料變動影響購物車
- `specification` 用於區分相同商品的不同規格

**使用範例**:
```dart
final cartItem = CartItem()
  ..productId = 1
  ..name = 'Nike Air Max 270'
  ..specification = '尺寸: L / 顏色: 黑色'
  ..unitPrice = 4500
  ..quantity = 1
  ..isSelected = true;
```

**位置**: [cart_item.dart:6](cart_item.dart#L6)

---

### Order
**檔案**: [order.dart](order.dart)

**用途**: 訂單主表資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `orderNumber` | `String` | 訂單編號（如 "20250117-0001"） |
| `createdAt` | `DateTime` | 訂單建立時間 |
| `status` | `String` | 訂單狀態（舊版，保留兼容） |
| `mainStatus` | `OrderMainStatus` | 訂單主要狀態（新版枚舉） |
| `logisticsStatus` | `LogisticsStatus` | 物流狀態（新版枚舉） |
| `subtotal` | `double` | 商品小計 |
| `discount` | `double` | 優惠折扣 |
| `shippingFee` | `double` | 運費 |
| `total` | `double` | 訂單總金額 |
| `couponId` | `int?` | 優惠券 ID |
| `couponName` | `String?` | 優惠券名稱 |
| `shippingMethodId` | `int` | 配送方式 ID |
| `shippingMethodName` | `String` | 配送方式名稱 |
| `paymentMethodId` | `int` | 付款方式 ID |
| `paymentMethodName` | `String` | 付款方式名稱 |
| `deliveryType` | `String?` | 配送類型（'convenience_store' / 'home_delivery'） |

**狀態說明**:
- 舊版 `status`: 字串型態（pending, processing, completed, cancelled）
- 新版採用雙狀態設計：
  - `mainStatus`: 訂單主要狀態（待付款、待出貨、待收貨等）
  - `logisticsStatus`: 物流狀態（運送中、已抵達、已簽收）

**使用範例**:
```dart
final order = Order()
  ..orderNumber = '20250117-0001'
  ..createdAt = DateTime.now()
  ..mainStatus = OrderMainStatus.pendingPayment
  ..logisticsStatus = LogisticsStatus.none
  ..subtotal = 4500
  ..discount = 100
  ..shippingFee = 60
  ..total = 4460
  ..deliveryType = 'convenience_store';
```

**位置**: [order.dart:8](order.dart#L8)

---

### OrderItem
**檔案**: [order.dart](order.dart)

**用途**: 訂單項目資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `orderId` | `int` | 關聯的訂單 ID（外鍵） |
| `productId` | `int` | 商品 ID |
| `productName` | `String` | 商品名稱（快照） |
| `specification` | `String` | 規格 |
| `unitPrice` | `double` | 單價（快照） |
| `quantity` | `int` | 數量 |
| `subtotal` | `double` | 小計（unitPrice × quantity） |

**關聯**:
- 多對一關聯 `Order`（一個訂單有多個項目）

**位置**: [order.dart:72](order.dart#L72)

---

### OrderStatusHistory
**檔案**: [order_status.dart](order_status.dart)

**用途**: 訂單狀態歷史記錄

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `orderId` | `int` | 關聯的訂單 ID |
| `mainStatus` | `OrderMainStatus` | 主要狀態（枚舉） |
| `logisticsStatus` | `LogisticsStatus` | 物流狀態（枚舉） |
| `description` | `String` | 狀態描述（如："訂單成立"、"賣家已確認"） |
| `timestamp` | `DateTime` | 狀態變更時間 |
| `note` | `String?` | 備註（可選） |

**用途說明**: 記錄訂單狀態的每次變更，方便追蹤訂單流程

**位置**: [order_status.dart:43](order_status.dart#L43)

---

### OrderStatusTimestamps
**檔案**: [order_status.dart](order_status.dart)

**用途**: 訂單狀態時間戳記錄（一對一關聯）

**欄位結構**:

**主要狀態時間戳**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `orderId` | `int` | 關聯的訂單 ID（唯一索引） |
| `createdAt` | `DateTime` | 訂單建立時間 |
| `pendingPaymentAt` | `DateTime?` | 待付款時間 |
| `paidAt` | `DateTime?` | 付款完成時間 |
| `pendingShipmentAt` | `DateTime?` | 待出貨時間 |
| `pendingDeliveryAt` | `DateTime?` | 待收貨時間 |
| `completedAt` | `DateTime?` | 訂單完成時間 |
| `returnRefundAt` | `DateTime?` | 退貨/退款時間 |
| `invalidAt` | `DateTime?` | 訂單不成立時間 |

**物流狀態時間戳**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `inTransitAt` | `DateTime?` | 開始運送時間 |
| `arrivedAtPickupPointAt` | `DateTime?` | 抵達收貨地點時間 |
| `signedAt` | `DateTime?` | 簽收時間 |

**設計說明**:
- 與 `Order` 是一對一關聯
- 透過 `@Index(unique: true)` 確保唯一性
- 方便計算各階段耗時

**位置**: [order_status.dart:71](order_status.dart#L71)

---

### UserProfile
**檔案**: [user_profile.dart](user_profile.dart)

**用途**: 使用者資料模型，與 Firebase Auth 的 UID 關聯

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `userId` | `String` | Firebase Auth UID（唯一索引） |
| `displayName` | `String?` | 使用者名稱（可更改） |
| `email` | `String?` | 電子郵件（從 Firebase Auth 同步） |
| `birthday` | `DateTime?` | 生日 |
| `phoneNumber` | `String?` | 手機號碼 |
| `membershipLevel` | `String?` | 會員等級（'regular', 'silver', 'gold', 'platinum'） |
| `membershipPoints` | `int?` | 會員點數 |
| `walletBalance` | `double?` | 錢包餘額 |
| `createdAt` | `DateTime?` | 建立時間 |
| `updatedAt` | `DateTime?` | 更新時間 |

**索引**:
- `userId` 欄位設有唯一索引 `@Index(unique: true)`

**使用範例**:
```dart
final profile = UserProfile()
  ..userId = 'firebase-uid-123'
  ..displayName = '王小明'
  ..email = 'user@example.com'
  ..membershipLevel = 'regular'
  ..membershipPoints = 100
  ..createdAt = DateTime.now();
```

**位置**: [user_profile.dart:8](user_profile.dart#L8)

---

### UserSettings
**檔案**: [user_settings.dart](user_settings.dart)

**用途**: 使用者設定資料模型（無障礙與顯示設定）

**欄位結構**:
| 欄位 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `id` | `Id` | 自動遞增 | 主鍵 |
| `ttsEnabled` | `bool` | `true` | 是否開啟語音播報 |
| `ttsSpeed` | `double` | `1.0` | 語速 |
| `fontSize` | `double` | `16.0` | 字體大小 |
| `preferredLanguage` | `String?` | `null` | 偏好語言（未來擴充） |

**使用範例**:
```dart
final settings = UserSettings()
  ..ttsEnabled = true
  ..ttsSpeed = 1.2
  ..fontSize = 18.0
  ..preferredLanguage = 'zh-TW';
```

**位置**: [user_settings.dart:6](user_settings.dart#L6)

---

### NotificationModel
**檔案**: [notification.dart](notification.dart)

**用途**: 通知項目資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `Id` | 自動遞增的主鍵 |
| `title` | `String` | 通知標題 |
| `content` | `String` | 通知內容 |
| `type` | `NotificationType` | 通知類型（枚舉） |
| `timestamp` | `DateTime` | 建立時間 |
| `isRead` | `bool` | 是否已讀（有索引） |
| `orderId` | `int?` | 關聯的訂單 ID（僅訂單通知） |
| `orderNumber` | `String?` | 關聯的訂單編號（僅訂單通知） |

**索引**:
- `isRead` 欄位設有索引 `@Index()`，加速查詢未讀通知

**使用範例**:
```dart
final notification = NotificationModel()
  ..title = '訂單已出貨'
  ..content = '您的訂單 #20250117-0001 已出貨'
  ..type = NotificationType.order
  ..timestamp = DateTime.now()
  ..isRead = false
  ..orderId = 1
  ..orderNumber = '20250117-0001';
```

**位置**: [notification.dart:14](notification.dart#L14)

---

## 簡單資料模型 (Plain Dart Classes)

這些模型不使用資料庫持久化，僅用於記憶體中的資料傳遞。

### Coupon
**檔案**: [coupon.dart](coupon.dart)

**用途**: 優惠券資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `int` | 優惠券 ID |
| `name` | `String` | 優惠券名稱 |
| `description` | `String` | 優惠券描述 |
| `discount` | `double` | 折扣金額 |
| `minAmount` | `double` | 最低消費金額 |

**靜態方法**:
- `getSampleCoupons()` - 取得範例優惠券資料

**範例資料**:
1. 新會員優惠 - 滿 1000 折 100
2. 運動季折扣 - 滿 2000 折 300
3. VIP 專屬 - 滿 3000 折 500

**使用範例**:
```dart
final coupons = Coupon.getSampleCoupons();
final coupon = coupons.first;
print('${coupon.name}: ${coupon.description}');
```

**位置**: [coupon.dart:2](coupon.dart#L2)

---

### ShippingMethod
**檔案**: [shipping_method.dart](shipping_method.dart)

**用途**: 配送方式資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `int` | 配送方式 ID |
| `name` | `String` | 配送方式名稱 |
| `description` | `String` | 配送方式描述 |
| `fee` | `double` | 運費 |

**靜態方法**:
- `getSampleMethods()` - 取得範例配送方式

**範例資料**:
1. 超商取貨 - 7-11 或全家門市取貨，運費 60 元
2. 宅配 - 送貨到府，運費 100 元
3. 郵局 - 郵局寄送，運費 80 元

**使用範例**:
```dart
final methods = ShippingMethod.getSampleMethods();
final method = methods.first;
print('${method.name}: ${method.description}, 運費 \$${method.fee}');
```

**位置**: [shipping_method.dart:2](shipping_method.dart#L2)

---

### PaymentMethod
**檔案**: [payment_method.dart](payment_method.dart)

**用途**: 付款方式資料模型

**欄位結構**:
| 欄位 | 類型 | 說明 |
|------|------|------|
| `id` | `int` | 付款方式 ID |
| `name` | `String` | 付款方式名稱 |
| `description` | `String` | 付款方式描述 |

**靜態方法**:
- `getSampleMethods()` - 取得範例付款方式

**範例資料**:
1. 信用卡 - Visa、Master、JCB
2. 貨到付款 - 收到商品時支付現金
3. ATM 轉帳 - 虛擬帳號轉帳

**使用範例**:
```dart
final methods = PaymentMethod.getSampleMethods();
final method = methods.first;
print('${method.name}: ${method.description}');
```

**位置**: [payment_method.dart:2](payment_method.dart#L2)

---

## 枚舉與擴展

### OrderMainStatus
**檔案**: [order_status.dart](order_status.dart)

**用途**: 訂單主要狀態枚舉

**枚舉值**:
| 值 | 顯示名稱 | 說明 |
|---|---------|------|
| `pendingPayment` | 待付款 | 訂單成立，等待付款 |
| `pendingShipment` | 待出貨 | 已付款，等待賣家出貨 |
| `pendingDelivery` | 待收貨 | 已出貨，等待買家收貨 |
| `completed` | 訂單已完成 | 訂單完成 |
| `returnRefund` | 退貨/退款 | 退貨或退款處理中 |
| `invalid` | 不成立 | 訂單不成立 |

**擴展方法**:
- `displayName` - 取得狀態的中文顯示名稱

**使用範例**:
```dart
final status = OrderMainStatus.pendingPayment;
print(status.displayName); // 輸出: 待付款
```

**位置**: [order_status.dart:6](order_status.dart#L6)

---

### LogisticsStatus
**檔案**: [order_status.dart](order_status.dart)

**用途**: 物流狀態枚舉（僅適用於待收貨訂單）

**枚舉值**:
| 值 | 顯示名稱 | 說明 |
|---|---------|------|
| `none` | 無 | 非待收貨狀態 |
| `inTransit` | 運送中 | 物流運送中 |
| `arrivedAtPickupPoint` | 已抵達收貨地點 | 已抵達超商取貨點 |
| `signed` | 已簽收 | 買家已簽收 |

**擴展方法**:
- `displayName` - 取得狀態的中文顯示名稱

**使用範例**:
```dart
final status = LogisticsStatus.inTransit;
print(status.displayName); // 輸出: 運送中
```

**位置**: [order_status.dart:27](order_status.dart#L27)

---

### NotificationType
**檔案**: [notification.dart](notification.dart)

**用途**: 通知類型枚舉

**枚舉值**:
| 值 | 說明 |
|---|------|
| `order` | 訂單通知 |
| `promotion` | 促銷通知 |
| `system` | 系統通知 |

**使用範例**:
```dart
final type = NotificationType.order;
```

**位置**: [notification.dart:6](notification.dart#L6)

---

## 模型關聯圖

```
Store (商家)
  └── 1:N → Product (商品)

Product (商品)
  └── 1:N → CartItem (購物車項目)

Order (訂單)
  ├── 1:N → OrderItem (訂單項目)
  ├── 1:1 → OrderStatusTimestamps (狀態時間戳)
  ├── 1:N → OrderStatusHistory (狀態歷史)
  └── 1:N → NotificationModel (通知)

UserProfile (使用者資料)
  └── 關聯 Firebase Auth UID

UserSettings (使用者設定)
  └── 單獨儲存（未與使用者直接關聯）

NotificationModel (通知)
  └── N:1 → Order (訂單) [可選]

---

簡單模型（不持久化）:
- Coupon (優惠券)
- ShippingMethod (配送方式)
- PaymentMethod (付款方式)
```

---

## 資料庫生成檔案

以下檔案由 Isar 的 `build_runner` 自動生成，**請勿手動編輯**：

- `store.g.dart`
- `product.g.dart`
- `cart_item.g.dart`
- `user_settings.g.dart`
- `user_profile.g.dart`
- `order.g.dart`
- `order_status.g.dart`
- `notification.g.dart`

**生成指令**:
```bash
flutter pub run build_runner build
```

**重新生成指令**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 設計模式與最佳實踐

### 1. 資料快照 (Snapshot Pattern)
`CartItem` 和 `OrderItem` 儲存商品名稱和價格的快照，避免原始商品資料變動影響已存在的購物車或訂單。

```dart
// ✅ 正確：儲存快照
final cartItem = CartItem()
  ..productId = product.id
  ..name = product.name  // 快照
  ..unitPrice = product.price;  // 快照

// ❌ 錯誤：只儲存 ID
final cartItem = CartItem()
  ..productId = product.id;  // 如果商品被刪除或改價，會有問題
```

### 2. 雙狀態設計
訂單使用雙狀態設計（`mainStatus` + `logisticsStatus`），提供更細緻的狀態追蹤：

```dart
// 訂單在「待收貨」階段，物流可以有多個子狀態
order.mainStatus = OrderMainStatus.pendingDelivery;
order.logisticsStatus = LogisticsStatus.inTransit;  // 運送中

// 後續更新物流狀態
order.logisticsStatus = LogisticsStatus.arrivedAtPickupPoint;  // 已抵達超商
order.logisticsStatus = LogisticsStatus.signed;  // 已簽收
```

### 3. 索引優化
對常用查詢欄位設置索引，提升查詢效能：

```dart
@Index(unique: true)
late String userId;  // 唯一索引

@Index()
late bool isRead;  // 一般索引
```

### 4. 可選欄位
使用 `?` 標記可選欄位，避免強制要求所有資料：

```dart
String? imageUrl;  // 圖片 URL 可為空
int? couponId;  // 優惠券可為空
```

### 5. 枚舉擴展
為枚舉添加擴展方法，提供更友善的顯示名稱：

```dart
extension OrderMainStatusExtension on OrderMainStatus {
  String get displayName {
    switch (this) {
      case OrderMainStatus.pendingPayment:
        return '待付款';
      // ...
    }
  }
}

// 使用
print(order.mainStatus.displayName);
```

---

## 訂單狀態流程圖

### 貨到付款流程
```
訂單成立 → 待付款 (pendingPayment)
          ↓ [1分鐘後自動確認]
        待出貨 (pendingShipment)
          ↓ [1小時後自動出貨]
        待收貨 (pendingDelivery) + 運送中 (inTransit)
          ↓ [1小時後]
        待收貨 (pendingDelivery) + 已抵達收貨地點 (arrivedAtPickupPoint) [超商]
          ↓ [1小時後]
        待收貨 (pendingDelivery) + 已簽收 (signed)
          ↓ [買家確認]
        訂單已完成 (completed)
```

### 線上付款流程
```
訂單成立 → 待出貨 (pendingShipment) [已付款]
          ↓ [1小時後自動出貨]
        待收貨 (pendingDelivery) + 運送中 (inTransit)
          ↓
        [後續同貨到付款]
```

---

## 常見使用場景

### 場景 1: 建立訂單
```dart
// 1. 取得購物車已選取項目
final cartItems = await db.getCartItems()
    .where((item) => item.isSelected)
    .toList();

// 2. 建立訂單
final order = await db.createOrder(
  cartItems: cartItems,
  couponId: 1,
  couponName: '新會員優惠',
  discount: 100,
  shippingMethodId: 1,
  shippingMethodName: '超商取貨',
  shippingFee: 60,
  paymentMethodId: 2,
  paymentMethodName: '貨到付款',
  isCashOnDelivery: true,
  deliveryType: 'convenience_store',
);

// 3. 清除已結帳的購物車項目
await db.clearSelectedCartItems();
```

### 場景 2: 查詢訂單狀態歷史
```dart
// 取得訂單狀態歷史
final history = await orderStatusService.getOrderStatusHistory(orderId);

// 顯示狀態變更時間軸
for (var record in history) {
  print('${record.timestamp}: ${record.description}');
  // 輸出範例:
  // 2025-01-17 10:30:00: 訂單成立（貨到付款）
  // 2025-01-17 10:31:00: 賣家已確認訂單
  // 2025-01-17 11:31:00: 賣家已出貨，開始運送
}
```

### 場景 3: 搜尋商品
```dart
// 智能搜尋，支援名稱、描述、分類
final products = await db.searchProducts('Nike');

// 結果按相關度排序：
// 1. 完全匹配 > 2. 開頭匹配 > 3. 包含關鍵字
```

### 場景 4: 通知管理
```dart
// 取得未讀通知數量
final unreadCount = await db.getUnreadNotificationCount();

// 取得所有通知
final notifications = await db.getNotifications();

// 標記為已讀
await db.markNotificationAsRead(notificationId);

// 清除所有已讀通知
await db.clearReadNotifications();
```

---

## 更新紀錄

- **2025-01-23**: 初始版本，記錄所有 models 資料夾中的資料模型
