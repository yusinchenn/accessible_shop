/// voice_control_appbar.dart
/// 支援語音控制的自定義 AppBar 元件
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_control_service.dart';

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
  });

  @override
  State<VoiceControlAppBar> createState() => _VoiceControlAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

class _VoiceControlAppBarState extends State<VoiceControlAppBar> {
  /// 長按計時器
  Timer? _longPressTimer;

  /// 是否正在處理語音控制切換
  bool _isTogglingVoiceControl = false;

  /// 長按持續時間（秒）
  int _longPressDuration = 0;

  /// 長按階段計時器
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    // 設置當前 BuildContext 到語音控制服務
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        voiceControlService.setContext(context);
      }
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  /// 處理長按開始
  void _onLongPressStart(LongPressStartDetails details) {
    // 取消之前的計時器（如果有）
    _longPressTimer?.cancel();
    _durationTimer?.cancel();

    // 重置長按持續時間
    setState(() {
      _longPressDuration = 0;
    });

    // 啟動持續時間計時器，每秒更新一次
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _longPressDuration += 1;
      });

      // 第1秒：開啟"小千助理"（語音控制）
      if (_longPressDuration == 1) {
        if (!voiceControlService.isEnabled) {
          _toggleVoiceControl();
        }
      }
      // 第2秒：開啟"大千世界"
      else if (_longPressDuration == 2) {
        _openAIAgent();
        timer.cancel();
      }
    });
  }

  /// 處理長按放開
  void _onLongPressEnd(LongPressEndDetails details) {
    // 取消計時器（如果還沒觸發）
    _longPressTimer?.cancel();
    _longPressTimer = null;
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
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;

    // 重置持續時間
    if (mounted) {
      setState(() {
        _longPressDuration = 0;
      });
    }
  }

  /// 切換語音控制
  Future<void> _toggleVoiceControl() async {
    // 防止重複呼叫
    if (_isTogglingVoiceControl) return;

    // 取消計時器
    _longPressTimer?.cancel();
    _longPressTimer = null;

    setState(() {
      _isTogglingVoiceControl = true;
    });

    try {
      // 更新 context
      voiceControlService.setContext(context);

      // 切換語音控制
      await voiceControlService.toggle();
    } catch (e) {
      debugPrint('❌ [VoiceControlAppBar] 切換語音控制失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingVoiceControl = false;
        });
      }
    }
  }

  /// 開啟"大千世界" AI 智能代理
  void _openAIAgent() {
    // 取消所有計時器
    _longPressTimer?.cancel();
    _durationTimer?.cancel();

    // 導航到 AI 代理頁面
    Navigator.of(context).pushNamed('/ai-agent');
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
                      value: _longPressDuration / 2, // 2秒完成
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.amber),
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
            else if (_isTogglingVoiceControl) ...[
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
