import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Menampilkan Dialog "Tentang SeKantin"
/// Desain minimalis, bersih, dan profesional mengikuti standar Human Interface Guidelines.
Future<void> showAboutSeKantinSheet(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => const _AboutSeKantinDialog(),
  );
}

class _AboutSeKantinDialog extends ConsumerWidget {
  const _AboutSeKantinDialog();

  String _formatRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'student':
      case 'siswa':
        return 'Siswa';
      case 'canteen_operator':
      case 'petugas_kantin':
        return 'Petugas Kantin';
      case 'finance_officer':
      case 'petugas_keuangan':
        return 'Petugas Keuangan';
      case 'parent':
      case 'orang_tua':
        return 'Orang Tua';
      case 'super_admin':
      case 'admin':
        return 'Administrator';
      default:
        return 'Pengguna';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = _formatRole(authState.profile?['role'] as String?);
    final isDark = context.isDark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.dividerCol, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Bar (Close) ──
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 16,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),

              // ── Brand Header ──
              Image.asset(
                isDark
                    ? 'assets/images/app_symbol_dark.png'
                    : 'assets/images/app_symbol_light.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Nebula.teal,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                AppStrings.appName,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                AppStrings.appTagline,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Nebula.teal,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Versi 2.0.0 (Rilis Resmi)',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Sistem transaksi digital kantin sekolah untuk kemudahan jajan dan pengelolaan saldo secara cepat, aman, dan tanpa uang tunai.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // ── Info Group List (Clean & Native) ──
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.dividerCol, width: 0.6),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      context,
                      label: 'Peran Akun',
                      value: userRole,
                      showDivider: true,
                    ),
                    _buildRow(
                      context,
                      label: 'Status Layanan',
                      customValue: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Aktif Online',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      showDivider: true,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/public/info');
                      },
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Panduan & Info Sekolah',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_forward,
                              size: 14,
                              color: context.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Footer ──
              Text(
                '© 2026 SeKantin • Hak Cipta Dilindungi',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: context.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? customValue,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
              ),
              if (customValue != null)
                customValue
              else
                Text(
                  value ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.5, color: context.dividerCol),
      ],
    );
  }
}
