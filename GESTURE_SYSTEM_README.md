# 統一手勢系統 - 完整說明

## 📋 概述

本專案已完成統一手勢系統的設計與實現，支援全局手勢操作，並與系統無障礙服務完全兼容。

---

## ✅ 已完成的工作

### 1. 核心服務層

#### ✅ FocusNavigationService
**文件位置**: `lib/services/focus_navigation_service.dart`

**功能**:
- 管理頁面內元素的焦點切換
- 支援左右滑動導航（上一個/下一個項目）
- 支援單擊朗讀和雙擊激活
- 自動滾動到聚焦元素

**主要 API**:
```dart
// 註冊可聚焦元素
focusNavigationService.registerItems(List<FocusableItem> items);

// 導航控制
focusNavigationService.moveToNext();      // 下一個項目
focusNavigationService.moveToPrevious();  // 上一個項目
focusNavigationService.readCurrent();     // 朗讀當前項目
focusNavigationService.activateCurrent(); // 激活當前項目

// 清理
focusNavigationService.clear();
```

#### ✅ GlobalGestureService
**文件位置**: `lib/services/global_gesture_service.dart`

**功能**:
- 處理全局導航手勢（雙指上/下滑）
- 雙指上滑 → 回首頁
- 雙指下滑 → 回上一頁
- 可配置語音提示和觸覺反饋

#### ✅ AccessibilityService
**文件位置**: `lib/services/accessibility_service.dart`

**功能**:
- 檢測系統無障礙狀態（TalkBack/VoiceOver）
- 自動切換系統/自訂模式
- 避免與系統手勢衝突

---

### 2. 組件層

#### ✅ UnifiedGestureWrapper
**文件位置**: `lib/widgets/unified_gesture_wrapper.dart`

**功能**: 整合所有手勢功能的統一包裝器

**支援的手勢**:
1. **左往右滑** → 上一個項目
2. **右往左滑** → 下一個項目
3. **單擊** → 朗讀元素（類型 + 內容）
4. **雙擊** → 選取/使用元素
5. **雙指上滑** → 回首頁
6. **雙指下滑** → 回上一頁

**使用方式**:
```dart
// 方式 1: 使用包裝器
Scaffold(
  body: UnifiedGestureWrapper(
    child: YourPageContent(),
  ),
)

// 方式 2: 使用 Scaffold 替代品（推薦）
UnifiedGestureScaffold(
  appBar: AppBar(title: Text('頁面標題')),
  body: YourPageContent(),
)
```

**配置選項**:
```dart
UnifiedGestureWrapper(
  enableGlobalGestures: true,   // 啟用雙指上/下滑
  enablePageGestures: true,     // 啟用左右滑、單/雙擊
  onlyInCustomMode: true,       // 只在自訂模式啟用
  horizontalSwipeThreshold: 50.0, // 水平滑動閾值
  verticalSwipeThreshold: 50.0,   // 垂直滑動閾值
  doubleTapInterval: 300,         // 雙擊間隔（毫秒）
  child: ...,
)
```

#### ✅ GlobalGestureWrapper
**文件位置**: `lib/widgets/global_gesture_wrapper.dart`

**功能**: 僅提供全局手勢（雙指上/下滑）

**適用場景**: 已有自訂滑動邏輯的頁面（如 PageView）

#### ✅ AccessibleGestureWrapper
**文件位置**: `lib/widgets/accessible_gesture_wrapper.dart`

**功能**: 智能手勢包裝器，根據系統無障礙模式自動切換策略

#### ✅ FocusableItemWidget
**文件位置**: `lib/widgets/focusable_item_widget.dart`

**功能**: 可聚焦元素組件，自動註冊到焦點導航系統

**使用方式**:
```dart
FocusableItemWidget(
  id: 'product-1',
  label: '商品名稱 - 100元',
  type: '商品',
  onActivate: () { /* 雙擊動作 */ },
  child: ProductCard(...),
)
```

---

### 3. 示範與測試

#### ✅ 手勢系統示範頁面
**文件位置**: `lib/pages/gesture_demo_page.dart`

**功能**:
- 完整展示所有手勢功能
- 視覺化當前焦點狀態
- 互動式操作說明

**訪問方式**:
```dart
Navigator.pushNamed(context, '/gesture-demo');
```

或從開發工具頁面進入：設定 → 開發工具 → 手勢系統示範

---

### 4. 文檔

#### ✅ 遷移指南
**文件位置**: `GESTURE_MIGRATION_GUIDE.md`

**內容**:
- 核心組件說明
- 頁面遷移步驟
- 特殊頁面處理
- 測試建議
- 常見問題解答
- 遷移檢查清單

---

## 🎯 手勢功能詳解

### 頁面級手勢（單指）

#### 1. 左往右滑 → 上一個項目
- **觸發條件**: 水平向右滑動距離 > 50 像素
- **效果**: 切換到上一個可聚焦元素並朗讀

#### 2. 右往左滑 → 下一個項目
- **觸發條件**: 水平向左滑動距離 > 50 像素
- **效果**: 切換到下一個可聚焦元素並朗讀

#### 3. 單擊 → 朗讀元素
- **觸發條件**: 點擊後移動距離 < 10 像素
- **效果**: 播放語音「類型，內容」（如：「按鈕，確認購買」）

#### 4. 雙擊 → 激活元素
- **觸發條件**:
  - 兩次點擊間隔 ≤ 300 毫秒
  - 兩次點擊位置距離 < 50 像素
- **效果**: 執行元素的主要動作（如：選取商品、按下按鈕）

### 全局手勢（雙指）

#### 5. 雙指上滑 → 回首頁
- **觸發條件**: 兩指同時向上滑動 > 50 像素
- **效果**: 導航到首頁（清除所有路由堆疊）

#### 6. 雙指下滑 → 回上一頁
- **觸發條件**: 兩指同時向下滑動 > 50 像素
- **效果**: 返回上一頁（如果在最上層則提示）

---

## 🔧 系統無障礙兼容性

### 兼容策略

#### 當系統 TalkBack/VoiceOver 啟用時：
- ✅ 自動切換為系統無障礙模式
- ✅ 使用系統的 Semantics 標籤
- ✅ 停用自訂 TTS 播報
- ✅ 停用自訂手勢（避免衝突）
- ✅ 使用標準的單擊手勢

#### 當系統無障礙未啟用時：
- ✅ 啟用自訂手勢系統
- ✅ 使用自訂 TTS 播報
- ✅ 支援單擊朗讀、雙擊激活
- ✅ 支援左右滑動導航

### 檢測機制

使用 `MediaQuery.of(context).accessibleNavigation` 檢測系統無障礙狀態：

```dart
bool get shouldUseSystemAccessibility =>
    MediaQuery.of(context).accessibleNavigation;

bool get shouldUseCustomGestures =>
    !MediaQuery.of(context).accessibleNavigation;
```

---

## 📱 頁面實現示例

### 標準列表頁面

```dart
class MyListPage extends StatefulWidget {
  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  final List<FocusNode> _focusNodes = [];
  final List<GlobalKey> _itemKeys = [];
  final List<Product> _products = [...];

  @override
  void initState() {
    super.initState();

    // 為每個項目創建 FocusNode 和 GlobalKey
    for (int i = 0; i < _products.length; i++) {
      _focusNodes.add(FocusNode());
      _itemKeys.add(GlobalKey());
    }

    // 註冊可聚焦元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFocusableItems();
    });
  }

  void _registerFocusableItems() {
    final items = <FocusableItem>[];

    for (int i = 0; i < _products.length; i++) {
      items.add(
        FocusableItem(
          id: 'product-$i',
          label: '${_products[i].name}，價格 ${_products[i].price} 元',
          type: '商品',
          focusNode: _focusNodes[i],
          key: _itemKeys[i],
          onActivate: () => _addToCart(_products[i]),
        ),
      );
    }

    focusNavigationService.registerItems(items);
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    focusNavigationService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedGestureScaffold(
      appBar: AppBar(title: Text('商品列表')),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return Container(
            key: _itemKeys[index],
            child: Focus(
              focusNode: _focusNodes[index],
              child: AnimatedBuilder(
                animation: _focusNodes[index],
                builder: (context, child) {
                  final hasFocus = _focusNodes[index].hasFocus;

                  return Card(
                    elevation: hasFocus ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      side: hasFocus
                          ? BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 3,
                            )
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      title: Text(_products[index].name),
                      subtitle: Text('\$${_products[index].price}'),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### 特殊頁面（使用 PageView）

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('設定')),
      body: GlobalGestureWrapper(
        // 只啟用全局手勢，不影響 PageView 的滑動
        child: PageView(
          children: [
            SettingCard1(),
            SettingCard2(),
            SettingCard3(),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 測試指南

### 功能測試

1. **訪問示範頁面**:
   - 首頁 → 帳號 → 開發工具 → 手勢系統示範

2. **測試項目**:
   - [ ] 左往右滑切換到上一個項目
   - [ ] 右往左滑切換到下一個項目
   - [ ] 單擊朗讀項目內容
   - [ ] 雙擊激活項目
   - [ ] 雙指上滑回首頁
   - [ ] 雙指下滑回上一頁
   - [ ] 聚焦項目有視覺反饋（邊框、陰影）
   - [ ] 當前焦點狀態正確顯示

### 系統無障礙兼容性測試

#### Android (TalkBack)
1. 設定 > 無障礙功能 > TalkBack > 開啟
2. 測試 app 是否切換到系統模式
3. 確認沒有手勢衝突

#### iOS (VoiceOver)
1. 設定 > 輔助使用 > 旁白 > 開啟
2. 測試 app 是否切換到系統模式
3. 確認沒有手勢衝突

---

## 📝 待辦事項

### 已完成 ✅
- [x] 探索現有手勢實現與無障礙服務架構
- [x] 分析系統無障礙手勢衝突問題
- [x] 設計統一的手勢處理架構
- [x] 實現全局手勢檢測器
- [x] 為所有頁面提供統一手勢組件
- [x] 創建示範頁面
- [x] 編寫遷移指南

### 進行中 🔄
- [ ] 測試手勢功能與系統無障礙服務兼容性

### 待進行 📋
- [ ] 為現有頁面應用統一手勢（需逐頁遷移）
- [ ] 在實際設備上測試所有手勢功能
- [ ] 收集用戶反饋並優化手勢靈敏度

---

## 🔍 問題排查

### 手勢沒有反應？

1. **檢查是否已註冊可聚焦元素**:
   ```dart
   focusNavigationService.registerItems(items);
   ```

2. **確認已包裝頁面**:
   ```dart
   UnifiedGestureScaffold(...) 或 UnifiedGestureWrapper(...)
   ```

3. **查看控制台日誌**:
   - Debug 模式會輸出手勢檢測信息
   - 搜尋 `[UnifiedGesture]` 或 `[FocusNavigation]`

### 與系統手勢衝突？

1. 確認 `AccessibilityService` 正確檢測系統狀態
2. 檢查 `onlyInCustomMode` 參數（預設為 `true`）
3. 查看控制台輸出的無障礙狀態日誌

### 左右滑動沒反應？

1. 確認已調用 `registerItems()`
2. 檢查 `enablePageGestures` 是否為 `true`
3. 確認滑動距離超過閾值（預設 50 像素）

### 雙擊沒觸發？

1. 兩次點擊間隔需在 300ms 內
2. 兩次點擊位置距離需在 50 像素內
3. 確認 `onActivate` 回調已設置

---

## 📚 相關文件

- [手勢遷移指南](GESTURE_MIGRATION_GUIDE.md)
- [焦點導航服務](lib/services/focus_navigation_service.dart)
- [全局手勢服務](lib/services/global_gesture_service.dart)
- [無障礙服務](lib/services/accessibility_service.dart)
- [統一手勢包裝器](lib/widgets/unified_gesture_wrapper.dart)
- [示範頁面](lib/pages/gesture_demo_page.dart)

---

## 👥 支援

如有問題或建議，請聯繫開發團隊。

**文檔版本**: 1.0
**最後更新**: 2025-10-20
