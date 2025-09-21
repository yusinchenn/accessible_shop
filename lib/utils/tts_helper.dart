// lib/utils/tts_helper.dart
//
// 提供 TTS 功能的輔助類別 (全域可用)
// 使用方式：在任何地方 import '../../utils/tts_helper.dart' (或 package: 路徑)
// 然後呼叫 `ttsHelper.speak("文字")` 或 `ttsHelper.speakQueue([...])`
//
// 注意：此檔案建立一個單一全域實例 `ttsHelper`，整個 App 請共用此實例，
// 切勿在 page 的 dispose() 中呼叫 ttsHelper.dispose() — 那會關閉全域 TTS。

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  int _speakSession = 0; // 用於中斷舊的 speakQueue
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  Future<void>? _initFuture;

  TtsHelper() {
    _initFuture = _init();
  }

  Future<void> _init() async {
    try {
      await _flutterTts.setLanguage("zh-TW");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      _initialized = true;
      // 開啟 debug print 可協助追蹤
      print('[TTS] initialized');
    } catch (e) {
      print('[TTS] init error: $e');
    }
  }

  /// 單句播放（會先 stop 以避免與前一次重疊）
  Future<void> speak(String text) async {
    if (!_initialized) await _initFuture;
    print('[TTS] speak: $text');
    try {
      _speakSession++; // 每次 speak 都中斷舊的 queue
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print('[TTS] speak error: $e');
    }
  }

  /// 逐句播放（確保每句播完才播下一句）
  /// 這裡使用 completion handler + timeout 作雙重保險。
  Future<void> speakQueue(List<String> texts) async {
    if (!_initialized) await _initFuture;
    if (texts.isEmpty) return;

    _speakSession++;
    final int session = _speakSession;

    for (final text in texts) {
      if (session != _speakSession) break; // 若有新語音要求則中斷
      print('[TTS] speakQueue start: $text');
      final completer = Completer<void>();

      _flutterTts.setCompletionHandler(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      try {
        await _flutterTts.stop();
        await _flutterTts.speak(text);

        await completer.future.timeout(
          const Duration(seconds: 6),
          onTimeout: () {
            if (!completer.isCompleted) completer.complete();
            print('[TTS] speakQueue timeout for: $text');
          },
        );
      } catch (e) {
        print('[TTS] speakQueue error for "$text": $e');
        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('[TTS] speakQueue end: $text');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('[TTS] stop error: $e');
    }
  }

  /// 不要在 page.dispose() 裡呼叫這個（除非你確定要完全關閉整個 app 的 TTS）
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (e) {
      print('[TTS] dispose error: $e');
    }
  }
}

/// 全域單例（請於整個 app 共用）
final TtsHelper ttsHelper = TtsHelper();
