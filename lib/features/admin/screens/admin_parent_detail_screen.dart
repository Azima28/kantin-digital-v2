import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final adminParentDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final client = ref.read(supabaseClientProvider);
  
  // 1. Fetch profile
  final profile = await client.from('profiles').select().eq('id', id).single();
  
  // 2. Fetch linked children data
  final List<dynamic> childrenRes = await client
      .from('parent_students')
      .select('student_id, students(class, profiles(full_name))')
      .eq('parent_id', id);
      
  return {
    'profile': profile,
    'children': List<Map<String, dynamic>>.from(childrenRes),
  };
});

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
      await client.from('profiles').update({'password': password}).eq('id', profileId);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi orang tua berhasil diperbarui!'),
            backgroundColor: Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah kata sandi: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
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
            content: Text('Akun orang tua berhasil ${newStatus ? "diaktifkan kembali" : "dinonaktifkan"}.'),
            backgroundColor: newStatus ? const Color(0xFF006A35) : const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menonaktifkan akun: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
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
        title: const Text('Ubah Kata Sandi'),
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
            child: const Text('Batal'),
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _changePassword(profileId),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentAsync = ref.watch(parentParentDetailProvider);
    const Color primaryTeal = Color(0xFF003434);
    const Color successGreen = Color(0xFF006A35);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: primaryTeal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profil Orang Tua',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
      ),
      body: parentAsync.when(
        data: (data) {
          final profile = data['profile'];
          final List<Map<String, dynamic>> children = data['children'];

          final String fullName = profile['full_name'] ?? '';
          final String email = profile['email'] ?? '';
          final String phone = profile['phone_number'] ?? '-';
          final bool isAccountActive = profile['is_active'] ?? true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryTeal.withValues(alpha: 0.1),
                        child: const Icon(CupertinoIcons.person_2_fill, color: primaryTeal, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Orang Tua Wali',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1C1B),
                            ),
                          ),
                          const Icon(CupertinoIcons.group, color: AppColors.textGray),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (children.isEmpty)
                        Text(
                          'Belum ada data anak yang ditautkan ke orang tua ini.',
                          style: GoogleFonts.beVietnamPro(color: AppColors.textGray, fontSize: 13),
                        )
                      else
                        Column(
                          children: children.map((c) {
                            final String studentId = c['student_id'] ?? '';
                            final studentInfo = c['students'] ?? {};
                            final String classStr = studentInfo['class'] ?? '-';
                            final profileInfo = studentInfo['profiles'] ?? {};
                            final String childName = profileInfo['full_name'] ?? 'Siswa';

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: primaryTeal.withValues(alpha: 0.1),
                                      child: const Icon(CupertinoIcons.person, color: primaryTeal, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            childName,
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1B1C1B),
                                            ),
                                          ),
                                          Text(
                                            'Kelas $classStr • SMP Terpadu',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 12,
                                              color: AppColors.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(CupertinoIcons.checkmark_circle_fill, color: successGreen),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Navigate shortcut to child
                                InkWell(
                                  onTap: () => context.push('/admin/users/student/$studentId'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: primaryTeal.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '👉 LIHAT DETAIL AKUN SISWA',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: primaryTeal,
                                          ),
                                        ),
                                        const Icon(CupertinoIcons.chevron_right, size: 14, color: primaryTeal),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityItem(
                        icon: CupertinoIcons.lock_shield,
                        title: 'Ubah Kata Sandi',
                        onTap: () => _showChangePasswordDialog(profile['id']),
                      ),
                      const Divider(height: 20, thickness: 0.5, color: Color(0xFFE4E2E1)),
                      _buildSecurityItem(
                        icon: CupertinoIcons.device_phone_portrait,
                        title: 'Sesi Aktif',
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Sesi Aktif'),
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
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFFFDAD6), width: 1),
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
                              child: const Text('Batal'),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                Navigator.pop(ctx);
                                _toggleDisableParentAccount(profile['id'], isAccountActive);
                              },
                              child: Text(isAccountActive ? 'Nonaktifkan' : 'Aktifkan'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      isAccountActive ? CupertinoIcons.minus_circle : CupertinoIcons.checkmark_seal,
                      color: const Color(0xFFBA1A1A),
                    ),
                    label: Text(
                      isAccountActive ? 'Nonaktifkan Akun Orang Tua' : 'Aktifkan Kembali Akun Orang Tua',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFBA1A1A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // Helper properties getter to make refactoring provider simple
  ProviderListenable<AsyncValue<Map<String, dynamic>>> get parentParentDetailProvider =>
      adminParentDetailProvider(widget.parentId);

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textGray),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3F4848),
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
                  backgroundColor: const Color(0xFFEFEDEC),
                  child: Icon(icon, size: 16, color: const Color(0xFF6F7978)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B1C1B),
                  ),
                ),
              ],
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFBFC8C8)),
          ],
        ),
      ),
    );
  }
}
