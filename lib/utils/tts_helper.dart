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
import 'package:flutter/foundation.dart';
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
  _SpeechTask? _currentTask;

  // 語音播放狀態追蹤
  Completer<void>? _speechStartCompleter;
  Completer<void>? _speechCompleteCompleter;

  TtsHelper() {
    _initFuture = _init();
  }

  Future<void> _init() async {
    try {
      await _flutterTts.setLanguage("zh-TW");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);

      // 設置語音開始的回調
      _flutterTts.setStartHandler(() {
        debugPrint('[TTS] 🚀 Start handler triggered');
        if (_speechStartCompleter != null && !_speechStartCompleter!.isCompleted) {
          _speechStartCompleter!.complete();
          debugPrint('[TTS] ▶️ Speech started - completer resolved');
        } else {
          debugPrint('[TTS] ⚠️ Start handler called but completer is null or already completed');
        }
      });

      // 設置語音完成的回調
      _flutterTts.setCompletionHandler(() {
        debugPrint('[TTS] 🎉 Completion handler triggered');
        if (_speechCompleteCompleter != null && !_speechCompleteCompleter!.isCompleted) {
          _speechCompleteCompleter!.complete();
          debugPrint('[TTS] ✅ Speech completed - completer resolved');
        } else {
          debugPrint('[TTS] ⚠️ Completion handler called but completer is null or already completed');
        }
      });

      _initialized = true;
      debugPrint('[TTS] initialized');
    } catch (e) {
      debugPrint('[TTS] init error: $e');
    }
  }

  /// 單句播放（手動操作，可立即打斷所有語音）
  Future<void> speak(String text) async {
    if (!_initialized) await _initFuture;
    debugPrint('[TTS] speak (manual): $text');

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

    debugPrint('[TTS] speakQueue (automatic): adding ${texts.length} texts to queue');

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
        debugPrint('[TTS] Task execution error: $e');
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
    for (int i = 0; i < task.texts.length; i++) {
      final text = task.texts[i];

      // 只有自動播放才檢查任務是否被中斷，手動操作直接執行
      if (task.type == _SpeechType.automatic) {
        if (!_isProcessing || _currentTask != task) {
          debugPrint('[TTS] Task interrupted, stopping execution');
          break;
        }
      }

      debugPrint('[TTS] 🎯 executing: $text (${task.type})');

      try {
        // 只在手動任務時調用 stop，自動任務不調用 stop 避免打斷前一個任務
        if (task.type == _SpeechType.manual) {
          await _flutterTts.stop();
          // 手動任務 stop 後等待一下，確保停止完成
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // 創建新的 completer 用於追蹤這次語音播放
        _speechStartCompleter = Completer<void>();
        _speechCompleteCompleter = Completer<void>();

        // 開始播放語音
        await _flutterTts.speak(text);

        // 等待語音開始播放（最多等待 1 秒）
        await _speechStartCompleter!.future.timeout(
          const Duration(milliseconds: 1000),
          onTimeout: () {
            debugPrint('[TTS] ⚠️ Start timeout for: $text');
          },
        );

        debugPrint('[TTS] 🔊 Speech playing: $text');

        // 等待語音播放完成（主要依賴 completion handler，timeout 只是最後的保險）
        // 設置一個很長的 timeout（60秒），正常情況下 completion handler 會先觸發
        await _speechCompleteCompleter!.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('[TTS] ⏱️ Complete timeout (60s) - completion handler 可能失效');
          },
        );

        debugPrint('[TTS] ✅ Task completed: $text');

        // 清理 completer
        _speechStartCompleter = null;
        _speechCompleteCompleter = null;

        // 在自動朗讀的文字之間增加短暫間隔
        if (task.type == _SpeechType.automatic && i < task.texts.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint('[TTS] ❌ execution error for "$text": $e');
        _speechStartCompleter = null;
        _speechCompleteCompleter = null;
        await Future.delayed(const Duration(milliseconds: 200));
      }
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

    // 如果當前任務存在，將其標記為中斷
    if (_currentTask != null && !_currentTask!.completer.isCompleted) {
      _currentTask!.completer.completeError(Exception('Interrupted by manual operation'));
    }

    // 清理語音播放狀態追蹤
    if (_speechStartCompleter != null && !_speechStartCompleter!.isCompleted) {
      _speechStartCompleter!.complete();
    }
    if (_speechCompleteCompleter != null && !_speechCompleteCompleter!.isCompleted) {
      _speechCompleteCompleter!.complete();
    }
    _speechStartCompleter = null;
    _speechCompleteCompleter = null;

    _isProcessing = false;
    _currentTask = null;

    debugPrint('[TTS] Queue cleared');
  }

  /// 停止語音並清空佇列（手動操作）
  Future<void> stop() async {
    debugPrint('[TTS] Manual stop requested');
    _clearQueue();
  }

  /// 不要在 page.dispose() 裡呼叫這個（除非你確定要完全關閉整個 app 的 TTS）
  void dispose() {
    try {
      _clearQueue();
      _flutterTts.stop();
    } catch (e) {
      debugPrint('[TTS] dispose error: $e');
    }
  }
}

/// 全域單例（請於整個 app 共用）
final TtsHelper ttsHelper = TtsHelper();
