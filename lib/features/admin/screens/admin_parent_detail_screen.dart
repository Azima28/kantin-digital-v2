import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';

class AdminParentDetailScreen extends ConsumerStatefulWidget {
  final String parentId;
  const AdminParentDetailScreen({super.key, required this.parentId});

  @override
  ConsumerState<AdminParentDetailScreen> createState() => _AdminParentDetailScreenState();
}

class _AdminParentDetailScreenState extends ConsumerState<AdminParentDetailScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(String profileId) async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) return;

    final client = ref.read(supabaseClientProvider);
    try {
      // Client-side role check before RPC call
      final currentUserRole = ref.read(authNotifierProvider).profile?['role'];
      if (currentUserRole != 'super_admin' && currentUserRole != 'admin' && currentUserRole != 'petugas_keuangan') {
        throw Exception('Tidak memiliki izin untuk mengubah password');
      }

      await client.rpc('update_auth_user_password', params: {
        'p_user_id': profileId,
        'p_new_password': password,
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPasswordUpdated),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah kata sandi'),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleDisableParentAccount(String profileId, bool currentStatus) async {
    final client = ref.read(supabaseClientProvider);
    final bool newStatus = !currentStatus;

    try {
      await client.from('profiles').update({'is_active': newStatus}).eq('id', profileId);
      ref.invalidate(adminParentDetailProvider(widget.parentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun orang tua berhasil ' '${newStatus ? AppStrings.successCardActivatedBack : AppStrings.adminNonaktifkan}' '.'),
            backgroundColor: newStatus ? AppColors.successGreen : AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailedDeactivate),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(String profileId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(AppStrings.adminChangePassword),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: _passwordController,
            placeholder: 'Masukkan sandi baru',
            obscureText: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            isDestructiveAction: true,
            onPressed: () => _changePassword(profileId),
            child: const Text(AppStrings.buttonSave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentAsync = ref.watch(parentParentDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.darkTeal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profil Orang Tua',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
      ),
      body: parentAsync.when(
        data: (data) {
          final profile = data.profile;
          final List<Map<String, dynamic>> children = data.children;

          final String fullName = profile.fullName ?? '';
          final String email = profile.email ?? '';
          final String phone = profile.phoneNumber ?? '-';
          final bool isAccountActive = profile.isActive ?? true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
                        child: const Icon(CupertinoIcons.person_2_fill, color: AppColors.darkTeal, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.darkTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Orang Tua Wali',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContactRow(CupertinoIcons.mail, email),
                      const SizedBox(height: 10),
                      _buildContactRow(CupertinoIcons.phone, phone),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Data Anak Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Data Anak',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.nearBlack,
                            ),
                          ),
                          const Icon(CupertinoIcons.group, color: AppColors.textGray),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (children.isEmpty)
                        Text(
                          'Belum ada data anak yang ditautkan ke orang tua ini.',
                          style: GoogleFonts.inter(color: AppColors.textGray, fontSize: 13),
                        )
                      else
                        Column(
                          children: children.map((c) {
                            final String studentId = c['student_id'] ?? '';
                            final studentInfo = c['students'] ?? {};
                            final String classStr = studentInfo['class'] ?? '-';
                            final profileInfo = studentInfo['profiles'] ?? {};
                            final String childName = profileInfo['full_name'] ?? AppStrings.adminStudents;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
                                      child: const Icon(CupertinoIcons.person, color: AppColors.darkTeal, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            childName,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.nearBlack,
                                            ),
                                          ),
                                          Text(
                                            'Kelas $classStr',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.successGreen),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Navigate shortcut to child
                                InkWell(
                                  onTap: () => context.push('/admin/users/student/$studentId'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkTeal.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.darkTeal.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '👉 LIHAT DETAIL AKUN SISWA',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.darkTeal,
                                          ),
                                        ),
                                        const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.darkTeal),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Security Settings
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Keamanan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityItem(
                        icon: CupertinoIcons.lock_shield,
                        title: AppStrings.adminChangePassword,
                        onTap: () => _showChangePasswordDialog(profile.id),
                      ),
                      const Divider(height: 20, thickness: 0.5, color: AppColors.borderGray),
                      _buildSecurityItem(
                        icon: CupertinoIcons.device_phone_portrait,
                        title: AppStrings.adminSessionActiveLabel,
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text(AppStrings.adminSessionActiveLabel),
                              content: const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('1 Sesi aktif di perangkat iOS (iPhone 15 Pro Max).'),
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Tutup'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Danger Zone Action
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.errorLightColor, width: 1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: Text(isAccountActive ? 'Nonaktifkan Akun' : 'Aktifkan Akun'),
                          content: Text(
                            isAccountActive 
                                ? 'Apakah Anda yakin ingin menonaktifkan akun orang tua ini?' 
                                : 'Apakah Anda yakin ingin mengaktifkan kembali akun orang tua ini?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text(AppStrings.buttonCancel),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                Navigator.pop(ctx);
                                _toggleDisableParentAccount(profile.id, isAccountActive);
                              },
                              child: Text(isAccountActive ? AppStrings.adminNonaktifkan : AppStrings.adminAktifkan),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      isAccountActive ? CupertinoIcons.minus_circle : CupertinoIcons.checkmark_seal,
                      color: AppColors.errorRed2,
                    ),
                    label: Text(
                      isAccountActive ? 'Nonaktifkan Akun Orang Tua' : 'Aktifkan Kembali Akun Orang Tua',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorRed2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminParentDetailProvider(widget.parentId)),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper properties getter to make refactoring provider simple
  ProviderListenable<AsyncValue<AdminParentDetail>> get parentParentDetailProvider =>
      adminParentDetailProvider(widget.parentId);

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textGray),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.lightGray,
                  child: Icon(icon, size: 16, color: AppColors.mutedGray),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.nearBlack,
                  ),
                ),
              ],
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
