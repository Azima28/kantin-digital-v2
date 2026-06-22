import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class KeuanganProfileScreen extends ConsumerStatefulWidget {
  const KeuanganProfileScreen({super.key});

  @override
  ConsumerState<KeuanganProfileScreen> createState() => _KeuanganProfileScreenState();
}

class _KeuanganProfileScreenState extends ConsumerState<KeuanganProfileScreen> {

  final _passwordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text(AppStrings.adminChangePassword),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    const Text('Masukkan kata sandi baru untuk akun Anda.'),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Kata sandi baru',
                      obscureText: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.inactiveGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text(AppStrings.buttonCancel),
                  onPressed: () {
                    _passwordController.clear();
                    Navigator.pop(context);
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: _isChangingPassword
                      ? null
                      : () async {
                          final password = _passwordController.text.trim();
                          if (password.isEmpty) return;

                          setDialogState(() {
                            _isChangingPassword = true;
                          });

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(this.context);

                          try {
                            final client = ref.read(supabaseClientProvider);
                            final profile = ref.read(authNotifierProvider).profile;
                            final profileId = profile?['id'];

                            // Client-side role check before RPC call
                            final currentUserRole = profile?['role'];
                            if (currentUserRole != 'super_admin' && currentUserRole != 'admin' && currentUserRole != 'petugas_keuangan') {
                              throw Exception('Tidak memiliki izin untuk mengubah password');
                            }

                            // Update password via RPC
                            await client.rpc('update_auth_user_password', params: {
                              'p_user_id': profileId,
                              'p_new_password': password,
                            });

                            _passwordController.clear();
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.successPasswordChanged),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${AppStrings.labelFailed} mengubah kata sandi'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            setDialogState(() {
                              _isChangingPassword = false;
                            });
                          }
                        },
                  child: _isChangingPassword
                      ? const CupertinoActivityIndicator()
                      : const Text(AppStrings.buttonSave),
                ),
              ],
            );
          },
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
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.darkTeal, fontSize: 18),
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.darkTeal.withValues(alpha: 0.08),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.nearBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin Keuangan · $school',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.mutedGray,
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
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
                        color: AppColors.nearBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Email', email),
                    const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                    _buildInfoRow('Username', username),
                    const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                    _buildInfoRow('Level Otoritas', 'L1 (Operator)'),
                    const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                    _buildInfoRow('Sekolah Asal', school),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Security Options Card ───
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
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
                          color: AppColors.nearBlack,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.darkTeal.withValues(alpha: 0.08),
                        child: const Icon(CupertinoIcons.lock_shield, color: AppColors.darkTeal, size: 20),
                      ),
                      title: Text(
                        AppStrings.adminChangePassword,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.mutedGray),
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
                    backgroundColor: AppColors.errorRed2.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.errorRed2.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Text(
                    '🚪 KELUAR DARI AKUN',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.errorRed2,
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
          style: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
