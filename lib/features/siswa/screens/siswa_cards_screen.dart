/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/widgets/hallmark_card.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

/// Hallmark Siswa Cards Management Screen
class SiswaCardsScreen extends ConsumerWidget {
  const SiswaCardsScreen({super.key});

  Future<void> _toggleCardStatus(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    bool currentStatus,
  ) async {
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

                await client
                    .from('students')
                    .update({'is_active': !currentStatus})
                    .eq('id', studentId);

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
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppStrings.labelFailed} memperbarui kartu: $e'),
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
    final colors = context.colors;
    final studentAsync = ref.watch(siswaStudentProvider);
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? AppStrings.adminStudents;
    final String email = authState.profile?['email'] ?? '';
    final String nis = email.split('@').first;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        title: Text(
          'Manajemen Kartu',
          style: HallmarkTypography.titleL3(colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: colors.borderTactile, width: 0.5),
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
              padding: const EdgeInsets.all(20.0),
              child: studentAsync.when(
                data: (student) {
                  if (student == null) {
                    return Center(
                      child: Text(
                        'Data kartu tidak tersedia.',
                        style: HallmarkTypography.bodyMain(colors.textMuted),
                      ),
                    );
                  }

                  final String rfidUid = student.rfidUid ?? 'BELUM DIHUBUNGKAN';
                  final String studentClass = student.class_ ?? '8-B';
                  final bool isActive = student.isActive;
                  final String studentId = student.id;

                  return Column(
                    children: [
                      const SizedBox(height: 8),

                      // Hallmark Digital Card Specimen
                      Container(
                        width: double.infinity,
                        height: 200,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.brandPrimary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.brandPrimary.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'KARTU SISWA DIGITAL',
                                  style: HallmarkTypography.labelButton(colors.brandPrimary),
                                ),
                                Icon(
                                  CupertinoIcons.wifi,
                                  color: colors.brandPrimary,
                                  size: 20,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: HallmarkTypography.headingL2(colors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIS: $nis • Kelas $studentClass',
                                  style: HallmarkTypography.bodySmall(colors.textMuted),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'UID: $rfidUid',
                                  style: HallmarkTypography.financialNumeral(
                                    color: colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isActive ? colors.statusSuccess : colors.statusError)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: (isActive ? colors.statusSuccess : colors.statusError)
                                          .withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktif' : 'Beku',
                                    style: HallmarkTypography.bodySmall(
                                      isActive ? colors.statusSuccess : colors.statusError,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Hallmark Settings Tile Card
                      HallmarkCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isActive ? colors.statusError : colors.statusSuccess)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isActive ? CupertinoIcons.lock : CupertinoIcons.lock_open,
                                color: isActive ? colors.statusError : colors.statusSuccess,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bekukan Sementara',
                                    style: HallmarkTypography.titleSmall(colors.textPrimary),
                                  ),
                                  Text(
                                    'Kunci kartu agar tidak bisa digunakan jajan.',
                                    style: HallmarkTypography.bodySmall(colors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoSwitch(
                              value: !isActive,
                              activeTrackColor: colors.statusError,
                              onChanged: (bool val) {
                                _toggleCardStatus(context, ref, studentId, isActive);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Shimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.borderTactile, width: 0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      HallmarkCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                SkeletonBox(width: 80, height: 14, borderRadius: 4),
                                SkeletonBox(width: 60, height: 22, borderRadius: 8),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                SkeletonBox(width: 60, height: 12, borderRadius: 4),
                                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      HallmarkCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                                SizedBox(height: 6),
                                SkeletonBox(width: 180, height: 11, borderRadius: 4),
                              ],
                            ),
                            const SkeletonBox(width: 50, height: 30, borderRadius: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    '${AppStrings.labelFailed} memuat status kartu',
                    style: HallmarkTypography.bodyMain(colors.statusError),
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
