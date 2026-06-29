import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/custom_confirm_dialog.dart';

// ── Parents Tab ─────────────────────────────────────────────────────────────

class ParentsTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const ParentsTab({required this.searchQuery, super.key});

  @override
  ConsumerState<ParentsTab> createState() => _ParentsTabState();
}

class _ParentsTabState extends ConsumerState<ParentsTab>
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
        role: 'parent',
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
      role: 'parent',
      searchQuery: widget.searchQuery,
    );
    final profilesState = ref.watch(paginatedProfilesProvider(filter));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(paginatedProfilesProvider(filter)),
      color: AppColors.darkTeal,
      child: Builder(
        builder: (context) {
          if (profilesState.isLoading) {
            return const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal));
          }

          if (profilesState.error != null && profilesState.items.isEmpty) {
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
                      onPressed: () => ref.invalidate(paginatedProfilesProvider(filter)),
                      child: const Text(AppStrings.buttonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final profiles = profilesState.items;
          final pending = profiles.where((p) => p.isActive != true).toList();

          if (profiles.isEmpty) {
            return _buildEmptyState(
              'Tidak ada orang tua yang terdaftar.',
              'Akun orang tua otomatis terbuat saat data siswa baru didaftarkan.',
            );
          }

          final List<Widget> children = [];

          // Pending verification section
          if (pending.isNotEmpty && widget.searchQuery.isEmpty) {
            children.add(_sectionHeader('⚠️  PERLU VERIFIKASI (${pending.length})'));
            children.add(const SizedBox(height: 8));
            children.addAll(pending.map(
              (p) => _buildParentCard(context, ref, p, isPending: true, filter: filter),
            ));
            children.add(const SizedBox(height: 20));
          }

          // All active parents
          children.add(_sectionHeader('SEMUA ORANG TUA (${profiles.length})'));
          children.add(const SizedBox(height: 8));
          children.addAll(profiles.map(
            (p) => _buildParentCard(context, ref, p, isPending: false, filter: filter),
          ));

          if (profilesState.isLoadingMore) {
            children.add(
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                ),
              ),
            );
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

  Widget _buildParentCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile parent, {
    required bool isPending,
    required PaginatedProfilesFilter filter,
  }) {
    final name = parent.fullName ?? 'Orang Tua';
    final email = parent.email ?? '-';
    final isActive = parent.isActive == true;
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name[0].toUpperCase();

    return GestureDetector(
      onTap: () {
        context.push('/finance/users/parent/${parent.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPending
              ? Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1)
              : null,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isPending
                        ? Colors.amber.withValues(alpha: 0.1)
                        : AppColors.darkTeal.withValues(alpha: 0.08),
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPending ? Colors.amber : AppColors.darkTeal,
                      ),
                    ),
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
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.mutedGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    _statusBadge('PENDING', Colors.amber)
                  else if (isActive)
                    _statusBadge('AKTIF', AppColors.successGreen)
                  else
                    _statusBadge('DIBLOKIR', AppColors.errorRed2),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed2,
                          side: const BorderSide(color: AppColors.errorRed2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () =>
                            _rejectParent(context, ref, parent.id, name, filter),
                        child: Text(
                          'TOLAK',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () =>
                            _verifyParent(context, ref, parent.id, name, filter),
                        child: Text(
                          'VERIFIKASI',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );

  Widget _buildEmptyState(String title, String subtitle) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.person_2,
          size: 64,
          color: AppColors.mutedGray,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.mutedGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Future<void> _verifyParent(
    BuildContext context,
    WidgetRef ref,
    String parentId,
    String name,
    PaginatedProfilesFilter filter,
  ) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client
          .from('profiles')
          .update({'is_active': true})
          .eq('id', parentId);
      ref.invalidate(paginatedProfilesProvider(filter));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name berhasil diverifikasi'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.labelFailed), backgroundColor: AppColors.errorRed2),
        );
      }
    }
  }

  Future<void> _rejectParent(
    BuildContext context,
    WidgetRef ref,
    String parentId,
    String name,
    PaginatedProfilesFilter filter,
  ) async {
    final confirmed = await showCustomConfirmDialog(
      context: context,
      title: 'Tolak Pendaftaran',
      message: 'Tolak pendaftaran orang tua "$name"?',
      confirmLabel: 'Tolak',
      cancelLabel: AppStrings.buttonCancel,
      isDestructive: true,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed && context.mounted) {
      final client = ref.read(supabaseClientProvider);
      try {
        await client
            .from('profiles')
            .update({'is_active': false})
            .eq('id', parentId);
        ref.invalidate(paginatedProfilesProvider(filter));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pendaftaran $name ditolak'),
              backgroundColor: AppColors.errorRed2,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.labelFailed),
              backgroundColor: AppColors.errorRed2,
            ),
          );
        }
      }
    }
  }
}
