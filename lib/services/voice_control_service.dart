import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/tts_helper.dart';
import '../widgets/voice_assistant_animation.dart';
import 'stt_service.dart';
import 'voice_command_parser.dart';
import 'voice_control_config.dart';

/// 語音控制服務
/// 整合 TTS、STT 和命令解析，提供完整的語音控制功能
class VoiceControlService {
  static final VoiceControlService _instance = VoiceControlService._internal();
  factory VoiceControlService() => _instance;
  VoiceControlService._internal() {
    _init();
  }

  static const String _prefsKey = 'voice_control_enabled';

  bool _isEnabled = false;
  bool _isInitialized = false;
  BuildContext? _context;

  /// 語音控制是否已開啟
  bool get isEnabled => _isEnabled;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化服務
  Future<void> _init() async {
    try {
      // 載入持久化狀態
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefsKey) ?? false;

      // 設置 STT 回調
      sttService.onResult = _handleSttResult;
      sttService.onError = _handleSttError;

      // 設置 TTS 狀態監聽器
      ttsHelper.onSpeakingStart = _onTtsSpeakingStart;
      ttsHelper.onSpeakingEnd = _onTtsSpeakingEnd;

      _isInitialized = true;

      // 如果之前已開啟，則自動啟動
      if (_isEnabled) {
        await _startVoiceControl();
      }

      debugPrint('[VoiceControl] Service initialized, enabled: $_isEnabled');
    } catch (e) {
      debugPrint('[VoiceControl] Initialization error: $e');
    }
  }

  /// 設置當前 BuildContext（用於導航）
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 開啟/關閉語音控制
  Future<void> toggle() async {
    if (_isEnabled) {
      await disable();
    } else {
      await enable();
    }
  }

  /// 開啟語音控制
  Future<void> enable() async {
    if (_isEnabled) return;

    debugPrint('[VoiceControl] Enabling voice control');

    // 震動反饋
    HapticFeedback.mediumImpact();

    // 顯示開啟動畫（如果有 context）
    if (_context != null && _context!.mounted) {
      VoiceAssistantAnimationOverlay.show(
        _context!,
        type: VoiceAssistantAnimationType.enable,
      );
    }

    // 語音提示：「您的語音操作助手 小千 駕到」
    await ttsHelper.speak('您的語音操作助手 小千 駕到');

    _isEnabled = true;

    // 持久化狀態
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);

    // 等待語音播放完成後再啟動 STT
    await Future.delayed(const Duration(milliseconds: 1500));

    // 啟動語音控制
    await _startVoiceControl();
  }

  /// 關閉語音控制
  /// [silent] 為 true 時，不播放動畫和語音提示（用於切換到語音代理人）
  Future<void> disable({bool silent = false}) async {
    if (!_isEnabled) return;

    debugPrint('[VoiceControl] Disabling voice control (silent: $silent)');

    // 停止語音監聽
    await _stopVoiceControl();

    _isEnabled = false;

    // 持久化狀態
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);

    // 震動反饋
    HapticFeedback.mediumImpact();

    // 只有在非靜默模式下才播放動畫和語音
    if (!silent) {
      // 顯示關閉動畫（如果有 context）
      if (_context != null && _context!.mounted) {
        VoiceAssistantAnimationOverlay.show(
          _context!,
          type: VoiceAssistantAnimationType.disable,
        );
      }

      // 語音提示：「您的語音操作助手 小千 告退」
      await ttsHelper.speak('您的語音操作助手 小千 告退');
    }
  }

  /// 啟動語音控制
  Future<void> _startVoiceControl() async {
    if (!_isEnabled) return;

    // 初始化並啟動 STT
    final success = await sttService.startListening();
    if (success) {
      debugPrint('[VoiceControl] Voice control started');
    } else {
      debugPrint('[VoiceControl] Failed to start voice control');
      // 啟動失敗，關閉語音控制
      _isEnabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, false);
    }
  }

  /// 停止語音控制
  Future<void> _stopVoiceControl() async {
    await sttService.stopListening();
    debugPrint('[VoiceControl] Voice control stopped');
  }

  /// 處理 STT 識別結果
  void _handleSttResult(String text) {
    debugPrint('[VoiceControl] STT result: $text');

    if (!_isEnabled || _context == null || !_context!.mounted) {
      return;
    }

    // 解析並執行語音命令
    final success = voiceCommandParser.parseAndExecute(text, _context!);

    if (success) {
      debugPrint('[VoiceControl] Command executed: $text');
      // 震動反饋
      HapticFeedback.lightImpact();
    } else {
      debugPrint('[VoiceControl] Command not recognized: $text');
      // 無法識別，靜默忽略（根據需求）
    }

    // STT 現在使用更長的監聽時間（5分鐘），不需要頻繁重啟
    // 只在真正停止時才需要恢復
  }

  /// 處理 STT 錯誤
  void _handleSttError(String error) {
    debugPrint('[VoiceControl] STT error: $error');
    // 可以選擇性地通知用戶或記錄錯誤

    // 如果語音控制仍開啟，嘗試恢復監聽
    if (_isEnabled && !sttService.isListening && !ttsHelper.isSpeaking) {
      debugPrint('[VoiceControl] Attempting to recover STT after error');
      Future.delayed(VoiceControlConfig.errorRetryDelay, () {
        if (_isEnabled && !sttService.isListening) {
          sttService.startListening();
        }
      });
    }
  }

  /// TTS 開始播放時暫停 STT
  void _onTtsSpeakingStart() {
    if (_isEnabled && sttService.isListening) {
      debugPrint('[VoiceControl] TTS started, pausing STT');
      sttService.stopListening();
    }
  }

  /// TTS 結束播放時恢復 STT
  void _onTtsSpeakingEnd() {
    if (_isEnabled && !sttService.isListening) {
      debugPrint('[VoiceControl] TTS ended, resuming STT');
      // 延遲一小段時間再恢復監聽，避免捕捉到 TTS 的尾音
      Future.delayed(VoiceControlConfig.ttsEndRecoveryDelay, () {
        if (_isEnabled) {
          sttService.startListening();
        }
      });
    }
  }

  /// 釋放資源
  void dispose() {
    sttService.dispose();
    _context = null;
  }
}

/// 全域語音控制服務實例
final voiceControlService = VoiceControlService();
