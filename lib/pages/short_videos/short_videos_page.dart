// lib/pages/short_videos/short_videos_page.dart
//
// 短影音頁面 - 提供短影音瀏覽功能

import 'package:flutter/material.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../services/accessibility_service.dart';

/// 短影音項目資料結構
class ShortVideo {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final int likes;
  final int views;

  const ShortVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.likes,
    required this.views,
  });
}

/// 短影音頁面
class ShortVideosPage extends StatefulWidget {
  const ShortVideosPage({super.key});

  @override
  State<ShortVideosPage> createState() => _ShortVideosPageState();
}

class _ShortVideosPageState extends State<ShortVideosPage> {
  bool _isAnnouncingEnter = false;
  bool _announceScheduled = false;
  int _selectedIndex = 0;

  // 測試用的短影音資料
  final List<ShortVideo> _videos = const [
    ShortVideo(
      id: '1',
      title: '春季新品上市',
      author: '購物達人小明',
      thumbnailUrl: '',
      likes: 1234,
      views: 5678,
    ),
    ShortVideo(
      id: '2',
      title: '美妝教學',
      author: '美妝博主小美',
      thumbnailUrl: '',
      likes: 2345,
      views: 8901,
    ),
    ShortVideo(
      id: '3',
      title: '廚房好物推薦',
      author: '料理達人阿華',
      thumbnailUrl: '',
      likes: 3456,
      views: 12345,
    ),
  ];

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

  /// 執行進入頁面的語音播報
  Future<void> _announceEnter() async {
    if (_isAnnouncingEnter) return;

    // 只在自訂模式播放語音
    if (!accessibilityService.shouldUseCustomTTS) return;

    await ttsHelper.stop();

    _isAnnouncingEnter = true;
    try {
      await ttsHelper.speak('進入短影音頁面');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_videos.isNotEmpty) {
        await ttsHelper.speak('當前有 ${_videos.length} 個影片');
      }
    } finally {
      _isAnnouncingEnter = false;
    }
  }

  /// 處理單擊事件 - 播報影片資訊
  void _onVideoTap(ShortVideo video, int index) {
    if (_isAnnouncingEnter) return;

    setState(() {
      _selectedIndex = index;
    });

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(
        '${video.title}，作者：${video.author}，按讚數：${video.likes}，觀看數：${video.views}',
      );
    }
  }

  /// 處理雙擊事件 - 播放影片
  void _onVideoDoubleTap(ShortVideo video) {
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak('播放影片：${video.title}');
    }

    // 這裡可以加入實際的影片播放邏輯
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('播放影片：${video.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('短影音'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _videos.isEmpty
          ? const Center(
              child: Text(
                '暫無影片',
                style: AppTextStyles.body,
              ),
            )
          : ListView.builder(
              itemCount: _videos.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (context, index) {
                final video = _videos[index];
                final isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () => _onVideoTap(video, index),
                  onDoubleTap: () => _onVideoDoubleTap(video),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          // 影片縮圖佔位符
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.play_circle_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // 影片資訊
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  style: AppTextStyles.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  video.author,
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.thumb_up_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${video.likes}',
                                      style: AppTextStyles.small,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    const Icon(
                                      Icons.visibility_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${video.views}',
                                      style: AppTextStyles.small,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}