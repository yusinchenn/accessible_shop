# 訂單狀態管理系統說明

## 概述

本系統實現了完整的訂單狀態管理流程，包含自動化的賣家操作和物流模擬。

## 訂單狀態分類

### 主要狀態 (OrderMainStatus)

1. **待付款 (pendingPayment)**
   - 貨到付款訂單在建立時會進入此狀態
   - 賣家會在訂單成立後 1 分鐘自動確認訂單

2. **待出貨 (pendingShipment)**
   - 線上付款訂單建立後直接進入此狀態
   - 貨到付款訂單在賣家確認後進入此狀態
   - 賣家會在訂單進入此狀態後 1 小時自動出貨

3. **待收貨 (pendingDelivery)**
   - 賣家出貨後進入此狀態
   - 此狀態下會有額外的物流狀態

4. **訂單已完成 (completed)**
   - 買家在商品簽收後手動點擊「完成訂單」按鈕進入此狀態

5. **退貨/退款 (returnRefund)**
   - 保留狀態，供未來擴充使用

6. **不成立 (invalid)**
   - 保留狀態，供未來擴充使用

### 物流狀態 (LogisticsStatus)

僅在「待收貨」狀態下有效：

1. **運送中 (inTransit)**
   - 賣家出貨後的初始物流狀態
   - 超商取貨：1 小時後自動變更為「已抵達收貨地點」
   - 宅配：1 小時後自動變更為「已簽收」

2. **已抵達收貨地點 (arrivedAtPickupPoint)**
   - 僅適用於超商取貨
   - 1 小時後自動變更為「已簽收」

3. **已簽收 (signed)**
   - 買家可以點擊「完成訂單」按鈕
   - 完成後訂單進入「訂單已完成」狀態

## 資料庫結構

### 新增的 Collection

1. **OrderStatusHistory** - 訂單狀態歷史記錄
   - 記錄每次狀態變更的時間和描述
   - 可追蹤完整的訂單生命週期

2. **OrderStatusTimestamps** - 訂單狀態時間戳
   - 記錄各個狀態的時間點
   - 一對一關聯到訂單

### 更新的 Collection

**Order** - 新增欄位：
- `mainStatus` - 主要訂單狀態（enum）
- `logisticsStatus` - 物流狀態（enum）
- `deliveryType` - 配送方式類型（'convenience_store' 或 'home_delivery'）

## 服務架構

### 1. OrderStatusService
- 管理訂單狀態變更
- 記錄狀態歷史
- 更新時間戳

### 2. SellerService
- 模擬賣家操作
- 自動確認待付款訂單（1分鐘後）
- 自動出貨待出貨訂單（1小時後）

### 3. LogisticsService
- 模擬物流操作
- 根據配送方式自動更新物流狀態
- 超商取貨：運送中 → 已抵達 → 已簽收（各1小時）
- 宅配：運送中 → 已簽收（1小時）

### 4. OrderAutomationService
- 統一管理上述三個服務
- 在應用啟動時掃描並監控現有訂單
- 處理新訂單的自動化流程

## 使用方式

### 1. 運行 build_runner 生成代碼

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. 在應用中初始化服務

在 `main.dart` 或應用啟動處添加：

```dart
import 'services/order_automation_service.dart';

// 在應用初始化時
final databaseService = DatabaseService();
final orderAutomationService = OrderAutomationService(databaseService);

// 初始化自動化服務
await orderAutomationService.initialize();
```

### 3. 創建訂單時觸發自動化

```dart
// 創建訂單後
final order = await db.createOrder(...);
await orderAutomationService.onOrderCreated(order);
```

### 4. 買家完成訂單

在訂單歷史頁面，已簽收的訂單會顯示「完成訂單」按鈕：

```dart
await orderStatusService.completeOrder(orderId);
```

## 訂單流程圖

### 貨到付款流程
```
訂單建立 (待付款)
    ↓ (1分鐘後自動)
賣家確認 (待出貨)
    ↓ (1小時後自動)
賣家出貨 (待收貨/運送中)
    ↓ (根據配送方式自動)
物流狀態變更
    ↓ (買家手動)
訂單已完成
```

### 線上付款流程
```
訂單建立 (待出貨)
    ↓ (1小時後自動)
賣家出貨 (待收貨/運送中)
    ↓ (根據配送方式自動)
物流狀態變更
    ↓ (買家手動)
訂單已完成
```

### 超商取貨物流
```
運送中
    ↓ (1小時後)
已抵達收貨地點
    ↓ (1小時後)
已簽收
```

### 宅配物流
```
運送中
    ↓ (1小時後)
已簽收
```

## 注意事項

1. 自動化計時器在應用重啟時會重新掃描並建立
2. 所有狀態變更都會記錄到歷史和時間戳表中
3. 訂單完成後會自動取消監控，停止計時器
4. 建議在測試時將計時器時間縮短以便快速驗證功能

## 測試建議

### 快速測試模式
如需快速測試，可將計時器時間修改為：
- 待付款 → 待出貨：10秒（原1分鐘）
- 待出貨 → 待收貨：30秒（原1小時）
- 物流狀態變更：30秒（原1小時）

修改位置：
- `seller_service.dart` - Timer duration
- `logistics_service.dart` - Timer duration

## 擴充功能建議

1. 實作退貨/退款流程
2. 新增訂單取消功能
3. 實作訂單不成立的條件判斷
4. 新增更多物流狀態（如「配送失敗」、「重新配送」等）
5. 實作手動操作介面（賣家後台）
6. 新增訂單狀態推播通知