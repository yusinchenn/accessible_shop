# 頁面設計原則

本文件說明 `lib/pages` 資料夾中所有頁面設計應遵循的無障礙設計原則。

## 1. 導航設計原則

### 關閉/返回操作
- **禁止使用按鈕**：頁面頁首不應該有「關閉」、「返回」等按鈕
- **使用手勢操作**：採用「雙指下滑」手勢來關閉或返回頁面
- **實作參考**：詳見 [lib/widgets/global_gesture_wrapper.dart](../widgets/global_gesture_wrapper.dart) 和 [lib/services/global_gesture_service.dart](../services/global_gesture_service.dart)

## 2. 語音朗讀原則

### 頁面進入朗讀
- 進入（開啟）頁面時必須朗讀：**「進入XX頁面」**
- 實作方式：使用 [lib/utils/tts_helper.dart](../utils/tts_helper.dart) 的 TTS 功能

### 元素朗讀規則
- **純內容元素**：單擊朗讀元素內容文字
  - 範例：文字標籤單擊時朗讀該文字內容

- **功能性元素**：單擊朗讀「內容 + 功能」
  - 範例：完成按鈕朗讀「完成按鈕」
  - 範例：刪除按鈕朗讀「刪除按鈕」
  - 範例：商品項目朗讀「商品名稱，加入購物車按鈕」

### 相容性要求
- 必須同時支援程式內建 TTS ([lib/utils/tts_helper.dart](../utils/tts_helper.dart))
- 必須相容手機內建無障礙功能（如 Android TalkBack、iOS VoiceOver）

## 3. 手勢操作原則

### 基本手勢
- **左右滑動**：選取頁面的上一項或下一項元素
- **單擊**：觸發元素的語音朗讀
- **雙擊**：觸發元素的點選動作（執行功能）
- **雙指下滑**：關閉/返回頁面

### 實作要求
- 所有頁面必須包裹在 `GlobalGestureWrapper` 中
- 手勢邏輯由 [lib/services/global_gesture_service.dart](../services/global_gesture_service.dart) 統一管理
- 詳細實作參考 [lib/widgets/global_gesture_wrapper.dart](../widgets/global_gesture_wrapper.dart)

### 相容性要求
- 必須支援程式自定義手勢
- 必須相容手機內建無障礙手勢（如 TalkBack、VoiceOver 手勢）

## 4. 實作檢查清單

在建立或修改頁面時，請確認以下事項：

- [ ] 頁面已使用 `GlobalGestureWrapper` 包裹
- [ ] 頁面進入時有朗讀「進入XX頁面」
- [ ] 頁首沒有「關閉」或「返回」按鈕
- [ ] 所有可互動元素都有適當的語音朗讀標籤
- [ ] 功能性元素的朗讀包含「元素名稱 + 按鈕/功能」
- [ ] 測試左右滑動可以正確切換元素焦點
- [ ] 測試單擊可以觸發朗讀
- [ ] 測試雙擊可以觸發元素動作
- [ ] 測試雙指下滑可以關閉/返回頁面
- [ ] 在 TalkBack/VoiceOver 開啟時測試相容性

## 5. 參考文件

- TTS 語音助手：[lib/utils/tts_helper.dart](../utils/tts_helper.dart)
- 全域手勢服務：[lib/services/global_gesture_service.dart](../services/global_gesture_service.dart)
- 全域手勢包裝器：[lib/widgets/global_gesture_wrapper.dart](../widgets/global_gesture_wrapper.dart)

## 6. 範例頁面

參考現有頁面的實作方式，確保新頁面遵循相同的設計模式和無障礙標準。
