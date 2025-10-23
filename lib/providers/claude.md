# Providers 資料夾架構文件

本文件說明 `lib/providers/` 資料夾中各個狀態管理 Provider 的用途、功能與使用方式。

## 目錄

1. [概述](#概述)
2. [AuthProvider - 身份驗證](#authprovider---身份驗證)
3. [ShoppingCartData - 購物車](#shoppingcartdata---購物車)
4. [ComparisonProvider - 商品比較](#comparisonprovider---商品比較)
5. [Provider 架構設計](#provider-架構設計)
6. [使用範例](#使用範例)

---

## 概述

本專案使用 Flutter 的 `Provider` 套件進行狀態管理。所有 Provider 繼承自 `ChangeNotifier`，遵循以下設計原則：

- **單一職責**: 每個 Provider 負責單一功能領域
- **響應式更新**: 使用 `notifyListeners()` 通知 UI 更新
- **服務層分離**: Provider 負責狀態管理，Service 負責業務邏輯
- **錯誤處理**: 統一的錯誤處理與載入狀態管理

**Provider 列表**:
- [AuthProvider](auth_provider.dart) - 身份驗證狀態管理
- [ShoppingCartData](cart_provider.dart) - 購物車狀態管理
- [ComparisonProvider](comparison_provider.dart) - 商品比較狀態管理

---

## AuthProvider - 身份驗證

**檔案**: [auth_provider.dart](auth_provider.dart)

**用途**: 管理使用者身份驗證狀態，提供登入、註冊、登出等功能。

### 依賴服務
- `AuthService` - Firebase 身份驗證服務

### 狀態屬性

| 屬性 | 類型 | 說明 |
|------|------|------|
| `user` | `User?` | 當前使用者（Firebase User） |
| `isAuthenticated` | `bool` | 是否已登入 |
| `isLoading` | `bool` | 載入中狀態 |
| `errorMessage` | `String?` | 錯誤訊息 |
| `userEmail` | `String?` | 使用者電子郵件 |
| `userId` | `String?` | 使用者 UID |

### 主要方法

#### 1. signUp() - 註冊
```dart
Future<bool> signUp({
  required String email,
  required String password,
})
```

**功能**: 使用 Email 和密碼註冊新帳號

**參數**:
- `email` - 電子郵件
- `password` - 密碼

**返回值**: `true` 表示成功，`false` 表示失敗

**流程**:
1. 設置載入狀態 `isLoading = true`
2. 清除錯誤訊息
3. 呼叫 `AuthService.signUpWithEmailPassword()`
4. 註冊成功後自動監聽狀態變化
5. 錯誤時儲存錯誤訊息到 `errorMessage`

**使用範例**:
```dart
final authProvider = context.read<AuthProvider>();
final success = await authProvider.signUp(
  email: 'user@example.com',
  password: 'password123',
);

if (success) {
  // 註冊成功，導航到主頁
} else {
  // 顯示錯誤訊息
  print(authProvider.errorMessage);
}
```

---

#### 2. signIn() - 登入
```dart
Future<bool> signIn({
  required String email,
  required String password,
})
```

**功能**: 使用 Email 和密碼登入

**參數**:
- `email` - 電子郵件
- `password` - 密碼

**返回值**: `true` 表示成功，`false` 表示失敗

**使用範例**:
```dart
final success = await authProvider.signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

---

#### 3. signOut() - 登出
```dart
Future<void> signOut()
```

**功能**: 登出當前使用者

**流程**:
1. 設置載入狀態
2. 呼叫 `AuthService.signOut()`
3. 清除使用者資料和錯誤訊息
4. 通知監聽者更新 UI

**使用範例**:
```dart
await authProvider.signOut();
```

---

#### 4. sendPasswordResetEmail() - 發送密碼重設郵件
```dart
Future<bool> sendPasswordResetEmail(String email)
```

**功能**: 發送密碼重設郵件到指定信箱

**參數**:
- `email` - 要接收重設郵件的電子郵件

**返回值**: `true` 表示成功，`false` 表示失敗

**使用範例**:
```dart
final success = await authProvider.sendPasswordResetEmail('user@example.com');
```

---

#### 5. clearError() - 清除錯誤訊息
```dart
void clearError()
```

**功能**: 清除錯誤訊息

**使用場景**: 在顯示錯誤訊息後，使用者關閉對話框時清除

---

### 自動狀態同步

AuthProvider 在建構函式中自動監聽 Firebase 身份驗證狀態變化：

```dart
AuthProvider() {
  _authService.authStateChanges.listen((User? user) {
    _user = user;
    notifyListeners();
  });
}
```

**好處**:
- 自動同步登入/登出狀態
- 跨裝置登入時自動更新
- Token 過期時自動登出

---

### 使用場景

#### 場景 1: 檢查登入狀態
```dart
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();

  if (authProvider.isAuthenticated) {
    return HomePage();
  } else {
    return LoginPage();
  }
}
```

#### 場景 2: 顯示使用者資訊
```dart
Text('歡迎, ${authProvider.userEmail}')
```

#### 場景 3: 錯誤處理
```dart
if (authProvider.errorMessage != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(authProvider.errorMessage!)),
  );
  authProvider.clearError();
}
```

**位置**: [auth_provider.dart:6](auth_provider.dart#L6)

---

## ShoppingCartData - 購物車

**檔案**: [cart_provider.dart](cart_provider.dart)

**用途**: 管理購物車狀態，提供購物車項目的增刪改查功能。

### 依賴服務
- `DatabaseService` - 資料庫服務

### 狀態屬性

| 屬性 | 類型 | 說明 |
|------|------|------|
| `items` | `List<CartItem>` | 購物車項目列表（不可變） |
| `isLoading` | `bool` | 載入中狀態 |
| `totalSelectedCount` | `int` | 已選商品數量 |
| `totalSelectedPrice` | `double` | 已選商品總價 |
| `selectedItems` | `List<CartItem>` | 已選商品列表 |

### 主要方法

#### 1. reload() - 重新載入購物車
```dart
Future<void> reload()
```

**功能**: 從資料庫重新載入購物車資料

**使用時機**:
- 手動刷新購物車
- 新增商品後確保資料同步

**注意**: Provider 已自動監聽 DatabaseService 變化，大部分情況不需手動呼叫

---

#### 2. getItemById() - 查詢單一商品
```dart
CartItem? getItemById(int id)
```

**功能**: 根據購物車項目 ID 查詢商品

**參數**:
- `id` - 購物車項目 ID

**返回值**: `CartItem?` - 找到的項目，找不到時返回 `null`

---

#### 3. incrementQuantity() - 增加數量
```dart
Future<void> incrementQuantity(int id)
```

**功能**: 將指定商品數量加 1

**參數**:
- `id` - 購物車項目 ID

**流程**:
1. 查找商品
2. 更新資料庫
3. 重新載入購物車

**使用範例**:
```dart
await cartProvider.incrementQuantity(cartItem.id);
```

---

#### 4. decrementQuantity() - 減少數量
```dart
Future<void> decrementQuantity(int id)
```

**功能**: 將指定商品數量減 1（最小為 1）

**參數**:
- `id` - 購物車項目 ID

**限制**: 數量不會低於 1

---

#### 5. toggleSelection() - 切換選取狀態
```dart
Future<void> toggleSelection(int id)
```

**功能**: 切換商品的選取狀態（用於結帳）

**參數**:
- `id` - 購物車項目 ID

**使用場景**: 使用者在購物車頁面勾選/取消勾選商品

---

#### 6. removeItem() - 移除商品
```dart
Future<void> removeItem(int id)
```

**功能**: 從購物車移除指定商品

**參數**:
- `id` - 購物車項目 ID

**流程**:
1. 從資料庫刪除
2. 重新載入購物車
3. 通知 UI 更新

---

### 自動同步機制

ShoppingCartData 自動監聽 DatabaseService 的變化：

```dart
ShoppingCartData(this._databaseService) {
  _loadCartItems();
  _databaseService.addListener(_onDatabaseChanged);
}

void _onDatabaseChanged() {
  _loadCartItems();
}
```

**好處**:
- 任何對資料庫的更改都會自動反映到購物車
- 不需要手動呼叫 reload()
- 確保資料一致性

**記得在 dispose 時移除監聽器**:
```dart
@override
void dispose() {
  _databaseService.removeListener(_onDatabaseChanged);
  super.dispose();
}
```

---

### 計算屬性

#### totalSelectedCount - 已選商品數量
```dart
int get totalSelectedCount => _items
    .where((item) => item.isSelected)
    .length;
```

**用途**: 顯示「已選 X 件商品」

---

#### totalSelectedPrice - 已選商品總價
```dart
double get totalSelectedPrice => _items
    .where((item) => item.isSelected)
    .fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
```

**用途**: 顯示「總計 $X 元」

---

#### selectedItems - 已選商品列表
```dart
List<CartItem> get selectedItems =>
    _items.where((item) => item.isSelected).toList();
```

**用途**: 結帳時取得已選商品

---

### 使用場景

#### 場景 1: 顯示購物車列表
```dart
Widget build(BuildContext context) {
  final cartProvider = context.watch<ShoppingCartData>();

  if (cartProvider.isLoading) {
    return CircularProgressIndicator();
  }

  return ListView.builder(
    itemCount: cartProvider.items.length,
    itemBuilder: (context, index) {
      final item = cartProvider.items[index];
      return CartItemTile(item: item);
    },
  );
}
```

#### 場景 2: 數量控制
```dart
Row(
  children: [
    IconButton(
      icon: Icon(Icons.remove),
      onPressed: () => cartProvider.decrementQuantity(item.id),
    ),
    Text('${item.quantity}'),
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () => cartProvider.incrementQuantity(item.id),
    ),
  ],
)
```

#### 場景 3: 結帳按鈕
```dart
ElevatedButton(
  onPressed: cartProvider.totalSelectedCount > 0
      ? () => navigateToCheckout(cartProvider.selectedItems)
      : null,
  child: Text('結帳 (${cartProvider.totalSelectedCount} 件 / \$${cartProvider.totalSelectedPrice.toStringAsFixed(0)})'),
)
```

**位置**: [cart_provider.dart:7](cart_provider.dart#L7)

---

## ComparisonProvider - 商品比較

**檔案**: [comparison_provider.dart](comparison_provider.dart)

**用途**: 管理商品比較清單，最多支援 5 個商品的並排比較。

### 常數

| 常數 | 值 | 說明 |
|------|---|------|
| `maxItems` | `5` | 比較清單最大商品數 |

### 狀態屬性

| 屬性 | 類型 | 說明 |
|------|------|------|
| `items` | `List<CartItem>` | 比較清單中的商品（不可變） |
| `itemCount` | `int` | 比較清單中的商品數量 |
| `isEmpty` | `bool` | 比較清單是否為空 |
| `isFull` | `bool` | 比較清單是否已滿（達到 5 個） |

### 主要方法

#### 1. isInComparison() - 檢查商品是否已在比較清單
```dart
bool isInComparison(int productId)
```

**功能**: 檢查指定商品是否已加入比較清單

**參數**:
- `productId` - 商品 ID

**返回值**: `true` 表示已在清單中，`false` 表示不在

**使用範例**:
```dart
if (comparisonProvider.isInComparison(product.id)) {
  // 顯示「已加入比較」
} else {
  // 顯示「加入比較」按鈕
}
```

---

#### 2. addToComparison() - 加入商品到比較清單
```dart
void addToComparison(CartItem item)
```

**功能**: 將商品加入比較清單

**參數**:
- `item` - 要加入的商品（CartItem）

**邏輯**:
1. 檢查商品是否已存在（避免重複）
2. 如果已達上限（5 個），自動移除最先加入的商品
3. 將新商品加入清單
4. 通知 UI 更新

**使用範例**:
```dart
final cartItem = CartItem()
  ..productId = product.id
  ..name = product.name
  ..unitPrice = product.price
  ..specification = '預設規格'
  ..quantity = 1
  ..isSelected = false;

comparisonProvider.addToComparison(cartItem);
```

---

#### 3. removeFromComparison() - 移除商品
```dart
void removeFromComparison(int productId)
```

**功能**: 從比較清單中移除指定商品

**參數**:
- `productId` - 要移除的商品 ID

**使用範例**:
```dart
comparisonProvider.removeFromComparison(product.id);
```

---

#### 4. clearAll() - 清除所有商品
```dart
void clearAll()
```

**功能**: 清空比較清單

**使用場景**: 使用者點擊「清空比較清單」按鈕

---

### 設計說明

#### 為何使用 CartItem 而非 Product？

ComparisonProvider 使用 `CartItem` 而非 `Product` 模型，原因如下：

1. **規格支援**: `CartItem` 包含 `specification` 欄位，可以比較同商品不同規格
2. **一致性**: 與購物車使用相同資料結構，方便整合
3. **擴展性**: 未來可以支援「將比較商品加入購物車」功能

#### FIFO 策略

當比較清單已滿（5 個）時，自動移除最先加入的商品：

```dart
if (_comparisonItems.length >= maxItems) {
  _comparisonItems.removeAt(0);  // 移除第一個（最舊）
}
```

這樣使用者可以持續加入新商品而不需手動移除舊商品。

---

### 使用場景

#### 場景 1: 商品列表中的比較按鈕
```dart
Widget build(BuildContext context) {
  final comparisonProvider = context.watch<ComparisonProvider>();

  return IconButton(
    icon: Icon(
      comparisonProvider.isInComparison(product.id)
          ? Icons.check_circle
          : Icons.compare_arrows,
    ),
    onPressed: comparisonProvider.isFull &&
                !comparisonProvider.isInComparison(product.id)
        ? null  // 已滿且不在清單中，停用按鈕
        : () {
            if (comparisonProvider.isInComparison(product.id)) {
              comparisonProvider.removeFromComparison(product.id);
            } else {
              comparisonProvider.addToComparison(cartItem);
            }
          },
  );
}
```

#### 場景 2: 比較清單提示
```dart
Text('已選擇 ${comparisonProvider.itemCount} / 5 個商品')
```

#### 場景 3: 比較頁面
```dart
if (comparisonProvider.isEmpty) {
  return Center(child: Text('尚未加入任何商品'));
}

return Row(
  children: comparisonProvider.items.map((item) {
    return Expanded(
      child: ComparisonCard(item: item),
    );
  }).toList(),
);
```

**位置**: [comparison_provider.dart:6](comparison_provider.dart#L6)

---

## Provider 架構設計

### 依賴注入架構

使用 `MultiProvider` 在應用程式根部注入所有 Provider：

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // 服務層
        ChangeNotifierProvider(
          create: (_) => DatabaseService(),
        ),

        // Provider 層
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<DatabaseService, ShoppingCartData>(
          create: (context) => ShoppingCartData(
            context.read<DatabaseService>(),
          ),
          update: (context, db, cart) => cart ?? ShoppingCartData(db),
        ),
        ChangeNotifierProvider(
          create: (_) => ComparisonProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

---

### Provider 分層架構

```
┌─────────────────────────────────────┐
│           UI Layer (Widgets)        │
│  - 使用 context.watch<T>() 監聽      │
│  - 使用 context.read<T>() 呼叫方法   │
└─────────────────────────────────────┘
                  ↕
┌─────────────────────────────────────┐
│      Provider Layer (Providers)     │
│  - 狀態管理                          │
│  - 業務邏輯協調                      │
│  - UI 更新通知                       │
└─────────────────────────────────────┘
                  ↕
┌─────────────────────────────────────┐
│      Service Layer (Services)       │
│  - 資料存取                          │
│  - API 呼叫                          │
│  - 業務邏輯實作                      │
└─────────────────────────────────────┘
```

---

### 狀態更新流程

```
使用者操作 (UI Event)
    ↓
Provider 方法呼叫
    ↓
Service 層執行業務邏輯
    ↓
資料庫/API 更新
    ↓
Provider 更新內部狀態
    ↓
notifyListeners() 通知
    ↓
UI 重新建構 (rebuild)
```

---

## 使用範例

### 完整範例: 購物車頁面

```dart
class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 監聽購物車狀態變化
    final cartProvider = context.watch<ShoppingCartData>();

    return Scaffold(
      appBar: AppBar(
        title: Text('購物車 (${cartProvider.items.length})'),
        actions: [
          // 顯示已選商品數量
          Chip(
            label: Text('已選 ${cartProvider.totalSelectedCount} 件'),
          ),
        ],
      ),
      body: cartProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : cartProvider.items.isEmpty
              ? Center(child: Text('購物車是空的'))
              : ListView.builder(
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return CartItemTile(
                      item: item,
                      onQuantityChanged: (newQuantity) {
                        if (newQuantity > item.quantity) {
                          cartProvider.incrementQuantity(item.id);
                        } else {
                          cartProvider.decrementQuantity(item.id);
                        }
                      },
                      onSelectionChanged: () {
                        cartProvider.toggleSelection(item.id);
                      },
                      onRemove: () {
                        cartProvider.removeItem(item.id);
                      },
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '總計: \$${cartProvider.totalSelectedPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: cartProvider.totalSelectedCount > 0
                    ? () => _checkout(context, cartProvider)
                    : null,
                child: Text('結帳'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkout(BuildContext context, ShoppingCartData cart) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: cart.selectedItems,
        ),
      ),
    );
  }
}
```

---

### 完整範例: 商品比較頁面

```dart
class ComparisonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final comparisonProvider = context.watch<ComparisonProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('商品比較 (${comparisonProvider.itemCount}/5)'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: comparisonProvider.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('確認清空'),
                        content: Text('確定要清空所有比較商品嗎？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              comparisonProvider.clearAll();
                              Navigator.pop(context);
                            },
                            child: Text('確定'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: comparisonProvider.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('尚未加入任何商品'),
                  SizedBox(height: 8),
                  Text('最多可比較 5 個商品'),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comparisonProvider.items.map((item) {
                  return SizedBox(
                    width: 200,
                    child: Card(
                      child: Column(
                        children: [
                          // 商品圖片
                          Image.network(item.imageUrl ?? ''),

                          // 商品名稱
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(item.name),
                          ),

                          // 價格
                          Text(
                            '\$${item.unitPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // 移除按鈕
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              comparisonProvider.removeFromComparison(
                                item.productId,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
```

---

## 最佳實踐

### 1. 使用 context.watch vs context.read

```dart
// ✅ 正確：需要監聽狀態變化時使用 watch
Widget build(BuildContext context) {
  final cart = context.watch<ShoppingCartData>();
  return Text('${cart.items.length}');  // 自動更新
}

// ✅ 正確：只需呼叫方法時使用 read
void _addToCart() {
  context.read<ShoppingCartData>().incrementQuantity(id);
}

// ❌ 錯誤：在 build 中使用 read 不會自動更新
Widget build(BuildContext context) {
  final cart = context.read<ShoppingCartData>();  // 不會自動更新！
  return Text('${cart.items.length}');
}
```

---

### 2. 避免不必要的重建

```dart
// ✅ 正確：只監聽需要的屬性
class CartBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 使用 select 只監聽 itemCount 變化
    final count = context.select<ShoppingCartData, int>(
      (cart) => cart.items.length,
    );

    return Badge(
      label: Text('$count'),
      child: Icon(Icons.shopping_cart),
    );
  }
}

// ❌ 避免：監聽整個 Provider（任何變化都會重建）
final cart = context.watch<ShoppingCartData>();
return Badge(label: Text('${cart.items.length}'));
```

---

### 3. 錯誤處理

```dart
Future<void> _performAction() async {
  try {
    await cartProvider.incrementQuantity(id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('操作成功')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('操作失敗: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### 4. 載入狀態處理

```dart
Widget build(BuildContext context) {
  final cart = context.watch<ShoppingCartData>();

  // 顯示載入指示器
  if (cart.isLoading) {
    return Center(child: CircularProgressIndicator());
  }

  // 顯示內容
  return ListView(...);
}
```

---

### 5. 避免在 Provider 中儲存 BuildContext

```dart
// ❌ 錯誤：不要在 Provider 中儲存 BuildContext
class MyProvider extends ChangeNotifier {
  BuildContext? _context;  // 危險！

  void setContext(BuildContext context) {
    _context = context;
  }
}

// ✅ 正確：將 BuildContext 作為參數傳遞
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

---

## 未來擴展建議

### 可能需要的新 Provider

1. **OrderProvider** - 訂單管理
   - 訂單列表
   - 訂單狀態追蹤
   - 訂單歷史

2. **NotificationProvider** - 通知管理
   - 未讀通知數量
   - 通知列表
   - 標記已讀

3. **ThemeProvider** - 主題管理
   - 深色/淺色模式
   - 字體大小
   - 無障礙設定

4. **SearchProvider** - 搜尋管理
   - 搜尋歷史
   - 熱門搜尋
   - 搜尋建議

---

## 更新紀錄

- **2025-01-23**: 初始版本，記錄所有 providers 資料夾中的 Provider
