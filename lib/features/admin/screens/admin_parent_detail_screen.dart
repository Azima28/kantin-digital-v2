import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_parent_sheet.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';


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

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/users/password',
        body: {
          'user_id': profileId,
          'new_password': password,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal mengubah kata sandi');
      }

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPasswordUpdated),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah kata sandi: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleDisableParentAccount(String profileId, bool currentStatus) async {
    final bool newStatus = !currentStatus;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/users/$profileId/status', body: {'is_active': newStatus});
      ref.invalidate(adminParentDetailProvider(widget.parentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun orang tua berhasil ' '${newStatus ? AppStrings.successCardActivatedBack : AppStrings.adminNonaktifkan}' '.'),
            backgroundColor: newStatus ? Nebula.teal : Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailedDeactivate),
            backgroundColor: Nebula.rose,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profil Orang Tua',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
          ),
        ),
        actions: [
          parentAsync.maybeWhen(
            data: (data) => IconButton(
              icon: Icon(CupertinoIcons.pencil, color: Nebula.teal),
              onPressed: () => showEditParentSheet(
                context,
                ref,
                data.profile,
                data.children,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
                NebulaCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                        child: Icon(CupertinoIcons.person_2_fill, color: Nebula.teal, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Orang Tua Wali',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
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
                const GradientLine(),
                const SizedBox(height: 12),

                // Data Anak Section
                NebulaCard(
                  padding: const EdgeInsets.all(20),
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
                              color: context.textPrimary,
                            ),
                          ),
                          Icon(CupertinoIcons.group, color: context.textSecondary),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (children.isEmpty)
                        Text(
                          'Belum ada data anak yang ditautkan ke orang tua ini.',
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                        )
                      else
                        Column(
                          children: children.map((c) {
                            final String studentId = c['student_id'] ?? '';
                            final studentInfo = c['students'] ?? {};
                            final String classStr = (studentInfo['class'] ??
                                (studentInfo['classes'] is Map
                                    ? (studentInfo['classes'] as Map)['name']
                                    : null))?.toString() ?? '-';
                            final profileInfo = studentInfo['profiles'] ?? {};
                            final String childName = profileInfo['full_name'] ?? AppStrings.adminStudents;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                                      child: Icon(CupertinoIcons.person, color: Nebula.teal, size: 20),
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
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Kelas $classStr',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(CupertinoIcons.checkmark_circle_fill, color: Nebula.teal),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // Navigate shortcut to child
                                PressScale(
                                  onTap: () => context.push('/admin/users/student/$studentId'),
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Nebula.teal.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Nebula.teal.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '👉 LIHAT DETAIL AKUN SISWA',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Nebula.teal,
                                          ),
                                        ),
                                        Icon(CupertinoIcons.chevron_right, size: 14, color: Nebula.teal),
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
                const GradientLine(),
                const SizedBox(height: 24),

                // Security Settings
                NebulaCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Keamanan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textSecondary,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityItem(
                        icon: CupertinoIcons.lock_shield,
                        title: AppStrings.adminChangePassword,
                        onTap: () => _showChangePasswordDialog(profile.id),
                      ),
                      Divider(height: 20, thickness: 0.5, color: context.dividerCol),
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
                    color: context.cardBg,
                    border: Border.all(color: Nebula.rose.withValues(alpha: 0.1), width: 1),
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
                      color: Nebula.rose,
                    ),
                    label: Text(
                      isAccountActive ? 'Nonaktifkan Akun Orang Tua' : 'Aktifkan Kembali Akun Orang Tua',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Nebula.rose,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Shimmer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            SkeletonBox(width: 80, height: 14, borderRadius: 4),
                            Spacer(),
                            SkeletonBox(width: 120, height: 14, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
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
        Icon(icon, size: 16, color: context.textSecondary),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: context.textSecondary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: PressScale(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: context.cardBg,
                  child: Icon(icon, size: 16, color: context.textSecondary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}