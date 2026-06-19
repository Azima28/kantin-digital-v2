import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/shared/screens/officer_activities_screen.dart';

class AdminFinanceDetailScreen extends ConsumerStatefulWidget {
  final String officerId;
  const AdminFinanceDetailScreen({super.key, required this.officerId});

  @override
  ConsumerState<AdminFinanceDetailScreen> createState() => _AdminFinanceDetailScreenState();
}

class _AdminFinanceDetailScreenState extends ConsumerState<AdminFinanceDetailScreen> {
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
            content: Text('Kata sandi petugas keuangan berhasil diperbarui!'),
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
    final detailAsync = ref.watch(adminFinanceDetailProvider(widget.officerId));
    const Color primaryTeal = Color(0xFF003434);
    const Color accentOrange = Color(0xFF904D00);
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
          'Profile Pegawai',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (data) {
          final profile = data.profile;
          final officer = data.officer;
          final List<AuditLog> logs = data.recentLogs;

          final String fullName = profile.fullName ?? '';
          final String username = profile.username ?? '';
          final String authorityLevel = officer['authority_level'] ?? 'L1';
          final List<dynamic> features = officer['features'] ?? [];

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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryTeal.withValues(alpha: 0.1),
                        child: const Icon(CupertinoIcons.person_solid, color: primaryTeal, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1C1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Staf Tata Usaha',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'USN: $username',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6F7978),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Change Password Button
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(profile.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield),
                  label: const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Access Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_user, size: 16, color: AppColors.textGray),
                          SizedBox(width: 6),
                          Text(
                            'TINGKAT AKSES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Officer $authorityLevel',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: features.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.toString(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: primaryTeal),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Audit Logs Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aktivitas Transaksi',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OfficerActivitiesScreen(
                              officerId: widget.officerId,
                              actorName: fullName,
                              primaryColor: primaryTeal,
                              accentColor: accentOrange,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (logs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Belum ada aktivitas transaksi manual.',
                        style: GoogleFonts.beVietnamPro(color: AppColors.textGray),
                      ),
                    ),
                  )
                else
                  Column(
                    children: logs.map((log) {
                      final String actionType = log.actionType;
                      final String desc = log.description;
                      final date = log.createdAt?.toLocal() ?? DateTime.now();

                      // Set specific icon & color for action types
                      IconData logIcon = CupertinoIcons.doc_text;
                      Color logColor = primaryTeal;
                      if (actionType.contains('KOREKSI')) {
                        logIcon = CupertinoIcons.refresh;
                        logColor = accentOrange;
                      } else if (actionType.contains('REGISTRASI')) {
                        logIcon = CupertinoIcons.creditcard;
                        logColor = successGreen;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: logColor.withValues(alpha: 0.1),
                              child: Icon(logIcon, color: logColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        actionType.replaceAll('_', ' '),
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: logColor,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(date),
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
}
