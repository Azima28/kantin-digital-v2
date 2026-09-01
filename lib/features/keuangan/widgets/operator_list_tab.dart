import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';

// ── Staff/Operator Tab ──────────────────────────────────────────────────────

class StaffTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const StaffTab({required this.searchQuery, super.key});

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab> {
  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant StaffTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _displayLimit = 10;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 60) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayLimit += 10;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(keuanganStaffProvider);
    const fmt = AppNumberFormat(symbol: 'Rp ');

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganStaffProvider),
      color: Nebula.teal,
      child: staffAsync.when(
        data: (list) {
          final profiles = list
              .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          final filtered = profiles.where((s) {
            final name = (s.fullName ?? '').toLowerCase();
            final uname = (s.username ?? '').toLowerCase();
            return name.contains(widget.searchQuery) || uname.contains(widget.searchQuery);
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
            return _buildEmptyState(context);
          }

          final displayed = filtered.take(_displayLimit).toList();
          final bool hasMore = _displayLimit < filtered.length;

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _sectionHeader(
                context,
                hasMore
                    ? 'PETUGAS AKTIF (${displayed.length}/${filtered.length})'
                    : 'PETUGAS AKTIF (${filtered.length})',
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.dividerCol,
                    width: 0.8,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayed.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1.0,
                    color: context.dividerCol,
                    indent: 14,
                    endIndent: 14,
                  ),
                  itemBuilder: (context, index) {
                    final s = displayed[index];
                    return _buildStaffCard(
                      context,
                      ref,
                      s,
                      fmt,
                      canteenData: rawItems[s.id]?['canteen_operators']
                          as Map<String, dynamic>?,
                      isFirst: index == 0,
                      isLast: index == displayed.length - 1,
                    );
                  },
                ),
              ),
              if (_isLoadingMore) ...[
                const SizedBox(height: 14),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Nebula.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memuat data berikutnya...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Nebula.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (hasMore) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Gulir ke bawah untuk memuat ${filtered.length - displayed.length} petugas lainnya...',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 6,
          itemBuilder: (context, index) => const SkeletonListTile(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
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

  Widget _sectionHeader(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 1.1,
      ),
    ),
  );

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.person_badge_plus_fill,
          size: 64,
          color: context.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada petugas kantin.',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tambahkan petugas dengan tombol [+] di atas.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.textSecondary,
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
    AppNumberFormat fmt, {
    required Map<String, dynamic>? canteenData,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final name = staff.fullName ?? 'Petugas';
    final isActive = staff.isActive == true;

    final canteenName = canteenData?['canteen_name'] ?? 'Belum Ada Stan';
    final omzet =
        (canteenData?['balance_earned'] as num?)?.toInt() ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/finance/users/merchant/${staff.id}');
        },
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AppAvatar(
                radius: 22,
                photoUrl: staff.avatarUrl,
                role: 'canteen',
                name: name,
                gender: staff.gender,
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
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      canteenName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Omzet: ${fmt.format(omzet)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
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
                          ? Nebula.teal.withValues(alpha: 0.1)
                          : context.dividerCol,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'AKTIF' : 'OFF',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Nebula.teal
                            : context.textSecondary,
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
                        color: Nebula.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NONAKTIF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Nebula.rose,
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
