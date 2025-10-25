# 商品詳情頁面布局優化說明

## 優化內容總結

本次優化重點在於改善商品詳情頁面的資訊呈現和布局結構，新增售出次數顯示、優化規格選擇區域、添加動態單價顯示。

---

## 📋 新增功能

### 1. 售出次數功能 ✅

#### 資料模型更新
**檔案**: [lib/models/product.dart](lib/models/product.dart)
```dart
// 銷售相關欄位
int soldCount = 0;  // 售出次數
```

#### 測試資料初始化
**檔案**: [lib/services/test_data_service.dart](lib/services/test_data_service.dart)
- 每個商品在初始化時獲得 0-999 之間的隨機售出次數
- 使用 `Random().nextInt(1000)` 生成隨機值

#### 訂單完成自動更新
**檔案**: [lib/services/order_status_service.dart:295-325](lib/services/order_status_service.dart#L295-L325)
- 當訂單狀態變更為「已完成」時，自動更新商品售出次數
- 新增 `_updateProductSoldCount()` 方法
- 根據訂單項目的數量累加到商品的 `soldCount`

```dart
/// 更新商品售出次數（訂單完成時）
Future<void> _updateProductSoldCount(int orderId) async {
  // 獲取訂單項目
  final orderItems = await _db.getOrderItems(orderId);

  // 更新每個商品的售出次數
  for (var item in orderItems) {
    final product = await _db.getProductById(item.productId);
    if (product != null) {
      product.soldCount += item.quantity;
      await isar.products.put(product);
    }
  }
}
```

#### UI 顯示
**位置**: 商品名稱和價格區域
**樣式**: 橙色標籤，包含趨勢圖標

```
┌─────────────────────────────────┐
│ 🔥 已售 456                     │
│ (橙色背景，橙色文字)             │
└─────────────────────────────────┘
```

**語音反饋**: 單擊標籤播報「已售出 X 件」

---

### 2. 規格選擇區域重構 ✅

#### 布局結構
**原本**:
```
選擇尺寸
[尺寸選項]

選擇顏色
[顏色選項]
```

**現在**:
```
規格 (主標題)
  尺寸 (副標題)
  [尺寸選項]

  顏色 (副標題)
  [顏色選項]
```

#### 標題階層
| 層級 | 標題 | 字體大小 | 字重 |
|------|------|----------|------|
| 主標題 | 規格 | 32px | bold |
| 副標題 | 尺寸、顏色 | 26px | w600 |

#### 視覺改進
- 明確的主副標題層級
- 更清晰的資訊架構
- 符合視覺設計原則

---

### 3. 動態單價顯示 ✅

#### 顯示位置
**新增區域**: 規格選擇區和數量選擇區之間

#### UI 設計
```
┌─────────────────────────────────┐
│ 單價                            │
│ $900                            │
│                                 │
│ 或（當數量 > 1）:               │
│ $900 × 2 = $1,800              │
│                                 │
│ 註：不同規格或數量可能享有優惠價格│
└─────────────────────────────────┘
```

**樣式特點**:
- 藍色背景 (`Colors.blue.shade50`)
- 藍色邊框 (`Colors.blue.shade200`)
- 圓角卡片設計
- 包含提示文字

#### 動態計算
**檔案**: [lib/pages/product/product_detail_page.dart:38-51](lib/pages/product/product_detail_page.dart#L38-L51)

```dart
/// 計算當前選擇的單價（未來可根據規格調整）
double get _currentUnitPrice {
  if (_product == null) return 0.0;
  // 未來可以根據 _selectedSize 和 _selectedColor 返回不同價格
  return _product!.price;
}

/// 計算總價（單價 × 數量，未來可加入多件優惠）
double get _totalPrice {
  // 未來可以加入多件優惠邏輯
  // 例如：買 3 件打 9 折
  return _currentUnitPrice * _quantity;
}
```

#### 顯示邏輯
- **數量 = 1**: 僅顯示單價
  ```
  單價
  $900
  ```

- **數量 > 1**: 顯示計算式
  ```
  單價
  $900 × 2 = $1,800
  ```

#### 語音反饋
單擊單價區域播報：「單價 X 元」

---

## 🎨 頁面布局優化

### 完整布局結構

```
┌─────────────────────────────────────┐
│ 商品圖片                             │
├─────────────────────────────────────┤
│ 商品名稱                             │
│ 商家名稱 (可點擊)                    │
│ $4,500  🔥已售 456  [分類]         │
├─────────────────────────────────────┤
│ 商品描述                             │
│ 描述內容...                          │
├─────────────────────────────────────┤
│ 規格                      ← 主標題   │
│   尺寸                    ← 副標題   │
│   [通用] [S] [M] [L] [XL]          │
│                                     │
│   顏色                    ← 副標題   │
│   [預設] [黑] [白] [灰] [藍]       │
├─────────────────────────────────────┤
│ 單價                      ← 新增區域 │
│ $900 × 2 = $1,800                  │
│ 註：不同規格或數量可能享有優惠價格   │
├─────────────────────────────────────┤
│ 選擇數量                             │
│ [-]  2  [+]                         │
├─────────────────────────────────────┤
│ [加入購物車] [直接購買]              │
├─────────────────────────────────────┤
│ 商品評價                             │
│ ⭐ 4.5 (13則評論)                   │
│ [AI 整理評論] ← (10則以上評論時顯示) │
│ ...評論列表...                       │
└─────────────────────────────────────┘
```

### 區域間距
| 區域之間 | 間距 |
|---------|------|
| 商品資訊 → 商品描述 | `AppSpacing.lg` |
| 商品描述 → 規格 | `AppSpacing.xl` |
| 規格 → 單價 | `AppSpacing.lg` |
| 單價 → 數量 | `AppSpacing.lg` |
| 數量 → 按鈕 | `AppSpacing.xl` |
| 按鈕 → 評論 | `AppSpacing.xl` |

---

## 📱 售出次數標籤設計

### 視覺設計
```
┌──────────────┐
│ 📈 已售 456  │
└──────────────┘
```

**顏色方案**:
- 背景: `Colors.orange.shade100`
- 邊框: `Colors.orange.shade300`
- 文字: `Colors.orange.shade700`
- 圖標: `Icons.trending_up`

**尺寸**:
- 字體大小: 22px
- 字重: w600
- 圖標大小: 18px
- 內邊距: `horizontal: sm, vertical: xs`

### 顯示位置
在商品名稱下方，與價格和分類標籤並排顯示：

```
$4,500  |  🔥已售 456  |  [運動鞋]
```

---

## 💰 動態單價顯示設計

### 卡片樣式
**背景**: 淺藍色 (`Colors.blue.shade50`)
**邊框**: 藍色 2px (`Colors.blue.shade200`)
**圓角**: 12px
**內邊距**: `AppSpacing.md`

### 內容組成

1. **標題**: 「單價」(24px, w600)
2. **單價金額**:
   - 主要價格: 36px, bold, primary color
   - 乘號和數量: 28px, w500, grey
   - 等號和總價: 32px, bold, accent color
3. **提示文字**: 18px, italic, grey (預告未來功能)

### 計算邏輯說明

#### 當前實現
- 所有規格和數量使用相同單價
- 總價 = 單價 × 數量

#### 未來擴展 (預留)
```dart
double get _currentUnitPrice {
  if (_product == null) return 0.0;

  // 未來可以這樣實現不同規格的價格
  // if (_selectedSize == 'XL') {
  //   return _product!.price * 1.2; // XL尺寸加價 20%
  // }

  return _product!.price;
}

double get _totalPrice {
  // 未來可以這樣實現多件優惠
  // if (_quantity >= 3) {
  //   return _currentUnitPrice * _quantity * 0.9; // 3件打9折
  // }

  return _currentUnitPrice * _quantity;
}
```

---

## 🔄 資料流程

### 售出次數更新流程

```
用戶完成訂單
    ↓
OrderStatusService.completeOrder()
    ↓
updateOrderStatus() (訂單狀態 → 已完成)
    ↓
_updateProductSoldCount() ← 新增
    ↓
獲取訂單項目
    ↓
for each 訂單項目:
    ↓
    取得商品資料
    ↓
    product.soldCount += item.quantity
    ↓
    儲存到資料庫
    ↓
輸出 Debug 日誌
```

**Debug 輸出範例**:
```
📈 [OrderStatusService] 更新商品售出次數: Nike Air Max 270 +2 (總計: 458)
```

---

## 🎯 使用者體驗優化

### 1. 資訊層級清晰
- **主標題** (規格): 32px bold
- **副標題** (尺寸、顏色): 26px w600
- **內容** (選項): 24px normal

### 2. 視覺引導
- 售出次數使用橙色，吸引注意力
- 單價卡片使用藍色背景，區隔其他區域
- 提示文字使用斜體，表示輔助資訊

### 3. 語音無障礙
- 所有新增元素都支援語音朗讀
- 售出次數: 「已售出 X 件」
- 單價: 「單價 X 元」
- 規格主標題: 「規格」
- 尺寸副標題: 「尺寸」
- 顏色副標題: 「顏色」

### 4. 動態反饋
- 數量改變時，單價卡片自動更新顯示
- 總價計算即時反應
- 未來可擴展規格價格差異

---

## 📊 修改的檔案清單

### 1. 資料模型
- ✅ [lib/models/product.dart](lib/models/product.dart) - 新增 `soldCount` 欄位

### 2. 測試資料
- ✅ [lib/services/test_data_service.dart](lib/services/test_data_service.dart) - 初始化隨機售出次數

### 3. 訂單服務
- ✅ [lib/services/order_status_service.dart](lib/services/order_status_service.dart) - 訂單完成時更新售出次數

### 4. 商品詳情頁面
- ✅ [lib/pages/product/product_detail_page.dart](lib/pages/product/product_detail_page.dart)
  - 新增 `_currentUnitPrice` getter
  - 新增 `_totalPrice` getter
  - 新增 `_buildPriceDisplay()` 方法
  - 更新價格和標籤區域，添加售出次數顯示
  - 重構規格選擇區域，添加主副標題
  - 調整布局，在規格和數量之間插入單價顯示

---

## 🧪 測試建議

### 測試案例 1: 售出次數顯示
1. 開啟任意商品詳情頁
2. 確認顯示售出次數標籤（橙色）
3. 單擊標籤確認播報「已售出 X 件」
4. 檢查數字在 0-999 範圍內

### 測試案例 2: 規格區域
1. 查看規格區域
2. 確認顯示主標題「規格」(32px)
3. 確認顯示副標題「尺寸」、「顏色」(26px)
4. 單擊各標題確認語音播報
5. 確認標題層級清晰

### 測試案例 3: 動態單價
1. 查看單價卡片（藍色背景）
2. 數量為 1 時，確認只顯示單價
3. 調整數量為 2：
   - 確認顯示「$900 × 2 = $1,800」
   - 確認計算正確
4. 調整數量為 3、4... 確認動態更新
5. 單擊單價區域確認語音播報

### 測試案例 4: 售出次數更新
1. 創建訂單並完成結帳
2. 使用自動化服務將訂單推進到「已完成」
3. 檢查 Debug 日誌：
   ```
   📈 [OrderStatusService] 更新商品售出次數: ...
   ```
4. 重新進入商品詳情頁
5. 確認售出次數已增加

### 測試案例 5: 資料庫重置
1. 執行資料庫重置
2. 確認商品售出次數恢復為 0-999 隨機值
3. 確認其他資料正常

---

## 🔮 未來擴展方向

### 1. 規格價格差異
```dart
// 不同尺寸的價格
Map<String, double> _sizePrices = {
  '通用尺寸': 1.0,
  'S': 1.0,
  'M': 1.0,
  'L': 1.1,  // 加價 10%
  'XL': 1.2, // 加價 20%
};

// 不同顏色的價格
Map<String, double> _colorPrices = {
  '預設顏色': 1.0,
  '黑色': 1.0,
  '白色': 1.0,
  '灰色': 1.0,
  '藍色': 1.05, // 特殊顏色加價 5%
  '紅色': 1.05,
};

double get _currentUnitPrice {
  if (_product == null) return 0.0;

  double basePrice = _product!.price;
  double sizeMultiplier = _sizePrices[_selectedSize] ?? 1.0;
  double colorMultiplier = _colorPrices[_selectedColor] ?? 1.0;

  return basePrice * sizeMultiplier * colorMultiplier;
}
```

### 2. 多件優惠
```dart
double get _totalPrice {
  double unitPrice = _currentUnitPrice;
  double total = unitPrice * _quantity;

  // 階梯折扣
  if (_quantity >= 5) {
    total *= 0.85; // 5件以上 85折
  } else if (_quantity >= 3) {
    total *= 0.9;  // 3-4件 9折
  }

  return total;
}

// UI 顯示折扣資訊
Widget _buildDiscountInfo() {
  if (_quantity >= 3) {
    return Container(
      child: Text('🎉 已享優惠！$_quantity 件 ${...}折'),
    );
  }
  return SizedBox.shrink();
}
```

### 3. 售出次數統計
```dart
// 在商品列表顯示熱賣標籤
Widget _buildHotLabel(Product product) {
  if (product.soldCount > 500) {
    return Container(
      child: Text('🔥 熱賣'),
    );
  }
  return SizedBox.shrink();
}

// 按售出次數排序
List<Product> sortByPopularity(List<Product> products) {
  products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
  return products;
}
```

### 4. 庫存管理
```dart
// 完成訂單時同步更新庫存
product.stock -= item.quantity;
product.soldCount += item.quantity;

// UI 顯示庫存狀態
if (product.stock < 10) {
  return Text('⚠️ 僅剩 ${product.stock} 件');
}
```

---

## 📝 重要提醒

### ⚠️ 需要執行的操作

用戶需要手動執行以下命令來重新生成資料模型：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**原因**: 我們修改了 `Product` 模型，添加了 `soldCount` 欄位，需要重新生成 `product.g.dart` 檔案。

### 資料庫遷移
- 現有資料庫中的商品 `soldCount` 會自動初始化為 0
- 執行「重置到乾淨狀態」會重新生成 0-999 隨機售出次數
- 不影響現有訂單和購物車資料

---

## 📈 效能考量

### 1. 售出次數更新
- 僅在訂單完成時更新，頻率低
- 使用事務保證資料一致性
- 錯誤處理完善，不影響訂單流程

### 2. 動態計算
- 使用 getter 方法，無需額外儲存
- 計算簡單，效能影響可忽略
- 未來擴展彈性高

### 3. UI 渲染
- 售出次數為靜態資料，不需頻繁更新
- 單價卡片僅在數量改變時重新渲染
- 使用 `setState()` 局部更新

---

## ✅ 完成檢查清單

- [x] Product 模型添加 soldCount 欄位
- [x] 測試資料初始化隨機售出次數 (0-999)
- [x] 訂單完成時自動更新售出次數
- [x] 商品詳情頁顯示售出次數標籤
- [x] 規格區域添加主標題「規格」
- [x] 尺寸和顏色改為副標題
- [x] 添加動態單價顯示卡片
- [x] 單價隨數量變化動態更新
- [x] 所有新增元素支援語音朗讀
- [x] 預留未來擴展的程式碼註解
- [x] 創建完整的功能說明文件

---

## 相關文件
- [商品詳情頁面](lib/pages/product/product_detail_page.dart)
- [商品模型](lib/models/product.dart)
- [測試資料服務](lib/services/test_data_service.dart)
- [訂單狀態服務](lib/services/order_status_service.dart)
- [商品詳情頁面優化 (按鈕互動)](PRODUCT_DETAIL_OPTIMIZATION.md)
- [AI 評論摘要功能](AI_REVIEW_SUMMARY.md)
