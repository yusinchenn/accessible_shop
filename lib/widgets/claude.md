# Widgets 資料夾架構文件

本文件說明 `lib/widgets/` 資料夾中各個自訂 Widget 的用途、功能與使用方式。

## 目錄

1. [概述](#概述)
2. [無障礙手勢組件](#無障礙手勢組件)
3. [焦點導航組件](#焦點導航組件)
4. [商品展示組件](#商品展示組件)
5. [暫未實作組件](#暫未實作組件)
6. [使用場景與最佳實踐](#使用場景與最佳實踐)

---

## 概述

本專案的 Widget 設計以**無障礙優先**為核心理念，提供完整的手勢支援與語音回饋系統。

**設計原則**:
- **適應性**: 自動偵測系統無障礙模式，切換手勢策略
- **可組合**: 所有 Widget 可自由組合使用
- **易用性**: 提供簡化版 Scaffold 包裝器
- **一致性**: 統一的手勢語意與操作邏輯

**Widget 分類**:

### 無障礙手勢組件
- [AccessibleGestureWrapper](#accessiblegesturewrapper) - 智能手勢包裝器
- [AccessibleSpeakWrapper](#accessiblespeakwrapper) - 語音朗讀包裝器
- [GlobalGestureWrapper](#globalgesturewrapper) - 全域導航手勢
- [UnifiedGestureWrapper](#unifiedgesturewrapper) - 統一手勢包裝器

### 焦點導航組件
- [FocusableItemWidget](#focusableitemwidget) - 可聚焦元素組件
- [FocusableListPage](#focusablelistpage) - 可聚焦列表頁面基類

### 商品展示組件
- [ProductCard](#productcard) - 商品卡片組件
- [CustomCard](#customcard) - 自訂商品卡片

### 暫未實作
- voice_button.dart
- accessible_text_field.dart

---

## 無障礙手勢組件

### AccessibleGestureWrapper

**檔案**: [accessible_gesture_wrapper.dart](accessible_gesture_wrapper.dart)

**用途**: 根據系統無障礙模式自動切換手勢策略的智能包裝器。

#### 核心功能

**自動策略切換**:
- **系統無障礙模式啟用時**: 使用 `Semantics` + 標準單擊
- **系統無障礙模式未啟用時**: 使用自訂 TTS + 雙擊手勢

#### 屬性

| 屬性 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `label` | `String` | ✅ | 語意標籤（用於系統無障礙服務） |
| `description` | `String?` | ❌ | 語意描述（提示文字） |
| `onTap` | `VoidCallback?` | ✅ | 點擊/雙擊動作 |
| `child` | `Widget` | ✅ | 要包裝的子元件 |
| `enabled` | `bool` | ❌ | 是否啟用（預設 `true`） |
| `customSpeakText` | `String?` | ❌ | 自訂朗讀文字（覆蓋 label） |

#### 手勢行為對比

| 場景 | 系統無障礙啟用 | 系統無障礙未啟用 |
|------|----------------|------------------|
| 點擊一次 | 執行動作 | 語音朗讀 |
| 點擊兩次 | 執行動作兩次 | 執行動作 |
| 語音朗讀 | 由系統處理 | 自訂 TTS |

#### 使用範例

```dart
// 基本用法
AccessibleGestureWrapper(
  label: '確認按鈕',
  description: '點擊後前往下一步',
  onTap: () {
    Navigator.push(context, ...);
  },
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('確認'),
  ),
)

// 自訂朗讀文字
AccessibleGestureWrapper(
  label: '加入購物車',
  customSpeakText: 'Nike Air Max 270，價格 4500 元，加入購物車',
  onTap: () => addToCart(product),
  child: Icon(Icons.add_shopping_cart),
)

// 禁用狀態
AccessibleGestureWrapper(
  label: '結帳按鈕',
  enabled: false, // 購物車為空時禁用
  onTap: () => checkout(),
  child: ElevatedButton(
    onPressed: null,
    child: Text('結帳'),
  ),
)
```

**位置**: [accessible_gesture_wrapper.dart:20](accessible_gesture_wrapper.dart#L20)

---

### AccessibleSpeakWrapper

**檔案**: [accessible_gesture_wrapper.dart](accessible_gesture_wrapper.dart)

**用途**: 僅提供語音朗讀的包裝器，無手勢動作。

#### 屬性

| 屬性 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `label` | `String` | ✅ | 語意標籤 |
| `child` | `Widget` | ✅ | 要包裝的子元件 |
| `customSpeakText` | `String?` | ❌ | 自訂朗讀文字 |

#### 使用場景

適用於**純資訊展示**元件，不需要互動動作：
- 統計資訊卡片
- 總計金額顯示
- 訂單狀態標籤

#### 使用範例

```dart
// 統計資訊
AccessibleSpeakWrapper(
  label: '商品總計 500 元',
  child: Text(
    '總計: \$500',
    style: TextStyle(fontSize: 24),
  ),
)

// 訂單狀態
AccessibleSpeakWrapper(
  label: '訂單狀態：待出貨',
  customSpeakText: '您的訂單目前狀態為待出貨，預計明天送達',
  child: Chip(
    label: Text('待出貨'),
    backgroundColor: Colors.orange,
  ),
)
```

**位置**: [accessible_gesture_wrapper.dart:89](accessible_gesture_wrapper.dart#L89)

---

### GlobalGestureWrapper

**檔案**: [global_gesture_wrapper.dart](global_gesture_wrapper.dart)

**用途**: 為頁面添加全域導航手勢支援（雙指上滑/下滑）。

#### 支援手勢

| 手勢 | 動作 | 說明 |
|------|------|------|
| **兩指上滑** | 回首頁 | `Navigator.pushNamedAndRemoveUntil('/home')` |
| **兩指下滑** | 回上一頁 | `Navigator.pop()` |

#### 屬性

| 屬性 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `child` | `Widget` | - | 子 Widget |
| `enabled` | `bool` | `true` | 是否啟用全域手勢 |
| `onlyInCustomMode` | `bool` | `true` | 是否只在自訂模式下啟用 |

#### 使用方式

**方式 1: 包裝頁面內容**
```dart
Scaffold(
  appBar: AppBar(title: Text('商品列表')),
  body: GlobalGestureWrapper(
    child: ProductListContent(),
  ),
)
```

**方式 2: 使用簡化版 Scaffold**
```dart
GlobalGestureScaffold(
  appBar: AppBar(title: Text('商品列表')),
  body: ProductListContent(),
  enableGlobalGestures: true,
)
```

#### 實作原理

使用 `Listener` 監聽觸控事件：
1. **onPointerDown**: 記錄觸控點起始位置
2. **onPointerMove**: 更新觸控點當前位置
3. **onPointerUp**: 計算滑動距離並判斷手勢

**偵測邏輯**:
```dart
// 計算兩個觸控點的平均滑動距離
final averageDeltaY = (deltaY1 + deltaY2) / 2;

if (averageDeltaY < -threshold) {
  // 向上滑動 - 回首頁
} else if (averageDeltaY > threshold) {
  // 向下滑動 - 回上一頁
}
```

#### 配置選項

透過 `GlobalGestureService` 調整手勢配置：
```dart
globalGestureService.updateConfig(
  GlobalGestureConfig(
    enableVoiceFeedback: true,    // 語音提示
    enableHapticFeedback: true,   // 觸覺反饋
    swipeThreshold: 50.0,         // 滑動閾值（像素）
  ),
);
```

**位置**: [global_gesture_wrapper.dart:25](global_gesture_wrapper.dart#L25)

---

### UnifiedGestureWrapper

**檔案**: [unified_gesture_wrapper.dart](unified_gesture_wrapper.dart)

**用途**: 整合頁面級和全局手勢的統一包裝器，提供完整的手勢支援。

#### 支援手勢 (6 種)

| 手勢 | 動作 | 說明 |
|------|------|------|
| **左往右滑** | 上個項目 | `focusNavigationService.moveToPrevious()` |
| **右往左滑** | 下個項目 | `focusNavigationService.moveToNext()` |
| **單擊** | 朗讀元素 | `focusNavigationService.readCurrent()` |
| **雙擊** | 激活/選取元素 | `focusNavigationService.activateCurrent()` |
| **兩指上滑** | 回首頁 | `globalGestureService.handleTwoFingerSwipeUp()` |
| **兩指下滑** | 回上一頁 | `globalGestureService.handleTwoFingerSwipeDown()` |

#### 屬性

| 屬性 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `child` | `Widget` | - | 子 Widget |
| `enableGlobalGestures` | `bool` | `true` | 啟用全局手勢（雙指） |
| `enablePageGestures` | `bool` | `true` | 啟用頁面級手勢（單指） |
| `onlyInCustomMode` | `bool` | `true` | 只在自訂模式下啟用 |
| `horizontalSwipeThreshold` | `double` | `50.0` | 水平滑動閾值 |
| `verticalSwipeThreshold` | `double` | `50.0` | 垂直滑動閾值 |
| `doubleTapInterval` | `int` | `300` | 雙擊間隔時間（毫秒） |

#### 使用方式

**方式 1: 完整手勢支援**
```dart
Scaffold(
  body: UnifiedGestureWrapper(
    child: MyPageContent(),
  ),
)
```

**方式 2: 僅全局手勢**
```dart
UnifiedGestureWrapper(
  enableGlobalGestures: true,
  enablePageGestures: false,
  child: MyPageContent(),
)
```

**方式 3: 使用簡化版 Scaffold**
```dart
UnifiedGestureScaffold(
  appBar: AppBar(title: Text('商品列表')),
  body: ProductListContent(),
  enableGlobalGestures: true,
  enablePageGestures: true,
)
```

#### 手勢偵測邏輯

**單指手勢判斷流程**:
```
1. 計算滑動距離: deltaX, deltaY
2. 判斷是否為滑動: |deltaX| > threshold && |deltaX| > |deltaY|
   └─ 是: 判斷方向（左往右 or 右往左）
   └─ 否: 判斷是否為點擊（移動距離 < 10px）
      └─ 檢查雙擊: 距離上次點擊 < 300ms
         └─ 是: 執行激活動作
         └─ 否: 執行朗讀動作
```

**雙指手勢判斷流程**:
```
1. 確認觸控點數量 == 2
2. 計算兩點平均滑動距離: averageDeltaY
3. 判斷方向:
   └─ averageDeltaY < -threshold: 回首頁
   └─ averageDeltaY > threshold: 回上一頁
```

#### 與其他手勢組件的差異

| 組件 | 單指滑動 | 點擊/雙擊 | 雙指滑動 | 適用場景 |
|------|---------|----------|---------|---------|
| `AccessibleGestureWrapper` | ❌ | ✅ | ❌ | 單一元件互動 |
| `GlobalGestureWrapper` | ❌ | ❌ | ✅ | 純導航 |
| `UnifiedGestureWrapper` | ✅ | ✅ | ✅ | 列表頁面 |

**位置**: [unified_gesture_wrapper.dart:28](unified_gesture_wrapper.dart#L28)

---

## 焦點導航組件

### FocusableItemWidget

**檔案**: [focusable_item_widget.dart](focusable_item_widget.dart)

**用途**: 自動將元素註冊到焦點導航系統，支援手勢操作與視覺高亮。

#### 屬性

| 屬性 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `id` | `String` | ✅ | 元素 ID（用於識別） |
| `label` | `String` | ✅ | 朗讀文本 |
| `type` | `String` | ✅ | 元素類型（按鈕、商品等） |
| `onActivate` | `VoidCallback?` | ❌ | 雙擊激活動作 |
| `onRead` | `VoidCallback?` | ❌ | 單擊朗讀動作（預設使用 label） |
| `child` | `Widget` | ✅ | 子組件 |
| `autoScroll` | `bool` | ❌ | 自動滾動到可見區域（預設 `true`） |

#### 功能特性

1. **自動聚焦高亮**: 被聚焦時自動添加邊框高亮效果
2. **自動滾動**: 聚焦元素自動滾動到可見區域
3. **焦點追蹤**: 監聽焦點變化並更新視覺狀態

#### 使用範例

```dart
FocusableItemWidget(
  id: 'product-1',
  label: 'Nike Air Max 270，價格 4500 元',
  type: '商品',
  onActivate: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  },
  child: ProductCard(product: product),
)
```

#### 視覺效果

**未聚焦狀態**: 正常顯示
```dart
child: widget.child
```

**聚焦狀態**: 添加高亮邊框
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: Theme.of(context).primaryColor,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: widget.child,
)
```

**位置**: [focusable_item_widget.dart:22](focusable_item_widget.dart#L22)

---

### FocusableListPage

**檔案**: [focusable_item_widget.dart](focusable_item_widget.dart)

**用途**: 簡化列表類頁面的手勢集成的抽象基類。

#### 使用方式

```dart
class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState
    extends FocusableListPageState<ProductListPage> {

  final List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  List<FocusableItem> buildFocusableItems() {
    return _products.map((product) {
      return FocusableItem(
        id: 'product-${product.id}',
        label: '${product.name}，價格 ${product.price} 元',
        type: '商品',
        focusNode: FocusNode(),
        onActivate: () => _openProductDetail(product),
      );
    }).toList();
  }

  @override
  Widget buildContent(BuildContext context) {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return FocusableItemWidget(
          id: 'product-${_products[index].id}',
          label: '${_products[index].name}',
          type: '商品',
          onActivate: () => _openProductDetail(_products[index]),
          child: ProductCard(product: _products[index]),
        );
      },
    );
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  }
}
```

#### 生命週期

1. **initState**: 自動註冊可聚焦元素
2. **dispose**: 自動清除焦點導航
3. **refreshFocusableItems()**: 當列表內容變化時手動調用

#### 刷新列表

當列表內容變化時（如：搜尋、篩選），需要手動刷新：

```dart
void _onSearchChanged(String keyword) {
  setState(() {
    _products = _searchProducts(keyword);
  });

  // 刷新焦點導航
  refreshFocusableItems();
}
```

**位置**: [focusable_item_widget.dart:142](focusable_item_widget.dart#L142)

---

## 商品展示組件

### ProductCard

**檔案**: [product_card.dart](product_card.dart)

**用途**: 標準化的商品卡片組件，可用於多個頁面。

#### 屬性

| 屬性 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `product` | `Product` | ✅ | 商品資料模型 |
| `tag` | `String?` | ❌ | 標籤（如：隔日到貨） |
| `storeName` | `String?` | ❌ | 商家名稱 |
| `onStoreDoubleTap` | `VoidCallback?` | ❌ | 雙擊商家時的回調 |

#### 顯示內容

1. **商品名稱** - 粗體大標題（35px）
2. **價格** - 主色調顯示（30px）
3. **商家名稱** - 灰色，附商店圖示，可雙擊
4. **商品描述** - 最多 4 行，超出省略
5. **標籤/分類** - 右下角標籤（tag 優先於 category）

#### 使用範例

```dart
// 基本用法
ProductCard(
  product: product,
)

// 顯示商家名稱
ProductCard(
  product: product,
  storeName: '運動世界專賣店',
)

// 添加標籤與商家互動
ProductCard(
  product: product,
  tag: '隔日到貨',
  storeName: '運動世界專賣店',
  onStoreDoubleTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StorePage(storeId: product.storeId),
      ),
    );
  },
)
```

#### 樣式配置

使用 `AppConstants` 統一樣式：
- 字體大小: 35px (標題), 30px (價格/內容), 26px (商家)
- 間距: `AppSpacing.sm`, `AppSpacing.md`
- 顏色: `AppColors.text`, `AppColors.primary`, `AppColors.accent`

**位置**: [product_card.dart:7](product_card.dart#L7)

---

### CustomCard

**檔案**: [custom_card.dart](custom_card.dart)

**用途**: 接收 `productMap` 並顯示的輕量級商品卡片。

#### 屬性

| 屬性 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `productMap` | `Map<String, dynamic>` | ✅ | 商品資料 Map |
| `onAddToCart` | `VoidCallback` | ✅ | 加入購物車回調 |

#### productMap 結構

```dart
{
  'id': 1,                          // 商品 ID
  'name': 'Nike Air Max 270',       // 商品名稱
  'price': 4500.0,                  // 價格（double）
  'imageUrl': 'https://...',        // 圖片 URL
}
```

#### 使用場景

適用於**不需要完整 Product 模型**的場景：
- 首頁商品推薦
- 快速商品展示
- 簡化的商品列表

#### 使用範例

```dart
CustomCard(
  productMap: {
    'id': 1,
    'name': 'Nike Air Max 270',
    'price': 4500.0,
    'imageUrl': 'https://picsum.photos/400/400?random=1',
  },
  onAddToCart: () {
    // 加入購物車邏輯
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入購物車')),
    );
  },
)
```

#### 與 ProductCard 的差異

| 特性 | CustomCard | ProductCard |
|------|-----------|-------------|
| 資料結構 | `Map<String, dynamic>` | `Product` 模型 |
| 商家資訊 | ❌ | ✅ |
| 描述文字 | ❌ | ✅ |
| 標籤支援 | ❌ | ✅ |
| 購物車按鈕 | ✅ | ❌ |
| 適用場景 | 簡化展示 | 完整資訊 |

**位置**: [custom_card.dart:8](custom_card.dart#L8)

---

## 暫未實作組件

以下組件檔案存在但尚未實作完整功能：

### voice_button.dart
**狀態**: 空檔案（僅 1 行）
**計劃用途**: 語音輸入按鈕組件

### accessible_text_field.dart
**狀態**: 空檔案（僅 1 行）
**計劃用途**: 無障礙文字輸入框組件

---

## 使用場景與最佳實踐

### 場景 1: 簡單頁面（只需全局手勢）

適用於**資訊展示頁面**，不需要列表導航。

```dart
GlobalGestureScaffold(
  appBar: AppBar(title: Text('關於我們')),
  body: AboutUsContent(),
)
```

**手勢支援**:
- ✅ 雙指上滑回首頁
- ✅ 雙指下滑回上一頁

---

### 場景 2: 列表頁面（需要完整手勢）

適用於**商品列表、搜尋結果**等需要焦點導航的頁面。

```dart
UnifiedGestureScaffold(
  appBar: AppBar(title: Text('商品列表')),
  body: ListView.builder(
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      return FocusableItemWidget(
        id: 'product-${product.id}',
        label: '${product.name}，價格 ${product.price} 元',
        type: '商品',
        onActivate: () => _openProductDetail(product),
        child: ProductCard(product: product),
      );
    },
  ),
)
```

**手勢支援**:
- ✅ 左往右滑 → 上個商品
- ✅ 右往左滑 → 下個商品
- ✅ 單擊 → 朗讀商品資訊
- ✅ 雙擊 → 開啟商品詳情
- ✅ 雙指上滑 → 回首頁
- ✅ 雙指下滑 → 回上一頁

---

### 場景 3: 按鈕互動（單一元件）

適用於**單一按鈕、卡片**等獨立互動元件。

```dart
AccessibleGestureWrapper(
  label: '加入購物車',
  description: 'Nike Air Max 270，價格 4500 元',
  onTap: () => addToCart(product),
  child: ElevatedButton(
    onPressed: () => addToCart(product),
    child: Row(
      children: [
        Icon(Icons.add_shopping_cart),
        SizedBox(width: 8),
        Text('加入購物車'),
      ],
    ),
  ),
)
```

**手勢行為**:
- 系統無障礙啟用: 單擊執行動作
- 系統無障礙未啟用: 單擊朗讀，雙擊執行動作

---

### 場景 4: 純資訊展示（無互動）

適用於**統計卡片、狀態標籤**等純資訊元件。

```dart
AccessibleSpeakWrapper(
  label: '商品總計 5400 元，優惠折扣 100 元，運費 60 元，訂單總金額 5360 元',
  child: Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('商品小計'),
              Text('\$5400'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('優惠折扣'),
              Text('-\$100'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('運費'),
              Text('\$60'),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('總計', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$5360', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  ),
)
```

---

### 最佳實踐

#### 1. 選擇合適的手勢組件

```dart
// ✅ 正確：列表頁面使用統一手勢包裝器
UnifiedGestureScaffold(
  body: ListView(...),
)

// ❌ 避免：列表頁面使用全局手勢（缺少列表導航）
GlobalGestureScaffold(
  body: ListView(...),
)

// ✅ 正確：資訊頁面使用全局手勢
GlobalGestureScaffold(
  body: AboutUsContent(),
)
```

---

#### 2. 提供有意義的 label

```dart
// ✅ 正確：完整描述元件功能
AccessibleGestureWrapper(
  label: 'Nike Air Max 270，價格 4500 元，加入購物車',
  onTap: () => addToCart(product),
  child: IconButton(icon: Icon(Icons.add_shopping_cart)),
)

// ❌ 避免：只有動作名稱
AccessibleGestureWrapper(
  label: '加入購物車',  // 不夠完整
  onTap: () => addToCart(product),
  child: IconButton(icon: Icon(Icons.add_shopping_cart)),
)
```

---

#### 3. 統一使用 FocusableItemWidget

```dart
// ✅ 正確：使用 FocusableItemWidget 包裝列表項目
ListView.builder(
  itemBuilder: (context, index) {
    return FocusableItemWidget(
      id: 'product-${products[index].id}',
      label: '${products[index].name}',
      type: '商品',
      onActivate: () => _openDetail(products[index]),
      child: ProductCard(product: products[index]),
    );
  },
)

// ❌ 避免：直接使用 AccessibleGestureWrapper（缺少焦點追蹤）
ListView.builder(
  itemBuilder: (context, index) {
    return AccessibleGestureWrapper(
      label: '${products[index].name}',
      onTap: () => _openDetail(products[index]),
      child: ProductCard(product: products[index]),
    );
  },
)
```

---

#### 4. 手勢閾值調整

```dart
// 預設閾值適合大多數場景
UnifiedGestureWrapper(
  horizontalSwipeThreshold: 50.0,  // 預設
  verticalSwipeThreshold: 50.0,    // 預設
  child: MyContent(),
)

// 較小螢幕或需要更靈敏的手勢
UnifiedGestureWrapper(
  horizontalSwipeThreshold: 30.0,  // 更靈敏
  verticalSwipeThreshold: 30.0,
  child: MyContent(),
)

// 防止誤觸（大型平板）
UnifiedGestureWrapper(
  horizontalSwipeThreshold: 80.0,  // 更高閾值
  verticalSwipeThreshold: 80.0,
  child: MyContent(),
)
```

---

#### 5. 合理使用 enabled 屬性

```dart
// ✅ 正確：根據狀態動態禁用
AccessibleGestureWrapper(
  label: '結帳',
  enabled: cart.selectedItems.isNotEmpty,  // 購物車有商品時啟用
  onTap: () => checkout(),
  child: ElevatedButton(
    onPressed: cart.selectedItems.isNotEmpty ? () => checkout() : null,
    child: Text('結帳'),
  ),
)

// ❌ 避免：hardcode enabled
AccessibleGestureWrapper(
  label: '結帳',
  enabled: true,  // 不夠靈活
  onTap: () => checkout(),
  child: ElevatedButton(...),
)
```

---

## Widget 組合建議

### 完整列表頁面架構

```dart
UnifiedGestureScaffold(
  appBar: AppBar(
    title: AccessibleSpeakWrapper(
      label: '商品列表頁面',
      child: Text('商品列表'),
    ),
  ),
  body: ListView.builder(
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];

      return FocusableItemWidget(
        id: 'product-${product.id}',
        label: '${product.name}，價格 ${product.price} 元',
        type: '商品',
        onActivate: () => _openDetail(product),
        child: AccessibleGestureWrapper(
          label: '${product.name}，價格 ${product.price} 元',
          onTap: () => _openDetail(product),
          child: ProductCard(
            product: product,
            storeName: store.name,
            onStoreDoubleTap: () => _openStore(product.storeId),
          ),
        ),
      );
    },
  ),
  bottomNavigationBar: AccessibleSpeakWrapper(
    label: '已選 ${cart.selectedItems.length} 件商品，總計 ${cart.totalPrice} 元',
    child: BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('總計: \$${cart.totalPrice}'),
          AccessibleGestureWrapper(
            label: '結帳按鈕，已選 ${cart.selectedItems.length} 件商品',
            enabled: cart.selectedItems.isNotEmpty,
            onTap: () => _checkout(),
            child: ElevatedButton(
              onPressed: cart.selectedItems.isNotEmpty ? _checkout : null,
              child: Text('結帳'),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

## 更新紀錄

- **2025-01-23**: 初始版本，記錄所有 widgets 資料夾中的組件
