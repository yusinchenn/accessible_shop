// lib/pages/settings/settings_page.dart
//
// 帳號設定頁面，使用卡片滑動設計

import 'package:flutter/material.dart';
import '../../utils/tts_helper.dart';
import '../../utils/app_constants.dart';
import '../../services/accessibility_service.dart';
import '../../widgets/global_gesture_wrapper.dart';
import '../../widgets/voice_control_appbar.dart';
import 'account_info_page.dart';
import 'app_settings_page.dart';
import 'help_support_page.dart';

/// 定義設定入口卡片的資料結構
class SettingEntryItem {
  final String title; // 卡片顯示的標題文字
  final IconData icon; // 卡片顯示的圖示
  final Widget? targetPage; // 導航目標頁面（可選）
  final String? route; // 導航路由（可選）

  const SettingEntryItem({
    required this.title,
    required this.icon,
    this.targetPage,
    this.route,
  });
}

/// 帳號設定主頁面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// 帳號設定頁面的狀態類
class _SettingsPageState extends State<SettingsPage> {
  late final PageController _pageController; // 控制 PageView 的滾動控制器
  int _currentPageIndex = 0; // 當前顯示的卡片索引
  bool _isAnnouncingEnter = false; // 標記是否正在進行進入頁面的語音播報
  bool _speaking = false; // 標記是否正在進行語音播報
  bool _announceScheduled = false; // 標記是否已排程進入頁面的播報

  /// 取得設定頁面的卡片清單
  List<SettingEntryItem> get _entryItems => <SettingEntryItem>[
    SettingEntryItem(
      title: '帳號資訊',
      icon: Icons.person_outline,
      targetPage: const AccountInfoPage(),
    ),
    SettingEntryItem(
      title: 'App 設定',
      icon: Icons.settings,
      targetPage: const AppSettingsPage(),
    ),
    SettingEntryItem(
      title: '幫助與客服',
      icon: Icons.help_outline,
      targetPage: const HelpSupportPage(),
    ),
    SettingEntryItem(
      title: '開發工具',
      icon: Icons.developer_mode,
      route: '/dev-tools',
    ),
  ];

  /// 初始化狀態，設置 PageView 控制器並監聽頁面變化
  @override
  void initState() {
    super.initState();
    final int initialPageOffset =
        _entryItems.length * 1000; // 設置初始頁面偏移，實現無限滾動效果
    _pageController = PageController(
      viewportFraction: 0.85, // 每個卡片佔據視窗寬度的 85%
      initialPage: initialPageOffset,
    );
    _currentPageIndex = initialPageOffset % _entryItems.length;
    _pageController.addListener(_onPageChanged); // 監聽頁面變化事件
  }

  /// 當依賴項變更時，檢查是否需要播報進入頁面語音
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
    _speaking = true;
    try {
      await ttsHelper.speak('進入帳號頁面');
      await Future.delayed(const Duration(seconds: 1));
      await ttsHelper.speak(_entryItems[_currentPageIndex].title);
    } finally {
      _isAnnouncingEnter = false;
      _speaking = false;
    }
  }

  /// 監聽 PageView 頁面變化，當卡片切換時更新索引並播報新卡片標題
  void _onPageChanged() {
    final int? page = _pageController.page?.round();
    if (page == null) return;
    final int actual = page % _entryItems.length;
    if (actual == _currentPageIndex) return;

    setState(() {
      _currentPageIndex = actual;
    });

    // 如果正在進行播報，則不進行新播報
    if (_isAnnouncingEnter || _speaking) return;

    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(_entryItems[_currentPageIndex].title);
    }
  }

  /// 清理資源
  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// 處理單次點擊事件，播報當前卡片的標題
  void _onSingleTap(int index) {
    if (_isAnnouncingEnter || _speaking) return;
    // 只在自訂模式播放語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(_entryItems[index].title);
    }
  }

  /// 處理雙擊事件，導航到指定頁面或路由
  void _onDoubleTap(int actualIndex) async {
    final item = _entryItems[actualIndex];

    await ttsHelper.stop();

    if (!mounted) return; // 檢查 Widget 是否還存在

    if (item.targetPage != null) {
      // 導航到頁面
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.targetPage!),
      );
    } else if (item.route != null) {
      // 導航到路由
      await Navigator.pushNamed(context, item.route!);
    }
    // 回到本頁面時，didChangeDependencies 會觸發 _announceEnter
  }

  /// 構建頁面 UI
  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_1,
      appBar: VoiceControlAppBar(
        title: '帳號',
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75, // 卡片區域高度為螢幕高度的 75%
          child: PageView.builder(
            controller: _pageController,
            itemCount: 999999, // 設置大量項目數以實現無限滾動
            itemBuilder: (context, index) {
              final actualIndex = index % _entryItems.length;
              final item = _entryItems[actualIndex];

              // 計算卡片的透明度，營造淡出淡入效果
              double opacity = 1.0;
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                final double value =
                    (index.toDouble() - (_pageController.page ?? 0))
                        .abs(); // 計算與當前頁面的距離
                // 當前卡片 (value < 0.5) 完全不透明(1.0)，旁邊的卡片半透明(0.3)
                opacity = value < 0.5 ? 1.0 : 0.3;
              }

              return Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: opacity, // 應用淡出淡入效果
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ), // 增加卡片間距
                    child: SizedBox(
                      width:
                          MediaQuery.of(context).size.width *
                          0.85, // 設定卡片寬度為螢幕寬度的 85%
                      child: GestureDetector(
                        onTap: () => _onSingleTap(actualIndex), // 單次點擊觸發語音播報
                        onDoubleTap: () => _onDoubleTap(actualIndex), // 雙擊導航
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 60,
                                  color: AppColors.text_1,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(item.title, style: AppTextStyles.title),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
