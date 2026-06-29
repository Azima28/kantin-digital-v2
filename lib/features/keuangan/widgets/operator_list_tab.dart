import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// ── Staff/Operator Tab ──────────────────────────────────────────────────────

class StaffTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const StaffTab({required this.searchQuery, super.key});

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

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
      final filter = PaginatedProfilesFilter(
        role: 'petugas_kantin',
        searchQuery: widget.searchQuery,
      );
      ref.read(paginatedProfilesProvider(filter).notifier).loadNextPage();
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
    final filter = PaginatedProfilesFilter(
      role: 'petugas_kantin',
      searchQuery: widget.searchQuery,
    );
    final staffState = ref.watch(paginatedProfilesProvider(filter));
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(paginatedProfilesProvider(filter)),
      color: AppColors.darkTeal,
      child: Builder(
        builder: (context) {
          if (staffState.isLoading) {
            return const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal));
          }

          if (staffState.error != null && staffState.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                    const SizedBox(height: 12),
                    Text('${AppStrings.labelFailed} memuat'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(paginatedProfilesProvider(filter)),
                      child: const Text(AppStrings.buttonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final profiles = staffState.items;

          if (profiles.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: profiles.length + (staffState.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == profiles.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                  ),
                );
              }
              final s = profiles[index];
              return _buildStaffCard(context, ref, s, fmt);
            },
          );
        },
      ),
    );
  }


  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.person_badge_plus_fill,
          size: 64,
          color: AppColors.mutedGray,
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada petugas kantin.',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tambahkan petugas dengan tombol [+] di atas.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.mutedGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildStaffCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile staff,
    NumberFormat fmt,
  ) {
    final name = staff.fullName ?? 'Petugas';
    final isActive = staff.isActive == true;
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name[0].toUpperCase();

    final canteenName = staff.canteenName ?? 'Belum Ada Stan';
    final omzet = staff.balanceEarned ?? 0;

    return GestureDetector(
      onTap: () {
        context.push('/finance/users/merchant/${staff.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.darkTeal.withValues(alpha: 0.08),
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.darkTeal,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.successGreen
                            : AppColors.borderGray,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.nearBlack,
                      ),
                    ),
                    Text(
                      canteenName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Omzet: ${fmt.format(omzet)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.mutedGray,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : AppColors.borderGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'AKTIF' : 'OFF',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? AppColors.successGreen
                            : AppColors.mutedGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NONAKTIF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorRed2,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
