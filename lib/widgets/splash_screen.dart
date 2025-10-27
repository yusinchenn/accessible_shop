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
  late AnimationController _dotController;
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

    // 點點跳動動畫
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 啟動動畫
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat(reverse: true);
    _dotController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _dotController.dispose();
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
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
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

                  SizedBox(height: AppSpacing.xl * 1.5),

                  // 三個點的載入動畫
                  AnimatedBuilder(
                    animation: _dotController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(0, AppColors.primary_2),
                          _buildDot(1, AppColors.secondery_2),
                          _buildDot(2, AppColors.accent_2),
                        ],
                      );
                    },
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

  /// 建立單個跳動的點
  Widget _buildDot(int index, Color color) {
    final delay = index * 0.2;
    final value = (_dotController.value - delay) % 1.0;
    final scale = value < 0.5
        ? 1.0 + (value * 2) * 0.5
        : 1.5 - ((value - 0.5) * 2) * 0.5;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
