# 語音助手「小千」動畫說明

## 🎭 動畫效果

### 開啟動畫
**角色登場：小千駕到！**

- **圖片**：`assets/images/agent_on.png`
- **尺寸**：螢幕寬度的 70%
- **動畫流程**：
  1. **階段1（0.0-0.4s）**：從螢幕底部向上冒出
     - 圖片從底部上升到螢幕中間偏下（50%位置）
     - 圖片底部不會高過畫面底部
  2. **階段2（0.4-0.7s）**：在中間位置水平旋轉一圈
     - 旋轉360度（2π弧度）
     - 保持在50%位置
  3. **階段3（0.7-1.0s）**：下降並消失
     - 從50%位置下降回底部
- **總時長**：2秒
- **語音提示**：「您的語音操作助手 小千 駕到」

### 關閉動畫
**角色退場：小千告退！**

- **圖片**：`assets/images/agent_off.png`
- **尺寸**：螢幕高度的 70%
- **動畫流程**：
  1. **階段1（0.0-0.4s）**：從螢幕右側向左冒出
     - 圖片從右側移動到螢幕中間偏右（50%位置）
     - 圖片右側不會超過畫面右側
  2. **階段2（0.4-0.7s）**：在中間位置停留
     - 停留約0.6秒
     - 保持在50%位置
  3. **階段3（0.7-1.0s）**：向右移動並隱藏
     - 從50%位置移動到右側邊緣外
- **總時長**：2秒
- **語音提示**：「您的語音操作助手 小千 告退」

## 📁 文件結構

```
lib/
├── widgets/
│   └── voice_assistant_animation.dart  # 動畫實現
├── services/
│   └── voice_control_service.dart      # 整合動畫和語音
└── utils/
    └── tts_helper.dart                 # 語音播報

assets/
└── images/
    ├── agent_on.png                    # 開啟動畫圖片
    └── agent_off.png                   # 關閉動畫圖片
```

## 🔧 實現細節

### 動畫 Widget

**[lib/widgets/voice_assistant_animation.dart](lib/widgets/voice_assistant_animation.dart)**

```dart
/// 動畫類型
enum VoiceAssistantAnimationType {
  enable,   // 開啟動畫
  disable,  // 關閉動畫
}

/// 動畫 Widget
class VoiceAssistantAnimation extends StatefulWidget {
  final VoiceAssistantAnimationType type;
  final VoidCallback? onComplete;
  // ...
}

/// Overlay 顯示動畫
class VoiceAssistantAnimationOverlay {
  static void show(BuildContext context, {
    required VoiceAssistantAnimationType type,
    VoidCallback? onComplete,
  });

  static void hide();
}
```

### 整合到語音控制服務

**[lib/services/voice_control_service.dart](lib/services/voice_control_service.dart)**

```dart
/// 開啟語音控制
Future<void> enable() async {
  // 1. 震動反饋
  HapticFeedback.mediumImpact();

  // 2. 顯示開啟動畫
  VoiceAssistantAnimationOverlay.show(
    context,
    type: VoiceAssistantAnimationType.enable,
  );

  // 3. 語音提示
  await ttsHelper.speak('您的語音操作助手 小千 駕到');

  // 4. 啟動語音控制
  await _startVoiceControl();
}

/// 關閉語音控制
Future<void> disable() async {
  // 1. 停止語音監聽
  await _stopVoiceControl();

  // 2. 震動反饋
  HapticFeedback.mediumImpact();

  // 3. 顯示關閉動畫
  VoiceAssistantAnimationOverlay.show(
    context,
    type: VoiceAssistantAnimationType.disable,
  );

  // 4. 語音提示
  await ttsHelper.speak('您的語音操作助手 小千 告退');
}
```

## 🎨 圖片資源要求

### agent_on.png（開啟動畫）
- **建議尺寸**：512x512 或更大（正方形）
- **格式**：PNG（支援透明背景）
- **內容建議**：
  - 友善的助手形象
  - 歡迎/打招呼的姿勢
  - 明亮的色調（藍色、綠色）

### agent_off.png（關閉動畫）
- **建議尺寸**：512x512 或更大（正方形）
- **格式**：PNG（支援透明背景）
- **內容建議**：
  - 揮手告別的姿勢
  - 柔和的色調（灰色、淡藍色）

### 占位符
如果圖片不存在，會顯示：
- **開啟**：藍色圓形 + 麥克風圖示
- **關閉**：紅色圓形 + 關閉麥克風圖示

## 🎯 使用流程

```
用戶：長按 AppBar 1秒
  ↓
系統：
  1. 震動反饋
  2. 顯示開啟動畫（小千從底部冒出並旋轉）
  3. 語音播報「您的語音操作助手 小千 駕到」
  4. 啟動語音識別
  ↓
語音控制已開啟，可以開始說命令
  ↓
用戶：再次長按 AppBar 1秒
  ↓
系統：
  1. 停止語音識別
  2. 震動反饋
  3. 顯示關閉動畫（小千從右邊出現並告別）
  4. 語音播報「您的語音操作助手 小千 告退」
  ↓
語音控制已關閉
```

## 🔍 技術細節

### 動畫控制器
```dart
AnimationController _controller = AnimationController(
  vsync: this,
  duration: Duration(milliseconds: 2000),
);

Animation<double> _animation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOut,
);
```

### 開啟動畫計算
```dart
// 階段1：上升（0.0-0.4）
if (_animation.value < 0.4) {
  final progress = _animation.value / 0.4;
  verticalOffset = screenHeight * (1 - progress * 0.5);
}

// 階段2：旋轉（0.4-0.7）
else if (_animation.value < 0.7) {
  final progress = (_animation.value - 0.4) / 0.3;
  verticalOffset = screenHeight * 0.5;
  rotation = progress * math.pi * 2;
}

// 階段3：下降（0.7-1.0）
else {
  final progress = (_animation.value - 0.7) / 0.3;
  verticalOffset = screenHeight * (0.5 + progress * 0.5);
}
```

### 關閉動畫計算
```dart
// 階段1：從右進入（0.0-0.4）
if (_animation.value < 0.4) {
  final progress = _animation.value / 0.4;
  horizontalOffset = screenWidth * (1 - progress * 0.5);
}

// 階段2：停留（0.4-0.7）
else if (_animation.value < 0.7) {
  horizontalOffset = screenWidth * 0.5;
}

// 階段3：向右退出（0.7-1.0）
else {
  final progress = (_animation.value - 0.7) / 0.3;
  horizontalOffset = screenWidth * (0.5 + progress * 0.5);
}
```

## 🐛 調試提示

### 查看動畫執行
在 console 中會看到：
```
[VoiceControl] Enabling voice control
[TTS] 🚀 Start handler triggered
[TTS] 🔊 Speech playing: 您的語音操作助手 小千 駕到
```

### 圖片載入問題
如果看到占位符而不是圖片：
1. 檢查圖片路徑是否正確：`assets/images/agent_on.png`
2. 確認已執行：`flutter pub get`
3. 重新建置專案：`flutter clean && flutter run`

### 動畫不流暢
如果動畫卡頓：
1. 確認圖片尺寸不要太大（建議 512x512 或 1024x1024）
2. 使用 PNG 格式並優化文件大小
3. 檢查設備性能

## 📱 測試步驟

1. **建置專案**
   ```bash
   flutter pub get
   flutter run
   ```

2. **測試開啟動畫**
   - 進入任何頁面
   - 長按 AppBar 標題 1 秒
   - 應該看到小千從底部上升並旋轉
   - 聽到「您的語音操作助手 小千 駕到」

3. **測試關閉動畫**
   - 再次長按 AppBar 標題 1 秒
   - 應該看到小千從右邊出現並退出
   - 聽到「您的語音操作助手 小千 告退」

4. **檢查占位符**
   - 如果圖片不存在，應該看到圓形占位符
   - 開啟：藍色圓形 + 麥克風圖示
   - 關閉：紅色圓形 + 麥克風關閉圖示

## 🎨 自訂動畫

如果想要修改動畫效果，可以調整以下參數：

### 動畫時長
```dart
// 在 voice_assistant_animation.dart 中
final duration = widget.type == VoiceAssistantAnimationType.enable
    ? const Duration(milliseconds: 2000) // 改為想要的時間
    : const Duration(milliseconds: 2000);
```

### 圖片尺寸
```dart
// 開啟動畫 - 寬度
final imageWidth = screenSize.width * 0.7; // 改為 0.5, 0.8 等

// 關閉動畫 - 高度
final imageHeight = screenSize.height * 0.7; // 改為 0.5, 0.8 等
```

### 動畫曲線
```dart
_animation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOut, // 改為其他曲線：bounceIn, elasticOut, etc.
);
```

## ✅ 完成檢查清單

- [x] 添加圖片資源到 pubspec.yaml
- [x] 創建動畫 Widget
- [x] 整合到語音控制服務
- [x] 更新語音提示
- [ ] 準備圖片資源（agent_on.png, agent_off.png）
- [ ] 測試動畫效果
- [ ] 優化圖片尺寸和性能
