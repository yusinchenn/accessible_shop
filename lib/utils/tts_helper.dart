import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  Future<void>? _initFuture;

  TtsHelper() {
    _initFuture = _init();
  }

  Future<void> _init() async {
    await _flutterTts.setLanguage("zh-TW");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    _initialized = true;
  }

  /// 播一句
  Future<void> speak(String text) async {
    if (!_initialized) await _initFuture;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// 模擬「逐句播報」
  Future<void> speakQueue(List<String> texts) async {
    if (!_initialized) await _initFuture;
    if (texts.isEmpty) return;

    // 先播第一句
    await speak(texts.first);

    // 之後用 delay 播下一句（避免 completion handler 不觸發）
    for (int i = 1; i < texts.length; i++) {
      await Future.delayed(const Duration(seconds: 1)); // 間隔時間可調
      await speak(texts[i]);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }
}
