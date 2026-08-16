import 'package:flutter/material.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';

/// Hallmark Reusable Empty-State Widget with Anti-AI-Slop Restraint
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? title;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.borderTactile,
                  width: 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: HallmarkTypography.titleL3(colors.textPrimary),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: HallmarkTypography.bodyMain(colors.textMuted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              HallmarkButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

