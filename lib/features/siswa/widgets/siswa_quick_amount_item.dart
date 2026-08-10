import 'package:flutter/cupertino.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class SiswaQuickAmountItem extends StatelessWidget {
  final int amount;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const SiswaQuickAmountItem({
    super.key,
    required this.amount,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal.withValues(alpha: 0.08) : context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                     color: isSelected ? Nebula.teal : context.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Nebula.teal,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
