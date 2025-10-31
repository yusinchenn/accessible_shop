/// 語音控制配置
class VoiceControlConfig {
  /// 單次監聽最長時間（分鐘）
  /// 設置較長時間以減少重啟頻率
  static const listenDuration = Duration(minutes: 10);

  /// 停頓多久後結束本次識別（秒）
  /// 設置較長時間，避免環境噪音導致頻繁結束識別
  static const pauseDuration = Duration(seconds: 10);

  /// 是否啟用部分結果（可以看到即時識別）
  static const enablePartialResults = true;

  /// 是否啟用音量監聽（用於調試）
  static const enableSoundLevelMonitoring = false;

  /// 錯誤後重試延遲（秒）
  static const errorRetryDelay = Duration(seconds: 1);

  /// 識別完成後重啟延遲（秒）
  /// 使用較長延遲，避免頻繁重啟
  static const restartDelay = Duration(seconds: 3);

  /// 最小音量閾值（0-100，用於判斷是否有聲音）
  /// 如果啟用，只有超過此閾值才會處理識別結果
  static const minSoundLevel = 0.0; // 0 表示不啟用閾值檢查

  /// TTS 結束後恢復 STT 的延遲時間（毫秒）
  static const ttsEndRecoveryDelay = Duration(milliseconds: 300);
}
