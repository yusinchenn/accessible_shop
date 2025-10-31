import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'voice_control_config.dart';

/// 語音轉文字服務
/// 負責處理語音識別、麥克風權限管理
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _shouldContinueListening = false; // 是否應該持續監聽

  /// 語音識別結果回調
  Function(String)? onResult;

  /// 語音識別錯誤回調
  Function(String)? onError;

  /// 是否正在監聽
  bool get isListening => _isListening;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化語音識別服務
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 檢查並請求麥克風權限
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        onError?.call('麥克風權限未授予');
        return false;
      }

      // 初始化語音識別
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('[STT] Error: ${error.errorMsg}');
          _isListening = false;
          onError?.call('語音識別錯誤: ${error.errorMsg}');
          // 如果是持續監聽模式，嘗試重啟
          if (_shouldContinueListening) {
            debugPrint('[STT] Attempting to restart after error in ${VoiceControlConfig.errorRetryDelay.inSeconds}s');
            Future.delayed(VoiceControlConfig.errorRetryDelay, () {
              if (_shouldContinueListening && !_isListening) {
                startListening();
              }
            });
          }
        },
        onStatus: (status) {
          debugPrint('[STT] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            // 延遲檢查是否需要重啟
            // 如果是因為短暫停頓（pauseFor）導致的 done，不需要重啟
            // 如果是因為超時（listenFor）導致的 done，才需要重啟
            Future.delayed(const Duration(seconds: 1), () {
              // 只在仍然需要持續監聽且確實沒在監聽時才重啟
              if (_shouldContinueListening && !_isListening && _isInitialized) {
                debugPrint('[STT] Session ended, restarting listening...');
                _restartListening();
              }
            });
          }
        },
      );

      return _isInitialized;
    } catch (e) {
      onError?.call('初始化失敗: $e');
      return false;
    }
  }

  /// 檢查並請求麥克風權限
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isRestricted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // 權限被永久拒絕，需要引導用戶到設定頁面
      onError?.call('麥克風權限已被永久拒絕，請到設定中手動開啟');
      return false;
    }

    return false;
  }

  /// 開始持續監聽
  Future<bool> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      return true;
    }

    try {
      final available = await _speech.hasPermission;
      if (!available) {
        onError?.call('沒有麥克風權限');
        return false;
      }

      await _speech.listen(
        onResult: (result) {
          // 處理部分結果和最終結果
          if (result.recognizedWords.isNotEmpty) {
            debugPrint('[STT] Recognized (final: ${result.finalResult}): ${result.recognizedWords}');

            // 只在最終結果時才觸發回調
            if (result.finalResult) {
              onResult?.call(result.recognizedWords);
            }
          }
        },
        listenFor: VoiceControlConfig.listenDuration, // 每次監聽最長時間
        pauseFor: VoiceControlConfig.pauseDuration, // 停頓多久後結束本次識別
        onSoundLevelChange: VoiceControlConfig.enableSoundLevelMonitoring
            ? (level) {
                debugPrint('[STT] Sound level: $level dB');
              }
            : null,
        localeId: 'zh_TW', // 繁體中文
        listenOptions: stt.SpeechListenOptions(
          partialResults: VoiceControlConfig.enablePartialResults, // 是否啟用部分結果
          cancelOnError: false,
        ),
      );

      _isListening = true;
      _shouldContinueListening = true; // 啟用持續監聽模式
      return true;
    } catch (e) {
      onError?.call('開始監聽失敗: $e');
      return false;
    }
  }

  /// 重新開始監聽（用於持續監聽模式）
  Future<void> _restartListening() async {
    // 檢查是否應該繼續監聽
    if (!_shouldContinueListening || !_isInitialized) return;

    // 等待一段時間後重新開始監聽
    debugPrint('[STT] Preparing to restart listening in ${VoiceControlConfig.restartDelay.inSeconds} seconds...');
    await Future.delayed(VoiceControlConfig.restartDelay);

    // 再次檢查狀態（可能在延遲期間被停止）
    if (!_shouldContinueListening || !_isInitialized) return;

    try {
      await _speech.listen(
        onResult: (result) {
          // 處理部分結果和最終結果
          if (result.recognizedWords.isNotEmpty) {
            debugPrint('[STT] Recognized (final: ${result.finalResult}): ${result.recognizedWords}');

            // 只在最終結果時才觸發回調
            if (result.finalResult) {
              onResult?.call(result.recognizedWords);
            }
          }
        },
        listenFor: VoiceControlConfig.listenDuration,
        pauseFor: VoiceControlConfig.pauseDuration,
        onSoundLevelChange: VoiceControlConfig.enableSoundLevelMonitoring
            ? (level) {
                debugPrint('[STT] Sound level: $level dB');
              }
            : null,
        localeId: 'zh_TW',
        listenOptions: stt.SpeechListenOptions(
          partialResults: VoiceControlConfig.enablePartialResults,
          cancelOnError: false,
        ),
      );
      _isListening = true;
      debugPrint('[STT] Listening restarted successfully');
    } catch (e) {
      debugPrint('[STT] Failed to restart listening: $e');
      _isListening = false;
    }
  }

  /// 停止監聽
  Future<void> stopListening() async {
    _shouldContinueListening = false; // 停止持續監聽模式

    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      onError?.call('停止監聽失敗: $e');
    }
  }

  /// 取消監聽
  Future<void> cancel() async {
    _shouldContinueListening = false; // 停止持續監聽模式

    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
    } catch (e) {
      onError?.call('取消監聽失敗: $e');
    }
  }

  /// 釋放資源
  void dispose() {
    _shouldContinueListening = false; // 停止持續監聽模式
    _speech.stop();
    _isListening = false;
  }
}

/// 全域 STT 服務實例
final sttService = SttService();
