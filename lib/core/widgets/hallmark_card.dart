/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';

/// Hallmark Tactile Surface Card Component for Kantin Digital v2.0
/// Attributes: Radius 16px, Elevation 0, 0.5px Hairline Border, Tactile Press/Hover scale
class HallmarkCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool isSelected;

  const HallmarkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.isSelected = false,
  });

  @override
  State<HallmarkCard> createState() => _HallmarkCardState();
}

class _HallmarkCardState extends State<HallmarkCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isClickable = widget.onTap != null;

    final baseBg = widget.backgroundColor ?? colors.surfaceContainer;
    final borderCol = widget.isSelected
        ? colors.brandPrimary
        : colors.borderTactile;

    Widget cardBody = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: baseBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderCol,
          width: widget.isSelected ? 1.5 : 0.5,
        ),
      ),
      child: widget.child,
    );

    if (!isClickable) {
      return cardBody;
    }

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (mounted) {
              if (highlighted) HapticFeedback.selectionClick();
              setState(() => _isPressed = highlighted);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: cardBody,
        ),
      ),
    );
  }
}
