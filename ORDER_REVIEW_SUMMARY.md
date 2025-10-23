# 訂單評論功能 - 完成總結

## ✅ 已完成的工作

### 1. 修復訂單歷史頁面的雙擊問題

**問題**: 完成訂單按鈕需要雙擊才能觸發

**解決方案**:
- 移除了 GestureDetector 的雙擊邏輯
- 將訂單卡片改為使用 InkWell 處理單擊（播放訂單資訊語音）
- 加入「查看詳情」按鈕，單擊直接跳轉
- 「完成訂單」按鈕保持單擊觸發

**檔案**: `lib/pages/orders/order_history_page_new.dart`

### 2. 建立訂單商品評論服務

**功能**:
- 檢查訂單是否可評論（完成後30天內）
- 創建商品評論（評分必填，評論選填）
- 自動更新商品的平均評分和評論數
- 獲取剩餘評論天數

**檔案**: `lib/services/order_review_service.dart`

**核心方法**:
```dart
// 檢查是否可評論
Future<bool> canReviewOrder(int orderId)

// 創建評論
Future<bool> createProductReview({
  required int productId,
  required double rating, // 1.0-5.0，必填
  String? comment,         // 選填
  String userName = '匿名用戶',
})

// 獲取剩餘天數
Future<int?> getRemainingDaysToReview(int orderId)
```

### 3. 建立商品評論對話框

**功能**:
- 顯示商品資訊
- 星級評分選擇（1-5星）
- 評論內容輸入（最多500字，選填）
- 表單驗證（評分必填）
- 語音提示支援
- 載入狀態顯示

**檔案**: `lib/widgets/product_review_dialog.dart`

**使用方式**:
```dart
final result = await showProductReviewDialog(
  context: context,
  orderItem: orderItem,
  reviewService: reviewService,
);
```

### 4. 建立完整的功能說明文件

**檔案**: `ORDER_REVIEW_FEATURE.md`

包含:
- 功能概述和規則
- 整合步驟
- UI 示意圖
- 相關檔案列表
- 注意事項和改進建議

## 📋 需要你手動完成的步驟

### 步驟 1: 替換訂單歷史頁面

請手動將以下檔案：
- **來源**: `lib/pages/orders/order_history_page_new.dart`
- **目標**: `lib/pages/orders/order_history_page.dart`

可以:
1. 刪除 `order_history_page.dart`
2. 將 `order_history_page_new.dart` 改名為 `order_history_page.dart`

或者直接複製 order_history_page_new.dart 的內容到 order_history_page.dart

### 步驟 2: 更新訂單詳情頁面

**檔案**: `lib/pages/orders/order_detail_page.dart`

需要加入以下功能（詳見 `ORDER_REVIEW_FEATURE.md`）:

#### A. 導入
在檔案開頭加入：
```dart
import '../../services/order_review_service.dart';
import '../../services/order_status_service.dart';
import '../../models/order_status.dart';
import '../../widgets/product_review_dialog.dart';
```

#### B. 加入狀態變數
在 `_OrderDetailPageState` 類中加入：
```dart
late OrderReviewService _reviewService;
late OrderStatusService _statusService;
bool _canReview = false;
int? _remainingDays;
```

#### C. 初始化服務
在 `didChangeDependencies()` 方法中：
```dart
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
```

#### D. 檢查評論權限
在 `_loadOrderDetail()` 方法的最後加入：
```dart
if (_order != null) {
  // 檢查是否可以評論
  _canReview = await _reviewService.canReviewOrder(_order!.id);
  _remainingDays = await _reviewService.getRemainingDaysToReview(_order!.id);
  setState(() {});

  // 現有的語音播報代碼...
}
```

#### E. 加入評論對話框方法
在 `_OrderDetailPageState` 類中加入：
```dart
Future<void> _showReviewDialog(OrderItem item) async {
  ttsHelper.speak('評論商品 ${item.productName}');

  final result = await showProductReviewDialog(
    context: context,
    orderItem: item,
    reviewService: _reviewService,
  );

  if (result == true && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('評論發布成功！感謝您的回饋', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

#### F. 在訂單狀態卡片中加入評論提示
在訂單狀態卡片的 Column children 中，訂單日期後面加入：
```dart
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

#### G. 在商品列表中加入評論按鈕
在每個商品項目的 Column children 中，小計金額後面加入：
```dart
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

## 🧪 測試流程

### 1. 測試完成按鈕（已修復）
- 進入訂單頁面
- 找到已簽收的訂單（待收貨 - 已簽收）
- 單擊「完成訂單」按鈕
- 應該立即觸發，不需要雙擊

### 2. 測試評論功能

#### 測試準備
1. 確保有一個已完成的訂單
2. 訂單完成時間在30天內

#### 測試步驟
1. 進入訂單詳情頁
2. 檢查是否顯示「可評論商品（剩餘 X 天）」提示
3. 找到商品項目，點擊「評論商品」按鈕
4. 評論對話框應該彈出

#### 測試場景A: 只評分不評論
1. 選擇評分（例如4星）
2. 不輸入評論內容
3. 點擊「發布評論」
4. 應該成功發布

#### 測試場景B: 評分+評論
1. 選擇評分（例如5星）
2. 輸入評論內容
3. 點擊「發布評論」
4. 應該成功發布

#### 測試場景C: 未選評分
1. 不選擇評分
2. 直接點擊「發布評論」
3. 應該提示「請先選擇評分（1-5星）」

#### 驗證結果
1. 評論發布成功後應該顯示成功提示
2. 到商品頁面檢查：
   - 平均評分應該更新
   - 評論數量應該增加
   - 新評論應該出現在評論列表中

### 3. 測試評論期限

#### 測試超過30天的訂單
1. 找一個完成時間超過30天的訂單
2. 進入訂單詳情
3. 不應該顯示「可評論商品」提示
4. 商品項目不應該有「評論商品」按鈕

## 📁 檔案清單

### 新增檔案
- `lib/services/order_review_service.dart` - 評論服務 ✅
- `lib/widgets/product_review_dialog.dart` - 評論對話框 ✅
- `lib/pages/orders/order_history_page_new.dart` - 新版訂單歷史 ✅
- `ORDER_REVIEW_FEATURE.md` - 功能說明文件 ✅
- `ORDER_REVIEW_SUMMARY.md` - 本檔案 ✅

### 需要修改的檔案
- `lib/pages/orders/order_history_page.dart` - 需替換為 _new 版本
- `lib/pages/orders/order_detail_page.dart` - 需加入評論功能

### 相關現有檔案
- `lib/models/product_review.dart` - 評論模型（已存在）
- `lib/models/order.dart` - 訂單模型（已存在）
- `lib/models/order_status.dart` - 訂單狀態模型（已存在）
- `lib/models/product.dart` - 商品模型（已存在）

## 🎯 功能特色

1. **30天評論期限**: 訂單完成後30天內可評論
2. **評分必填**: 必須選擇1-5星評分才能發布
3. **評論選填**: 評論文字非強制，可以只評分
4. **自動更新**: 評論發布後自動更新商品的平均評分和評論數
5. **語音支援**: 所有操作都有語音提示
6. **完整驗證**: 表單驗證確保資料正確性
7. **單擊操作**: 所有按鈕都是單擊觸發，不需要雙擊

## 💡 注意事項

1. **評論關聯**: 目前 ProductReview 模型沒有 orderId 欄位，無法追蹤評論來自哪個訂單
2. **重複評論**: 目前允許同一商品多次評論
3. **用戶名稱**: 目前使用固定的「用戶」，可擴展為從用戶資料獲取
4. **評論編輯**: 目前不支援編輯或刪除已發布的評論

## 🚀 未來改進建議

1. 在 ProductReview 模型中加入 orderId 欄位
2. 限制每個訂單的每個商品只能評論一次
3. 加入評論編輯和刪除功能
4. 加入評論圖片上傳
5. 整合用戶系統，顯示真實用戶資訊
6. 加入評論點贊/踩功能
7. 加入評論舉報功能

## 📞 如有問題

請查看 `ORDER_REVIEW_FEATURE.md` 獲取更詳細的整合說明和範例代碼。
