import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';

/// A premium ListTile-style row for switching between light and dark mode.
class ThemeToggleTile extends ConsumerWidget {
  final bool showDivider;
  final EdgeInsetsGeometry? padding;
  final bool useCircleIcon;

  const ThemeToggleTile({
    super.key,
    this.showDivider = false,
    this.padding,
    this.useCircleIcon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final iconBgColor = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primaryLight;
    final iconColor = AppColors.primary;

    Widget leadingIcon;
    if (useCircleIcon) {
      leadingIcon = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
          key: ValueKey(isDark),
          color: iconColor,
          size: 18,
        ),
      );
    } else {
      leadingIcon = Icon(
        isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
        key: ValueKey(isDark),
        color: context.textSecondary,
        size: 20,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => ref.read(themeProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mode Tampilan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                        size: 12,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDark ? 'Gelap' : 'Terang',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: context.borderLight,
            ),
          ),
      ],
    );
  }
}
