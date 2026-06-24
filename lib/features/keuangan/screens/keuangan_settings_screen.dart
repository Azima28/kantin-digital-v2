import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class KeuanganSettingsScreen extends ConsumerStatefulWidget {
  const KeuanganSettingsScreen({super.key});

  @override
  ConsumerState<KeuanganSettingsScreen> createState() => _KeuanganSettingsScreenState();
}

class _KeuanganSettingsScreenState extends ConsumerState<KeuanganSettingsScreen> {

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
                            final response = await client.rpc('update_auth_user_password', params: {
                              'p_user_id': profileId,
                              'p_new_password': password,
                              'p_caller_id': profileId,
                            });
                            if (response is Map && response['success'] == false) {
                              throw Exception(response['error'] ?? 'Gagal mengubah kata sandi');
                            }

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
    final username = profile?['username'] ?? '-';
    final school = profile?['assigned_school'] ?? 'SMP Terpadu';
    final phone = profile?['phone'] ?? '-';
    final role = profile?['role'] ?? 'petugas_keuangan';

    // Map role code to human-readable label
    String roleLabel;
    switch (role) {
      case 'petugas_keuangan':
        roleLabel = 'Admin Keuangan';
        break;
      case 'tata_usaha':
        roleLabel = 'Tata Usaha';
        break;
      default:
        roleLabel = 'Admin Keuangan';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.darkTeal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Profile Header Bento Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.darkTeal,
                      AppColors.darkTeal2,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkTeal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent.withValues(alpha: 0.15),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$roleLabel · $school',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Detail Profil Card ───
              _buildSectionCard(
                title: '${AppStrings.titleDetail} Profil',
                icon: CupertinoIcons.person_crop_circle,
                children: [
                  _buildInfoRow(AppStrings.labelFullName, fullName),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildInfoRow('Email', email),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildInfoRow('Username', username),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildInfoRow('No. Telepon', phone),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildInfoRow('Sekolah', school),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildInfoRow('Role', roleLabel),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Keamanan Card ───
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
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.lock_shield, color: AppColors.darkTeal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Keamanan',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.nearBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.darkTeal.withValues(alpha: 0.08),
                        child: const Icon(CupertinoIcons.lock_rotation, color: AppColors.darkTeal, size: 20),
                      ),
                      title: Text(
                        AppStrings.adminChangePassword,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      subtitle: Text(
                        'Terakhir diubah: belum pernah',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedGray,
                        ),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.mutedGray),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Tentang Aplikasi Card ───
              _buildSectionCard(
                title: 'Tentang Aplikasi',
                icon: CupertinoIcons.info_circle,
                children: [
                  _buildInfoRow('Versi', '1.0.0'),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildInfoRow('Platform', 'Kantin Digital'),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Logout Button ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(CupertinoIcons.square_arrow_right, size: 20),
                  label: Text(
                    'Keluar dari Akun',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed2,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppColors.darkTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.nearBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.nearBlack,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
