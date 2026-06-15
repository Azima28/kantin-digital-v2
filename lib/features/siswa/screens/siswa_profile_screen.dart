import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaProfileScreen extends ConsumerWidget {
  const SiswaProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun siswa ini?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/student/welcome');
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoAlertDialog(
          title: const Text('Ubah Sandi Akun'),
          content: Card(
            color: Colors.transparent,
            elevation: 0,
            margin: const EdgeInsets.only(top: 12),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  CupertinoTextFormFieldRow(
                    controller: oldPasswordController,
                    placeholder: 'Sandi Lama',
                    obscureText: true,
                    style: const TextStyle(fontSize: 14),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Wajib diisi';
                      return null;
                    },
                  ),
                  CupertinoTextFormFieldRow(
                    controller: newPasswordController,
                    placeholder: 'Sandi Baru',
                    obscureText: true,
                    style: const TextStyle(fontSize: 14),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Wajib diisi';
                      if (val.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text('Simpan'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final String oldPwd = oldPasswordController.text;
                final String newPwd = newPasswordController.text;
                
                final authState = ref.read(authNotifierProvider);
                final profileId = authState.profile?['id'];
                
                if (profileId == null) return;

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                
                try {
                  final client = ref.read(supabaseClientProvider);
                  
                  // Verify old password
                  final profile = await client
                      .from('profiles')
                      .select('password')
                      .eq('id', profileId)
                      .single();
                  
                  if (profile['password'] != oldPwd) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Sandi lama yang dimasukkan salah.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    navigator.pop();
                    return;
                  }

                  // Update new password
                  await client
                      .from('profiles')
                      .update({'password': newPwd})
                      .eq('id', profileId);

                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Kata sandi berhasil diperbarui!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengubah kata sandi: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(siswaStudentProvider);
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Siswa';
    final String email = authState.profile?['email'] ?? '';
    final String nis = email.split('@').first;

    const String avatarUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBHY2iWpG2UFhUcpU5RqtgENtU9_Wpve_gbV2HPl_pXpDkZb7Ziws9p-eU8MISdIo5XdX0HQcGL2xl7LD3YpWxYe7Vw07SGnbGEdnIEoafRCkKVJgwMDl2cKIfeBamVdlBJhHjX09AB2sDdBPHpCGNG2L2klMozr_gJgs1Tdr2slsNb1cFtzJffPTpxIlIRgK6H30zyriUVpxCrm5V3ps59kpHps-6p9lq6PrphwMvNrbXGDMBdm8JWr1KipFUKdtK4GMc2TPvjUns';

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          'Akun',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      body: studentAsync.when(
        data: (student) {
          final String studentClass = student?['class'] ?? '8-B';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile avatar header section
                Container(
                  color: AppColors.cardBackground,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE5E5EA),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(CupertinoIcons.person, color: AppColors.primary, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: $nis \u2022 Kelas $studentClass',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: Kontak Orang Tua
                _buildSectionHeader('KONTAK ORANG TUA'),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 0.5),
                      bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Email', 'budi.subarjo@gmail.com', isFirst: true),
                      _buildInfoRow('No. HP', '08123456789', isLast: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Keamanan & Akses
                _buildSectionHeader('KEAMANAN & AKSES'),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 0.5),
                      bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildActionRow(
                        context,
                        'Ubah Sandi Akun',
                        CupertinoIcons.chevron_right,
                        onTap: () => _showChangePasswordDialog(context, ref),
                        isFirst: true,
                      ),
                      _buildActionRow(
                        context,
                        'Keluar dari Akun',
                        CupertinoIcons.chevron_right,
                        textColor: AppColors.error,
                        onTap: () => _handleLogout(context, ref),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
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
          child: Text('Gagal memuat profil: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, right: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    String label,
    IconData icon, {
    Color? textColor,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              icon,
              color: AppColors.textGray.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
