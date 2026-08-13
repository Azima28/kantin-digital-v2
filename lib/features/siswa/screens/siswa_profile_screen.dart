import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/core/widgets/change_password_panel.dart';
import 'package:kantin_digital/core/widgets/theme_toggle_tile.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_profile_header.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_profile_helpers.dart';

class SiswaProfileScreen extends ConsumerWidget {
  const SiswaProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final isDark = context.isDark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF242424) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Nebula.rose.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Nebula.rose,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Keluar dari Akun',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Apakah Anda yakin ingin keluar dari akun siswa ini?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        AppStrings.buttonCancel,
                        style: GoogleFonts.poppins(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.rose,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                      child: Text(
                        AppStrings.buttonLogout,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
    );
  }

  void _showChangePasswordPanel(BuildContext context, WidgetRef ref) {
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

  Future<void> _handleAvatarChange(BuildContext context, WidgetRef ref) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Ubah Foto Profil'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadAvatar(context, ref, ImageSource.camera);
            },
            child: const Text('Ambil Foto dari Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadAvatar(context, ref, ImageSource.gallery);
            },
            child: const Text('${AppStrings.buttonSelect} dari Galeri'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text(AppStrings.buttonCancel),
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final authState = ref.read(authNotifierProvider);
    final String? userId = authState.profile?['id'];
    if (userId == null) return;

    final client = ref.read(supabaseClientProvider);
    final storageService = StorageService(client);

    final imageFile = await storageService.pickImage(source: source);
    if (imageFile == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengupload foto...'),
          duration: Duration(seconds: 60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      await storageService.uploadAvatar(userId: userId, imageFile: imageFile);
      ref.invalidate(siswaStudentProvider);
      if (context.mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil Disimpan',
          message: 'Foto profil Anda telah aman diperbarui.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} upload foto: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(siswaStudentProvider);
    final authState = ref.watch(authNotifierProvider);
    final parentContactAsync = ref.watch(siswaParentContactProvider);
    final String fullName =
        authState.profile?['full_name'] ?? AppStrings.adminStudents;
    final String email = authState.profile?['email'] ?? '';
    final String nis = authState.profile?['nisn'] ?? email.split('@').first;

    final String parentEmail = parentContactAsync.maybeWhen(
      data: (data) => data?['email'] ?? 'budi.subarjo@gmail.com',
      orElse: () => 'budi.subarjo@gmail.com',
    );
    final String parentPhone = parentContactAsync.maybeWhen(
      data: (data) => data?['phone'] ?? '08123456789',
      orElse: () => '08123456789',
    );

    final String? avatarUrl = authState.profile?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: studentAsync.when(
        data: (student) {
          final String studentClass = student?.class_ ?? '8-B';

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Akun',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile Card
                      SiswaProfileHeader(
                        fullName: fullName,
                        nis: nis,
                        studentClass: studentClass,
                        avatarUrl: avatarUrl,
                        onAvatarTap: () => _handleAvatarChange(context, ref),
                      ),
                      const SizedBox(height: 24),

                      // Kontak Orang Tua
                      buildSectionHeader(context, 'KONTAK ORANG TUA'),
                      const SizedBox(height: 8),
                      buildProfileCard(context, 
                        child: Column(
                          children: [
                            buildIconRow(context, 
                              icon: CupertinoIcons.envelope,
                              iconColor: context.textSecondary,
                              label: 'Email',
                              value: parentEmail,
                              showDivider: true,
                            ),
                            buildIconRow(context, 
                              icon: CupertinoIcons.phone,
                              iconColor: context.textSecondary,
                              label: 'No. HP',
                              value: parentPhone,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const GradientLine(),

                      // Keamanan & Akses
                      buildSectionHeader(context, 'KEAMANAN & AKSES'),
                      const SizedBox(height: 8),
                      buildProfileCard(context, 
                        child: Column(
                          children: [
                            const ThemeToggleTile(showDivider: true),
                            buildIconActionRow(context, 
                              icon: CupertinoIcons.lock,
                              iconColor: context.textSecondary,
                              label: 'Ubah Sandi Akun',
                              onTap: () =>
                                  _showChangePasswordPanel(context, ref),
                              showDivider: true,
                            ),
                            buildIconActionRow(context, 
                              icon: CupertinoIcons.square_arrow_right,
                              iconColor: Nebula.rose,
                              label: 'Keluar dari Akun',
                              textColor: Nebula.rose,
                              onTap: () => _handleLogout(context, ref),
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CupertinoActivityIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            '${AppStrings.labelFailed} memuat profil: $err',
            style: const TextStyle(color: Nebula.rose),
          ),
        ),
      ),
    );
  }
}
