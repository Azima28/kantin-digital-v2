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
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';


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
    bool obscure = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: ctx.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ctx.dividerCol, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: ctx.shadowColor,
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Nebula.teal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppStrings.adminChangePassword,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: ctx.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: obscure,
                    style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Masukkan sandi baru',
                      hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: ctx.surfaceBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ctx.dividerCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ctx.dividerCol),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setLocal(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _passwordController.clear();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: ctx.dividerCol),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.buttonCancel,
                            style: GoogleFonts.inter(
                              color: ctx.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _changePassword(profileId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.buttonSave,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentAsync = ref.watch(adminParentDetailProvider(widget.parentId));

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
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 400),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ctx.cardBg,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: ctx.dividerCol, width: 0.8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ctx.shadowColor,
                                        blurRadius: 24,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Nebula.teal.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.devices_rounded, color: Nebula.teal, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              AppStrings.adminSessionActiveLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: ctx.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        '1 Sesi aktif di perangkat mobile.',
                                        style: GoogleFonts.inter(fontSize: 13.5, color: ctx.textSecondary),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Nebula.teal,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                    onPressed: () async {
                      final confirmed = await showAppConfirmationDialog(
                        context,
                        title: isAccountActive ? 'Nonaktifkan Akun' : 'Aktifkan Akun',
                        message: isAccountActive
                            ? 'Apakah Anda yakin ingin menonaktifkan akun orang tua ini?'
                            : 'Apakah Anda yakin ingin mengaktifkan kembali akun orang tua ini?',
                        confirmLabel: isAccountActive ? AppStrings.adminNonaktifkan : AppStrings.adminAktifkan,
                        isDestructive: isAccountActive,
                        icon: isAccountActive ? Icons.person_off_rounded : Icons.person_rounded,
                      );

                      if (confirmed) {
                        _toggleDisableParentAccount(profile.id, isAccountActive);
                      }
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