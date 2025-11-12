/// voice_control_appbar.dart
/// 支援語音控制的自定義 AppBar 元件
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_control_service.dart';
import '../utils/tts_helper.dart';
import 'voice_assistant_animation.dart';

/// 語音功能狀態
enum VoiceFeatureState {
  /// 未啟用任何功能
  none,

  /// 語音切換頁面功能已啟用
  voiceControl,

  /// 語音代理人控制功能已啟用
  voiceAgent,
}

/// 自定義 AppBar，支援長按 1 秒開啟/關閉語音控制
class VoiceControlAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// AppBar 標題文字
  final String title;

  /// 點擊時的回調（短按）- 通常用於朗讀頁面說明
  final VoidCallback? onTap;

  /// 是否居中顯示標題
  final bool centerTitle;

  /// 是否自動顯示返回按鈕
  final bool automaticallyImplyLeading;

  /// 前導 Widget（左側）
  final Widget? leading;

  /// 動作按鈕列表（右側）
  final List<Widget>? actions;

  /// 背景顏色
  final Color? backgroundColor;

  /// 底部 Widget（通常用於 TabBar）
  final PreferredSizeWidget? bottom;

  /// 標題文字樣式
  final TextStyle? titleTextStyle;

  /// 初始語音功能狀態
  final VoiceFeatureState? initialState;

  const VoiceControlAppBar({
    super.key,
    required this.title,
    this.onTap,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.bottom,
    this.titleTextStyle,
    this.initialState,
  });

  @override
  State<VoiceControlAppBar> createState() => _VoiceControlAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

class _VoiceControlAppBarState extends State<VoiceControlAppBar> {
  /// 當前語音功能狀態
  late VoiceFeatureState _currentState;

  /// 長按持續時間（秒）
  int _longPressDuration = 0;

  /// 長按階段計時器
  Timer? _durationTimer;

  /// 是否正在處理狀態切換
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // 使用初始狀態，如果沒有提供則從服務狀態判斷
    if (widget.initialState != null) {
      _currentState = widget.initialState!;
    } else {
      // 同步語音控制服務的狀態
      _currentState = voiceControlService.isEnabled
          ? VoiceFeatureState.voiceControl
          : VoiceFeatureState.none;
    }

    // 設置當前 BuildContext 到語音控制服務
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        voiceControlService.setContext(context);
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  /// 處理長按開始
  void _onLongPressStart(LongPressStartDetails details) {
    // 如果正在處理中，忽略新的長按
    if (_isProcessing) return;

    // 取消之前的計時器（如果有）
    _durationTimer?.cancel();

    // 重置長按持續時間
    setState(() {
      _longPressDuration = 0;
    });

    // 記錄長按開始時的狀態
    final startState = _currentState;

    // 啟動持續時間計時器，每秒更新一次
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _longPressDuration += 1;
      });

      // 根據長按開始時的狀態處理長按
      if (startState == VoiceFeatureState.none) {
        // 從未啟用狀態開始長按
        if (_longPressDuration == 1) {
          // 長按1秒 -> 啟用語音控制
          _activateVoiceControl();
        } else if (_longPressDuration == 5) {
          // 繼續長按到5秒 -> 啟用語音代理人
          timer.cancel();
          _activateVoiceAgent();
        }
      } else {
        // 從已啟用狀態（語音控制/語音代理人）開始長按
        if (_longPressDuration == 1) {
          // 長按1秒 -> 關閉所有功能
          timer.cancel();
          _deactivateAll();
        }
      }
    });
  }

  /// 處理長按放開
  void _onLongPressEnd(LongPressEndDetails details) {
    // 取消計時器
    _durationTimer?.cancel();
    _durationTimer = null;

    // 重置持續時間
    if (mounted) {
      setState(() {
        _longPressDuration = 0;
      });
    }
  }

  /// 處理長按取消
  void _onLongPressCancel() {
    // 取消計時器
    _durationTimer?.cancel();
    _durationTimer = null;

    // 重置持續時間
    if (mounted) {
      setState(() {
        _longPressDuration = 0;
      });
    }
  }

  /// 啟用語音控制功能（播放 agent_on 動畫）
  void _activateVoiceControl() {
    if (_isProcessing) return;

    // 播放開啟動畫
    VoiceAssistantAnimationOverlay.show(
      context,
      type: VoiceAssistantAnimationType.enable,
      onComplete: () {
        debugPrint('✅ agent_on 動畫播放完成');
      },
    );

    // 更新 context
    voiceControlService.setContext(context);

    // 開啟語音控制（非同步執行，不阻塞）
    if (!voiceControlService.isEnabled) {
      voiceControlService.toggle().catchError((e) {
        debugPrint('❌ [VoiceControlAppBar] 啟用語音控制失敗: $e');
      });
    }

    // 更新狀態
    setState(() {
      _currentState = VoiceFeatureState.voiceControl;
    });

    debugPrint('✅ 語音控制功能已啟用');
  }

  /// 啟用語音代理人功能（播放 agent_pro 動畫）
  Future<void> _activateVoiceAgent() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 靜默關閉語音控制（不播放動畫，不語音提示）
      if (voiceControlService.isEnabled) {
        // 先停止當前的語音播放
        await ttsHelper.stop();
        // 靜默關閉語音控制服務（不觸發動畫和語音提示）
        await voiceControlService.disable(silent: true);
      }

      // 檢查 mounted 後再使用 context
      if (!mounted) return;

      // 播放語音提示："大千世界，開！"
      ttsHelper.speak('大千世界，開啟！');

      // 播放代理人動畫
      VoiceAssistantAnimationOverlay.show(
        context,
        type: VoiceAssistantAnimationType.enableAgent,
        onComplete: () {
          debugPrint('✅ agent_pro 動畫播放完成');
        },
      );

      // 導航到 AI 代理頁面
      if (mounted) {
        Navigator.of(context).pushNamed('/ai-agent');
      }

      // 更新狀態
      if (mounted) {
        setState(() {
          _currentState = VoiceFeatureState.voiceAgent;
        });
      }

      debugPrint('✅ 語音代理人功能已啟用（已靜默關閉語音控制）');
    } catch (e) {
      debugPrint('❌ [VoiceControlAppBar] 啟用語音代理人失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 停用所有語音功能
  Future<void> _deactivateAll() async {
    if (_isProcessing) return;

    final previousState = _currentState;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 如果是從語音控制關閉，播放 agent_off 動畫
      if (previousState == VoiceFeatureState.voiceControl) {
        VoiceAssistantAnimationOverlay.show(
          context,
          type: VoiceAssistantAnimationType.disable,
          onComplete: () {
            debugPrint('✅ agent_off 動畫播放完成');
          },
        );
      }

      // 關閉語音控制
      if (voiceControlService.isEnabled) {
        await voiceControlService.toggle();
      }

      // 如果是從語音代理人狀態關閉，導航回首頁
      if (previousState == VoiceFeatureState.voiceAgent) {
        if (mounted) {
          // 使用 Navigator 導航回首頁，清除所有路由堆疊
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }

      // 更新狀態
      if (mounted) {
        setState(() {
          _currentState = VoiceFeatureState.none;
        });
      }

      debugPrint('✅ 所有語音功能已關閉');
    } catch (e) {
      debugPrint('❌ [VoiceControlAppBar] 關閉語音功能失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        // 短按：執行原有的點擊回調（朗讀頁面說明）
        onTap: widget.onTap,
        // 長按開始：記錄開始時間
        onLongPressStart: _onLongPressStart,
        // 長按放開：檢查持續時間並切換語音控制
        onLongPressEnd: _onLongPressEnd,
        // 長按取消：重置狀態
        onLongPressCancel: _onLongPressCancel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: widget.titleTextStyle),
            // 顯示小千助理開啟狀態圖示
            if (_currentState == VoiceFeatureState.voiceControl) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: kToolbarHeight, // 圖片高度與 AppBar 同高
                child: Image.asset(
                  'assets/images/agent_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
            // 顯示長按進度指示器
            if (_longPressDuration > 0) ...[
              const SizedBox(width: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      value: _currentState == VoiceFeatureState.none
                          ? _longPressDuration /
                                5 // 無狀態：5秒完成（1秒語音控制，5秒代理人）
                          : _longPressDuration / 1, // 有狀態：1秒關閉
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _currentState == VoiceFeatureState.none
                            ? Colors
                                  .amber // 啟用時為琥珀色
                            : Colors.red, // 關閉時為紅色
                      ),
                      backgroundColor: Colors.white38,
                    ),
                  ),
                  Text(
                    '$_longPressDuration',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ]
            // 顯示處理指示器
            else if (_isProcessing) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
      centerTitle: widget.centerTitle,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      leading: widget.leading,
      actions: widget.actions,
      backgroundColor: widget.backgroundColor,
      bottom: widget.bottom,
    );
  }
}
