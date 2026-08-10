import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

// â”€â”€â”€ Particle Data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ParticleData {
  final double angle;
  final double distanceFactor;
  final double radius;
  final Color color;
  final double delay;

  const ParticleData({
    required this.angle,
    required this.distanceFactor,
    required this.radius,
    required this.color,
    required this.delay,
  });
}

List<ParticleData> _buildParticles() {
  final rng = Random(42);
  const colors = [
    Color(0xFFFFC94D),
    Color(0xFF00C897),
    Color(0xFFFF6B6B),
    Color(0xFF4FC3F7),
    Color(0xFFAB47BC),
    Color(0xFFFF8F00),
  ];
  return List.generate(24, (i) {
    final angle = (i / 24) * 2 * pi + rng.nextDouble() * 0.4;
    // distanceFactor defines the explosion radius multiplier
    final distanceFactor = 0.5 + rng.nextDouble() * 0.5;
    return ParticleData(
      angle: angle,
      distanceFactor: distanceFactor,
      radius: 4 + rng.nextDouble() * 5,
      color: colors[i % colors.length],
      delay: rng.nextDouble() * 0.25,
    );
  });
}

// â”€â”€â”€ Overlay Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SiswaPaymentAnimationOverlay extends ConsumerStatefulWidget {
  final int totalAmount;
  final List<dynamic> cartItems;
  final VoidCallback onComplete;

  const SiswaPaymentAnimationOverlay({
    super.key,
    required this.totalAmount,
    required this.cartItems,
    required this.onComplete,
  });

  @override
  ConsumerState<SiswaPaymentAnimationOverlay> createState() =>
      _SiswaPaymentAnimationOverlayState();
}

class _SiswaPaymentAnimationOverlayState
    extends ConsumerState<SiswaPaymentAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<ParticleData> _particles;

  late Animation<double> _bgFade;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _ringProgress;
  late Animation<double> _ringFade;
  late Animation<double> _checkDraw;
  late Animation<double> _particleProgress;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _capBounce;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    Animation<double> a(double begin, double end, double from, double to,
        [Curve curve = Curves.easeOut]) {
      return Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(parent: _ctrl, curve: Interval(from, to, curve: curve)),
      );
    }

    _bgFade          = a(0, 1, 0.00, 0.10);
    _cardSlide       = a(80, 0, 0.05, 0.28, Curves.elasticOut);
    _cardFade        = a(0, 1, 0.05, 0.22);
    _ringProgress    = a(0, 1, 0.28, 0.52, Curves.elasticOut);
    _ringFade        = a(0, 1, 0.28, 0.42);
    _checkDraw       = a(0, 1, 0.50, 0.72, Curves.easeInOut);
    _particleProgress = a(0, 1, 0.52, 0.85, Curves.easeOut);
    _textSlide       = a(30, 0, 0.70, 0.90);
    _textFade        = a(0, 1, 0.70, 0.90);
    _capBounce       = a(0, 1, 0.60, 0.80, Curves.bounceOut);

    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          // 1. Pop the dialog route from Navigator stack to prevent being stuck
          Navigator.of(context).pop();
          // 2. Trigger successor callbacks (clear cart, navigate)
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final String studentName = authState.profile?['full_name'] ?? 'Siswa';
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF5),
          body: Opacity(
            opacity: _bgFade.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Responsive Particles Explosion
                ..._particles.map((p) => _buildParticleWidget(p, size)),

                // Main content container with safety paddings
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animating Card
                          Transform.translate(
                            offset: Offset(0, _cardSlide.value),
                            child: Opacity(
                              opacity: _cardFade.value.clamp(0.0, 1.0),
                              child: _buildAnimatedCard(size),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Text details
                          Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: Opacity(
                              opacity: _textFade.value.clamp(0.0, 1.0),
                              child: _buildTexts(studentName),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleWidget(ParticleData p, Size size) {
    final rawProgress = _particleProgress.value - p.delay;
    final progress = rawProgress.clamp(0.0, 1.0);
    if (progress <= 0) return const SizedBox.shrink();

    // Scale explosion distance based on current viewport size
    final maxExplosionRadius = min(size.width, size.height) * 0.45;
    final dist = maxExplosionRadius * p.distanceFactor;
    
    final dx = cos(p.angle) * dist * progress;
    final dy = sin(p.angle) * dist * progress;
    
    // Simulate natural gravity drop
    final gravity = 45 * progress * progress;

    return Positioned(
      left: size.width / 2 + dx - p.radius,
      top: size.height / 2 + dy + gravity - p.radius,
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Container(
          width: p.radius * 2,
          height: p.radius * 2,
          decoration: BoxDecoration(
            color: p.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(Size size) {
    final t = _ringProgress.value.clamp(0.0, 1.0);

    // Responsive card dimensions based on screen width
    final double cardWidth = (size.width * 0.65).clamp(220.0, 290.0);
    final double cardHeight = cardWidth * 0.58; // Golden/credit card aspect ratio

    final w = lerpDouble(cardWidth, 120, t)!;
    final h = lerpDouble(cardHeight, 120, t)!;
    final r = lerpDouble(16, 60, t)!;

    const fromColor1 = Color(0xFF1A2A4A);
    const toColor1 = Color(0xFF00C897);
    const fromColor2 = Color(0xFF0D1B2E);
    const toColor2 = Color(0xFF00A87A);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Ring rotation
        if (_ringFade.value > 0)
          Opacity(
            opacity: _ringFade.value.clamp(0.0, 1.0),
            child: SizedBox(
              width: w + 24,
              height: h + 24,
              child: Transform.rotate(
                angle: _ctrl.value * 4 * pi,
                child: CustomPaint(
                  painter: _DashedRingPainter(color: const Color(0xFFFFC94D)),
                ),
              ),
            ),
          ),

        // Main shape
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(fromColor1, toColor1, t)!,
                Color.lerp(fromColor2, toColor2, t)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0x551A2A4A),
                  const Color(0x6600C897),
                  t,
                )!,
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: t < 0.5
              ? _buildCardContent()
              : _buildCheckContent(),
        ),

        // Graduation cap landing bounce
        if (_capBounce.value > 0)
          Positioned(
            top: -(24 * _capBounce.value),
            child: Text(
              'ðŸŽ“',
              style: TextStyle(fontSize: 22 + 6 * _capBounce.value),
            ),
          ),
      ],
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC94D),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text('â—†', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
          const Text(
            'Kantin Digital',
            style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckContent() {
    return Center(
      child: CustomPaint(
        size: const Size(60, 60),
        painter: _CheckmarkPainter(progress: _checkDraw.value),
      ),
    );
  }

  Widget _buildTexts(String studentName) {
    return Column(
      children: [
        Text(
          'Pembayaran Berhasil! 🥳',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Halo, $studentName!',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF00C897),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Transaksi kamu sudah selesai ✅',
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// â”€â”€â”€ Custom Painters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const dashCount = 18;
    const gap = 0.22;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * pi;
      final sweepAngle = (1 / dashCount - gap) * 2 * pi;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  _CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.18, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.74);
    final p3 = Offset(size.width * 0.82, size.height * 0.28);

    final seg1 = (p2 - p1).distance;
    final seg2 = (p3 - p2).distance;
    final total = seg1 + seg2;
    final drawn = total * progress;

    final path = Path();
    if (drawn <= seg1) {
      final t = drawn / seg1;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final remaining = drawn - seg1;
      final t = remaining / seg2;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}
