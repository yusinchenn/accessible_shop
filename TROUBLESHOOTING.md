# 訂單建立失敗問題排查指南

## 問題描述
在結帳時出現「建立訂單失敗」的錯誤訊息。

## 已進行的修改
已在 [checkout_page.dart](lib/pages/checkout/checkout_page.dart) 第 917-919 行加入完整的錯誤日誌輸出，包括錯誤訊息和堆疊追蹤。

## 排查步驟

### 1. 查看完整錯誤訊息

重新測試結帳流程，在 Console 中查找以下日誌：
```
❌ [CheckoutPage] 建立訂單失敗: [錯誤訊息]
📍 [CheckoutPage] 堆疊追蹤: [堆疊追蹤]
```

### 2. 可能的原因

#### A. 資料庫未初始化完成
**症狀**: 錯誤訊息包含 "Isar" 或 "database"
**解決方案**:
- 確保在 main.dart 中 DatabaseService 已正確初始化
- 檢查應用啟動時是否有資料庫相關錯誤

#### B. OrderAutomationService 未正確初始化
**症狀**: 錯誤訊息包含 "OrderAutomationService" 或 "null"
**可能原因**:
- `service.initialize()` 是異步方法但在 main.dart 中被同步調用
- 服務內部的 `_sellerService` 或 `_logisticsService` 未初始化

**臨時解決方案**:
將 checkout_page.dart 的第 897 行改為可選調用：
```dart
// 暫時註解以測試
// await automationService.onOrderCreated(order);
```

#### C. 訂單狀態相關問題
**症狀**: 錯誤訊息包含 "OrderMainStatus" 或 "LogisticsStatus"
**可能原因**:
- 模型類別未正確生成
- 需要執行 `flutter pub run build_runner build`

#### D. 時間戳記錄問題
**症狀**: 錯誤訊息包含 "OrderStatusTimestamps"
**可能原因**:
- 資料庫 schema 未更新
- 需要清除應用資料重新初始化

### 3. 快速測試方案

#### 測試 1: 停用自動化服務
在 [checkout_page.dart](lib/pages/checkout/checkout_page.dart) 的 `_createOrder` 方法中：

```dart
// 臨時註解第 896-897 行
// 觸發訂單自動化服務
// await automationService.onOrderCreated(order);
```

如果這樣可以成功建立訂單，問題就在 OrderAutomationService。

#### 測試 2: 簡化訂單建立
檢查 widget.selectedPayment 和 widget.selectedShipping 是否為 null：

```dart
// 在第 867 行之前加入
if (widget.selectedPayment == null) {
  throw Exception('未選擇付款方式');
}
if (widget.selectedShipping == null) {
  throw Exception('未選擇配送方式');
}
```

#### 測試 3: 檢查資料庫連接
在 `_createOrder` 方法開頭加入：

```dart
try {
  final db = Provider.of<DatabaseService>(context, listen: false);
  final isar = await db.isar;
  print('✅ 資料庫連接正常: ${isar.isOpen}');
} catch (e) {
  print('❌ 資料庫連接失敗: $e');
}
```

### 4. 修復 main.dart 中的異步初始化問題

將 [main.dart](lib/main.dart) 第 176-187 行改為：

```dart
ProxyProvider<DatabaseService, OrderAutomationService>(
  create: (context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final service = OrderAutomationService(db);
    // 異步初始化，不阻塞建立
    Future.microtask(() => service.initialize());
    return service;
  },
  update: (context, dbService, previous) {
    if (previous == null) {
      final service = OrderAutomationService(dbService);
      Future.microtask(() => service.initialize());
      return service;
    }
    return previous;
  },
  dispose: (context, service) => service.dispose(),
),
```

### 5. 清理資料庫重新初始化

如果問題持續，嘗試清理應用資料：

**Android**:
```bash
adb shell pm clear com.example.accessible_shop
```

或在設定中：
設定 > 應用程式 > Accessible Shop > 儲存空間 > 清除資料

**然後重新安裝**:
```bash
flutter clean
flutter pub get
flutter run
```

### 6. 檢查是否需要重新生成程式碼

如果是 Windows 系統，可能需要在 PowerShell 或 CMD 中執行：

```bash
# 進入專案目錄
cd d:\dev\accessible_shop

# 清理並重新生成
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 7. 最小化測試配置

為了快速測試訂單自動更新功能，可以將時間改短：

在 [order_check_service.dart](lib/services/order_check_service.dart) 第 24-27 行：

```dart
// 測試用：改為 30 秒轉換
static const Duration statusTransitionDuration = Duration(seconds: 30);

// 測試用：改為 10 秒檢查一次
static const Duration checkInterval = Duration(seconds: 10);
```

這樣可以在 30 秒內看到訂單狀態變化。

## 預期行為

正常情況下，建立訂單應該：

1. 呼叫 `db.createOrder()` 建立訂單
2. 在資料庫中建立 Order 和 OrderItem 記錄
3. 自動建立 OrderStatusTimestamps 記錄
4. 自動建立 OrderStatusHistory 記錄
5. 清除購物車中已結帳的項目
6. 呼叫 `automationService.onOrderCreated(order)` 啟動自動監控
7. 顯示結帳完成頁面

如果任何一步失敗，現在都會顯示完整的錯誤訊息。

## 下一步行動

1. **執行應用並重現問題**
2. **查看 Console 中的完整錯誤訊息**
3. **根據錯誤訊息確定具體原因**
4. **應用對應的解決方案**

## 需要提供的資訊

如果問題持續，請提供：
- 完整的錯誤訊息（❌ [CheckoutPage] 開頭的那幾行）
- 完整的堆疊追蹤（📍 [CheckoutPage] 開頭的那幾行）
- 是否有其他相關的錯誤日誌
- 應用是第一次安裝還是更新後出現問題

## 相關檔案

- [lib/pages/checkout/checkout_page.dart](lib/pages/checkout/checkout_page.dart) - 結帳頁面
- [lib/services/database_service.dart](lib/services/database_service.dart) - 資料庫服務
- [lib/services/order_automation_service.dart](lib/services/order_automation_service.dart) - 訂單自動化服務
- [lib/services/order_check_service.dart](lib/services/order_check_service.dart) - 訂單檢查服務
- [lib/main.dart](lib/main.dart) - 應用入口和服務初始化
