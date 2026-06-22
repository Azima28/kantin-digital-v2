import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class NfcPulseAnimator extends StatefulWidget {
  final Widget child;
  final double size;
  final Color color;

  const NfcPulseAnimator({
    super.key,
    required this.child,
    this.size = 140.0,
    this.color = AppColors.primary,
  });

  @override
  State<NfcPulseAnimator> createState() => _NfcPulseAnimatorState();
}

class _NfcPulseAnimatorState extends State<NfcPulseAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.8,
      height: widget.size * 1.8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple 3 (delayed)
              _buildRipple(offsetValue: 0.66),
              // Ripple 2 (delayed)
              _buildRipple(offsetValue: 0.33),
              // Ripple 1
              _buildRipple(offsetValue: 0.0),
              // Core central button/icon
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(child: widget.child),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRipple({required double offsetValue}) {
    // Calculate progress with wrap-around offset
    double progress = (_controller.value + offsetValue) % 1.0;
    
    // Scale starts at 1.0 and goes up to 1.8
    double scale = 1.0 + (progress * 0.8);
    
    // Opacity fades out as progress increases
    double opacity = (1.0 - progress) * 0.45;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: opacity),
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
