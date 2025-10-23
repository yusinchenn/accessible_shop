# 訂單自動更新系統說明

## 概述

本系統實現了訂單狀態的自動更新功能，模擬賣家和物流的實際操作流程。系統會根據訂單的創建時間自動推進訂單狀態，每個狀態持續 5 分鐘後自動轉換到下一個狀態。

## 核心功能

### 1. 自動狀態轉換

訂單狀態會按照以下流程自動轉換（每個狀態持續 5 分鐘）：

```
待付款 (5分鐘) → 待出貨 (5分鐘) → 待收貨/運送中 (5分鐘) → 已簽收
```

#### 詳細流程：

- **待付款** → **待出貨**（5分鐘後）
  - 模擬賣家確認訂單
  - 系統通知：「訂單已確認」

- **待出貨** → **待收貨/運送中**（5分鐘後）
  - 模擬賣家出貨
  - 系統通知：「訂單已出貨」

- **運送中** → **已抵達超商**（5分鐘後，僅超商取貨）
  - 模擬商品送達超商
  - 系統通知：「商品已到店」

- **運送中** → **已簽收**（5分鐘後，宅配）
  - 模擬宅配直接簽收
  - 系統通知：「商品已簽收」

- **已抵達超商** → **已簽收**（5分鐘後）
  - 模擬買家取貨
  - 系統通知：「商品已簽收」

### 2. 每分鐘自動檢查

系統會每 1 分鐘自動檢查所有訂單的狀態，比對當前時間與訂單時間戳，判斷是否需要更新狀態。

## 技術架構

### 核心服務

#### 1. OrderCheckService（訂單檢查服務）
- **檔案位置**: `lib/services/order_check_service.dart`
- **功能**:
  - 每分鐘定期檢查所有訂單
  - 根據時間戳計算是否需要更新狀態
  - 自動觸發狀態轉換

#### 2. OrderAutomationService（訂單自動化服務）
- **檔案位置**: `lib/services/order_automation_service.dart`
- **功能**:
  - 統一管理所有自動化服務
  - 在應用啟動時初始化檢查服務
  - 提供手動操作接口

#### 3. SellerService（賣家服務）
- **檔案位置**: `lib/services/seller_service.dart`
- **功能**:
  - 模擬賣家確認訂單（待付款 → 待出貨）
  - 模擬賣家出貨（待出貨 → 待收貨）
  - 保留手動操作功能

#### 4. LogisticsService（物流服務）
- **檔案位置**: `lib/services/logistics_service.dart`
- **功能**:
  - 模擬物流運送過程
  - 處理超商取貨和宅配兩種情況
  - 保留手動操作功能

### 資料模型

#### OrderStatusTimestamps（訂單狀態時間戳）
- **檔案位置**: `lib/models/order_status.dart`
- **用途**: 記錄訂單每個狀態的時間戳
- **關鍵欄位**:
  - `createdAt`: 訂單建立時間
  - `pendingPaymentAt`: 待付款時間
  - `pendingShipmentAt`: 待出貨時間
  - `pendingDeliveryAt`: 待收貨時間
  - `inTransitAt`: 運送中時間
  - `arrivedAtPickupPointAt`: 抵達超商時間
  - `signedAt`: 簽收時間
  - `completedAt`: 完成時間

## 使用方式

### 在應用中啟用自動更新

自動更新服務會在應用啟動時自動初始化：

```dart
// 通常在 main.dart 或應用初始化時
final orderAutomationService = OrderAutomationService(databaseService);
await orderAutomationService.initialize();
```

### 創建新訂單

當用戶完成結帳時，系統會自動：
1. 創建訂單記錄
2. 初始化訂單時間戳
3. 創建狀態歷史記錄
4. 啟動自動檢查（無需額外操作）

### 監控訂單狀態

系統會：
- 每 1 分鐘自動檢查所有訂單
- 自動更新符合條件的訂單狀態
- 發送系統通知給用戶
- 記錄狀態歷史

## 時間配置

### 狀態轉換間隔
- **預設**: 5 分鐘
- **配置位置**: `OrderCheckService.statusTransitionDuration`
- **可調整**: 修改 `Duration(minutes: 5)` 即可

### 檢查頻率
- **預設**: 1 分鐘
- **配置位置**: `OrderCheckService.checkInterval`
- **可調整**: 修改 `Duration(minutes: 1)` 即可

## 測試建議

### 1. 快速測試（開發環境）

如需加快測試速度，可以臨時調整時間：

```dart
// 在 order_check_service.dart 中修改
static const Duration statusTransitionDuration = Duration(seconds: 30); // 改為30秒
static const Duration checkInterval = Duration(seconds: 10); // 改為10秒檢查
```

### 2. 手動觸發狀態轉換

系統保留了手動操作功能，可用於測試或特殊情況：

```dart
// 手動確認訂單
await orderAutomationService.manualConfirmOrder(orderId);

// 手動出貨
await orderAutomationService.manualShipOrder(orderId);

// 手動標記抵達超商
await orderAutomationService.manualArriveAtPickupPoint(orderId);

// 手動簽收
await orderAutomationService.manualSignOrder(orderId);
```

### 3. 查看訂單狀態歷史

```dart
final history = await orderStatusService.getOrderStatusHistory(orderId);
for (var record in history) {
  print('${record.timestamp}: ${record.description}');
}
```

## 除錯模式

在開發模式下（`kDebugMode`），系統會輸出詳細的日誌：

```
⏰ [OrderCheckService] 已啟動定期檢查服務（每1分鐘檢查一次）
⏰ [OrderCheckService] 開始檢查訂單狀態...
⏳ [OrderCheckService] 訂單 #20250123-0001 還有 3 分鐘轉為待出貨
✅ [OrderCheckService] 訂單已確認: #20250123-0002 -> 待出貨
✅ [OrderCheckService] 訂單檢查完成
```

## 注意事項

1. **時間戳記錄**: 每次狀態轉換都會記錄時間戳，用於計算經過時間
2. **自動通知**: 每次狀態轉換都會自動發送通知給用戶
3. **狀態歷史**: 所有狀態變更都會記錄在歷史記錄中
4. **資源管理**: 應用關閉時會自動清理所有計時器
5. **並行安全**: 系統設計為可以處理多個訂單同時更新

## 系統流程圖

```
用戶下單
   ↓
創建訂單 + 初始化時間戳
   ↓
OrderCheckService 啟動（每1分鐘檢查）
   ↓
檢查時間差是否 >= 5分鐘
   ↓
是 → 更新訂單狀態 → 發送通知 → 記錄歷史
   ↓
否 → 等待下次檢查
   ↓
重複檢查，直到訂單完成
```

## 相關檔案

- `lib/services/order_check_service.dart` - 訂單檢查服務
- `lib/services/order_automation_service.dart` - 訂單自動化服務
- `lib/services/seller_service.dart` - 賣家服務
- `lib/services/logistics_service.dart` - 物流服務
- `lib/services/order_status_service.dart` - 訂單狀態管理
- `lib/models/order_status.dart` - 訂單狀態模型
- `lib/models/order.dart` - 訂單模型

## 更新日誌

### 2025-01-23
- ✅ 實現基於時間戳的自動狀態檢查
- ✅ 設定 5 分鐘自動轉換間隔
- ✅ 實現每 1 分鐘自動檢查機制
- ✅ 保留手動操作功能
- ✅ 完善時間戳記錄系統
