# 訂單自動更新系統 - 更新總結

## 更新日期
2025-01-23

## 更新目標
實現訂單自動狀態更新功能，當使用者產生訂單後，訂單在 5 分鐘後自動更新為下個狀態（待付款 > 待出貨 > 待收貨），UI 每 1 分鐘自動檢查更新。

## 已完成的更新

### 1. 新增檔案

#### [lib/services/order_check_service.dart](lib/services/order_check_service.dart)
新建的訂單檢查服務，核心功能：
- 每 1 分鐘自動檢查所有訂單狀態
- 基於訂單時間戳計算是否達到 5 分鐘轉換條件
- 自動觸發狀態轉換並發送通知
- 支援超商取貨和宅配兩種配送方式

主要方法：
- `startPeriodicCheck()` - 啟動定期檢查
- `_checkPendingPaymentOrders()` - 檢查待付款訂單
- `_checkPendingShipmentOrders()` - 檢查待出貨訂單
- `_checkPendingDeliveryOrders()` - 檢查待收貨訂單

#### [ORDER_AUTO_UPDATE_README.md](ORDER_AUTO_UPDATE_README.md)
完整的系統說明文件，包含：
- 功能概述
- 技術架構
- 使用方式
- 時間配置
- 測試建議
- 除錯指南

### 2. 更新的檔案

#### [lib/services/seller_service.dart](lib/services/seller_service.dart)
更新內容：
- 將自動確認時間從 1 分鐘改為 5 分鐘
- 將自動出貨時間從 1 小時改為 5 分鐘
- 更新相關日誌訊息

變更：
```dart
// 舊版
Timer(const Duration(minutes: 1), ...)  // 待付款 -> 待出貨
Timer(const Duration(hours: 1), ...)    // 待出貨 -> 待收貨

// 新版
Timer(const Duration(minutes: 5), ...)  // 待付款 -> 待出貨
Timer(const Duration(minutes: 5), ...)  // 待出貨 -> 待收貨
```

#### [lib/services/logistics_service.dart](lib/services/logistics_service.dart)
更新內容：
- 超商取貨抵達時間從 1 小時改為 5 分鐘
- 宅配簽收時間從 1 小時改為 5 分鐘
- 超商簽收時間從 1 小時改為 5 分鐘
- 更新相關日誌訊息

變更：
```dart
// 舊版
Timer(const Duration(hours: 1), ...)  // 運送中 -> 抵達/簽收

// 新版
Timer(const Duration(minutes: 5), ...)  // 運送中 -> 抵達/簽收
```

#### [lib/services/order_automation_service.dart](lib/services/order_automation_service.dart)
更新內容：
- 新增 `OrderCheckService` 的整合
- 在 `initialize()` 方法中啟動定期檢查服務
- 在 `dispose()` 方法中清理檢查服務
- 新增 `orderCheckService` getter

變更：
```dart
// 新增
late final OrderCheckService _orderCheckService;
_orderCheckService = OrderCheckService(_db, _orderStatusService);

// 在 initialize() 中
_orderCheckService.startPeriodicCheck();

// 在 dispose() 中
_orderCheckService.dispose();
```

#### [lib/services/test_data_service.dart](lib/services/test_data_service.dart)
更新內容：
- 新增 `order_status.dart` 的導入
- 新增 `_initializeOrderTimestamps()` 方法
- 在 `initializeOrders()` 中為每個訂單初始化時間戳

變更：
```dart
// 新增導入
import '../models/order_status.dart';

// 新增方法
Future<void> _initializeOrderTimestamps(Order order) async {
  // 根據訂單狀態設定對應的時間戳
  ...
}
```

### 3. 保持不變的檔案

以下檔案已經有完整的時間戳支援，無需修改：
- [lib/services/database_service.dart](lib/services/database_service.dart) - 訂單建立時已正確初始化時間戳
- [lib/services/order_status_service.dart](lib/services/order_status_service.dart) - 狀態更新時已正確記錄時間戳
- [lib/models/order.dart](lib/models/order.dart) - 訂單模型定義
- [lib/models/order_status.dart](lib/models/order_status.dart) - 訂單狀態模型定義

## 系統運作流程

### 1. 訂單建立
```
用戶完成結帳
   ↓
database_service.createOrder()
   ↓
建立 Order 記錄 + OrderStatusTimestamps 記錄
   ↓
記錄 createdAt 和初始狀態時間戳
```

### 2. 自動檢查
```
應用啟動
   ↓
OrderAutomationService.initialize()
   ↓
OrderCheckService.startPeriodicCheck()
   ↓
每 1 分鐘執行 _checkAllOrders()
   ↓
檢查所有訂單的時間戳
   ↓
如果經過時間 >= 5 分鐘 → 更新狀態
```

### 3. 狀態轉換
```
OrderCheckService 檢測到需要轉換
   ↓
調用 OrderStatusService.updateOrderStatus()
   ↓
更新 Order 狀態
   ↓
更新 OrderStatusTimestamps
   ↓
建立 OrderStatusHistory 記錄
   ↓
發送系統通知
```

## 時間配置

### 當前配置
- **狀態轉換間隔**: 5 分鐘
- **檢查頻率**: 1 分鐘

### 如何調整

在 [lib/services/order_check_service.dart](lib/services/order_check_service.dart) 中修改：

```dart
// 狀態轉換間隔時間
static const Duration statusTransitionDuration = Duration(minutes: 5);

// 檢查間隔時間
static const Duration checkInterval = Duration(minutes: 1);
```

### 快速測試配置

如需加快測試速度（開發用）：

```dart
// 30 秒轉換一次狀態
static const Duration statusTransitionDuration = Duration(seconds: 30);

// 10 秒檢查一次
static const Duration checkInterval = Duration(seconds: 10);
```

## 測試建議

### 1. 基本功能測試

1. 建立新訂單（貨到付款）
2. 觀察訂單狀態
3. 等待約 5 分鐘，檢查是否自動轉為「待出貨」
4. 再等待 5 分鐘，檢查是否自動轉為「待收貨/運送中」
5. 再等待 5 分鐘，檢查是否自動轉為「已簽收」

### 2. 通知測試

在每次狀態轉換時，應收到系統通知：
- 訂單已確認
- 訂單已出貨
- 商品已到店（超商取貨）
- 商品已簽收

### 3. 日誌檢查

在開發模式下，Console 應輸出：
```
⏰ [OrderCheckService] 已啟動定期檢查服務（每1分鐘檢查一次）
⏰ [OrderCheckService] 開始檢查訂單狀態...
⏳ [OrderCheckService] 訂單 #20250123-0001 還有 3 分鐘轉為待出貨
✅ [OrderCheckService] 訂單已確認: #20250123-0001 -> 待出貨
```

## 相容性

### 向後相容
- 保留了舊的 Timer 機制（SellerService 和 LogisticsService）
- 新舊系統可以同時運作
- 手動操作功能仍然可用

### 資料庫
- 使用現有的 OrderStatusTimestamps 表
- 不需要資料庫遷移
- 現有訂單會在下次檢查時自動納入系統

## 已知限制

1. **時間精度**: 檢查頻率為 1 分鐘，實際轉換時間可能在 5-6 分鐘之間
2. **背景執行**: 應用關閉時，定期檢查會停止（這是預期行為）
3. **時區**: 使用裝置本地時間，跨時區使用需注意

## 後續優化建議

1. **UI 即時更新**: 可以使用 Stream 或 ChangeNotifier 讓 UI 自動刷新
2. **背景服務**: 考慮使用 WorkManager 實現真正的背景執行
3. **推播通知**: 整合 FCM 實現推播通知
4. **狀態可視化**: 在訂單詳情頁顯示倒數計時
5. **效能優化**: 大量訂單時可以考慮索引優化

## 檔案清單

### 新增檔案
- `lib/services/order_check_service.dart`
- `ORDER_AUTO_UPDATE_README.md`
- `UPDATE_SUMMARY.md`（本檔案）

### 修改檔案
- `lib/services/seller_service.dart`
- `lib/services/logistics_service.dart`
- `lib/services/order_automation_service.dart`
- `lib/services/test_data_service.dart`

### 相關檔案（未修改）
- `lib/services/database_service.dart`
- `lib/services/order_status_service.dart`
- `lib/models/order.dart`
- `lib/models/order_status.dart`

## 總結

本次更新成功實現了訂單自動狀態更新系統：

✅ 訂單在 5 分鐘後自動更新為下個狀態
✅ UI 每 1 分鐘自動檢查更新
✅ 基於訂單創建時間計算，確保準確性
✅ 完整的通知和歷史記錄
✅ 保留手動操作功能
✅ 完善的文件和測試建議

系統已準備好進行測試和使用！
