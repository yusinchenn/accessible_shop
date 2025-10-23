# 訂單商品評論功能說明

## 功能概述

為已完成的訂單加入商品評論功能，允許用戶在訂單完成後30天內為購買的商品進行評分和評論。

## 核心規則

1. **評論時機**: 訂單完成後30天內可評論
2. **評分**: 必填，1-5星
3. **評論內容**: 選填，最多500字
4. **單次評論**: 每個商品可多次評論（目前設定）

## 已完成的功能

### 1. 訂單評論服務 (OrderReviewService)

**檔案位置**: `lib/services/order_review_service.dart`

**主要方法**:
- `canReviewOrder(int orderId)` - 檢查訂單是否可評論
- `getOrderItems(int orderId)` - 獲取訂單商品列表
- `createProductReview()` - 創建商品評論
- `getRemainingDaysToReview(int orderId)` - 獲取剩餘評論天數

**規則**:
```dart
// 評論有效期限
static const int reviewValidDays = 30;

// 評分範圍
1.0 <= rating <= 5.0
```

### 2. 商品評論對話框 (ProductReviewDialog)

**檔案位置**: `lib/widgets/product_review_dialog.dart`

**功能**:
- 顯示商品資訊
- 星級評分選擇（1-5星）
- 評論內容輸入（選填，最多500字）
- 語音提示
- 表單驗證

**使用方式**:
```dart
final result = await showProductReviewDialog(
  context: context,
  orderItem: orderItem,
  reviewService: reviewService,
);

if (result == true) {
  // 評論發布成功
}
```

## 需要整合的部分

### 1. 訂單詳情頁面 (order_detail_page.dart)

需要加入以下功能：

#### A. 導入必要的檔案
```dart
import '../../services/order_review_service.dart';
import '../../services/order_status_service.dart';
import '../../models/order_status.dart';
import '../../widgets/product_review_dialog.dart';
```

#### B. 加入狀態變數
```dart
class _OrderDetailPageState extends State<OrderDetailPage> {
  // 現有變數...
  late OrderReviewService _reviewService;
  late OrderStatusService _statusService;
  bool _canReview = false;
  int? _remainingDays;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      _reviewService = OrderReviewService(db);
      _statusService = OrderStatusService(db);
      _loadOrderDetail();
    }
  }
}
```

#### C. 在 _loadOrderDetail() 中檢查評論權限
```dart
Future<void> _loadOrderDetail() async {
  // 現有代碼...

  if (_order != null) {
    // 檢查是否可以評論
    _canReview = await _reviewService.canReviewOrder(_order!.id);
    _remainingDays = await _reviewService.getRemainingDaysToReview(_order!.id);
    setState(() {});
  }
}
```

#### D. 在商品列表中加入評論按鈕

在每個商品項目下方加入評論按鈕：

```dart
// 在商品項目的 Column children 中加入
if (_canReview) ...[
  const SizedBox(height: AppSpacing.xs),
  Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: () => _showReviewDialog(item),
      icon: const Icon(Icons.rate_review, size: 18),
      label: const Text('評論商品'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),
  ),
],
```

#### E. 實作評論對話框方法
```dart
Future<void> _showReviewDialog(OrderItem item) async {
  ttsHelper.speak('評論商品 ${item.productName}');

  final result = await showProductReviewDialog(
    context: context,
    orderItem: item,
    reviewService: _reviewService,
  );

  if (result == true && mounted) {
    // 評論成功，可以重新載入或顯示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('評論發布成功！感謝您的回饋', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

#### F. 在訂單資訊卡片中顯示剩餘天數

在訂單狀態卡片中加入評論提示：

```dart
// 在訂單狀態卡片的 children 中加入
if (_canReview && _remainingDays != null) ...[
  const SizedBox(height: AppSpacing.sm),
  Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue, width: 1),
    ),
    child: Row(
      children: [
        const Icon(Icons.rate_review, color: Colors.blue, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '可評論商品（剩餘 $_remainingDays 天）',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: AppFontSizes.body,
            ),
          ),
        ),
      ],
    ),
  ),
],
```

### 2. 訂單歷史頁面 (order_history_page.dart)

檔案已經更新為新版本：
- `order_history_page_new.dart` 包含修復後的版本
- 完成按鈕改為單擊
- 加入「查看詳情」按鈕

需要將 `order_history_page_new.dart` 覆蓋 `order_history_page.dart`

## 整合步驟

### 步驟 1: 更新訂單歷史頁面
```bash
# 備份原檔案
cp lib/pages/orders/order_history_page.dart lib/pages/orders/order_history_page_backup.dart

# 使用新版本
cp lib/pages/orders/order_history_page_new.dart lib/pages/orders/order_history_page.dart
```

### 步驟 2: 更新訂單詳情頁面

根據上述說明修改 `lib/pages/orders/order_detail_page.dart`，或使用以下完整範例。

### 步驟 3: 測試流程

1. 創建一個新訂單
2. 等待訂單自動完成（或手動完成）
3. 進入訂單詳情
4. 檢查是否顯示「可評論商品」提示
5. 點擊商品的「評論商品」按鈕
6. 選擇評分（必填）
7. 輸入評論內容（選填）
8. 提交評論
9. 檢查商品頁面的評分是否更新

## UI 示意

### 訂單詳情頁面

```
┌─────────────────────────────────┐
│ 訂單 #20250123-0001             │
│                                 │
│ ┌─ 訂單狀態 ─────────────────┐ │
│ │ 已完成                [綠色] │ │
│ │ 訂單編號: 20250123-0001     │ │
│ │ ⓘ 可評論商品（剩餘 28 天）  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─ 商品明細 ───────────────────┐│
│ │ Nike Air Max 270             ││
│ │ 尺寸: L / 顏色: 黑色         ││
│ │ $4500 x 1                    ││
│ │          [評論商品 >]        ││
│ └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### 評論對話框

```
┌─────────────────────────────────┐
│ 商品評論                    [X] │
│                                 │
│ ┌─ 商品資訊 ─────────────────┐ │
│ │ Nike Air Max 270            │ │
│ │ 尺寸: L / 顏色: 黑色        │ │
│ └─────────────────────────────┘ │
│                                 │
│ 評分 *                          │
│ ★ ★ ★ ★ ☆                      │
│ 4 星                            │
│                                 │
│ 評論內容（選填）                │
│ ┌─────────────────────────────┐ │
│ │ 分享您的使用心得...         │ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│ [    發布評論    ]              │
└─────────────────────────────────┘
```

## 相關檔案

- `lib/services/order_review_service.dart` - 評論服務（已完成）
- `lib/widgets/product_review_dialog.dart` - 評論對話框（已完成）
- `lib/pages/orders/order_history_page_new.dart` - 新版訂單歷史（已完成）
- `lib/pages/orders/order_detail_page.dart` - 訂單詳情（需要更新）
- `lib/models/product_review.dart` - 評論模型（已存在）
- `lib/models/product.dart` - 商品模型（已存在）

## 注意事項

1. **評論關聯**: 目前 ProductReview 模型沒有 orderId 欄位，無法追蹤評論來自哪個訂單
2. **重複評論**: 目前允許同一商品多次評論
3. **用戶名稱**: 目前使用固定的「用戶」或「匿名用戶」，可以擴展為從用戶資料中獲取
4. **評論編輯**: 目前不支援編輯或刪除已發布的評論

## 未來改進建議

1. 在 ProductReview 模型中加入 orderId 欄位
2. 限制每個訂單的每個商品只能評論一次
3. 加入評論編輯和刪除功能
4. 加入評論圖片上傳功能
5. 加入評論點贊/踩功能
6. 加入評論舉報功能
7. 整合用戶系統，顯示真實用戶名稱和頭像
