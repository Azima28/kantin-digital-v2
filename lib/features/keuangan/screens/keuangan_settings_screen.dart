import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/change_password_panel.dart';
import 'package:kantin_digital/core/widgets/theme_toggle_tile.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class KeuanganSettingsScreen extends ConsumerStatefulWidget {
  const KeuanganSettingsScreen({super.key});

  @override
  ConsumerState<KeuanganSettingsScreen> createState() => _KeuanganSettingsScreenState();
}

class _KeuanganSettingsScreenState extends ConsumerState<KeuanganSettingsScreen> {
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
        centerTitle: false,
        title: Text(
          'Akun Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Profile Header Bento Card ───
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Nebula.teal,
                      Nebula.tealDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.3),
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
                          color: context.cardBg,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.cardBg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.cardBg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$roleLabel · $school',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.cardBg.withValues(alpha: 0.9),
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
                  Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                  _buildInfoRow('Email', email),
                  Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                  _buildInfoRow('Username', username),
                  Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                  _buildInfoRow('No. Telepon', phone),
                  Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                  _buildInfoRow('Sekolah', school),
                  Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                  _buildInfoRow('Role', roleLabel),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Keamanan Card ───
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
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
                      padding: EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 8),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.lock_shield, color: Nebula.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Keamanan',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ThemeToggleTile(showDivider: true),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                        child: Icon(CupertinoIcons.lock_rotation, color: Nebula.teal, size: 20),
                      ),
                      title: Text(
                        AppStrings.adminChangePassword,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Terakhir diubah: belum pernah',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                      trailing: Icon(CupertinoIcons.chevron_forward, size: 16, color: context.textSecondary),
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
                  Divider(height: 16, thickness: 0.5, color: context.dividerCol),
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
                      color: context.cardBg,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.rose,
                    foregroundColor: context.cardBg,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Icon(icon, color: Nebula.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.textPrimary,
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
            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}