# 手勢系統遷移指南

## 概述

本專案實現了統一的手勢系統，支援以下手勢操作：

### 全局手勢（所有頁面適用）
1. **左往右滑** = 上個項目（頁面元素）
2. **右往左滑** = 下個項目（頁面元素）
3. **單擊** = 朗讀元素內容及類型
4. **雙擊** = 選取（購物車）或使用（按鈕或入口）元素
5. **雙指上滑** = 回首頁
6. **雙指下滑** = 回上一頁

### 與系統無障礙服務的兼容性
- 當系統 TalkBack/VoiceOver 啟用時，自動切換為系統無障礙模式
- 當系統無障礙未啟用時，使用自訂手勢和 TTS
- 完全避免與系統手勢衝突

---

## 核心組件

### 1. 服務層

#### `FocusNavigationService`
位置：`lib/services/focus_navigation_service.dart`

管理頁面內元素的焦點切換。

**主要方法：**
```dart
// 註冊可聚焦元素
focusNavigationService.registerItems(List<FocusableItem> items);

// 移動到下一個元素
focusNavigationService.moveToNext();

// 移動到上一個元素
focusNavigationService.moveToPrevious();

// 朗讀當前元素
focusNavigationService.readCurrent();

// 激活當前元素
focusNavigationService.activateCurrent();

// 清除所有元素
focusNavigationService.clear();
```

#### `GlobalGestureService`
位置：`lib/services/global_gesture_service.dart`

處理全局導航手勢（雙指上/下滑）。

#### `AccessibilityService`
位置：`lib/services/accessibility_service.dart`

檢測系統無障礙狀態，決定使用系統或自訂模式。

---

### 2. 組件層

#### `UnifiedGestureWrapper`
位置：`lib/widgets/unified_gesture_wrapper.dart`

統一手勢包裝器，整合頁面級和全局手勢功能。

**使用方式：**
```dart
Scaffold(
  body: UnifiedGestureWrapper(
    child: YourPageContent(),
  ),
)
```

#### `UnifiedGestureScaffold`
位置：`lib/widgets/unified_gesture_wrapper.dart`

簡化版，直接替代 Scaffold。

**使用方式：**
```dart
UnifiedGestureScaffold(
  appBar: AppBar(title: Text('頁面標題')),
  body: YourPageContent(),
)
```

#### `FocusableItemWidget`
位置：`lib/widgets/focusable_item_widget.dart`

可聚焦元素組件，自動註冊到焦點導航系統。

---

## 頁面遷移步驟

### 步驟 1：替換 Scaffold

**舊代碼：**
```dart
Scaffold(
  appBar: AppBar(title: Text('頁面')),
  body: ListView(...),
)
```

**新代碼：**
```dart
UnifiedGestureScaffold(
  appBar: AppBar(title: Text('頁面')),
  body: ListView(...),
)
```

或者使用包裝器：
```dart
Scaffold(
  appBar: AppBar(title: Text('頁面')),
  body: UnifiedGestureWrapper(
    child: ListView(...),
  ),
)
```

---

### 步驟 2：註冊可聚焦元素

為頁面中的互動元素創建 `FocusableItem` 並註冊到 `FocusNavigationService`。

#### 方法 A：手動註冊（適用於列表頁面）

```dart
class MyListPage extends StatefulWidget {
  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  final List<FocusNode> _focusNodes = [];
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();

    // 為每個項目創建 FocusNode 和 GlobalKey
    for (int i = 0; i < items.length; i++) {
      _focusNodes.add(FocusNode());
      _itemKeys.add(GlobalKey());
    }

    // 註冊可聚焦元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFocusableItems();
    });
  }

  void _registerFocusableItems() {
    final focusableItems = <FocusableItem>[];

    for (int i = 0; i < items.length; i++) {
      focusableItems.add(
        FocusableItem(
          id: 'item-$i',
          label: '${items[i].name}，價格 ${items[i].price} 元',
          type: '商品',
          focusNode: _focusNodes[i],
          key: _itemKeys[i],
          onActivate: () => _onItemSelected(i),
        ),
      );
    }

    focusNavigationService.registerItems(focusableItems);
  }

  @override
  void dispose() {
    // 清理資源
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
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            key: _itemKeys[index],
            child: Focus(
              focusNode: _focusNodes[index],
              child: _buildItem(index),
            ),
          );
        },
      ),
    );
  }
}
```

#### 方法 B：使用 FocusableItemWidget（更簡單）

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return FocusableItemWidget(
      id: 'item-$i',
      label: '${items[i].name}，價格 ${items[i].price} 元',
      type: '商品',
      onActivate: () => _onItemSelected(i),
      child: ListTile(
        title: Text(items[i].name),
        subtitle: Text('\$${items[i].price}'),
      ),
    );
  },
)
```

---

### 步驟 3：實現聚焦視覺反饋

為聚焦的元素添加視覺效果，幫助用戶識別當前位置。

```dart
AnimatedBuilder(
  animation: _focusNodes[index],
  builder: (context, child) {
    final hasFocus = _focusNodes[index].hasFocus;

    return Card(
      elevation: hasFocus ? 8 : 2,
      shape: RoundedRectangleBorder(
        side: hasFocus
            ? BorderSide(color: Theme.of(context).primaryColor, width: 3)
            : BorderSide.none,
      ),
      child: ListTile(...),
    );
  },
)
```

---

### 步驟 4：處理動態列表

當列表內容變化時（如加載更多、刪除項目），需要重新註冊可聚焦元素。

```dart
void _onDataChanged() {
  setState(() {
    // 更新數據
  });

  // 重新創建 FocusNode 和 GlobalKey
  _focusNodes.clear();
  _itemKeys.clear();
  for (int i = 0; i < newItems.length; i++) {
    _focusNodes.add(FocusNode());
    _itemKeys.add(GlobalKey());
  }

  // 重新註冊
  _registerFocusableItems();
}
```

---

## 特殊頁面處理

### 使用自定義滑動邏輯的頁面（如 PageView）

對於使用 `PageView`、`TabView` 等自訂滑動邏輯的頁面（如設定頁面），應：

1. **保持原有滑動邏輯**
2. **僅啟用全局手勢**（雙指上/下滑）
3. **禁用頁面級手勢**（左右滑、單擊、雙擊）

```dart
UnifiedGestureWrapper(
  enableGlobalGestures: true,   // 啟用雙指上/下滑
  enablePageGestures: false,    // 禁用左右滑等
  child: PageView(...),
)
```

或使用 `GlobalGestureWrapper`：
```dart
GlobalGestureWrapper(
  child: PageView(...),
)
```

---

## 測試建議

### 1. 手勢功能測試

使用示範頁面進行測試：
```dart
Navigator.pushNamed(context, '/gesture-demo');
```

測試項目：
- ✅ 左往右滑切換到上一個項目
- ✅ 右往左滑切換到下一個項目
- ✅ 單擊朗讀項目內容
- ✅ 雙擊激活項目
- ✅ 雙指上滑回首頁
- ✅ 雙指下滑回上一頁

### 2. 系統無障礙兼容性測試

#### Android（TalkBack）
1. 設定 > 無障礙功能 > TalkBack > 開啟
2. 測試應用是否切換到系統模式
3. 確認不會出現手勢衝突

#### iOS（VoiceOver）
1. 設定 > 輔助使用 > 旁白 > 開啟
2. 測試應用是否切換到系統模式
3. 確認不會出現手勢衝突

---

## 常見問題

### Q1: 手勢沒有反應？
**解答：**
- 檢查是否已註冊可聚焦元素
- 確認 `UnifiedGestureWrapper` 包裝了頁面內容
- 查看控制台日誌（Debug 模式會輸出手勢檢測信息）

### Q2: 與系統手勢衝突？
**解答：**
- 檢查 `AccessibilityService` 是否正確檢測系統無障礙狀態
- 確認 `onlyInCustomMode` 參數設置正確

### Q3: 左右滑動沒有切換項目？
**解答：**
- 確認已調用 `focusNavigationService.registerItems()`
- 檢查 `enablePageGestures` 是否為 `true`
- 確認滑動距離超過閾值（預設 50 像素）

### Q4: 雙擊沒有觸發？
**解答：**
- 確認兩次點擊間隔在 300ms 內
- 確認兩次點擊位置距離在 50 像素內
- 檢查 `onActivate` 回調是否已設置

---

## 頁面遷移檢查清單

使用以下清單確保頁面正確遷移：

- [ ] 已替換 `Scaffold` 為 `UnifiedGestureScaffold` 或使用 `UnifiedGestureWrapper`
- [ ] 已為互動元素創建 `FocusNode` 和 `GlobalKey`
- [ ] 已在 `initState` 中註冊可聚焦元素
- [ ] 已在 `dispose` 中清理資源（`FocusNode`、`focusNavigationService.clear()`）
- [ ] 已實現聚焦視覺反饋（邊框、陰影等）
- [ ] 已為每個項目設置有意義的 `label` 和 `type`
- [ ] 已實現 `onActivate` 回調
- [ ] 已測試所有手勢功能
- [ ] 已測試系統無障礙兼容性

---

## 示範頁面

完整示範請參考：`lib/pages/gesture_demo_page.dart`

該頁面展示了：
- 如何註冊可聚焦元素
- 如何實現聚焦視覺反饋
- 如何處理項目激活
- 如何顯示當前焦點狀態

---

## 相關文件

- [無障礙服務架構](lib/services/accessibility_service.dart)
- [焦點導航服務](lib/services/focus_navigation_service.dart)
- [全局手勢服務](lib/services/global_gesture_service.dart)
- [統一手勢包裝器](lib/widgets/unified_gesture_wrapper.dart)
- [可聚焦元素組件](lib/widgets/focusable_item_widget.dart)

---

## 支援與反饋

如有問題或建議，請聯繫開發團隊。
