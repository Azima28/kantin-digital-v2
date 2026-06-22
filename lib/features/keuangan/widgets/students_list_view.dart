import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

class StudentsListView extends ConsumerWidget {
  final String searchQuery;
  final String selectedClass;
  final String selectedStatus;

  const StudentsListView({
    super.key,
    required this.searchQuery,
    required this.selectedClass,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(keuanganStudentsProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganStudentsProvider),
      color: AppColors.darkTeal,
      child: studentsAsync.when(
        data: (list) {
          // Filter the list
          final filtered = list.where((student) {
            final fullName = student.fullName.toLowerCase();
            final email = (student.email ?? '').toLowerCase();
            final nisn = (student.nisn ?? '').toLowerCase();
            final isAc = student.isActive;

            final sClass = (student.class_ ?? '').toLowerCase();
            final int sBalance = student.balance;
            final rfid = student.rfidUid;

            // Search query matching
            final matchesSearch = fullName.contains(searchQuery) ||
                email.contains(searchQuery) ||
                nisn.contains(searchQuery) ||
                sClass.contains(searchQuery);

            // Class filter matching
            final matchesClass = selectedClass == 'Semua' || student.class_ == selectedClass;

            // Status filter matching
            bool matchesStatus = true;
            if (selectedStatus == 'Aktif') {
              matchesStatus = isAc && rfid != null && rfid.isNotEmpty && student.cardIsActive;
            } else if (selectedStatus == 'Akun Diblokir') {
              matchesStatus = !isAc && rfid != null && rfid.isNotEmpty;
            } else if (selectedStatus == 'Kartu Diblokir') {
              matchesStatus = isAc && !student.cardIsActive && rfid != null && rfid.isNotEmpty;
            } else if (selectedStatus == 'Belum Aktif') {
              matchesStatus = rfid == null || rfid.isEmpty;
            } else if (selectedStatus == 'Saldo Rendah') {
              matchesStatus = sBalance < 5000;
            }

            return matchesSearch && matchesClass && matchesStatus;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 64, color: AppColors.mutedGray),
                  const SizedBox(height: 16),
                  Text(
                    'Siswa tidak ditemukan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nearBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Coba sesuaikan kata kunci pencarian Anda.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mutedGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final student = filtered[index];
              final studentId = student.id;
              final fullName = student.fullName;
              final nisn = student.nisn ?? '-';
              final isActive = student.isActive;

              final sClass = student.class_ ?? 'Belum Diisi';
              final int balance = student.balance;
              final String? rfid = student.rfidUid;
              final hasCard = rfid != null && rfid.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/finance/students/$studentId'),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.darkTeal.withValues(alpha: 0.08),
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Student info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.nearBlack,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NISN: $nisn · Kelas $sClass',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.mutedGray,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (!isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorRed2.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(CupertinoIcons.clear_circled_solid, size: 10, color: AppColors.errorRed2),
                                            const SizedBox(width: 4),
                                            Text(
                                              'AKUN DIBLOKIR',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.errorRed2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (!hasCard)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.borderGray,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(CupertinoIcons.info_circle_fill, size: 10, color: AppColors.mutedGray),
                                            const SizedBox(width: 4),
                                            Text(
                                              'BELUM AKTIF',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.mutedGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (!student.cardIsActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warningYellowLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(CupertinoIcons.exclamationmark_circle_fill, size: 10, color: AppColors.warningYellow),
                                            const SizedBox(width: 4),
                                            Text(
                                              'KARTU DIBLOKIR',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.warningYellow,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.successGreen.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(CupertinoIcons.checkmark_circle_fill, size: 10, color: AppColors.successGreen),
                                            const SizedBox(width: 4),
                                            Text(
                                              'AKTIF',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.successGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Saldo
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Saldo',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.mutedGray,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fmt.format(balance),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: balance < 5000 ? AppColors.errorRed2 : AppColors.nearBlack,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CupertinoActivityIndicator(color: AppColors.darkTeal),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                const SizedBox(height: 12),
                Text('${AppStrings.labelFailed} memuat data'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(keuanganStudentsProvider),
                  child: const Text(AppStrings.buttonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
