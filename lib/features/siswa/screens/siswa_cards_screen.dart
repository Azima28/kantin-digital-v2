import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaCardsScreen extends ConsumerWidget {
  const SiswaCardsScreen({super.key});

  Future<void> _toggleCardStatus(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    bool currentStatus,
  ) async {
    // Confirmation dialog
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(currentStatus ? 'Bekukan Kartu' : 'Aktifkan Kartu'),
        content: Text(currentStatus
            ? 'Apakah Anda yakin ingin membekukan kartu? Kartu tidak akan bisa digunakan jajan sementara waktu.'
            : 'Apakah Anda yakin ingin mengaktifkan kembali kartu Anda?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: currentStatus,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final client = ref.read(supabaseClientProvider);
                
                // Update active status
                await client
                    .from('students')
                    .update({'is_active': !currentStatus})
                    .eq('id', studentId);

                // Send a notification about freeze
                await client.from('notifications').insert({
                  'student_id': studentId,
                  'title': !currentStatus ? 'Kartu Diaktifkan' : 'Kartu Dibekukan',
                  'message': !currentStatus 
                      ? 'Kartu RFID Anda berhasil diaktifkan kembali.' 
                      : 'Kartu RFID Anda telah dibekukan sementara untuk keamanan.',
                  'type': 'system',
                });

                ref.invalidate(siswaStudentProvider);
                ref.invalidate(siswaNotificationsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(!currentStatus ? 'Kartu berhasil diaktifkan!' : 'Kartu berhasil dibekukan!'),
                      backgroundColor: !currentStatus ? AppColors.success : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui kartu: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(currentStatus ? 'Bekukan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(siswaStudentProvider);
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Siswa';
    final String email = authState.profile?['email'] ?? '';
    final String nis = email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          'Manajemen Kartu',
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaStudentProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: studentAsync.when(
                data: (student) {
                  if (student == null) {
                    return const Center(child: Text('Data kartu tidak tersedia.'));
                  }

                  final String rfidUid = student['rfid_uid'] ?? 'BELUM DIHUBUNGKAN';
                  final String studentClass = student['class'] ?? '8-B';
                  final bool isActive = student['is_active'] ?? true;
                  final String studentId = student['id'];

                  return Column(
                    children: [
                      const SizedBox(height: 10),

                      // RFID Card Replica Widget (Primary Teal color with Squircle design)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF008282)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'KARTU SISWA DIGITAL',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.wifi,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'NIS: $nis \u2022 Kelas $studentClass',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'UID: $rfidUid',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktif' : 'Beku',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // IOS List Group
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primaryLight : AppColors.errorLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? CupertinoIcons.lock : CupertinoIcons.lock_open,
                                  color: isActive ? AppColors.primary : AppColors.error,
                                  size: 16,
                                ),
                              ),
                              title: const Text(
                                'Bekukan Sementara',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              subtitle: const Text(
                                'Kunci kartu agar tidak bisa digunakan jajan.',
                                style: TextStyle(fontSize: 11, color: AppColors.textGray),
                              ),
                              trailing: CupertinoSwitch(
                                value: !isActive,
                                activeTrackColor: AppColors.primary,
                                onChanged: (bool val) {
                                  _toggleCardStatus(context, ref, studentId, isActive);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CupertinoActivityIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Gagal memuat status kartu: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
