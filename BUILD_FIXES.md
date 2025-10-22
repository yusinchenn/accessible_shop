# Build Runner 執行後的錯誤修正

## 問題說明

執行 `flutter pub run build_runner build --delete-conflicting-outputs` 後出現編譯錯誤：
1. **缺少 Isar 導入** - 所有使用 Isar 查詢的服務文件都需要導入 `package:isar/isar.dart`
2. **錯誤的查詢 API** - 需要使用 `.filter()` 而不是 `.where()` 進行條件查詢

## ⚠️ 最重要的修正：添加 Isar 導入

**所有使用 Isar 查詢的服務文件都必須添加此導入：**

```dart
import 'package:isar/isar.dart';
```

### 需要添加導入的文件：
1. ✅ `lib/services/order_status_service.dart`
2. ✅ `lib/services/seller_service.dart`
3. ✅ `lib/services/logistics_service.dart`

沒有此導入，編譯器會報錯：`The method 'findAll' isn't defined for the type 'QueryBuilder'`

## Isar 查詢 API 規則

### 1. 使用 `.where()` 查詢（適用於有索引的欄位）
```dart
// ✅ 正確：where() 可以直接使用 sort 和 findAll/findFirst
await isar.orders
    .where()
    .sortByCreatedAtDesc()
    .findAll();

await isar.orderStatusTimestamps
    .where()
    .orderIdEqualTo(orderId)  // orderId 有 @Index(unique: true)
    .findFirst();
```

### 2. 使用 `.filter()` 查詢（適用於沒有索引的欄位）
```dart
// ✅ 正確：filter() 後直接 findAll/findFirst
await isar.orders
    .filter()
    .mainStatusEqualTo(status)
    .findAll();

// ❌ 錯誤：filter() 後不能直接使用 sortBy
await isar.orders
    .filter()
    .mainStatusEqualTo(status)
    .sortByCreatedAtDesc()  // ❌ 這會報錯
    .findAll();

// ✅ 正確：filter() 後需要排序時，在 Dart 層排序
final results = await isar.orders
    .filter()
    .mainStatusEqualTo(status)
    .findAll();
results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
```

## 修正的檔案

### 1. lib/services/order_status_service.dart

#### 修正內容：

**第 1-5 行：** 添加 Isar 導入
```dart
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';  // ← 新增這行
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';
```

**第 55-65 行：** 使用 `.filter()` 查詢
```dart
// 查找現有的時間戳記錄
var timestamps = await isar.orderStatusTimestamps
    .filter()  // ← 使用 filter() 而不是 where()
    .orderIdEqualTo(orderId)
    .findFirst();

if (timestamps == null) {
  timestamps = OrderStatusTimestamps()
    ..orderId = orderId
    ..createdAt = DateTime.now();
}
```

**第 210-222 行：** filter 查詢後在 Dart 層排序
```dart
Future<List<OrderStatusHistory>> getOrderStatusHistory(int orderId) async {
  final isar = await _db.isar;
  final results = await isar.orderStatusHistorys
      .filter()
      .orderIdEqualTo(orderId)
      .findAll();

  // 在 Dart 層排序
  results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return results;
}
```

**第 225-232 行：** 使用 `.where()` 查詢 unique index
```dart
Future<OrderStatusTimestamps?> getOrderStatusTimestamps(int orderId) async {
  final isar = await _db.isar;
  return await isar.orderStatusTimestamps
      .where()
      .orderIdEqualTo(orderId)
      .findFirst();
}
```

**第 233-243 行：** filter 查詢後在 Dart 層排序
```dart
Future<List<Order>> getOrdersByMainStatus(OrderMainStatus status) async {
  final isar = await _db.isar;
  final results = await isar.orders
      .filter()
      .mainStatusEqualTo(status)
      .findAll();

  // 在 Dart 層排序（時間倒序）
  results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return results;
}
```

### 2. lib/services/seller_service.dart

#### 修正內容：

**第 1-7 行：** 添加 Isar 導入
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';  // ← 新增這行
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';
import 'order_status_service.dart';
```

查詢代碼本身無需修改 - 原本就使用正確的 `.filter().findAll()` 模式。

### 3. lib/services/logistics_service.dart

#### 修正內容：

**第 1-7 行：** 添加 Isar 導入
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';  // ← 新增這行
import '../models/order.dart';
import '../models/order_status.dart';
import 'database_service.dart';
import 'order_status_service.dart';
```

查詢代碼本身無需修改 - 原本就使用正確的 `.filter().findAll()` 模式。

## 驗證步驟

執行以下命令確認所有錯誤已修正：

```bash
flutter analyze
```

應該沒有任何錯誤輸出。

## 索引說明

在 `order_status.dart` 中，`OrderStatusTimestamps.orderId` 有 unique index：

```dart
@Collection()
class OrderStatusTimestamps {
  Id id = Isar.autoIncrement;

  @Index(unique: true)  // ← unique index
  late int orderId;

  // ...
}
```

因此可以使用 `.where().orderIdEqualTo()` 來查詢。

## 總結

### 關鍵修正：
1. **✅ 添加 Isar 導入** - 所有服務文件都需要 `import 'package:isar/isar.dart';`
2. **✅ 使用 `.filter()`** - 所有條件查詢都使用 `.filter()` 而不是 `.where()`
3. **✅ Dart 層排序** - filter 查詢後如需排序，在結果上使用 Dart 的 `.sort()`

### 查詢模式：
- **簡單查詢**：`.where().sortBy...().findAll()`（無條件）
- **條件查詢**：`.filter().xxxEqualTo().findAll()`
- **需要排序**：先 `findAll()` 再在 Dart 層 `.sort()`

所有修正已完成，應該可以正常編譯運行！

### 快速檢查清單：
- [x] order_status_service.dart - 添加 Isar 導入 + 改用 filter
- [x] seller_service.dart - 添加 Isar 導入
- [x] logistics_service.dart - 添加 Isar 導入