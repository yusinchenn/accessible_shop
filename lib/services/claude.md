# Services 資料夾架構文件

本文件說明 `lib/services/` 資料夾中各個服務的用途、主要功能與使用方式。

## 目錄

1. [核心服務](#核心服務)
2. [無障礙服務](#無障礙服務)
3. [訂單管理服務](#訂單管理服務)
4. [資料庫與測試服務](#資料庫與測試服務)
5. [AI 客戶端服務](#ai-客戶端服務)
6. [暫未實作服務](#暫未實作服務)

---

## 核心服務

### DatabaseService
**檔案**: [database_service.dart](database_service.dart)

**用途**: 管理應用程式的本地資料庫（Isar），提供所有資料模型的 CRUD 操作。

**主要功能**:
- **商家管理**: `getStores()`, `getStoreById(id)`, `getProductsByStoreId(storeId)`
- **商品管理**: `getProducts()`, `getProductById(id)`, `searchProducts(keyword)` - 支援智能搜尋與優先級排序
- **購物車管理**:
  - `getCartItems()`, `addToCart()`, `updateCartItemQuantity()`
  - `toggleCartItemSelection()`, `removeFromCart()`, `clearCart()`
  - `clearSelectedCartItems()` - 結帳後清除已選取項目
- **訂單管理**:
  - `createOrder()` - 建立訂單，支援貨到付款與線上付款
  - `getOrders()`, `getOrderById()`, `getOrderItems()`
  - `updateOrderStatus()`, `generateOrderNumber()`
- **使用者資料管理**:
  - `getUserProfile()`, `saveUserProfile()`
  - `updateDisplayName()`, `updateBirthday()`, `updatePhoneNumber()`
- **通知管理**:
  - `createNotification()`, `createOrderNotification()`
  - `getNotifications()`, `getUnreadNotificationCount()`
  - `markNotificationAsRead()`, `markAllNotificationsAsRead()`
  - `deleteNotification()`, `clearReadNotifications()`

**使用範例**:
```dart
final db = DatabaseService();
final products = await db.getProducts();
await db.addToCart(
  productId: 1,
  productName: 'Nike Air Max',
  price: 4500,
  specification: '尺寸: L / 顏色: 黑色',
);
```

**位置**: [database_service.dart:15](database_service.dart#L15)

---

### AuthService
**檔案**: [auth_service.dart](auth_service.dart)

**用途**: Firebase 身份驗證服務，管理使用者註冊、登入、登出等功能。

**主要功能**:
- `signUpWithEmailPassword()` - Email 和密碼註冊
- `signInWithEmailPassword()` - Email 和密碼登入
- `signOut()` - 登出
- `sendPasswordResetEmail()` - 發送密碼重設郵件
- `currentUser` - 取得當前使用者
- `authStateChanges` - 監聽身份驗證狀態變化
- `_handleAuthException()` - 處理 Firebase Auth 例外，提供中文錯誤訊息

**錯誤處理**: 支援常見錯誤的中文訊息，如密碼強度不足、Email 已被註冊等

**位置**: [auth_service.dart:4](auth_service.dart#L4)

---

### TestDataService
**檔案**: [test_data_service.dart](test_data_service.dart)

**用途**: 初始化和管理測試資料，用於開發與測試環境。

**主要功能**:
- `initializeAllTestData()` - 初始化所有測試資料（商家、商品、使用者設定）
- `clearAllData()` - 清空所有資料
- `initializeStores()` - 初始化 3 家測試商家
- `initializeProducts()` - 初始化 20 個測試商品（分佈於 3 家商家）
- `initializeCartItems()` - 初始化購物車測試資料
- `initializeOrders()` - 初始化訂單測試資料
- `getDatabaseStats()` / `printDatabaseStats()` - 取得/列印資料庫統計資訊

**測試資料內容**:
- **商家**: 運動世界專賣店、健身器材專賣店、戶外探險家
- **商品**: 運動鞋、運動服飾、健身器材、運動配件、球類運動、戶外用品等

**位置**: [test_data_service.dart:10](test_data_service.dart#L10)

---

## 無障礙服務

### AccessibilityService
**檔案**: [accessibility_service.dart](accessibility_service.dart)

**用途**: 偵測系統無障礙模式（TalkBack/VoiceOver），提供相應的語音和手勢策略。

**主要功能**:
- `initialize(context)` - 初始化並監聽系統無障礙狀態
- `shouldUseSystemAccessibility` - 檢查是否應該使用系統無障礙
- `shouldUseCustomTTS` - 檢查是否應該使用自訂 TTS（系統無障礙未開啟時）
- `shouldUseCustomGestures` - 檢查是否應該使用自訂手勢

**設計理念**: 優先使用系統內建無障礙功能，僅在系統無障礙未開啟時啟用自訂功能。

**位置**: [accessibility_service.dart:8](accessibility_service.dart#L8)

---

### GlobalGestureService
**檔案**: [global_gesture_service.dart](global_gesture_service.dart)

**用途**: 提供全域導航手勢支援（兩指上滑回首頁、兩指下滑回上一頁）。

**主要功能**:
- `handleTwoFingerSwipeUp(context)` - 處理兩指上滑（回首頁）
- `handleTwoFingerSwipeDown(context)` - 處理兩指下滑（回上一頁）
- `updateConfig(config)` - 更新手勢配置

**手勢配置** (`GlobalGestureConfig`):
- `enableVoiceFeedback` - 是否啟用語音提示（預設: true）
- `enableHapticFeedback` - 是否啟用觸覺反饋（預設: true）
- `swipeThreshold` - 手勢靈敏度（預設: 50.0 像素）

**位置**: [global_gesture_service.dart:37](global_gesture_service.dart#L37)

---

### FocusNavigationService
**檔案**: [focus_navigation_service.dart](focus_navigation_service.dart)

**用途**: 管理頁面內元素的焦點切換，支援語音朗讀與導航。

**主要功能**:
- **元素管理**:
  - `registerItems(items)` - 註冊頁面的可聚焦元素
  - `clear()` - 清除所有元素
- **導航控制**:
  - `moveToNext()` - 移至下一個元素（右往左滑）
  - `moveToPrevious()` - 移至上一個元素（左往右滑）
  - `moveToIndex(index)` - 移至指定索引
  - `moveToId(id)` - 移至指定 ID 的元素
- **互動動作**:
  - `readCurrent()` - 朗讀當前元素（單擊）
  - `activateCurrent()` - 激活當前元素（雙擊）
- **查詢功能**:
  - `currentItem` - 取得當前聚焦的元素
  - `findIndexById(id)` - 根據 ID 查找元素索引

**元素定義** (`FocusableItem`):
- `id` - 元素標識符
- `label` - 語音朗讀文本
- `type` - 元素類型（如：按鈕、輸入欄、文字）
- `focusNode` - Flutter FocusNode
- `onRead` - 單擊時的動作（朗讀）
- `onActivate` - 雙擊時的動作（激活/選取）
- `key` - 用於滾動定位的 GlobalKey

**位置**: [focus_navigation_service.dart:47](focus_navigation_service.dart#L47)

---

## 訂單管理服務

### OrderAutomationService
**檔案**: [order_automation_service.dart](order_automation_service.dart)

**用途**: 統一管理訂單自動化流程，協調賣家服務與物流服務。

**主要功能**:
- `initialize()` - 初始化服務，掃描並監控所有現有訂單
- `onOrderCreated(order)` - 新訂單建立時的處理
- `onOrderStatusChanged(order)` - 訂單狀態變更時的處理
- **手動觸發**:
  - `manualConfirmOrder(orderId)` - 手動觸發賣家確認訂單
  - `manualShipOrder(orderId)` - 手動觸發賣家出貨
  - `manualArriveAtPickupPoint(orderId)` - 手動觸發物流抵達超商
  - `manualSignOrder(orderId)` - 手動觸發物流簽收
- `dispose()` - 清理所有服務

**依賴服務**: SellerService, LogisticsService, OrderStatusService

**位置**: [order_automation_service.dart:10](order_automation_service.dart#L10)

---

### SellerService
**檔案**: [seller_service.dart](seller_service.dart)

**用途**: 模擬賣場對訂單的操作（確認訂單、出貨）。

**主要功能**:
- **自動化流程**:
  - `startMonitoringPendingPaymentOrder(order)` - 監控待付款訂單（1分鐘後自動確認）
  - `startMonitoringPendingShipmentOrder(order)` - 監控待出貨訂單（1小時後自動出貨）
- **手動操作**:
  - `manualConfirmOrder(orderId)` - 手動確認訂單
  - `manualShipOrder(orderId)` - 手動出貨
- **監控管理**:
  - `cancelMonitoring(orderId)` - 取消訂單監控
  - `rescanAndMonitorOrders()` - 重新掃描並監控所有符合條件的訂單
  - `dispose()` - 清理所有計時器

**狀態轉換**:
- 待付款 → 待出貨（確認訂單）
- 待出貨 → 待收貨/運送中（出貨）

**位置**: [seller_service.dart:10](seller_service.dart#L10)

---

### LogisticsService
**檔案**: [logistics_service.dart](logistics_service.dart)

**用途**: 模擬物流對訂單的操作（運送、抵達、簽收）。

**主要功能**:
- **自動化流程**:
  - `startMonitoringInTransitOrder(order)` - 監控運送中的訂單
    - 超商取貨：1小時後抵達超商
    - 宅配：1小時後直接簽收
  - `startMonitoringArrivedOrder(order)` - 監控已抵達訂單（1小時後簽收）
- **手動操作**:
  - `manualArriveAtPickupPoint(orderId)` - 手動抵達超商
  - `manualSignOrder(orderId)` - 手動簽收
- **監控管理**:
  - `cancelMonitoring(orderId)` - 取消訂單監控
  - `rescanAndMonitorOrders()` - 重新掃描並監控訂單
  - `dispose()` - 清理所有計時器

**配送方式**:
- `convenience_store` - 超商取貨（運送中 → 抵達超商 → 簽收）
- `home_delivery` - 宅配（運送中 → 簽收）

**位置**: [logistics_service.dart:10](logistics_service.dart#L10)

---

### OrderStatusService
**檔案**: [order_status_service.dart](order_status_service.dart)

**用途**: 管理訂單狀態的更新、歷史記錄與時間戳。

**主要功能**:
- **狀態更新**:
  - `updateOrderStatus()` - 更新訂單主要狀態和物流狀態
  - `updateLogisticsStatus()` - 更新物流狀態（僅限待收貨訂單）
- **查詢功能**:
  - `getOrderStatusHistory(orderId)` - 取得訂單狀態歷史
  - `getOrderStatusTimestamps(orderId)` - 取得訂單狀態時間戳
  - `getOrdersByMainStatus(status)` - 根據主要狀態篩選訂單
- **訂單完成**:
  - `completeOrder(orderId)` - 完成訂單（僅限已簽收的待收貨訂單）

**內部功能**:
- `_addStatusHistory()` - 創建訂單狀態歷史記錄
- `_updateTimestamps()` - 更新訂單狀態時間戳

**位置**: [order_status_service.dart:8](order_status_service.dart#L8)

---

## AI 客戶端服務

### OpenAICompatibleClient
**檔案**: [openai_client.dart](openai_client.dart)

**用途**: 提供 OpenAI Chat Completion API 相容的客戶端，支援多個 AI 服務供應商。

**主要功能**:
- `chatCompletion(opts)` - 非串流對話完成請求
- `chatCompletionStream(opts)` - 串流對話完成請求（SSE）

**核心類別**:
- **`ChatMessage`**: 對話訊息
  - `role` - 角色（system, user, assistant, function）
  - `content` - 訊息內容
  - `name` - 可選名稱（用於 function）
  - `functionCallResult` - 可選函數呼叫結果

- **`ProviderConfig`**: AI 服務供應商配置
  - `name` - 供應商名稱
  - `baseUrl` - API 基礎 URL
  - `apiKey` - API 金鑰
  - `defaultModel` - 預設模型
  - `extraHeaders` - 額外 HTTP 標頭

- **`ChatCompletionOptions`**: 對話完成選項
  - `messages` - 對話訊息列表
  - `model` - 模型名稱（覆蓋預設）
  - `stream` - 是否串流回應
  - `temperature` - 取樣溫度（0-2）
  - `maxTokens` - 最大 token 數
  - `tools` - 可用工具（函數）列表
  - `extraParams` - 供應商專用參數

**使用範例**:
```dart
final provider = ProviderConfig(
  name: 'DeepSeek',
  baseUrl: 'https://api.deepseek.com',
  apiKey: '<YOUR_KEY>',
  defaultModel: 'deepseek-chat',
);

final client = OpenAICompatibleClient(provider);

// 非串流請求
final reply = await client.chatCompletion(
  ChatCompletionOptions(
    messages: [
      ChatMessage(role: Role.system, content: 'You are a helpful assistant.'),
      ChatMessage(role: Role.user, content: '用中文列出 3 個 Dart 的優點'),
    ],
    temperature: 0.7,
  ),
);

// 串流請求
await for (final delta in client.chatCompletionStream(
  ChatCompletionOptions(
    messages: [
      ChatMessage(role: Role.user, content: 'Explain SSE streaming briefly.'),
    ],
    stream: true,
  ),
)) {
  print(delta);
}
```

**位置**: [openai_client.dart:166](openai_client.dart#L166)

---

## 暫未實作服務

以下服務檔案存在但尚未實作完整功能：

### api_service.dart
**狀態**: 空檔案（僅 1 行）
**計劃用途**: API 通訊服務（待實作）

### tts_service.dart
**狀態**: 空檔案（僅 1 行）
**計劃用途**: 文字轉語音服務（Text-to-Speech）
**注意**: 目前使用 `utils/tts_helper.dart` 替代

### stt_service.dart
**狀態**: 空檔案（僅 1 行）
**計劃用途**: 語音轉文字服務（Speech-to-Text）

---

## 服務依賴關係圖

```
OrderAutomationService
├── DatabaseService
├── OrderStatusService
│   └── DatabaseService
├── SellerService
│   ├── DatabaseService
│   └── OrderStatusService
└── LogisticsService
    ├── DatabaseService
    └── OrderStatusService

FocusNavigationService
├── AccessibilityService
└── utils/tts_helper

GlobalGestureService
├── AccessibilityService
└── utils/tts_helper

TestDataService
└── DatabaseService (Isar)
```

---

## 服務初始化順序建議

1. **DatabaseService** - 最先初始化
2. **AccessibilityService** - 初始化無障礙檢測
3. **GlobalGestureService** - 設定全域手勢
4. **AuthService** - Firebase 驗證
5. **OrderAutomationService** - 訂單自動化（含 SellerService、LogisticsService）
6. **TestDataService** - 僅開發環境需要

---

## 最佳實踐

### 1. 使用單例模式
多數無障礙服務使用單例模式（Singleton），通過全域實例存取：
```dart
final accessibilityService = AccessibilityService();
final globalGestureService = GlobalGestureService();
final focusNavigationService = FocusNavigationService();
```

### 2. 依賴注入
DatabaseService 與訂單相關服務建議使用 Provider 進行依賴注入：
```dart
Provider<DatabaseService>(
  create: (_) => DatabaseService(),
  child: MyApp(),
)
```

### 3. 資源清理
記得在適當時機調用 `dispose()` 清理資源：
```dart
@override
void dispose() {
  orderAutomationService.dispose();
  super.dispose();
}
```

### 4. 錯誤處理
使用 try-catch 包裹異步操作：
```dart
try {
  await db.createOrder(...);
} catch (e) {
  print('建立訂單失敗: $e');
}
```

---

## 更新紀錄

- **2025-01-23**: 初始版本，記錄所有 services 資料夾中的服務
