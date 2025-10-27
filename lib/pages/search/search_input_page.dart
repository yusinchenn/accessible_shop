// lib/pages/search/search_input_page.dart
//
// 搜尋輸入頁面 - 提供搜尋輸入介面

import 'package:flutter/material.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../services/accessibility_service.dart';

/// 搜尋輸入頁面
class SearchInputPage extends StatefulWidget {
  const SearchInputPage({super.key});

  @override
  State<SearchInputPage> createState() => _SearchInputPageState();
}

class _SearchInputPageState extends State<SearchInputPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _announceScheduled = false;

  @override
  void initState() {
    super.initState();
    // 頁面載入後自動獲取焦點
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化無障礙服務
    accessibilityService.initialize(context);

    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (routeIsCurrent && !_announceScheduled) {
      _announceScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceScheduled = false;
        _announceEnter();
      });
    }
  }

  /// 進入頁面時的語音播報
  Future<void> _announceEnter() async {
    // 只在自訂模式播放語音
    if (!accessibilityService.shouldUseCustomTTS) return;

    await ttsHelper.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    await ttsHelper.speak('開啟搜尋，請輸入文字');
  }

  /// 處理搜尋提交
  void _onSearchSubmit(String keyword) {
    if (keyword.trim().isEmpty) {
      // 如果輸入為空，提示用戶
      if (accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak('請輸入搜尋關鍵字');
      }
      return;
    }

    _searchFocusNode.unfocus(); // 關閉鍵盤
    Navigator.pushReplacementNamed(
      context,
      '/search',
      arguments: keyword.trim(),
    );
  }

  /// 處理推薦商品按鈕點擊
  void _onRecommendedProducts() {
    _searchFocusNode.unfocus(); // 關閉鍵盤
    Navigator.pushReplacementNamed(
      context,
      '/search',
      arguments: '__recommended__', // 使用特殊標記來識別推薦商品模式
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      appBar: AppBar(
        title: const Text('搜尋'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background_2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              const Icon(Icons.search, size: 80, color: AppColors.primary_2),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: () {
                  // 單擊朗讀
                  if (accessibilityService.shouldUseCustomTTS) {
                    ttsHelper.speak('推薦商品按鈕');
                  }
                },
                onDoubleTap: _onRecommendedProducts,
                child: OutlinedButton(
                  onPressed: () {}, // 禁用預設行為，使用 GestureDetector 處理
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('推薦商品', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(fontSize: 28),
                decoration: const InputDecoration(
                  hintText: '輸入商品名稱...',
                  hintStyle: TextStyle(fontSize: 28),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onSubmitted: _onSearchSubmit,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => _onSearchSubmit(_searchController.text),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: const Text('搜尋', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
