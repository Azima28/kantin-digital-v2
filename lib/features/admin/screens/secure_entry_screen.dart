import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class SecureEntryScreen extends ConsumerStatefulWidget {
  const SecureEntryScreen({super.key});

  @override
  ConsumerState<SecureEntryScreen> createState() => _SecureEntryScreenState();
}

class _SecureEntryScreenState extends ConsumerState<SecureEntryScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // If authenticated as admin/super_admin, go straight to dashboard
    if (authState.isAuthenticated &&
        (authState.profile?['role'] == 'super_admin' ||
            authState.profile?['role'] == 'admin')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/admin');
        }
      });
    }

    // If not authenticated or not admin, show redirect to login
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Shield Box
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.darkTeal,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkTeal.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Kantin Digital',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTeal,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 48),

                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppColors.mutedGray,
                ),
                const SizedBox(height: 16),

                Text(
                  'Anda harus login sebagai Admin',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.nearBlack,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Silakan login terlebih dahulu untuk mengakses panel admin.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedGray,
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkTeal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppStrings.buttonLogin,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
