import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/features/keuangan/widgets/keuangan_users_filter.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_users_list.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// ── Students Tab ────────────────────────────────────────────────────────────

class StudentsTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const StudentsTab({required this.searchQuery, super.key});

  @override
  ConsumerState<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<StudentsTab> {
  String _selectedStatus = 'Semua';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(keuanganStudentsProvider);
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganStudentsProvider),
      color: AppColors.darkTeal,
      child: studentsAsync.when(
        data: (list) {
          final filtered = list.where((student) {
            final name = student.fullName.toLowerCase();
            final email = (student.email ?? '').toLowerCase();
            final nisn = (student.nisn ?? '').toLowerCase();
            final studentClass = (student.class_ ?? '').toLowerCase();
            final matchesSearch = name.contains(widget.searchQuery) ||
                email.contains(widget.searchQuery) ||
                nisn.contains(widget.searchQuery) ||
                studentClass.contains(widget.searchQuery);

            bool matchesStatus = true;
            final hasCard = student.hasRfid == true;
            final isAc = student.isActive == true;

            if (_selectedStatus == 'Aktif') {
              matchesStatus = hasCard && isAc;
            } else if (_selectedStatus == 'Belum Aktif') {
              matchesStatus = !hasCard;
            } else if (_selectedStatus == 'Diblokir') {
              matchesStatus = !isAc;
            }

            return matchesSearch && matchesStatus;
          }).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Dropdown Status Filter
              KeuanganStatusFilter(
                selectedStatus: _selectedStatus,
                onChanged: (val) {
                  setState(() {
                    _selectedStatus = val;
                  });
                },
              ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.person_crop_circle_badge_exclam,
                          size: 64,
                          color: AppColors.mutedGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Siswa tidak ditemukan',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.nearBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba sesuaikan kata kunci pencarian atau status filter.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.mutedGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _sectionHeader('SEMUA SISWA (${filtered.length})'),
                const SizedBox(height: 8),
                ...filtered.map(
                  (student) => KeuanganStudentCard(
                    student: student,
                    fmt: fmt,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.xmark_circle,
                  size: 48,
                  color: AppColors.errorRed2,
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppStrings.labelFailed} memuat data',
                  style: GoogleFonts.inter(color: AppColors.errorRed2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
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

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.mutedGray,
        letterSpacing: 1.1,
      ),
    ),
  );
}
