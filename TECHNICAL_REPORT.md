# Accessible Shop 技術報告

## 目錄
- [專案簡介](#專案簡介)
- [系統架構](#系統架構)
- [應用技術](#應用技術)
- [技術亮點](#技術亮點)

---

## 專案簡介

### 專案概述
**Accessible Shop** 是一個專為視障人士設計的無障礙購物應用程式，提供完整的語音導航和智能AI助理，讓視障用戶能夠獨立完成線上購物的所有流程。

- **專案名稱**：Accessible Shop
- **版本**：1.0.0+1
- **開發框架**：Flutter 3.9.2+
- **主要語言**：Dart
- **目標平台**：Android、iOS

### 目標用戶
- 視障人士
- 弱視用戶
- 需要無障礙輔助的使用者

### 核心功能

#### 1. 全語音導航系統
- 所有頁面和操作都配備語音提示
- 智能語音助手「小千」提供即時導航協助
- 支援語音命令快速跳轉頁面

#### 2. 雙模式無障礙系統
- **系統模式**：自動偵測並適配 TalkBack/VoiceOver
- **自訂模式**：當系統無障礙未啟用時，提供自訂語音和手勢支援
- **智能切換**：避免與系統無障礙功能衝突

#### 3. AI 智能助理
- **小千**：語音導航助手，支援語音命令解析
- **大千**：AI 購物顧問，提供商品諮詢和購物建議

#### 4. 完整購物流程
- 商品搜尋（支援模糊搜尋）
- 商品瀏覽與比較
- 購物車管理
- 結帳與付款
- 訂單追蹤
- 商品評價

#### 5. 手勢控制
- **兩指上滑**：快速回到首頁
- **兩指下滑**：返回上一頁
- **智能啟用**：系統無障礙啟用時自動停用，避免衝突

#### 6. 其他功能
- 短影音瀏覽
- 即時訊息對話
- 通知系統
- 電子錢包
- 優惠券管理
- 商店頁面

---

## 系統架構

### 技術棧

#### 前端框架
- **Flutter SDK**: 3.9.2+
- **Dart SDK**: 3.9.2+
- **Material Design**: 使用 Material Design 組件

#### 狀態管理
- **Provider** (v6.1.5+1)：輕量級狀態管理解決方案
  - `AuthProvider`：管理用戶認證狀態
  - `CartProvider`：管理購物車狀態
  - `ComparisonProvider`：管理商品比較狀態

#### 資料持久化
- **本地資料庫**：
  - **Isar** (v3.1.0+1)：高性能 NoSQL 資料庫
  - **SharedPreferences** (v2.3.4)：輕量級鍵值對存儲

- **雲端資料庫**：
  - **Firebase Firestore** (v6.0.3)：即時雲端資料庫
  - **Firebase Authentication** (v6.1.0)：用戶認證

#### 網路請求
- **Dio** (v5.9.0)：強大的 HTTP 客戶端
- **Connectivity Plus** (v6.1.2)：網路狀態監控

#### 無障礙技術
- **flutter_tts** (v4.2.3)：文字轉語音（Text-to-Speech）
- **speech_to_text** (v7.3.0)：語音轉文字（Speech-to-Text）
- **permission_handler** (v12.0.1)：權限管理

#### 其他核心套件
- **google_fonts** (v6.2.0)：字體支援
- **flutter_dotenv** (v6.0.0)：環境變數管理
- **flutter_local_notifications** (v18.0.1)：本地推送通知
- **intl** (v0.20.2)：國際化與日期格式化
- **timezone** (v0.10.0)：時區支援

### 資料庫架構

#### Isar 本地資料庫模型

```
models/
├── product.dart              # 商品資料
├── cart_item.dart            # 購物車項目
├── order.dart                # 訂單資料
├── order_status.dart         # 訂單狀態追蹤
├── store.dart                # 商店資料
├── user_profile.dart         # 用戶個人資料
├── user_settings.dart        # 用戶設定
├── notification.dart         # 通知資料
├── conversation.dart         # 對話記錄
├── chat_message.dart         # 聊天訊息
├── product_review.dart       # 商品評論
├── coupon.dart               # 優惠券
├── payment_method.dart       # 付款方式
└── shipping_method.dart      # 配送方式
```

**Isar 優勢**：
- 極快的查詢速度
- 支援複雜查詢和索引
- 完全離線工作
- 自動代碼生成
- 跨平台支援

#### Firebase Firestore 雲端資料庫
- 用於資料同步和備份
- 支援即時資料更新
- 提供安全規則保護

### 服務架構

#### 核心服務層

```
services/
├── 語音相關
│   ├── stt_service.dart                # 語音轉文字服務
│   ├── voice_control_service.dart      # 語音控制整合服務
│   ├── voice_command_parser.dart       # 語音命令解析器
│   └── voice_control_config.dart       # 語音控制配置
│
├── AI 相關
│   ├── ai_agent_service.dart           # AI 代理服務
│   └── openai_client.dart              # OpenAI 兼容客戶端
│
├── 無障礙相關
│   ├── accessibility_service.dart      # 無障礙服務（系統偵測）
│   ├── global_gesture_service.dart     # 全域手勢服務
│   └── focus_navigation_service.dart   # 焦點導航服務
│
├── 資料服務
│   ├── database_service.dart           # Isar 資料庫服務
│   ├── firestore_service.dart          # Firestore 服務
│   ├── auth_service.dart               # 認證服務
│   └── api_service.dart                # API 服務
│
├── 業務邏輯
│   ├── product_comparison_service.dart # 商品比較服務
│   ├── order_automation_service.dart   # 訂單自動化服務
│   ├── order_status_service.dart       # 訂單狀態服務
│   ├── order_review_service.dart       # 訂單評論服務
│   ├── order_check_service.dart        # 訂單檢查服務
│   ├── logistics_service.dart          # 物流服務
│   ├── seller_service.dart             # 賣家服務
│   ├── notification_service.dart       # 通知服務
│   ├── daily_reward_scheduler.dart     # 每日獎勵排程
│   └── connectivity_service.dart       # 網路連線服務
│
└── 測試相關
    └── test_data_service.dart          # 測試數據服務
```

#### 服務設計模式
- **單例模式**：TtsHelper、VoiceControlService 等確保全域唯一實例
- **觀察者模式**：使用 Provider 進行狀態通知
- **策略模式**：雙模式無障礙系統根據系統狀態切換策略

### 資料夾結構

```
d:\dev\accessible_shop\
│
├── lib/                          # 主要程式碼
│   ├── main.dart                 # 應用入口
│   ├── firebase_options.dart     # Firebase 配置
│   │
│   ├── models/                   # 資料模型（14 個模型）
│   ├── pages/                    # UI 頁面（按功能模組分類）
│   ├── services/                 # 業務邏輯服務（24 個服務）
│   ├── providers/                # 狀態管理（3 個 Provider）
│   ├── widgets/                  # 可重用 UI 元件（20+ 元件）
│   └── utils/                    # 工具類（TTS、常數、搜尋演算法等）
│
├── assets/                       # 資源檔案
│   └── images/                   # 圖片資源（應用圖標、動畫圖片）
│
├── android/                      # Android 平台配置
├── ios/                          # iOS 平台配置
├── functions/                    # Firebase Cloud Functions
│
├── pubspec.yaml                  # 依賴配置
├── .env                          # 環境變數（API 金鑰）
├── firebase.json                 # Firebase 配置
└── firestore.rules               # Firestore 安全規則
```

---

## 應用技術

### 文字轉語音（TTS）技術

#### 使用套件
- **flutter_tts** (v4.2.3)

#### 實現位置
- 核心實現：[lib/utils/tts_helper.dart](lib/utils/tts_helper.dart)

#### 技術特性

##### 1. 全域單例模式
```dart
class TtsHelper {
  static final TtsHelper _instance = TtsHelper._internal();
  factory TtsHelper() => _instance;
  TtsHelper._internal();
}
```
- 確保整個應用只有一個 TTS 實例
- 避免多個語音同時播放造成混亂

##### 2. 雙模式語音隊列系統
- **手動操作模式**（`isManualOperation: true`）
  - 立即打斷所有正在播放的語音
  - 適用於用戶主動觸發的操作
  - 確保即時反饋

- **自動朗讀模式**（`isManualOperation: false`）
  - 排隊執行，不互相打斷
  - 適用於頁面自動播報
  - 保證資訊完整性

##### 3. 語音配置
```dart
語言：繁體中文（zh-TW）
語速：0.45（較慢，便於理解）
音調：1.0（標準音調）
音量：1.0（最大音量）
```

##### 4. 狀態管理
- 支援語音開始回調（`onStart`）
- 支援語音結束回調（`onComplete`）
- 追蹤當前語音播放狀態

##### 5. 智能停止機制
- 可選擇性停止手動或自動語音
- 支援全部停止

#### 使用場景
- 按鈕點擊語音反饋
- 頁面導航語音提示
- 商品資訊朗讀
- AI 回應朗讀
- 錯誤訊息播報

### 語音轉文字（STT）技術

#### 使用套件
- **speech_to_text** (v7.3.0)

#### 實現位置
- 核心實現：[lib/services/stt_service.dart](lib/services/stt_service.dart)

#### 技術特性

##### 1. 持續監聽模式
```dart
持續監聽時間：最長 300 秒（5 分鐘）
停頓檢測：3 秒停頓後自動結束
```

##### 2. 即時轉文字
- 支援部分結果（partial results）即時顯示
- 使用者可即時看到識別進度
- 提供更好的互動體驗

##### 3. 自動重啟機制
- 監聽意外中斷時自動恢復
- 確保語音控制持續可用

##### 4. 語音配置
```dart
語言：繁體中文（zh_TW）
部分結果：啟用
聲音級別監控：可選
```

##### 5. 權限管理
- 自動檢查麥克風權限
- 引導用戶授予必要權限
- 整合 permission_handler 套件

#### 錯誤處理
- 偵測並處理權限拒絕
- 處理語音識別超時
- 處理網路異常

#### 使用場景
- 語音搜尋商品
- 語音命令導航
- 與 AI 助理對話
- 語音輸入文字

### AI 技術

#### 使用的 AI 模型

##### DeepSeek Chat API
- **模型名稱**：deepseek-chat
- **API 端點**：https://api.deepseek.com
- **API 格式**：兼容 OpenAI Chat Completion API

#### 實現位置
- AI 代理服務：[lib/services/ai_agent_service.dart](lib/services/ai_agent_service.dart)
- OpenAI 兼容客戶端：[lib/services/openai_client.dart](lib/services/openai_client.dart)

#### 技術特性

##### 1. 流式回應（SSE）
```dart
使用 Server-Sent Events 即時接收 AI 回應
逐字顯示，提供打字機效果
降低用戶等待感
```

##### 2. 對話歷史管理
- 保留完整對話上下文
- 支援多輪對話
- 記憶用戶偏好和需求

##### 3. 系統提示（System Prompt）
```
角色定位：購物助手「大千」
風格：友善、口語化、繁體中文
輸出格式：純文字，無 emoji 和特殊符號
回答長度：一般限制 60 字（除非檢索資料）
專業領域：購物諮詢、商品推薦、訂單協助
```

##### 4. 智能功能
- **商品搜尋輔助**：理解自然語言搜尋意圖
- **購物建議**：根據用戶需求推薦商品
- **訂單查詢**：協助查詢訂單狀態
- **問題解答**：回答購物相關問題

##### 5. 環境變數管理
```env
DEEPSEEK_API_KEY=your_api_key_here
```
使用 flutter_dotenv 安全管理 API 金鑰

#### AI 整合流程
```
用戶語音輸入（STT）
    ↓
語音轉文字
    ↓
發送到 DeepSeek API
    ↓
流式接收 AI 回應
    ↓
文字顯示 + TTS 朗讀
    ↓
保存對話歷史
```

### 無障礙技術

#### 1. 智能雙模式無障礙系統

##### 系統偵測服務
- **實現位置**：[lib/services/accessibility_service.dart](lib/services/accessibility_service.dart)
- **功能**：自動偵測 TalkBack（Android）或 VoiceOver（iOS）是否啟用

##### 模式切換邏輯

**系統無障礙已啟用時**：
```dart
單擊：聚焦並朗讀（使用系統 TTS）
雙擊：執行動作
使用 Semantics 標籤
停用自訂全域手勢（避免衝突）
```

**系統無障礙未啟用時**：
```dart
單擊：朗讀說明（使用自訂 TTS）
雙擊：執行動作
使用 GestureDetector
啟用自訂全域手勢
```

#### 2. 智能手勢包裝器

##### AccessibleGestureWrapper
- **實現位置**：[lib/widgets/accessible_gesture_wrapper.dart](lib/widgets/accessible_gesture_wrapper.dart)
- **功能**：
  - 根據系統無障礙狀態自動切換行為
  - 提供統一的單擊/雙擊介面
  - 整合語音反饋

##### GlobalGestureWrapper
- **實現位置**：[lib/widgets/global_gesture_wrapper.dart](lib/widgets/global_gesture_wrapper.dart)
- **功能**：
  - 兩指上滑：回到首頁
  - 兩指下滑：返回上一頁
  - 智能啟用/停用

#### 3. 焦點導航系統

- **實現位置**：[lib/services/focus_navigation_service.dart](lib/services/focus_navigation_service.dart)
- **功能**：
  - 管理頁面內可聚焦項目
  - 支援左右滑動切換項目
  - 自動朗讀當前聚焦項目
  - 視覺高亮顯示當前焦點

#### 4. 無障礙 UI 元件

##### VoiceControlAppBar
- **實現位置**：[lib/widgets/voice_control_appbar.dart](lib/widgets/voice_control_appbar.dart)
- **功能**：
  - 短按：朗讀頁面指引
  - 長按 2 秒：開啟/關閉語音控制
  - 動畫反饋

##### AccessibleTextField
- 整合語音朗讀
- 支援語音輸入
- 無障礙標籤

##### AccessibleStarRating
- 可透過語音操作評分
- 星星數量語音播報
- 支援左右滑動調整評分

#### 5. 語音控制整合

##### VoiceControlService
- **實現位置**：[lib/services/voice_control_service.dart](lib/services/voice_control_service.dart)
- **功能**：
  - 整合 TTS 和 STT
  - 語音命令解析
  - 智能暫停機制（TTS 播放時暫停 STT）
  - 持久化語音控制狀態

##### VoiceCommandParser
- **實現位置**：[lib/services/voice_command_parser.dart](lib/services/voice_command_parser.dart)
- **支援命令**：
  - 導航命令：「回首頁」、「打開購物車」、「訂單」
  - 搜尋命令：「搜尋[商品名稱]」
  - 功能命令：「開啟語音控制」、「關閉語音控制」

### 其他關鍵技術

#### 1. 模糊搜尋演算法

- **實現位置**：[lib/utils/fuzzy_search_helper.dart](lib/utils/fuzzy_search_helper.dart)

##### 演算法組成
- **編輯距離（Levenshtein Distance）**：計算字串相似度
- **部分匹配**：支援子字串匹配
- **拼音匹配**：支援注音/拼音搜尋
- **智能排序**：綜合多種因素排序結果

##### 搜尋優化
- 支援錯字容忍
- 不分大小寫
- 去除空白字元
- 權重計分系統

#### 2. 網路連線監控

- **實現位置**：[lib/services/connectivity_service.dart](lib/services/connectivity_service.dart)

##### 功能
- 即時監控網路狀態
- 斷線時顯示等待畫面
- 自動重連機制
- 整合到導航系統

#### 3. 通知系統

##### 本地推送通知
- **套件**：flutter_local_notifications
- **功能**：
  - 訂單狀態更新通知
  - 每日獎勵提醒
  - 促銷活動通知
- **時區支援**：使用 timezone 套件確保準確時間

#### 4. 訂單自動化系統

- **實現位置**：[lib/services/order_automation_service.dart](lib/services/order_automation_service.dart)

##### 功能
- 自動更新訂單狀態
- 模擬物流進度
- 自動完成訂單
- 觸發通知

#### 5. 動畫效果

##### 語音助手動畫
- **實現位置**：[lib/widgets/voice_assistant_animation.dart](lib/widgets/voice_assistant_animation.dart)
- **資源**：
  - 開啟動畫：assets/images/agent_on.png
  - 關閉動畫：assets/images/agent_off.png

##### 金蓮花動畫
- **實現位置**：[lib/widgets/golden_lotus_animation.dart](lib/widgets/golden_lotus_animation.dart)
- **用途**：AI 代理「大千世界」的開場動畫
- **效果**：漸入漸出、旋轉、縮放的組合動畫

---

## 技術亮點

### 1. 創新的雙模式無障礙系統

**問題**：
- 系統無障礙服務（如 TalkBack）與應用自訂功能容易衝突
- 未開啟系統無障礙的用戶無法享受無障礙功能

**解決方案**：
- 智能偵測系統無障礙狀態
- 動態切換系統模式和自訂模式
- 避免功能重複和衝突
- 提供最佳使用體驗

**創新點**：
- 業界少見的智能適配方案
- 兼容性和自主性的完美平衡

### 2. 完整的語音交互生態

**TTS + STT + AI 的無縫整合**：
```
用戶 → STT 語音輸入 → AI 理解 → AI 回應 → TTS 朗讀 → 用戶
```

**智能防干擾**：
- TTS 播放時自動暫停 STT
- 避免語音助手「自己和自己對話」
- 雙模式語音隊列避免混亂

### 3. 高性能本地資料庫

**選用 Isar 的優勢**：
- 比 SQLite 快 10 倍以上
- 完全離線工作
- 自動代碼生成，減少錯誤
- 支援複雜查詢和索引

**應用場景**：
- 商品資料緩存
- 購物車離線管理
- 訂單歷史存儲
- 對話記錄保存

### 4. 智能搜尋系統

**多維度匹配**：
- 精確匹配
- 模糊匹配（編輯距離）
- 部分匹配
- 拼音匹配

**智能排序**：
- 綜合相似度評分
- 考慮商品熱度
- 價格範圍篩選
- 評分權重

### 5. AI 驅動的購物體驗

**個性化服務**：
- 理解用戶自然語言需求
- 提供智能商品推薦
- 24/7 購物諮詢
- 持續學習用戶偏好

**無障礙友善**：
- 純文字輸出，適合 TTS 朗讀
- 簡潔明瞭的回答
- 口語化表達

### 6. 離線優先設計

**策略**：
- 本地資料庫作為主要資料來源
- 雲端資料庫用於同步和備份
- 離線也能瀏覽商品、管理購物車
- 網路恢復後自動同步

**優勢**：
- 極快的響應速度
- 降低流量消耗
- 提升用戶體驗

### 7. 完善的開發工具

**開發工具頁面**：
- 資料庫管理介面
- 測試數據一鍵初始化
- 快速清除數據
- 方便開發和測試

**代碼品質**：
- 使用 flutter_lints 確保代碼品質
- build_runner 自動生成代碼
- 減少手動編寫錯誤

### 8. 模組化架構

**清晰的分層**：
```
UI 層（Pages + Widgets）
    ↓
業務邏輯層（Services）
    ↓
資料層（Models + Database）
```

**優勢**：
- 易於維護和擴展
- 元件可重用性高
- 測試友善
- 團隊協作效率高

### 9. 安全性考慮

**API 金鑰管理**：
- 使用 .env 檔案存儲敏感資訊
- .gitignore 排除 .env 避免洩漏

**Firebase 安全規則**：
- Firestore 規則保護資料存取
- 用戶只能存取自己的資料

**權限管理**：
- 使用 permission_handler 規範權限請求
- 引導用戶理解權限用途

### 10. 跨平台一致性

**Flutter 優勢**：
- 單一代碼庫支援 Android 和 iOS
- 一致的 UI 和 UX
- 降低開發和維護成本

**平台適配**：
- 自動適配 TalkBack（Android）和 VoiceOver（iOS）
- 使用 Cupertino 和 Material 組件
- 響應式設計

---

## 總結

Accessible Shop 是一個技術先進、功能完整的無障礙購物應用，特別專注於視障用戶的使用體驗。透過創新的雙模式無障礙系統、完整的語音交互生態、AI 智能助理，以及高性能的技術架構，為視障人士提供了一個真正可用、好用的線上購物平台。

### 主要成就
- 完整的語音導航和控制系統
- 智能 AI 購物助理
- 高性能離線優先架構
- 創新的雙模式無障礙設計
- 模組化和可擴展的代碼結構

### 技術創新
- 智能適配系統無障礙服務
- TTS/STT/AI 的無縫整合
- 雙模式語音隊列系統
- 多維度智能搜尋演算法

### 未來展望
- 擴展更多 AI 功能（如智能客服、語音導購）
- 優化語音識別準確度
- 增加更多無障礙手勢
- 整合更多支付和物流服務
- 建立無障礙設計標準和最佳實踐

---

**文件版本**：1.0
**更新日期**：2025-11-08
**作者**：Accessible Shop 開發團隊
