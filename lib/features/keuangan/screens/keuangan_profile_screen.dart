import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/core/widgets/change_password_panel.dart';
import 'package:kantin_digital/core/widgets/theme_toggle_tile.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/app_image_picker_sheet.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';

class KeuanganProfileScreen extends ConsumerStatefulWidget {
  const KeuanganProfileScreen({super.key});

  @override
  ConsumerState<KeuanganProfileScreen> createState() => _KeuanganProfileScreenState();
}

class _KeuanganProfileScreenState extends ConsumerState<KeuanganProfileScreen> {

  Future<void> _handleAvatarChange() async {
    await showAppImagePickerBottomSheet(
      context,
      title: 'Ubah Foto Profil Petugas',
      onSourceSelected: (source) => _uploadAvatar(source),
    );
  }

  Future<void> _uploadAvatar(ImageSource source) async {
    final authState = ref.read(authNotifierProvider);
    final String? userId = authState.profile?['id'];
    if (userId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final storageService = StorageService(apiClient);

    final imageFile = await storageService.pickImage(source: source);
    if (imageFile == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengupload foto profil...'),
          duration: Duration(seconds: 60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      final avatarUrl = await storageService.uploadAvatar(
        userId: userId,
        imageFile: imageFile,
      );

      await ref.read(authNotifierProvider.notifier).updateProfileAvatar(avatarUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload foto: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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

  Future<void> _handleLogout() async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed && mounted) {
      final router = GoRouter.of(context);
      await ref.read(authNotifierProvider.notifier).logout();
      router.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).profile;
    final acadSchool = ref.watch(academicStructureProvider).valueOrNull?.schoolName;
    final fullName = profile?['full_name'] ?? 'Admin Keuangan';
    final email = profile?['email'] ?? '-';
    final username = profile?['username'] ?? 'budi_fin';
    final school = acadSchool?.isNotEmpty == true
        ? acadSchool!
        : (profile?['assigned_school'] ?? 'Sekolah Digital');
    final String? avatarUrl = profile?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Avatar Bento Card with Camera Button ───
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
                    GestureDetector(
                      onTap: _handleAvatarChange,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Nebula.teal.withValues(alpha: 0.1),
                              border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 2),
                            ),
                            child: ClipOval(
                              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Nebula.teal,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Nebula.teal,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.borderLight, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.camera_fill,
                                size: 14,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ],
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
                  children: [
                    _buildInfoTile('Username', username, context),
                    _buildDivider(context),
                    _buildInfoTile('Email', email, context),
                    _buildDivider(context),
                    _buildInfoTile('Unit Sekolah', school, context),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Display Mode Toggle Tile ───
              const ThemeToggleTile(),
              const SizedBox(height: 16),

              // ─── Actions & Security Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
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
                    _buildActionItem(
                      icon: CupertinoIcons.lock_shield,
                      title: 'Ubah Kata Sandi',
                      onTap: _showChangePasswordDialog,
                      context: context,
                    ),
                    _buildDivider(context),
                    _buildActionItem(
                      icon: CupertinoIcons.square_arrow_right,
                      title: 'Keluar',
                      isDestructive: true,
                      onTap: _handleLogout,
                      context: context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Nebula.rose : Nebula.teal,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Nebula.rose : context.textPrimary,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: context.textSecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: context.dividerCol,
    );
  }
}
