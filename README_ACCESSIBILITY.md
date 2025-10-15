# 無障礙設計說明文件

## 概述

本專案實作了**智能雙模式無障礙系統**，能自動偵測並適配系統無障礙服務（TalkBack/VoiceOver），避免與手機原生無障礙功能產生衝突。

---

## 核心架構

### 1. 無障礙服務 (AccessibilityService)
**位置**: `lib/services/accessibility_service.dart`

**功能**:
- 偵測系統無障礙模式是否啟用（TalkBack/VoiceOver）
- 提供策略判斷 API

**使用方式**:
```dart
// 初始化（在頁面 initState 中）
accessibilityService.initialize(context);

// 檢查是否應使用系統無障礙
if (accessibilityService.shouldUseSystemAccessibility) {
  // 使用 Semantics Widget
}

// 檢查是否應使用自訂 TTS
if (accessibilityService.shouldUseCustomTTS) {
  ttsHelper.speak("文字");
}
```

---

### 2. 智能手勢包裝器
**位置**: `lib/widgets/accessible_gesture_wrapper.dart`

提供兩個核心 Widget：

#### AccessibleGestureWrapper
用於**可點擊的元素**（按鈕、選項等）

**雙模式行為**:
- **系統無障礙已啟用**:
  - 使用 `Semantics` 提供語意標籤
  - 單擊執行動作（符合 TalkBack/VoiceOver 規範）

- **系統無障礙未啟用**:
  - 單擊播放語音說明
  - 雙擊執行動作

**使用範例**:
```dart
AccessibleGestureWrapper(
  label: '下一步',
  description: '前往選擇優惠券',
  onTap: () {
    // 執行動作
  },
  child: Container(
    // 按鈕視覺設計
  ),
)
```

#### AccessibleSpeakWrapper
用於**僅需朗讀的元素**（資訊顯示、文字說明等）

**雙模式行為**:
- **系統無障礙已啟用**: 使用 `Semantics` 標註為 `readOnly`
- **系統無障礙未啟用**: 單擊播放語音

**使用範例**:
```dart
AccessibleSpeakWrapper(
  label: '商品總計 500 元',
  child: Row(
    children: [
      Text('總計:'),
      Text('\$500'),
    ],
  ),
)
```

---

## 手勢設計對照表

| 使用者操作 | 系統無障礙模式 | 自訂模式 |
|----------|-------------|---------|
| 單擊元素 | 聚焦並朗讀 | 朗讀說明 |
| 雙擊元素 | 執行動作 | 執行動作 |
| 語音來源 | 系統 TTS (TalkBack/VoiceOver) | 自訂 TTS (flutter_tts) |

---

## 衝突避免機制

### 問題 1: 重複朗讀
**解決方案**:
```dart
if (accessibilityService.shouldUseCustomTTS) {
  ttsHelper.speak("文字");
}
```
只在自訂模式下播放語音，避免與系統朗讀重複。

### 問題 2: 手勢衝突
**解決方案**:
- 系統模式: 使用標準 `onTap` + `Semantics`
- 自訂模式: 使用 `onTap`（朗讀）+ `onDoubleTap`（執行）

---

## 實作範例：結帳頁面

**檔案**: `lib/pages/checkout/checkout_page_refactored.dart`

### 初始化
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // 1. 初始化無障礙服務
    accessibilityService.initialize(context);

    // 2. 只在自訂模式播放歡迎語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak("進入結帳頁面");
    }
  });
}
```

### 按鈕實作
```dart
AccessibleGestureWrapper(
  label: '確認結帳',
  description: '完成付款並送出訂單',
  enabled: selectedPayment != null,
  onTap: selectedPayment != null ? onNext : null,
  child: Container(
    // 按鈕 UI
  ),
)
```

### 資訊顯示實作
```dart
AccessibleSpeakWrapper(
  label: '商品總計 ${subtotal.toStringAsFixed(0)} 元',
  child: Row(
    children: [
      Text('商品總計:'),
      Text('\$${subtotal.toStringAsFixed(0)}'),
    ],
  ),
)
```

---

## 測試指南

### 測試自訂模式（系統無障礙關閉）
1. 確保手機 TalkBack/VoiceOver **已關閉**
2. 開啟 App
3. 驗證行為:
   - 單擊元素 → 播放語音說明
   - 雙擊元素 → 執行動作
   - 語音來源: flutter_tts

### 測試系統模式（系統無障礙開啟）
1. 開啟手機 TalkBack (Android) 或 VoiceOver (iOS)
2. 開啟 App
3. 驗證行為:
   - 單擊元素 → 聚焦並朗讀（系統語音）
   - 雙擊元素 → 執行動作
   - 語音來源: 系統 TTS
   - 無雙重朗讀

---

## 遷移指南

### 從舊版遷移到新版

**舊版程式碼**:
```dart
GestureDetector(
  onTap: () {
    ttsHelper.speak('下一步');
  },
  onDoubleTap: onNext,
  child: Container(...),
)
```

**新版程式碼**:
```dart
AccessibleGestureWrapper(
  label: '下一步',
  description: '前往下一個步驟',
  onTap: onNext,
  child: Container(...),
)
```

**優勢**:
1. 自動適配系統無障礙
2. 無手勢衝突
3. 符合無障礙規範
4. 更簡潔的 API

---

## 最佳實踐

### ✅ 正確做法
```dart
// 1. 在頁面初始化時偵測模式
accessibilityService.initialize(context);

// 2. 條件性播放語音
if (accessibilityService.shouldUseCustomTTS) {
  ttsHelper.speak("歡迎訊息");
}

// 3. 使用包裝器而非手動判斷
AccessibleGestureWrapper(...)
```

### ❌ 錯誤做法
```dart
// 1. 直接播放語音（可能重複）
ttsHelper.speak("訊息");

// 2. 手動處理雙模式邏輯
if (某條件) {
  // Semantics...
} else {
  // GestureDetector...
}

// 3. 混用系統和自訂手勢
```

---

## 技術細節

### MediaQuery.accessibleNavigation
Flutter 透過 `MediaQuery.of(context).accessibleNavigation` 偵測系統無障礙服務：

- **Android**: 偵測 TalkBack 是否啟用
- **iOS**: 偵測 VoiceOver 是否啟用
- **Web/Desktop**: 根據平台輔助技術決定

### Semantics Widget
提供給系統無障礙服務的語意資訊：

```dart
Semantics(
  label: '按鈕名稱',           // 元素標籤
  hint: '操作說明',            // 操作提示
  button: true,               // 標記為按鈕
  enabled: true,              // 是否可用
  onTap: () {},              // 點擊回調
  child: Widget(...),
)
```

---

## 常見問題

### Q: 如何測試系統無障礙模式？
**A**:
- Android: 設定 → 無障礙 → TalkBack → 開啟
- iOS: 設定 → 輔助使用 → VoiceOver → 開啟

### Q: 為什麼要優先使用系統無障礙？
**A**:
1. 使用者已熟悉系統手勢
2. 更完整的無障礙功能（導航、點字支援等）
3. 符合平台規範

### Q: 可以強制使用自訂模式嗎？
**A**:
可以，但**不建議**。若確實需要：
```dart
// 修改 accessibility_service.dart
bool get shouldUseCustomTTS => true; // 強制自訂
```

### Q: 如何調整語音速度？
**A**:
修改 `lib/utils/tts_helper.dart`:
```dart
await _flutterTts.setSpeechRate(0.45); // 調整數值 (0.0 - 1.0)
```

---

## 參考資源

- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://m3.material.io/foundations/accessible-design/overview)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
