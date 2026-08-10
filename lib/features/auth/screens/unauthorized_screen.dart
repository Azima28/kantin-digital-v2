import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// Screen yang ditampilkan ketika user tidak memiliki hak akses
/// ke suatu halaman (role mismatch).
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: Nebula.rose,
                ),
                const SizedBox(height: 24),
                Text(
                  'Akses Ditolak',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Anda tidak memiliki izin untuk mengakses halaman ini. Silakan hubungi administrator sekolah.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 15,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.cardBg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
