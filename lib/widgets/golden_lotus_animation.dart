/// golden_lotus_animation.dart
/// 大千世界開場動畫 - 金色蓮花綻放效果
library;

import 'dart:math';
import 'package:flutter/material.dart';

/// 金色蓮花動畫 Widget
class GoldenLotusAnimation extends StatefulWidget {
  /// 動畫完成回調
  final VoidCallback? onComplete;

  /// 動畫持續時間（秒）
  final int durationSeconds;

  const GoldenLotusAnimation({
    super.key,
    this.onComplete,
    this.durationSeconds = 12,
  });

  @override
  State<GoldenLotusAnimation> createState() => _GoldenLotusAnimationState();
}

class _GoldenLotusAnimationState extends State<GoldenLotusAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random random = Random();

  late final List<_LotusInfo> frontLotuses;
  late final List<_LotusInfo> backLotuses;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();

    // 監聽動畫完成
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    // 前方 10 朵蓮花
    frontLotuses = List.generate(10, (i) {
      final baseAngle = (i / 10) * 2 * pi;
      final distance = 180 + random.nextDouble() * 180;
      final scale = 0.6 + random.nextDouble() * 0.8;
      final delay = random.nextDouble() * 0.3;
      return _LotusInfo(
        angle: baseAngle,
        distance: distance,
        scale: scale,
        delay: delay,
        opacityFactor: 1.0,
      );
    });

    // 後方 10 朵蓮花（更小更淡）
    backLotuses = List.generate(10, (i) {
      final baseAngle = (i / 10) * 2 * pi + 0.15; // 稍微錯開
      final distance = 150 + random.nextDouble() * 120;
      final scale = 0.4 + random.nextDouble() * 0.4;
      final delay = random.nextDouble() * 0.3;
      return _LotusInfo(
        angle: baseAngle,
        distance: distance,
        scale: scale,
        delay: delay,
        opacityFactor: 0.45, // 半透明
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 🌼 後方蓮花（在主體後面）
              for (final lotus in backLotuses)
                _buildAnimatedLotus(lotus, t),

              // ✨ 中央主體 - agent_pro.png
              _buildCenterImage(t),

              // 🌸 前方蓮花（在主體前方）
              for (final lotus in frontLotuses)
                _buildAnimatedLotus(lotus, t),

              // 標題文字
              Positioned(
                bottom: 80,
                child: _buildTitle(t),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 構建中央圖片
  Widget _buildCenterImage(double t) {
    // 淡入效果
    double opacity = t < 0.3 ? Curves.easeIn.transform(t / 0.3) : 1.0;

    // 縮放效果
    double scale = t < 0.5
        ? Curves.easeOutBack.transform(t / 0.5)
        : 1.0;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/agent_pro.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 如果圖片載入失敗，顯示佔位符
                return Container(
                  color: Colors.white,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.amber,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 構建標題
  Widget _buildTitle(double t) {
    double opacity = t < 0.5 ? 0 : Curves.easeIn.transform((t - 0.5) / 0.5);

    return Opacity(
      opacity: opacity,
      child: const Text(
        '大千世界',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
          shadows: [
            Shadow(
              color: Colors.amber,
              blurRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 構建動畫蓮花
  Widget _buildAnimatedLotus(_LotusInfo lotus, double t) {
    double progress = (t + lotus.delay) % 1.0;

    // 淡入淡出
    double opacity;
    if (progress < 0.2) {
      opacity = Curves.easeIn.transform(progress / 0.2);
    } else if (progress > 0.8) {
      opacity = Curves.easeOut.transform(1 - (progress - 0.8) / 0.2);
    } else {
      opacity = 1.0;
    }
    opacity *= lotus.opacityFactor;

    // 散開距離
    double move = lotus.distance * Curves.easeOut.transform(progress);

    // 呼吸縮放
    double scale = lotus.scale * (0.6 + 0.4 * sin(progress * pi));

    // 橢圓分佈
    final offset = Offset(
      cos(lotus.angle) * move,
      sin(lotus.angle) * move * 0.7,
    );

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale * 0.25,
          child: CustomPaint(
            painter: _SideLotusPainter(rotation: (t + lotus.delay) * 2 * pi),
            size: const Size(250, 250),
          ),
        ),
      ),
    );
  }
}

/// 蓮花資訊
class _LotusInfo {
  final double angle;
  final double distance;
  final double scale;
  final double delay;
  final double opacityFactor;

  _LotusInfo({
    required this.angle,
    required this.distance,
    required this.scale,
    required this.delay,
    required this.opacityFactor,
  });
}

/// 側視蓮花繪製器
class _SideLotusPainter extends CustomPainter {
  final double rotation;

  _SideLotusPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final petalCount = 10;
    final radius = size.width * 0.22;

    // 光暈效果
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawCircle(center, size.width * 0.7, glow);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 外層花瓣
    for (int i = 0; i < petalCount; i++) {
      final angle = rotation + (i * 2 * pi / petalCount);
      _drawSidePetal(
        canvas,
        radius * 1.2,
        angle,
        0.5,
        const Color(0xFFFFB800),
        const Color(0xFF8B5E00),
      );
    }

    // 內層花瓣
    for (int i = 0; i < petalCount; i++) {
      final angle = rotation + (i * 2 * pi / petalCount) + 0.2;
      _drawSidePetal(
        canvas,
        radius,
        angle,
        0.25,
        const Color(0xFFFFD700),
        const Color(0xFFFFA800),
      );
    }

    // 花蕊
    final corePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.orangeAccent, Colors.deepOrange],
      ).createShader(
        Rect.fromCircle(center: const Offset(0, 0), radius: radius * 1.1),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: radius * 0.4,
        height: radius * 0.2,
      ),
      corePaint,
    );

    canvas.restore();
  }

  /// 繪製側視花瓣
  void _drawSidePetal(
    Canvas canvas,
    double radius,
    double angle,
    double tilt,
    Color topColor,
    Color bottomColor,
  ) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [topColor, bottomColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    final double len = radius * 1.2;
    final double width = radius * 1.4;
    final double heightTilt = radius * tilt;

    final Offset base = const Offset(0, 0);
    final Offset tip = Offset(
      cos(angle) * len,
      sin(angle) * heightTilt - radius * 0.8,
    );
    final Offset left = Offset(
      cos(angle - 0.35) * width,
      sin(angle - 0.35) * heightTilt,
    );
    final Offset right = Offset(
      cos(angle + 0.35) * width,
      sin(angle + 0.35) * heightTilt,
    );

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, base.dx, base.dy)
      ..close();

    canvas.drawPath(path, paint);

    // 花瓣邊緣高光
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(_SideLotusPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}