import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen ambient running food & drinks background
///
/// Cartoon food and drink characters with arms, legs, sneakers, and cartoon gloves
/// running continuously across the entire background without any blinking, freezing, or stutter.
class RunningFoodBackground extends StatefulWidget {
  final bool isInteractive;

  const RunningFoodBackground({
    super.key,
    this.isInteractive = true,
  });

  @override
  State<RunningFoodBackground> createState() => _RunningFoodBackgroundState();
}

enum FoodCharacterType {
  bobaDrink,
  burger,
  noodleBowl,
  donut,
  milkCarton,
  fries,
  iceCream,
}

class _RunnerModel {
  final FoodCharacterType type;
  final String name;
  final String speechBubble;
  final double speedFactor; // Relative speed multiplier
  final double scale;
  final double yFraction; // Vertical position (0.0 to 1.0)
  final double initialOffsetRatio; // Staggered start position ratio (0.0 to 1.0)
  final bool movingRight;
  final double opacity;
  double jumpStartTime = -999.0;
  double bubbleEndTime = -999.0;

  _RunnerModel({
    required this.type,
    required this.name,
    required this.speechBubble,
    required this.speedFactor,
    required this.scale,
    required this.yFraction,
    required this.initialOffsetRatio,
    this.movingRight = true,
    this.opacity = 0.85,
  });
}

class _RunningFoodBackgroundState extends State<RunningFoodBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsedSeconds = 0.0;
  late final List<_RunnerModel> _runners;

  @override
  void initState() {
    super.initState();

    // 12 diverse runners running in various directions & heights across the background
    _runners = [
      // Top Area (Behind Title / Header)
      _RunnerModel(
        type: FoodCharacterType.bobaDrink,
        name: 'Si Boba',
        speechBubble: 'Segar Banget!',
        speedFactor: 1.10,
        scale: 0.85,
        yFraction: 0.05,
        initialOffsetRatio: 0.05,
        movingRight: true,
        opacity: 0.75,
      ),
      _RunnerModel(
        type: FoodCharacterType.donut,
        name: 'Si Donat',
        speechBubble: 'Manis Gurih!',
        speedFactor: 0.90,
        scale: 0.80,
        yFraction: 0.12,
        initialOffsetRatio: 0.45,
        movingRight: false,
        opacity: 0.70,
      ),
      _RunnerModel(
        type: FoodCharacterType.iceCream,
        name: 'Si Es Krim',
        speechBubble: 'Dingin Enak!',
        speedFactor: 1.25,
        scale: 0.75,
        yFraction: 0.19,
        initialOffsetRatio: 0.25,
        movingRight: true,
        opacity: 0.65,
      ),

      // Upper Middle Area (Behind Form Top)
      _RunnerModel(
        type: FoodCharacterType.burger,
        name: 'Si Burger',
        speechBubble: 'Nyam Nyam!',
        speedFactor: 0.85,
        scale: 0.95,
        yFraction: 0.28,
        initialOffsetRatio: 0.70,
        movingRight: false,
        opacity: 0.80,
      ),
      _RunnerModel(
        type: FoodCharacterType.milkCarton,
        name: 'Si Susu',
        speechBubble: 'Semangat!',
        speedFactor: 1.35,
        scale: 0.82,
        yFraction: 0.38,
        initialOffsetRatio: 0.15,
        movingRight: true,
        opacity: 0.75,
      ),
      _RunnerModel(
        type: FoodCharacterType.fries,
        name: 'Si Kentang',
        speechBubble: 'Kriuk Renyah!',
        speedFactor: 1.15,
        scale: 0.85,
        yFraction: 0.47,
        initialOffsetRatio: 0.60,
        movingRight: false,
        opacity: 0.75,
      ),

      // Lower Middle Area (Behind Form Middle/Buttons)
      _RunnerModel(
        type: FoodCharacterType.noodleBowl,
        name: 'Si Mangkok',
        speechBubble: 'Kantin Buka!',
        speedFactor: 1.05,
        scale: 0.90,
        yFraction: 0.57,
        initialOffsetRatio: 0.35,
        movingRight: true,
        opacity: 0.80,
      ),
      _RunnerModel(
        type: FoodCharacterType.bobaDrink,
        name: 'Si Es Teh',
        speechBubble: 'Es Teh Jumbo!',
        speedFactor: 1.20,
        scale: 0.88,
        yFraction: 0.67,
        initialOffsetRatio: 0.80,
        movingRight: false,
        opacity: 0.85,
      ),
      _RunnerModel(
        type: FoodCharacterType.donut,
        name: 'Si Donat Pink',
        speechBubble: 'Ayo Jajan!',
        speedFactor: 0.95,
        scale: 0.92,
        yFraction: 0.76,
        initialOffsetRatio: 0.10,
        movingRight: true,
        opacity: 0.80,
      ),

      // Bottom Area (Behind Footer)
      _RunnerModel(
        type: FoodCharacterType.burger,
        name: 'Si Burger Super',
        speechBubble: 'Cepat Jajan!',
        speedFactor: 1.40,
        scale: 1.00,
        yFraction: 0.84,
        initialOffsetRatio: 0.50,
        movingRight: false,
        opacity: 0.90,
      ),
      _RunnerModel(
        type: FoodCharacterType.fries,
        name: 'Si Kentang Balap',
        speechBubble: 'Siap Melayani!',
        speedFactor: 1.30,
        scale: 0.85,
        yFraction: 0.89,
        initialOffsetRatio: 0.75,
        movingRight: true,
        opacity: 0.85,
      ),
      _RunnerModel(
        type: FoodCharacterType.noodleBowl,
        name: 'Si Bakso Mantap',
        speechBubble: 'Bakso Hangat!',
        speedFactor: 1.00,
        scale: 0.95,
        yFraction: 0.94,
        initialOffsetRatio: 0.20,
        movingRight: false,
        opacity: 0.90,
      ),
    ];

    // High-precision monotonic VSYNC ticker for seamless 60/120fps motion without any timer resets
    _ticker = createTicker((Duration elapsed) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
        });
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTapRunner(int index) {
    if (!widget.isInteractive) return;
    final runner = _runners[index];
    setState(() {
      runner.jumpStartTime = _elapsedSeconds;
      runner.bubbleEndTime = _elapsedSeconds + 2.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Base continuous horizontal run speed (pixels per second)
        const baseSpeedPxPerSec = 75.0;

        return SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle ambient background track lines
              ...List.generate(6, (i) {
                final lineY = screenHeight * (0.15 + i * 0.15);
                return Positioned(
                  top: lineY,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0D9488).withValues(alpha: 0.03),
                          const Color(0xFF14B8A6).withValues(alpha: 0.06),
                          const Color(0xFF0D9488).withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Seamless infinite runner rendering
              ...List.generate(_runners.length, (index) {
                final runner = _runners[index];
                final runnerWidth = 70.0 * runner.scale;
                final offscreenMargin = runnerWidth + 50.0;
                final trackWidth = screenWidth + (offscreenMargin * 2);

                // Continuous monotonic distance calculation (NEVER resets/jumps)
                final runnerSpeed = baseSpeedPxPerSec * runner.speedFactor;
                final distanceTraveled = (runner.initialOffsetRatio * trackWidth) +
                    (_elapsedSeconds * runnerSpeed);

                // Smooth modulo across the full off-screen boundary
                final normalizedX = distanceTraveled % trackWidth;

                final double currentX;
                if (runner.movingRight) {
                  currentX = -offscreenMargin + normalizedX;
                } else {
                  currentX = screenWidth + offscreenMargin - normalizedX - runnerWidth;
                }

                // Continuous leg running cycle phase (synchronized with speed)
                final legPhase = (_elapsedSeconds * runnerSpeed * 0.18) % (2 * math.pi);
                final bodyBob = math.sin(legPhase * 2).abs() * (3.5 * runner.scale);

                // Jump physics calculation on tap
                double jumpOffset = 0.0;
                final jumpElapsed = _elapsedSeconds - runner.jumpStartTime;
                if (jumpElapsed >= 0.0 && jumpElapsed < 0.6) {
                  final jumpProgress = jumpElapsed / 0.6;
                  // Parabolic curve: 4 * p * (1 - p) reaches max 1.0 at p = 0.5
                  jumpOffset = -42.0 * (4.0 * jumpProgress * (1.0 - jumpProgress));
                }

                final posY = (screenHeight * runner.yFraction) + bodyBob + jumpOffset;
                final showBubble = _elapsedSeconds < runner.bubbleEndTime;

                return Positioned(
                  left: currentX,
                  top: posY.clamp(0.0, screenHeight - 50),
                  child: Opacity(
                    opacity: runner.opacity,
                    child: GestureDetector(
                      onTap: () => _handleTapRunner(index),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Speech Bubble on tap
                            if (showBubble)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  runner.speechBubble,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                            // Flip horizontally when moving towards left
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(
                                runner.movingRight ? 1.0 : -1.0,
                                1.0,
                                1.0,
                              ),
                              child: CustomPaint(
                                size: Size(65 * runner.scale, 70 * runner.scale),
                                painter: FoodRunnerPainter(
                                  type: runner.type,
                                  legPhase: legPhase,
                                  scale: runner.scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Canvas Painter that renders cartoon Food & Drinks with animated running limbs
class FoodRunnerPainter extends CustomPainter {
  final FoodCharacterType type;
  final double legPhase;
  final double scale;

  FoodRunnerPainter({
    required this.type,
    required this.legPhase,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;

    // Running limb calculations using trigonometry
    // Left Leg
    final leftLegAngle = math.sin(legPhase) * 0.75;
    final leftKneeBend = (math.cos(legPhase) * 0.5).clamp(0.0, 1.0);

    // Right Leg (opposite phase)
    final rightLegAngle = math.sin(legPhase + math.pi) * 0.75;
    final rightKneeBend = (math.cos(legPhase + math.pi) * 0.5).clamp(0.0, 1.0);

    // Arms (opposite to legs)
    final leftArmAngle = math.sin(legPhase + math.pi) * 0.8;
    final rightArmAngle = math.sin(legPhase) * 0.8;

    // 1. Draw Back Limbs (Right Leg & Right Arm)
    _drawLimbs(
      canvas: canvas,
      centerX: centerX + 6,
      hipY: centerY + 16,
      shoulderY: centerY,
      legAngle: rightLegAngle,
      kneeBend: rightKneeBend,
      armAngle: rightArmAngle,
      isBackLimb: true,
    );

    // 2. Draw Food/Drink Body & Face
    switch (type) {
      case FoodCharacterType.bobaDrink:
        _drawBobaCup(canvas, centerX, centerY);
        break;
      case FoodCharacterType.burger:
        _drawBurger(canvas, centerX, centerY);
        break;
      case FoodCharacterType.noodleBowl:
        _drawNoodleBowl(canvas, centerX, centerY);
        break;
      case FoodCharacterType.donut:
        _drawDonut(canvas, centerX, centerY);
        break;
      case FoodCharacterType.milkCarton:
        _drawMilkCarton(canvas, centerX, centerY);
        break;
      case FoodCharacterType.fries:
        _drawFries(canvas, centerX, centerY);
        break;
      case FoodCharacterType.iceCream:
        _drawIceCream(canvas, centerX, centerY);
        break;
    }

    // 3. Draw Front Limbs (Left Leg & Left Arm)
    _drawLimbs(
      canvas: canvas,
      centerX: centerX - 6,
      hipY: centerY + 16,
      shoulderY: centerY,
      legAngle: leftLegAngle,
      kneeBend: leftKneeBend,
      armAngle: leftArmAngle,
      isBackLimb: false,
    );

    // 4. Draw Running Dust Particles behind character
    _drawRunningDust(canvas, centerX - 22, size.height - 10, legPhase);
  }

  void _drawLimbs({
    required Canvas canvas,
    required double centerX,
    required double hipY,
    required double shoulderY,
    required double legAngle,
    required double kneeBend,
    required double armAngle,
    required bool isBackLimb,
  }) {
    final limbColor = isBackLimb ? const Color(0xFF475569) : const Color(0xFF1E293B);
    final shoeColor = isBackLimb ? const Color(0xFFE11D48) : const Color(0xFFF43F5E);
    final sockColor = Colors.white;

    final limbPaint = Paint()
      ..color = limbColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // --- ARM DRAWING ---
    const armLength = 15.0;
    final armEndX = centerX + math.sin(armAngle) * armLength + 3;
    final armEndY = shoulderY + math.cos(armAngle) * armLength * 0.6 + 5;

    // Arm line
    canvas.drawLine(
      Offset(centerX + (isBackLimb ? 4 : -4), shoulderY),
      Offset(armEndX, armEndY),
      limbPaint,
    );

    // Hand (Cute cartoon white glove)
    fillPaint.color = Colors.white;
    canvas.drawCircle(Offset(armEndX, armEndY), 4.2, fillPaint);
    final gloveBorder = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(armEndX, armEndY), 4.2, gloveBorder);

    // --- LEG DRAWING ---
    const thighLength = 11.0;
    const shinLength = 11.0;

    final kneeX = centerX + math.sin(legAngle) * thighLength;
    final kneeY = hipY + math.cos(legAngle) * thighLength;

    final footAngle = legAngle - kneeBend;
    final footX = kneeX + math.sin(footAngle) * shinLength;
    final footY = kneeY + math.cos(footAngle) * shinLength;

    // Thigh & Shin
    canvas.drawLine(Offset(centerX, hipY), Offset(kneeX, kneeY), limbPaint);
    canvas.drawLine(Offset(kneeX, kneeY), Offset(footX, footY), limbPaint);

    // Running Sneaker / Shoe
    final shoeCenter = Offset(footX + 3, footY + 2);

    // White Sock
    fillPaint.color = sockColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(footX, footY - 2), width: 6, height: 4),
        const Radius.circular(2),
      ),
      fillPaint,
    );

    // Sneaker Body
    fillPaint.color = shoeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: shoeCenter, width: 13, height: 6.5),
        const Radius.circular(3),
      ),
      fillPaint,
    );

    // Sneaker Sole & Toe
    fillPaint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(shoeCenter.dx + 4, shoeCenter.dy), width: 4.5, height: 5.5),
        const Radius.circular(2),
      ),
      fillPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(shoeCenter.dx - 6.5, shoeCenter.dy + 1.8, 13, 1.8),
      fillPaint,
    );
  }

  /// 1. Si Boba / Es Teh Segar
  void _drawBobaCup(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Cup Shadow
    paint.color = Colors.black.withValues(alpha: 0.06);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 24), width: 32, height: 7), paint);

    // Cup Body
    final cupPath = Path()
      ..moveTo(cx - 15, cy - 13)
      ..lineTo(cx + 15, cy - 13)
      ..lineTo(cx + 11, cy + 18)
      ..quadraticBezierTo(cx, cy + 21, cx - 11, cy + 18)
      ..close();

    // Tea Liquid Gradient Fill
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFFB45309)],
    ).createShader(Rect.fromLTWH(cx - 15, cy - 13, 30, 34));
    canvas.drawPath(cupPath, paint);
    paint.shader = null;

    // Boba Pearls at bottom
    paint.color = const Color(0xFF1E1B18);
    const bobaOffsets = [
      Offset(-6, 13),
      Offset(0, 15),
      Offset(5, 13),
      Offset(-3, 9),
      Offset(3, 8),
    ];
    for (var pos in bobaOffsets) {
      canvas.drawCircle(Offset(cx + pos.dx, cy + pos.dy), 2.8, paint);
    }

    // Ice Cubes
    final icePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 4, cy - 4), width: 7, height: 7),
        const Radius.circular(2),
      ),
      icePaint,
    );

    // Plastic Cup Outline
    final cupBorder = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(cupPath, cupBorder);

    // Dome Lid
    final lidPath = Path()
      ..moveTo(cx - 17, cy - 13)
      ..lineTo(cx + 17, cy - 13)
      ..quadraticBezierTo(cx, cy - 23, cx - 17, cy - 13);
    paint.color = Colors.white.withValues(alpha: 0.85);
    canvas.drawPath(lidPath, paint);
    canvas.drawPath(lidPath, cupBorder);

    // Straw
    final strawPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 2, cy - 11), Offset(cx + 9, cy - 25), strawPaint);

    // Face
    _drawCuteFace(canvas, cx, cy + 1, happy: true);
  }

  /// 2. Si Burger Lezat
  void _drawBurger(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Top Bun
    final topBunPath = Path()
      ..moveTo(cx - 18, cy - 2)
      ..quadraticBezierTo(cx - 16, cy - 18, cx, cy - 18)
      ..quadraticBezierTo(cx + 16, cy - 18, cx + 18, cy - 2)
      ..close();

    paint.color = const Color(0xFFF59E0B);
    canvas.drawPath(topBunPath, paint);
    canvas.drawPath(topBunPath, strokePaint);

    // Sesame Seeds
    paint.color = const Color(0xFFFEF3C7);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 7, cy - 12), width: 2.8, height: 1.6), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 5, cy - 11), width: 2.8, height: 1.6), paint);

    // Lettuce
    paint.color = const Color(0xFF22C55E);
    final lettucePath = Path()
      ..moveTo(cx - 20, cy - 1)
      ..quadraticBezierTo(cx - 13, cy + 3, cx - 7, cy - 1)
      ..quadraticBezierTo(cx, cy + 3, cx + 7, cy - 1)
      ..quadraticBezierTo(cx + 13, cy + 3, cx + 20, cy - 1)
      ..lineTo(cx - 20, cy - 1);
    canvas.drawPath(lettucePath, paint);

    // Melted Cheese
    paint.color = const Color(0xFFFACC15);
    final cheesePath = Path()
      ..moveTo(cx - 16, cy + 1)
      ..lineTo(cx + 16, cy + 1)
      ..lineTo(cx + 5, cy + 8)
      ..lineTo(cx - 16, cy + 1);
    canvas.drawPath(cheesePath, paint);

    // Meat Patty
    paint.color = const Color(0xFF78350F);
    final pattyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 36, height: 7),
      const Radius.circular(3),
    );
    canvas.drawRRect(pattyRect, paint);
    canvas.drawRRect(pattyRect, strokePaint);

    // Bottom Bun
    paint.color = const Color(0xFFD97706);
    final bottomBunRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 11), width: 32, height: 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(bottomBunRect, paint);
    canvas.drawRRect(bottomBunRect, strokePaint);

    // Face
    _drawCuteFace(canvas, cx, cy - 8, happy: true);
  }

  /// 3. Si Mangkok Mie & Bakso
  void _drawNoodleBowl(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Steam
    final steamPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.6)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final steam1 = Path()
      ..moveTo(cx - 5, cy - 12)
      ..quadraticBezierTo(cx - 8, cy - 18, cx - 5, cy - 23);
    final steam2 = Path()
      ..moveTo(cx + 5, cy - 12)
      ..quadraticBezierTo(cx + 8, cy - 18, cx + 5, cy - 23);
    canvas.drawPath(steam1, steamPaint);
    canvas.drawPath(steam2, steamPaint);

    // Bowl
    final bowlPath = Path()
      ..moveTo(cx - 18, cy - 3)
      ..lineTo(cx + 18, cy - 3)
      ..quadraticBezierTo(cx + 14, cy + 16, cx, cy + 16)
      ..quadraticBezierTo(cx - 14, cy + 16, cx - 18, cy - 3)
      ..close();

    paint.color = const Color(0xFFDC2626);
    canvas.drawPath(bowlPath, paint);
    canvas.drawPath(bowlPath, strokePaint);

    // Rim
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 3), width: 36, height: 8), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 3), width: 36, height: 8), strokePaint);

    // Noodles
    paint.color = const Color(0xFFFBBF24);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 3), width: 30, height: 6), paint);

    // Bakso
    paint.color = const Color(0xFF9A3412);
    canvas.drawCircle(Offset(cx - 5, cy - 4), 3.5, paint);
    canvas.drawCircle(Offset(cx + 4, cy - 3), 3.0, paint);

    // Face
    _drawCuteFace(canvas, cx, cy + 5, happy: true, isWhiteFace: true);
  }

  /// 4. Si Donat Stroberi
  void _drawDonut(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Base
    paint.color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(cx, cy), 16, paint);
    canvas.drawCircle(Offset(cx, cy), 16, strokePaint);

    // Glaze
    paint.color = const Color(0xFFF472B6);
    canvas.drawCircle(Offset(cx, cy - 1), 14, paint);

    // Center Hole
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), 5.0, paint);
    canvas.drawCircle(Offset(cx, cy), 5.0, strokePaint);

    // Sprinkles
    final sprinklePaint = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    sprinklePaint.color = const Color(0xFF38BDF8);
    canvas.drawLine(Offset(cx - 8, cy - 8), Offset(cx - 5, cy - 7), sprinklePaint);

    sprinklePaint.color = const Color(0xFFFACC15);
    canvas.drawLine(Offset(cx + 6, cy - 6), Offset(cx + 8, cy - 8), sprinklePaint);

    sprinklePaint.color = const Color(0xFF4ADE80);
    canvas.drawLine(Offset(cx - 8, cy + 5), Offset(cx - 6, cy + 8), sprinklePaint);

    // Face
    _drawCuteFace(canvas, cx, cy - 5, happy: true);
  }

  /// 5. Si Kotak Susu
  void _drawMilkCarton(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Body
    final cartonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 24, height: 24),
      const Radius.circular(3),
    );
    paint.color = const Color(0xFFE0F2FE);
    canvas.drawRRect(cartonRect, paint);
    canvas.drawRRect(cartonRect, strokePaint);

    // Roof
    final roofPath = Path()
      ..moveTo(cx - 12, cy - 9)
      ..lineTo(cx, cy - 16)
      ..lineTo(cx + 12, cy - 9)
      ..close();
    paint.color = const Color(0xFF38BDF8);
    canvas.drawPath(roofPath, paint);
    canvas.drawPath(roofPath, strokePaint);

    // Straw
    final strawPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 3, cy - 13), Offset(cx + 8, cy - 21), strawPaint);

    // Face
    _drawCuteFace(canvas, cx, cy - 1, happy: true);
  }

  /// 6. Si Kentang Goreng (Fries)
  void _drawFries(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Golden Fries Sticks
    paint.color = const Color(0xFFFACC15);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 8, cy - 18, 4, 16), const Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 3, cy - 21, 4, 19), const Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2, cy - 19, 4, 17), const Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6, cy - 16, 4, 14), const Radius.circular(2)), paint);

    // Red Box
    final boxPath = Path()
      ..moveTo(cx - 12, cy - 4)
      ..lineTo(cx + 12, cy - 4)
      ..lineTo(cx + 9, cy + 16)
      ..lineTo(cx - 9, cy + 16)
      ..close();

    paint.color = const Color(0xFFEF4444);
    canvas.drawPath(boxPath, paint);
    canvas.drawPath(boxPath, strokePaint);

    // Yellow Logo Arc on Box
    final arcPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + 8), width: 8, height: 6), 0, math.pi, false, arcPaint);

    // Face
    _drawCuteFace(canvas, cx, cy + 4, happy: true, isWhiteFace: true);
  }

  /// 7. Si Es Krim Cone
  void _drawIceCream(Canvas canvas, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Waffle Cone (Bottom Triangle)
    final conePath = Path()
      ..moveTo(cx - 10, cy + 1)
      ..lineTo(cx + 10, cy + 1)
      ..lineTo(cx, cy + 18)
      ..close();

    paint.color = const Color(0xFFD97706);
    canvas.drawPath(conePath, paint);
    canvas.drawPath(conePath, strokePaint);

    // Soft-serve swirl (Pink & Vanilla)
    paint.color = const Color(0xFFFDA4AF);
    canvas.drawCircle(Offset(cx, cy - 6), 11, paint);
    paint.color = const Color(0xFFFEF08A);
    canvas.drawCircle(Offset(cx, cy - 14), 7, paint);

    // Cherry on Top
    paint.color = const Color(0xFFDC2626);
    canvas.drawCircle(Offset(cx, cy - 20), 3.5, paint);

    // Face
    _drawCuteFace(canvas, cx, cy - 6, happy: true);
  }

  /// Helper to draw expressive, happy anime cartoon faces
  void _drawCuteFace(
    Canvas canvas,
    double cx,
    double cy, {
    required bool happy,
    bool isWhiteFace = false,
  }) {
    final eyePaint = Paint()
      ..color = isWhiteFace ? Colors.white : const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Two eyes
    canvas.drawCircle(Offset(cx - 5.0, cy - 1), 2.0, eyePaint);
    canvas.drawCircle(Offset(cx + 5.0, cy - 1), 2.0, eyePaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFB7185).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 8, cy + 2), 2.0, cheekPaint);
    canvas.drawCircle(Offset(cx + 8, cy + 2), 2.0, cheekPaint);

    // Smiling Mouth
    final mouthPaint = Paint()
      ..color = isWhiteFace ? Colors.white : const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(cx - 2.5, cy + 2)
      ..quadraticBezierTo(cx, cy + 5.0, cx + 2.5, cy + 2);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  /// Running dust particles popping behind the runner
  void _drawRunningDust(Canvas canvas, double x, double y, double phase) {
    final dustPaint = Paint()..style = PaintingStyle.fill;
    final dustPhase = (phase * 2) % (2 * math.pi);
    final opacity = (math.sin(dustPhase).abs()).clamp(0.1, 0.5);

    dustPaint.color = const Color(0xFFCBD5E1).withValues(alpha: opacity);
    canvas.drawCircle(Offset(x - 3, y + 2), 2.2, dustPaint);
    canvas.drawCircle(Offset(x - 7, y - 1), 1.6, dustPaint);
  }

  @override
  bool shouldRepaint(covariant FoodRunnerPainter oldDelegate) {
    return oldDelegate.legPhase != legPhase ||
        oldDelegate.type != type ||
        oldDelegate.scale != scale;
  }
}

/// Standalone Horizontal Track Runner Component (if used in single-line track)
class RunningFoodCharacters extends StatelessWidget {
  final double height;
  const RunningFoodCharacters({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const RunningFoodBackground(isInteractive: true),
    );
  }
}
