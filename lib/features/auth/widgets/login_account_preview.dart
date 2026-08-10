import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class LoginAccountPreview extends StatelessWidget {
  final Widget child;
  final double? width;

  const LoginAccountPreview({super.key, required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final primaryTeal = isDark ? const Color(0xFF06D6A0) : const Color(0xFF0D9488);
    final glassBorder = isDark ? const Color(0x14FFFFFF) : const Color(0xFFCEECE4);
    final glassBg = isDark ? const Color(0xA6202020) : const Color(0xF5FFFFFF);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Container(
      width: width ?? 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x99000000) : const Color(0x14065F56),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: AKUN DEMO + info icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: isDark ? 0.12 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 14,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AKUN DEMO',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Tooltip(
                message: 'Gunakan akun ini untuk login',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 1,
            color: glassBorder,
          ),
          const SizedBox(height: 16),
          // Demo Account items
          child,
        ],
      ),
    );
  }
}


