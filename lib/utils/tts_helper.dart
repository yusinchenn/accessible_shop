// lib/utils/tts_helper.dart
//
// 提供 TTS 功能的輔助類別 (全域可用)
// 使用方式：在任何地方 import '../../utils/tts_helper.dart' (或 package: 路徑)
// 然後呼叫 `ttsHelper.speak("文字")` 或 `ttsHelper.speakQueue([...])`
//
// 注意：此檔案建立一個單一全域實例 `ttsHelper`，整個 App 請共用此實例，
// 切勿在 page 的 dispose() 中呼叫 ttsHelper.dispose() — 那會關閉全域 TTS。

import 'dart:async';
import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';

/// 語音任務類型
enum _SpeechType {
  manual,    // 手動操作，可以打斷
  automatic, // 自動朗讀，需要排隊
}

/// 語音任務
class _SpeechTask {
  final List<String> texts;
  final _SpeechType type;
  final Completer<void> completer;

  _SpeechTask({
    required this.texts,
    required this.type,
    required this.completer,
  });
}

class TtsHelper {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  Future<void>? _initFuture;

  // 語音佇列相關
  final Queue<_SpeechTask> _queue = Queue<_SpeechTask>();
  bool _isProcessing = false;
  Completer<void>? _currentSpeechCompleter;
  _SpeechTask? _currentTask;

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

  /// 單句播放（手動操作，可立即打斷所有語音）
  Future<void> speak(String text) async {
    if (!_initialized) await _initFuture;
    print('[TTS] speak (manual): $text');

    final task = _SpeechTask(
      texts: [text],
      type: _SpeechType.manual,
      completer: Completer<void>(),
    );

    // 手動操作：清空佇列並立即執行
    _clearQueue();
    await _executeTask(task);
  }

  /// 逐句播放（自動朗讀，加入佇列等待執行）
  /// 自動朗讀不會被後續的自動朗讀打斷，只會被手動操作打斷
  Future<void> speakQueue(List<String> texts) async {
    if (!_initialized) await _initFuture;
    if (texts.isEmpty) return;

    print('[TTS] speakQueue (automatic): adding ${texts.length} texts to queue');

    final task = _SpeechTask(
      texts: texts,
      type: _SpeechType.automatic,
      completer: Completer<void>(),
    );

    // 自動朗讀：加入佇列
    _queue.add(task);
    _processQueue();

    // 等待任務完成
    return task.completer.future;
  }

  /// 處理佇列
  void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _processNextTask();
  }

  /// 處理下一個任務
  Future<void> _processNextTask() async {
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      _currentTask = task;

      try {
        await _executeTask(task);
        if (!task.completer.isCompleted) {
          task.completer.complete();
        }
      } catch (e) {
        print('[TTS] Task execution error: $e');
        if (!task.completer.isCompleted) {
          task.completer.completeError(e);
        }
      }

      _currentTask = null;
    }

    _isProcessing = false;
  }

  /// 執行單個任務（播放所有文字）
  Future<void> _executeTask(_SpeechTask task) async {
    for (final text in task.texts) {
      // 只有自動播放才檢查任務是否被中斷，手動操作直接執行
      if (task.type == _SpeechType.automatic) {
        if (!_isProcessing || _currentTask != task) {
          print('[TTS] Task interrupted, stopping execution');
          break;
        }
      }

      print('[TTS] executing: $text (${task.type})');

      final completer = Completer<void>();
      _currentSpeechCompleter = completer;

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
            if (!completer.isCompleted) {
              completer.complete();
              print('[TTS] timeout for: $text');
            }
          },
        );
      } catch (e) {
        print('[TTS] execution error for "$text": $e');
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _currentSpeechCompleter = null;
      print('[TTS] completed: $text');
    }
  }

  /// 清空佇列並停止當前播放（用於手動操作）
  void _clearQueue() {
    // 清空所有等待中的任務
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (!task.completer.isCompleted) {
        task.completer.completeError(Exception('Interrupted by manual operation'));
      }
    }

    // 停止當前播放
    _flutterTts.stop();

    if (_currentSpeechCompleter != null && !_currentSpeechCompleter!.isCompleted) {
      _currentSpeechCompleter!.complete();
    }

    _isProcessing = false;
    _currentTask = null;

    print('[TTS] Queue cleared');
  }

  /// 停止語音並清空佇列（手動操作）
  Future<void> stop() async {
    print('[TTS] Manual stop requested');
    _clearQueue();
  }

  /// 不要在 page.dispose() 裡呼叫這個（除非你確定要完全關閉整個 app 的 TTS）
  void dispose() {
    try {
      _clearQueue();
      _flutterTts.stop();
    } catch (e) {
      print('[TTS] dispose error: $e');
    }
  }
}

/// 全域單例（請於整個 app 共用）
final TtsHelper ttsHelper = TtsHelper();
