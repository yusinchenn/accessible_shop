# 修復：訂單建立失敗 - 唯一索引衝突

## 問題描述

建立訂單時出現錯誤：
```
IsarError: Unique index violated.
```

## 問題原因

`OrderStatusTimestamps` 模型中的 `orderId` 欄位有唯一索引約束（`@Index(unique: true)`），但在建立訂單的過程中，這個記錄被創建了兩次，導致衝突。

### 衝突流程

1. `database_service.dart` 的 `createOrder()` 方法創建訂單
2. 創建 `OrderStatusTimestamps` 記錄（第一次）
3. 創建 `OrderStatusHistory` 記錄
4. 某處調用 `order_status_service.dart` 的 `_updateTimestamps()`
5. `_updateTimestamps()` 發現記錄不存在，又創建一次（第二次）
6. **唯一索引衝突** ❌

## 解決方案

### 修改 1: database_service.dart

確保在創建訂單時正確初始化 `OrderStatusTimestamps` 記錄，並使用相同的時間戳。

**檔案**: `lib/services/database_service.dart`
**位置**: 第 393-421 行

```dart
// 創建訂單狀態時間戳記錄（在創建歷史記錄之前）
final now = DateTime.now();
final timestamps = OrderStatusTimestamps()
  ..orderId = order.id
  ..createdAt = now;

// 根據付款方式設定對應的時間戳
if (isCashOnDelivery) {
  timestamps.pendingPaymentAt = now;
} else {
  timestamps.paidAt = now;
  timestamps.pendingShipmentAt = now;
}

await isar.writeTxn(() async {
  await isar.orderStatusTimestamps.put(timestamps);
});

// 創建訂單狀態歷史記錄
final history = OrderStatusHistory()
  ..orderId = order.id
  ..mainStatus = initialStatus
  ..logisticsStatus = LogisticsStatus.none
  ..description = isCashOnDelivery ? '訂單成立（貨到付款）' : '訂單成立（線上付款已完成）'
  ..timestamp = now;

await isar.writeTxn(() async {
  await isar.orderStatusHistorys.put(history);
});
```

### 修改 2: order_status_service.dart

在 `_updateTimestamps()` 方法中加入日誌，以便追蹤何時會創建新記錄。

**檔案**: `lib/services/order_status_service.dart`
**位置**: 第 62-72 行

```dart
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
```

## 驗證修復

### 測試步驟

1. 清除應用資料（可選，確保乾淨的測試環境）
2. 啟動應用
3. 加入商品到購物車
4. 進入結帳流程
5. 選擇配送方式和付款方式
6. 提交訂單
7. 檢查 Console 日誌

### 預期結果

**成功情況**:
```
📦 [DatabaseService] 建立訂單: 20251023-0001, 共 1 項商品, 總金額: $XXX, 狀態: pendingPayment
🤖 [OrderAutomationService] 新訂單建立: #20251023-0001, 狀態: 待付款
✅ 訂單建立成功
```

**不應該看到**:
- `❌ [CheckoutPage] 建立訂單失敗: IsarError: Unique index violated.`
- `⚠️ [OrderStatusService] 為訂單 #XXX 創建時間戳記錄（補救措施）`（在新訂單創建時）

### 如果仍然失敗

如果問題持續，檢查以下幾點：

1. **確認修改已應用**: 重新啟動應用，確保程式碼變更生效

2. **清除應用資料**:
   ```bash
   # Android
   adb shell pm clear com.example.accessible_shop
   ```

3. **檢查資料庫 Schema**:
   ```bash
   flutter clean
   flutter pub get
   ```

4. **查看完整堆疊追蹤**: 在 Console 中搜尋錯誤訊息並查看完整的堆疊追蹤

## 相關檔案

- `lib/services/database_service.dart` - 訂單建立服務 ✅ 已修改
- `lib/services/order_status_service.dart` - 訂單狀態服務 ✅ 已修改
- `lib/models/order_status.dart` - 訂單狀態模型（含 OrderStatusTimestamps）
- `lib/pages/checkout/checkout_page.dart` - 結帳頁面

## 技術細節

### OrderStatusTimestamps 模型

```dart
@Collection()
class OrderStatusTimestamps {
  Id id = Isar.autoIncrement;

  @Index(unique: true)  // ← 唯一索引約束
  late int orderId;

  late DateTime createdAt;
  // ... 其他時間戳欄位
}
```

### 唯一索引約束

`@Index(unique: true)` 確保每個訂單只有一條時間戳記錄。如果嘗試插入相同 `orderId` 的記錄，Isar 會拋出 `IsarError: Unique index violated` 錯誤。

### 為什麼需要時間戳記錄？

時間戳記錄用於：
1. 追蹤訂單各個狀態的時間
2. 計算訂單處理時長
3. 訂單自動更新系統依賴這些時間戳判斷何時該轉換狀態
4. 評論功能計算是否在30天內

## 預防措施

為了避免未來出現類似問題：

1. **統一創建點**: 盡量在一個地方創建 `OrderStatusTimestamps` 記錄
2. **檢查存在性**: 在創建前先檢查記錄是否已存在
3. **使用 upsert**: 考慮使用 Isar 的 upsert 操作
4. **加入測試**: 為訂單建立流程加入自動化測試

## 修復狀態

✅ 已修復
📅 修復日期: 2025-01-23
👤 修復者: Claude

## 參考

- Isar 文檔: https://isar.dev/
- Unique Index: https://isar.dev/schema.html#unique-index
