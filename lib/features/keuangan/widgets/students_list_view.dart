import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

class StudentsListView extends ConsumerStatefulWidget {
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
  ConsumerState<StudentsListView> createState() => _StudentsListViewState();
}

class _StudentsListViewState extends ConsumerState<StudentsListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final filter = PaginatedStudentsFilter(
        classFilter: widget.selectedClass,
        statusFilter: widget.selectedStatus,
        searchQuery: widget.searchQuery,
      );
      ref.read(paginatedStudentsProvider(filter).notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = PaginatedStudentsFilter(
      classFilter: widget.selectedClass,
      statusFilter: widget.selectedStatus,
      searchQuery: widget.searchQuery,
    );
    final studentsState = ref.watch(paginatedStudentsProvider(filter));
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(paginatedStudentsProvider(filter)),
      color: AppColors.darkTeal,
      child: Builder(
        builder: (context) {
          if (studentsState.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CupertinoActivityIndicator(color: AppColors.darkTeal),
              ),
            );
          }

          if (studentsState.error != null && studentsState.items.isEmpty) {
            return Center(
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
                      onPressed: () => ref.invalidate(paginatedStudentsProvider(filter)),
                      child: const Text(AppStrings.buttonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final list = studentsState.items;

          if (list.isEmpty) {
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
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: list.length + (studentsState.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == list.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                  ),
                );
              }
              final student = list[index];
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
      ),
    );
  }
}
