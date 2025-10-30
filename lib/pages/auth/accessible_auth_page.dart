import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

/// 無障礙登入/註冊頁面 - 分步驟設計
class AccessibleAuthPage extends StatefulWidget {
  const AccessibleAuthPage({super.key});

  @override
  State<AccessibleAuthPage> createState() => _AccessibleAuthPageState();
}

class _AccessibleAuthPageState extends State<AccessibleAuthPage> {
  final PageController _pageController = PageController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  int _currentStep = 0; // 0: 電子郵件, 1: 密碼
  bool _hasAnnounced = false; // 標記是否已經播報過

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在頁面真正顯示時播報，避免在登入狀態切換時誤播
    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (routeIsCurrent && !_hasAnnounced) {
      _hasAnnounced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
          return;
        }

        // 延遲 300ms 後再次確認頁面仍然是當前路由
        // 這樣可以避免在 AuthProvider 初始化期間的短暫顯示
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          _announceCurrentPage();
        }
      });
    }
  }

  void _announceCurrentPage() {
    if (_currentStep == 0) {
      ttsHelper.speakQueue([
        _isLoginMode ? '登入頁面' : '註冊頁面',
        '請輸入電子郵件',
        '輸入完成後，點擊下一步按鈕',
      ]);
    } else {
      ttsHelper.speak('請輸入密碼');
    }
  }

  Future<void> _goToPasswordStep() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ttsHelper.speak('請輸入電子郵件');
      return;
    }

    if (!email.contains('@')) {
      ttsHelper.speak('請輸入有效的電子郵件格式');
      return;
    }

    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    ttsHelper.speakQueue([
      '密碼輸入頁面',
      '您的電子郵件是：$email',
      '如需修改，請點擊上方的電子郵件',
      '請輸入密碼',
      '至少需要 6 個字元',
    ]);
  }

  Future<void> _goBackToEmailStep() async {
    // 返回 email 步驟，不清空 email 讓用戶可以修改
    _passwordController.clear();

    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    ttsHelper.speakQueue([
      '返回電子郵件輸入',
      '請修改您的電子郵件',
      '目前的電子郵件是：${_emailController.text}',
    ]);
  }

  Future<void> _submit() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      ttsHelper.speak('請輸入密碼');
      return;
    }

    if (password.length < 6) {
      ttsHelper.speak('密碼至少需要 6 個字元');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    ttsHelper.speak(_isLoginMode ? '正在登入' : '正在註冊');

    bool success;
    if (_isLoginMode) {
      success = await authProvider.signIn(email: email, password: password);
    } else {
      success = await authProvider.signUp(email: email, password: password);
    }

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      // 登入失敗 - 朗讀錯誤並回到第一步
      await ttsHelper.speakQueue([
        '登入資訊錯誤',
        authProvider.errorMessage!,
        '請重新輸入電子郵件',
      ]);

      authProvider.clearError();

      // 清空輸入並回到第一步
      _emailController.clear();
      _passwordController.clear();

      setState(() => _currentStep = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (success) {
      ttsHelper.speak(_isLoginMode ? '登入成功' : '註冊成功');
      // 登入/註冊成功後，導航到首頁並清除所有導航堆疊
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _currentStep = 0;
      _emailController.clear();
      _passwordController.clear();
    });

    _pageController.jumpToPage(0);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _announceCurrentPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      enableGlobalGestures: false, // 登入頁面禁用全域手勢，防止未登入時跳轉
      appBar: AppBar(
        title: Text(
          _isLoginMode ? '登入' : '註冊',
          style: AppTextStyles.title.copyWith(color: AppColors.text_2),
        ),
        backgroundColor: AppColors.background_2,
        automaticallyImplyLeading: false,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildEmailStep(), _buildPasswordStep()],
      ),
    );
  }

  /// 步驟 1: 電子郵件輸入
  Widget _buildEmailStep() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 單擊非按鈕非輸入框區域，重新朗讀頁面說明
        _announceCurrentPage();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.md),
              Text(
                'Accessible Shop',
                textAlign: TextAlign.center,
                style: AppTextStyles.extraLargeTitle.copyWith(
                  color: AppColors.text_2,
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // 步驟指示
              Text(
                '步驟 1/2：輸入電子郵件',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.subtitle_2,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Email 輸入框
              TextField(
                controller: _emailController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: '電子郵件',
                  labelStyle: AppTextStyles.body.copyWith(
                    color: AppColors.subtitle_2,
                  ),
                  prefixIcon: Icon(
                    Icons.email,
                    size: 32,
                    color: AppColors.text_2,
                  ),
                  filled: true,
                  fillColor: AppColors.background_2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.subtitle_2,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary_2,
                      width: 3,
                    ),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onTap: () => ttsHelper.speak('電子郵件輸入框'),
                onChanged: (value) {
                  if (value.isEmpty) {
                    ttsHelper.speak('電子郵件已清空');
                  } else if (value.length > 50) {
                    ttsHelper.speak('電子郵件地址過長，請檢查是否正確');
                  } else if (value.length > 30 && !value.contains('@')) {
                    ttsHelper.speak('電子郵件格式可能有誤，請檢查');
                  }
                },
              ),
              SizedBox(height: AppSpacing.xl),

              // 下一步按鈕（雙擊確認）
              DoubleClickButton(
                onConfirm: _goToPasswordStep,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary_2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '下一步',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.bottonText_2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // 切換模式（雙擊確認）
              DoubleClickButton(
                onConfirm: _toggleMode,
                buttonText: _isLoginMode ? '註冊入口' : '登入入口',
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    _isLoginMode ? '還沒有帳號？立即註冊' : '已有帳號？立即登入',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.text_2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// 步驟 2: 密碼輸入
  Widget _buildPasswordStep() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 單擊非按鈕非輸入框區域，重新朗讀頁面說明
        _announceCurrentPage();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),
              // 步驟指示
              Text(
                '步驟 2/2：輸入密碼',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.subtitle_2,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // 顯示已輸入的電子郵件（可點擊修改）
              DoubleClickButton(
                onConfirm: _goBackToEmailStep,
                buttonText: '電子郵件：${_emailController.text}，點擊可修改',
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background_2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary_2.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email, size: 28, color: AppColors.text_2),
                      SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          _emailController.text,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text_2,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Icon(Icons.edit, size: 20, color: AppColors.primary_2),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // 密碼輸入框
              TextField(
                controller: _passwordController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: '密碼（至少 6 個字元）',
                  labelStyle: AppTextStyles.body.copyWith(
                    color: AppColors.subtitle_2,
                  ),
                  prefixIcon: Icon(
                    Icons.lock,
                    size: 32,
                    color: AppColors.text_2,
                  ),
                  filled: true,
                  fillColor: AppColors.background_2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.subtitle_2,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary_2,
                      width: 3,
                    ),
                  ),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onTap: () => ttsHelper.speak('密碼輸入框'),
                onChanged: (value) {
                  if (value.isEmpty) {
                    ttsHelper.speak('密碼已清空');
                  }
                },
              ),
              SizedBox(height: AppSpacing.xl),

              // 登入/註冊按鈕（雙擊確認）
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isLoading) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary_2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            _isLoginMode ? '登入中...' : '註冊中...',
                            style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DoubleClickButton(
                    onConfirm: _submit,
                    buttonText: _isLoginMode ? '登入' : '註冊',
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.text_2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isLoginMode ? '登入' : '註冊',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 雙擊確認按鈕元件
class DoubleClickButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onConfirm;
  final String? buttonText;

  const DoubleClickButton({
    super.key,
    required this.child,
    required this.onConfirm,
    this.buttonText,
  });

  @override
  State<DoubleClickButton> createState() => _DoubleClickButtonState();
}

class _DoubleClickButtonState extends State<DoubleClickButton> {
  DateTime? _lastTapTime;

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      // 雙擊 - 打斷舊語音，然後執行動作
      _lastTapTime = null;
      ttsHelper.stop(); // 停止當前語音
      widget.onConfirm();
    } else {
      // 單擊 - 朗讀提示
      _lastTapTime = now;
      final announcement = widget.buttonText ?? '下一步';
      ttsHelper.speak('按鈕，$announcement');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}
