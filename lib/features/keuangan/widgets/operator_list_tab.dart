import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// ── Staff/Operator Tab ──────────────────────────────────────────────────────

class StaffTab extends ConsumerWidget {
  final String searchQuery;
  const StaffTab({required this.searchQuery, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(keuanganStaffProvider);
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganStaffProvider),
      color: AppColors.darkTeal,
      child: staffAsync.when(
        data: (list) {
          final profiles = list
              .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          final filtered = profiles.where((s) {
            final name = (s.fullName ?? '').toLowerCase();
            final uname = (s.username ?? '').toLowerCase();
            return name.contains(searchQuery) || uname.contains(searchQuery);
          }).toList();

          // Keep raw data for nested canteen_operators access
          final rawItems = <String, Map<String, dynamic>>{};
          for (final raw in list) {
            final id = raw['id'] as String?;
            if (id != null) {
              rawItems[id] = Map<String, dynamic>.from(raw);
            }
          }

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _sectionHeader('PETUGAS AKTIF (${filtered.length})'),
              const SizedBox(height: 8),
              ...filtered.map((s) => _buildStaffCard(
                context, ref, s, fmt,
                canteenData: rawItems[s.id]?['canteen_operators']
                    as Map<String, dynamic>?,
              )),
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
                const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                const SizedBox(height: 12),
                Text('${AppStrings.labelFailed} memuat'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(keuanganStaffProvider),
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
    NumberFormat fmt, {
    required Map<String, dynamic>? canteenData,
  }) {
    final name = staff.fullName ?? 'Petugas';
    final isActive = staff.isActive == true;
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name[0].toUpperCase();

    final canteenName = canteenData?['canteen_name'] ?? 'Belum Ada Stan';
    final omzet =
        (canteenData?['balance_earned'] as num?)?.toInt() ?? 0;

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
