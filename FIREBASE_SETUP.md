# Firebase 整合設定指南（免費方案版本）

本專案使用 Firebase Cloud Firestore 來存取用戶資訊與錢包餘額。

## ⭐ 免費方案說明

此版本**不使用 Cloud Functions**，適用於 Firebase Spark（免費）方案。

### 與付費版的差異

| 項目 | 免費版本（當前） | 付費版本（Cloud Functions） |
|------|-----------------|---------------------------|
| 費用 | 完全免費 | Blaze 方案（有大量免費額度） |
| 安全性 | 依賴 Firestore Rules + Transaction | 伺服器端驗證（最安全） |
| 餘額操作 | 客戶端執行 + Rules 限制 | 伺服器端執行 |
| 部署複雜度 | 簡單（只需設定 Rules） | 需要部署 Functions |

**結論**：對於小型專案，免費版本的安全性已經足夠！

## 資料結構

### users 集合

```
users (collection)
  └── userId (document)
        ├── userId: string           // Firebase Auth UID
        ├── displayName: string?     // 用戶名稱
        ├── email: string?           // 電子郵件
        ├── birthday: string?        // 生日 (ISO8601 格式)
        ├── phoneNumber: string?     // 手機號碼
        ├── walletBalance: number    // 錢包餘額（不可直接修改）
        ├── lastDailyLogin: timestamp // 上次領取每日獎勵時間（不可直接修改）
        ├── membershipLevel: string  // 會員等級
        ├── membershipPoints: number // 會員點數
        ├── createdAt: timestamp     // 建立時間
        └── updatedAt: timestamp     // 更新時間
```

## 設定步驟

### 1. 安裝依賴套件

```bash
flutter pub get
```

### 2. 設定 Firestore Security Rules

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案 `accessible-shop`
3. 進入 `Firestore Database` → `規則`
4. 複製 `firestore.rules` 的內容並貼上
5. 點擊「發布」

### 3. 在 main.dart 中註冊 FirestoreService

在 `lib/main.dart` 中加入 `FirestoreService` 提供者：

```dart
import 'package:accessible_shop/services/firestore_service.dart';

// 在 MultiProvider 中加入
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => DatabaseService()),
    ChangeNotifierProvider(create: (_) => FirestoreService()), // ← 加入這行
    // ... 其他 providers
  ],
  child: MyApp(),
)
```

### 5. 測試功能

#### 5.1 測試用戶資料同步

1. 執行 App 並登入
2. 進入「帳號資訊」頁面
3. 修改個人資料並儲存
4. 前往 Firebase Console → Firestore Database
5. 確認 `users` 集合中有該用戶的資料

#### 5.2 測試錢包功能

1. 進入「我的錢包」頁面
2. 點擊「領取今日獎勵」
3. 確認餘額增加
4. 前往 Firebase Console 確認資料已更新

## 安全性說明

### ✅ 安全機制（免費版本）

1. **Firestore Security Rules 防護**
   - 限制每日獎勵最多 +1 元
   - 禁止餘額變成負數
   - 只允許讀取和更新自己的資料
   - 檢查必要的時間戳記欄位

2. **Transaction 確保數據一致性**
   - 所有錢包操作都使用 Firestore Transaction
   - 避免併發問題導致的數據錯誤
   - 先檢查再更新，確保數據正確性

3. **客戶端驗證**
   - 領取獎勵前檢查日期
   - 扣款前檢查餘額是否足夠
   - 使用 Transaction 避免競爭條件

### ⚠️ 注意事項

1. **安全規則是最後防線**
   ```dart
   // ✅ 正確做法：使用 FirestoreService 的方法
   await firestoreService.claimDailyReward(userId);

   // ❌ 錯誤做法：直接操作 Firestore
   await firestore.collection('users').doc(userId).update({
     'walletBalance': currentBalance + 10,
   });
   ```

2. **敏感資料不要存入 Firestore**
   - 不要存放密碼（使用 Firebase Auth）
   - 不要存放信用卡資訊
   - 不要存放 API 密鑰

3. **定期檢查 Security Rules**
   - 確保規則符合最新需求
   - 使用 Firebase 模擬器測試規則

## Firestore 本地測試（可選）

使用 Firebase Emulator 在本地測試：

```bash
# 安裝 emulator
firebase init emulators

# 啟動 emulator
firebase emulators:start

# 在 Flutter 中連接到 emulator
# lib/main.dart
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

## 常見問題

### Q1: 權限錯誤 (permission-denied)

**解決方法：**
1. 確認已設定 Firestore Security Rules
2. 確認用戶已登入 (`FirebaseAuth.instance.currentUser != null`)
3. 檢查 userId 是否正確

### Q2: 餘額未同步

**解決方法：**
1. 檢查 Firestore Console 的資料
2. 確認沒有快取問題（重新載入資料）
3. 查看 Flutter Console 的錯誤訊息

### Q3: 每日獎勵無法領取

**解決方法：**
1. 確認 Firestore Rules 已正確設定
2. 檢查 `lastDailyLogin` 時間戳記格式
3. 查看是否有時區問題（使用伺服器時間）

## 進階配置

### 升級到付費版本（使用 Cloud Functions）

如果未來需要更高的安全性，可以升級到 Blaze 方案並使用 Cloud Functions：

1. 在 Firebase Console 升級到 Blaze 方案
2. 部署 `functions/index.js` 中的 Cloud Functions
3. 在 `firestore_service.dart` 中啟用 Functions 版本的方法
4. 更新 Security Rules 為更嚴格的版本

詳細步驟請參考 `functions/index.js` 中的註解。

### 錢包交易記錄

建議建立 `transactions` 集合記錄所有錢包變更：

```
transactions (collection)
  └── transactionId (document)
        ├── userId: string
        ├── type: string          // 'daily_reward', 'purchase', 'refund'
        ├── amount: number        // 正數為收入，負數為支出
        ├── balanceBefore: number
        ├── balanceAfter: number
        ├── description: string
        └── timestamp: timestamp
```

## 相關文件

- [Cloud Firestore 官方文件](https://firebase.google.com/docs/firestore)
- [Cloud Functions 官方文件](https://firebase.google.com/docs/functions)
- [Security Rules 參考](https://firebase.google.com/docs/firestore/security/get-started)
