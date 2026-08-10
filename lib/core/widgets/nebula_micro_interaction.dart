import 'package:flutter/material.dart';
import 'package:kantin_digital/core/theme/nebula_tokens.dart';

/// Wraps a child with a press-scale animation.
/// Shrinks to [scale] when pressed, returns to normal when released.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.duration,
    this.curve,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration? duration;
  final Curve? curve;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? NebulaAnimation.normal,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? NebulaAnimation.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Transform.scale(
          scale: _animation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Animated card that lifts (transforms + glow) on hover/press.
/// For web: responds to hover. For mobile: responds to tap.
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.liftAmount = 4,
    this.scaleAmount = 1.02,
    this.glowColor,
    this.duration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double liftAmount;
  final double scaleAmount;
  final Color? glowColor;
  final Duration? duration;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _liftAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? NebulaAnimation.smooth,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: NebulaAnimation.easeOut),
    );
    _liftAnim = Tween<double>(begin: 0, end: widget.liftAmount.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: NebulaAnimation.easeOut),
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: NebulaAnimation.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.onTap != null
          ? (_) => _controller.forward()
          : null,
      onExit: widget.onTap != null
          ? (_) => _controller.reverse()
          : null,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _controller.reverse();
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_liftAnim.value),
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: widget.glowColor != null
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor!.withValues(
                          alpha: 0.3 * _glowAnim.value,
                        ),
                        blurRadius: 20 + (10 * _glowAnim.value),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
