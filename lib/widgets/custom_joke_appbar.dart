/// custom_joke_appbar.dart
/// 自定義 AppBar 元件，支援長按說笑話功能
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/tts_helper.dart';
import '../services/openai_client.dart';
import '../services/accessibility_service.dart';

/// 自定義 AppBar，支援長按至少 2 秒放開後說笑話
class CustomJokeAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// AppBar 標題文字
  final String title;

  /// 點擊時的回調（短按）
  final VoidCallback? onTap;

  /// 是否居中顯示標題
  final bool centerTitle;

  /// 是否自動顯示返回按鈕
  final bool automaticallyImplyLeading;

  const CustomJokeAppBar({
    super.key,
    required this.title,
    this.onTap,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
  });

  @override
  State<CustomJokeAppBar> createState() => _CustomJokeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomJokeAppBarState extends State<CustomJokeAppBar> {
  /// 長按開始時間
  DateTime? _longPressStartTime;

  /// 是否正在生成笑話
  bool _isGeneratingJoke = false;

  /// OpenAI 客戶端
  late final OpenAICompatibleClient _aiClient;

  @override
  void initState() {
    super.initState();
    _initializeAIClient();
  }

  /// 初始化 AI 客戶端
  void _initializeAIClient() {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';

    final config = ProviderConfig(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: apiKey,
      defaultModel: 'deepseek-chat',
    );

    _aiClient = OpenAICompatibleClient(config);
  }

  /// 處理長按開始
  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _longPressStartTime = DateTime.now();
    });
  }

  /// 處理長按放開
  Future<void> _onLongPressEnd(LongPressEndDetails details) async {
    if (_longPressStartTime == null) return;

    final pressDuration = DateTime.now().difference(_longPressStartTime!);

    // 檢查是否長按超過 2 秒
    if (pressDuration.inMilliseconds >= 1000) {
      await _tellJoke();
    }

    setState(() {
      _longPressStartTime = null;
    });
  }

  /// 生成並朗讀笑話
  Future<void> _tellJoke() async {
    // 防止重複呼叫
    if (_isGeneratingJoke) return;

    setState(() {
      _isGeneratingJoke = true;
    });

    try {
      // 呼叫 LLM 生成笑話
      final joke = await _generateJoke();

      // 使用 TTS 朗讀笑話
      if (accessibilityService.shouldUseCustomTTS) {
        await ttsHelper.speak(joke);
      }
    } catch (e) {
      debugPrint('❌ [CustomJokeAppBar] 生成笑話失敗: $e');

      // 播報錯誤訊息
      if (accessibilityService.shouldUseCustomTTS) {
        if (e.toString().contains('API key')) {
          await ttsHelper.speak('錯誤，API Key 未設置');
        } else if (e.toString().contains('HTTP')) {
          await ttsHelper.speak('錯誤，無法連接到服務');
        } else {
          await ttsHelper.speak('錯誤，笑話生成失敗');
        }
      }
    } finally {
      setState(() {
        _isGeneratingJoke = false;
      });
    }
  }

  /// 使用 LLM 生成笑話
  Future<String> _generateJoke() async {
    final systemPrompt = '''你是一個幽默風趣的笑話大師。
創作一個關於盲人的笑話，滿足以下要求：
1. 笑話要簡短（15~60字之間），適合語音朗讀
2. 不要直接提到"盲人"
3. 可以是網路上有說過的笑話
4. 直接輸出笑話內容，不要有任何前綴或解釋''';

    final userPrompt = '請給我一個笑話';

    final options = ChatCompletionOptions(
      messages: [
        ChatMessage(role: Role.system, content: systemPrompt),
        ChatMessage(role: Role.user, content: userPrompt),
      ],
      temperature: 0.9, // 提高創意度
      maxTokens: 200,
    );

    final result = await _aiClient.chatCompletion(options);

    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        // 短按：執行原有的點擊回調
        onTap: widget.onTap,
        // 長按開始：記錄開始時間
        onLongPressStart: _onLongPressStart,
        // 長按放開：檢查持續時間並執行笑話功能
        onLongPressEnd: _onLongPressEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title),
            // 顯示載入指示器
            if (_isGeneratingJoke) ...[
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
    );
  }
}
