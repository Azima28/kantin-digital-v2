import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Screen yang ditampilkan ketika user tidak memiliki hak akses
/// ke suatu halaman (role mismatch atau session invalid).
class UnauthorizedScreen extends ConsumerWidget {
  const UnauthorizedScreen({super.key});

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'petugas_keuangan':
        return 'Petugas Keuangan';
      case 'petugas_kantin':
        return 'Petugas Kantin (POS)';
      case 'student':
        return 'Siswa';
      case 'parent':
        return 'Orang Tua';
      default:
        return 'Tamu / Belum Login';
    }
  }

  void _navigateHome(BuildContext context, AuthState authState) {
    final role = authState.profile?['role'] as String?;
    if (!authState.isAuthenticated) {
      context.go('/login');
      return;
    }

    if (role == 'super_admin' || role == 'admin') {
      context.go('/admin');
    } else if (role == 'petugas_keuangan') {
      context.go('/finance');
    } else if (role == 'petugas_kantin') {
      context.go('/pos');
    } else if (role == 'parent') {
      final studentId = authState.profile?['student_id'] as String?;
      if (studentId != null && studentId.isNotEmpty) {
        context.go('/parent/dashboard/$studentId');
      } else {
        context.go('/parent');
      }
    } else {
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.profile?['role'] as String?;
    final fullName = authState.profile?['full_name'] as String? ?? 'Pengguna';
    final roleDisplayName = _getRoleDisplayName(role);

    return Scaffold(
      backgroundColor: context.surfaceBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Nebula.rose.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Nebula.rose.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 44,
                      color: Nebula.rose,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Akses Ditolak',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Anda tidak memiliki wewenang untuk mengakses halaman ini dengan peran akun saat ini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                if (authState.isAuthenticated) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.dividerCol, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Nebula.teal.withValues(alpha: 0.15),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            size: 14,
                            color: Nebula.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Peran Aktif: $roleDisplayName',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Nebula.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateHome(context, authState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      authState.isAuthenticated
                          ? 'Kembali ke Beranda Utama'
                          : 'Kembali ke Login',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (authState.isAuthenticated) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.dividerCol, width: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Keluar / Ganti Akun',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
