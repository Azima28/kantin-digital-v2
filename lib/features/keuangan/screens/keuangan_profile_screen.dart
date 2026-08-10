import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/widgets/change_password_panel.dart';
import 'package:kantin_digital/core/widgets/theme_toggle_tile.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class KeuanganProfileScreen extends ConsumerStatefulWidget {
  const KeuanganProfileScreen({super.key});

  @override
  ConsumerState<KeuanganProfileScreen> createState() => _KeuanganProfileScreenState();
}

class _KeuanganProfileScreenState extends ConsumerState<KeuanganProfileScreen> {

  void _showChangePasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.white.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              ),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ChangePasswordPanel(parentContext: context),
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun keuangan ini?'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              router.go('/login');
            },
            child: const Text(AppStrings.buttonLogout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).profile;
    final fullName = profile?['full_name'] ?? 'Admin Keuangan';
    final email = profile?['email'] ?? '-';
    final username = profile?['username'] ?? 'budi_fin';
    final school = profile?['assigned_school'] ?? 'SMP Terpadu';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Avatar Bento Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.cardBg.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin Keuangan · $school',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Informational Account Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.cardBg.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Akun',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Email', email),
                    Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                    _buildInfoRow('Username', username),
                    Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                    _buildInfoRow('Level Otoritas', 'L1 (Operator)'),
                    Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                    _buildInfoRow('Sekolah Asal', school),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Security Options Card ───
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.cardBg.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 8),
                      child: Text(
                        'Pengaturan Keamanan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    ThemeToggleTile(showDivider: true),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                        child: Icon(CupertinoIcons.lock_shield, color: Nebula.teal, size: 20),
                      ),
                      title: Text(
                        AppStrings.adminChangePassword,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      trailing: Icon(CupertinoIcons.chevron_forward, size: 16, color: context.textSecondary),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Logout Button ───
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _handleLogout,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Nebula.rose.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Nebula.rose.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Text(
                    '🚪 KELUAR DARI AKUN',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Nebula.rose,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}