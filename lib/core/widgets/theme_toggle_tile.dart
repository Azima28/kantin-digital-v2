import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// A sleek, minimal ListTile-style row for switching between light and dark mode.
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
    final themeAccent = isDark ? const Color(0xFFF59E0B) : Nebula.teal;

    Widget leadingIcon;
    if (useCircleIcon) {
      leadingIcon = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: themeAccent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
          key: ValueKey(isDark),
          color: themeAccent,
          size: 16,
        ),
      );
    } else {
      leadingIcon = Icon(
        isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
        key: ValueKey(isDark),
        color: themeAccent,
        size: 20,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => ref.read(themeProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mode Tampilan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeAccent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                        size: 12,
                        color: themeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDark ? 'Gelap' : 'Terang',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: themeAccent,
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
            padding: const EdgeInsets.only(top: 10, bottom: 10),
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

