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

class _StudentsTabState extends ConsumerState<StudentsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'Semua';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final statusVal = _selectedStatus == 'Diblokir' ? 'Akun Diblokir' : _selectedStatus;
      final filter = PaginatedStudentsFilter(
        statusFilter: statusVal,
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
    super.build(context);
    final statusVal = _selectedStatus == 'Diblokir' ? 'Akun Diblokir' : _selectedStatus;
    final filter = PaginatedStudentsFilter(
      statusFilter: statusVal,
      searchQuery: widget.searchQuery,
    );
    final studentsState = ref.watch(paginatedStudentsProvider(filter));
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(paginatedStudentsProvider(filter)),
      color: AppColors.darkTeal,
      child: Builder(
        builder: (context) {
          if (studentsState.isLoading) {
            return const Center(
              child: CupertinoActivityIndicator(color: AppColors.darkTeal),
            );
          }

          if (studentsState.error != null && studentsState.items.isEmpty) {
            return Center(
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
                      onPressed: () => ref.invalidate(paginatedStudentsProvider(filter)),
                      child: const Text(AppStrings.buttonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = studentsState.items;
          final List<Widget> children = [
            // Dropdown Status Filter
            KeuanganStatusFilter(
              selectedStatus: _selectedStatus,
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                });
              },
            ),
          ];

          if (filtered.isEmpty) {
            children.add(
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
              ),
            );
          } else {
            children.add(_sectionHeader('SEMUA SISWA (${filtered.length})'));
            children.add(const SizedBox(height: 8));
            children.addAll(filtered.map(
              (student) => KeuanganStudentCard(
                student: student,
                fmt: fmt,
              ),
            ));
            if (studentsState.isLoadingMore) {
              children.add(
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                  ),
                ),
              );
            }
          }

          return ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: children,
          );
        },
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
