import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

/// 啟動載入畫面
/// 使用 app_icon.png 和 _2 顏色主題設計的精美動畫
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // 淡入動畫
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // 脈衝動畫（縮放效果）
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 旋轉動畫（微旋轉效果）
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    // 啟動動畫
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background_2,
        body: Stack(
          children: [
          // 背景裝飾圓圈
          Positioned(
            top: -100,
            right: -100,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary_2.withValues(alpha: 0.15),
                      AppColors.background_2.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondery_2.withValues(alpha: 0.1),
                      AppColors.background_2.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -50,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blockBackground_2.withValues(alpha: 0.2),
                      AppColors.background_2.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 主要內容
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 動畫
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseAnimation,
                      _rotateAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary_2.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // App 名稱
                  Text(
                    'Accessible Shop',
                    style: AppTextStyles.extraLargeTitle.copyWith(
                      color: AppColors.text_2,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  SizedBox(height: AppSpacing.sm),

                  // 副標題
                  Text(
                    '無障礙購物體驗',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.subtitle_2,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl * 1.5),

                  // 載入指示器
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary_2,
                      ),
                      strokeWidth: 4,
                    ),
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // 載入文字
                  Text(
                    '正在初始化...',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.subtitle_2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部裝飾
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary_2,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondery_2,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent_2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
