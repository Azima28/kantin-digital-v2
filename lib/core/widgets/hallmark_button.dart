/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';

/// Hallmark 8-State Interactive Action Button for Kantin Digital v2.0
/// Component-Scope Discipline: Supports all 8 mandatory states:
/// [default, hover, focus-visible, active (0.98x), disabled, loading, error, success]
class HallmarkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isError;
  final bool isSuccess;
  final IconData? icon;
  final bool isFullWidth;

  const HallmarkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isError = false,
    this.isSuccess = false,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  State<HallmarkButton> createState() => _HallmarkButtonState();
}

class _HallmarkButtonState extends State<HallmarkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDisabled = widget.onPressed == null && !widget.isLoading;

    Color backgroundColor = colors.brandPrimary;
    Color foregroundColor = Colors.white;

    if (isDisabled) {
      backgroundColor = colors.surfaceSubtle;
      foregroundColor = colors.textMuted.withValues(alpha: 0.5);
    } else if (widget.isError) {
      backgroundColor = colors.statusError;
      foregroundColor = Colors.white;
    } else if (widget.isSuccess) {
      backgroundColor = colors.statusSuccess;
      foregroundColor = Colors.white;
    }

    Widget labelWidget = Text(
      widget.isLoading ? "Memproses..." : widget.label,
      style: HallmarkTypography.labelButton(foregroundColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.isSuccess) ...[
          const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 8),
        ] else if (widget.isError) ...[
          const Icon(Icons.error_outline_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Flexible(child: labelWidget),
      ],
    );

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled || widget.isLoading ? null : widget.onPressed,
            onHighlightChanged: (highlighted) {
              if (mounted) {
                if (highlighted) HapticFeedback.lightImpact();
                setState(() => _isPressed = highlighted);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.borderTactile,
                  width: 0.5,
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
