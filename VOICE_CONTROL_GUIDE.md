# 語音控制優化指南

## 🎯 優化方案

### 問題描述
原本的設計會讓麥克風頻繁開關，造成不好的用戶體驗。

### 解決方案
採用 **長時間連續監聽** 的策略，減少麥克風開關頻率：

1. **延長監聽時間**：從 30 秒增加到 10 分鐘
2. **增加停頓容忍度**：從 3 秒增加到 10 秒
3. **智能重啟邏輯**：只在真正超時時重啟，避免頻繁開關
4. **啟用部分結果**：可以看到即時識別（調試用）
5. **音量監聽**：可選的音量偵測功能

## ⚙️ 配置說明

所有配置都在 `lib/services/voice_control_config.dart` 中：

```dart
class VoiceControlConfig {
  /// 單次監聽最長時間（預設：10分鐘）
  /// 麥克風會保持開啟直到超時或偵測到停頓
  static const listenDuration = Duration(minutes: 10);

  /// 停頓多久後結束本次識別（預設：10秒）
  /// 用戶說完話後，會等待10秒沒有聲音才結束識別
  /// 較長的停頓時間可避免環境噪音導致頻繁重啟
  static const pauseDuration = Duration(seconds: 10);

  /// 是否啟用部分結果（預設：啟用）
  /// 啟用後可以在 debug console 看到即時識別結果
  static const enablePartialResults = true;

  /// 是否啟用音量監聽（預設：關閉）
  /// 啟用後會在 console 顯示音量變化（dB）
  static const enableSoundLevelMonitoring = false;

  /// 最小音量閾值（預設：0，不啟用）
  /// 如果啟用（>0），只有超過此音量才處理識別結果
  /// 範圍：0-100
  static const minSoundLevel = 0.0;

  /// 錯誤後重試延遲（預設：1秒）
  static const errorRetryDelay = Duration(seconds: 1);

  /// 識別完成後重啟延遲（預設：3秒）
  /// 使用較長延遲避免頻繁重啟
  static const restartDelay = Duration(seconds: 3);

  /// TTS 結束後恢復 STT 的延遲時間（預設：300ms）
  static const ttsEndRecoveryDelay = Duration(milliseconds: 300);
}
```

## 🔄 最新優化 (v2)

### 問題
原本的設計會在任何聲響（包括環境噪音）時觸發語音識別，導致麥克風頻繁重啟開關。

### 改進
1. **延長監聽時間**：10 分鐘（更長的持續監聽）
2. **延長停頓容忍**：10 秒（避免環境噪音干擾）
3. **智能重啟邏輯**：
   - 移除了在每次識別完成時的自動重啟
   - 只在真正超時（10分鐘）時才重啟
   - 延遲 1 秒檢查是否需要重啟，避免誤判
4. **更長的重啟延遲**：3 秒（進一步減少頻率）

### 效果
- ✅ 麥克風保持開啟更長時間（10 分鐘）
- ✅ 不會因為環境噪音而重啟
- ✅ 用戶可以連續說多個命令
- ✅ 識別精準度更高（有更多時間處理）

## 📱 使用說明

### 如何開啟語音控制
1. 在任何頁面**長按 AppBar 標題 1 秒**
2. 聽到「開啟語音控制」提示
3. 感受到震動反饋
4. 開始說出語音命令

### 常用語音命令
- **導航類**：「購物車」、「訂單」、「搜尋」、「設定」
- **返回類**：「上一頁」、「返回」、「回首頁」
- **其他頁面**：「通知」、「短影音」、「錢包」、「商品比較」

### 如何關閉語音控制
1. 再次**長按 AppBar 標題 1 秒**
2. 聽到「關閉語音控制」提示

### 使用流程範例
```
👤 用戶：長按 AppBar 1秒
🔊 系統：「開啟語音控制」
🎤 麥克風：開始監聽（最長10分鐘）

👤 用戶：「購物車」
📱 系統：震動反饋 → 進入購物車頁面
🎤 麥克風：持續監聽（不重啟）

👤 用戶：（停頓5秒）「訂單」
📱 系統：震動反饋 → 進入訂單頁面
🎤 麥克風：持續監聽（不重啟）

👤 用戶：（環境噪音或其他聲音）
🎤 麥克風：持續監聽（不受干擾）

👤 用戶：「回首頁」
📱 系統：震動反饋 → 回到首頁
🎤 麥克風：持續監聽（不重啟）

（經過 10 分鐘後）
🔄 系統：自動重啟監聽（用戶無感知）
```

## 🔧 調整建議

### 如果想要更快速的響應
```dart
static const pauseDuration = Duration(seconds: 3);  // 減少等待時間
static const restartDelay = Duration(seconds: 1);   // 更快重啟
```

### 如果想要更長的連續操作
```dart
static const listenDuration = Duration(minutes: 10); // 延長監聽時間
static const pauseDuration = Duration(seconds: 8);   // 給更多思考時間
```

### 如果想要啟用音量偵測（調試用）
```dart
static const enableSoundLevelMonitoring = true;  // 啟用音量監聽
```

然後在 debug console 中可以看到：
```
[STT] Sound level: 45.2 dB
[STT] Sound level: 52.8 dB
```

### 如果想要過濾環境噪音（進階）
```dart
static const minSoundLevel = 30.0;  // 只處理超過30dB的聲音
```

## 🎤 工作流程

### 開啟語音控制後
1. 麥克風開始監聽（最長10分鐘）
2. 偵測到語音 → 開始識別
3. 識別到有效命令 → 執行命令
4. 繼續監聽（不重啟，除非超時）
5. 10分鐘超時 → 延遲1秒後檢查是否需要重啟
6. 如需重啟 → 等待3秒後重啟（回到步驟1）

### 優點
- ✅ 麥克風保持開啟更長時間（10分鐘）
- ✅ 大幅減少開關頻率
- ✅ 不受環境噪音干擾
- ✅ 更自然的語音互動
- ✅ 支援連續多個命令
- ✅ 更穩定的識別效果

### TTS 播放時
- 自動暫停 STT（避免識別到自己的聲音）
- TTS 結束後 300ms 自動恢復

### 錯誤處理
- 遇到錯誤會自動重試（1秒後）
- 不會因為單次錯誤就停止語音控制

## 📊 性能考量

### 電池消耗
- 長時間監聽會增加電池消耗
- 建議在實際使用中測試並調整 `listenDuration`

### 隱私考量
- 所有語音識別都在本地進行（使用 Google 的語音識別 API）
- 不會錄音或儲存語音數據
- 只處理最終的文字結果

## 🚀 進階功能（未來可擴展）

### 關鍵詞喚醒
可以實現類似 "Hey Siri" 的功能：
- 持續監聽特定喚醒詞
- 聽到喚醒詞後才處理命令
- 需要額外的關鍵詞偵測庫

### 自適應停頓時間
根據用戶的說話習慣動態調整 `pauseDuration`：
- 說話快的用戶：縮短停頓時間
- 說話慢的用戶：延長停頓時間

### 情境感知
根據當前頁面或時間調整監聽策略：
- 購物時：啟用商品相關詞彙優化
- 夜間：降低音量閾值

## 🐛 調試技巧

### 查看語音識別日誌
在 debug console 中會看到：
```
[STT] Status: listening
[STT] Recognized (final: false): 購物
[STT] Recognized (final: true): 購物車
[VoiceControl] Command executed: 購物車
```

### 啟用音量監聽
```dart
static const enableSoundLevelMonitoring = true;
```

### 查看重啟流程
```
[STT] Status: done
[STT] Preparing to restart listening in 2 seconds...
[STT] Listening restarted successfully
```

## 📝 注意事項

1. **Android 權限**：確保 `AndroidManifest.xml` 中有 `RECORD_AUDIO` 權限
2. **iOS 權限**：需要在 `Info.plist` 中設置麥克風使用說明
3. **網絡需求**：語音識別需要網絡連接（使用 Google API）
4. **測試建議**：在不同環境（安靜/嘈雜）下測試效果
