import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
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
            child: const Text(AppStrings.buttonCancel),
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
                      backgroundColor: !currentStatus ? Nebula.teal : Nebula.rose,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppStrings.labelFailed} memperbarui kartu: $e'),
                      backgroundColor: Nebula.rose,
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
    final String fullName = authState.profile?['full_name'] ?? AppStrings.adminStudents;
    final String email = authState.profile?['email'] ?? '';
    final String nis = email.split('@').first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Manajemen Kartu',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
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

                  final String rfidUid = student.rfidUid ?? 'BELUM DIHUBUNGKAN';
                  final String studentClass = student.class_ ?? '8-B';
                  final bool isActive = student.isActive;
                  final String studentId = student.id;

                   return Column(
                    children: [
                      const SizedBox(height: 10),

                      // RFID Card Replica Widget — Stitch teal gradient
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00C4B4),  // Stitch bright teal
                              Color(0xFF00A896),  // Mid teal
                              Color(0xFF007B6E),  // Deep teal
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C4B4).withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                top: -40,
                                right: -40,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -50,
                                left: -30,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                              ),
                              Padding(
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
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.wifi,
                                            color: Colors.white.withValues(alpha: 0.85),
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
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'NIS: $nis • Kelas $studentClass',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withValues(alpha: 0.85),
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
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.white.withValues(alpha: 0.25)
                                                  : Colors.red.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              isActive ? 'Aktif' : 'Beku',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // IOS List Group
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderLight, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isActive ? Nebula.teal.withValues(alpha: 0.08) : Nebula.rose.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? CupertinoIcons.lock : CupertinoIcons.lock_open,
                                  color: isActive ? Nebula.teal : Nebula.rose,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                'Bekukan Sementara',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Kunci kartu agar tidak bisa digunakan jajan.',
                                style: TextStyle(fontSize: 11, color: context.textSecondary),
                              ),
                              trailing: CupertinoSwitch(
                                value: !isActive,
                                activeTrackColor: Nebula.teal,
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
                    '${AppStrings.labelFailed} memuat status kartu: $err',
                    style: const TextStyle(color: Nebula.rose),
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