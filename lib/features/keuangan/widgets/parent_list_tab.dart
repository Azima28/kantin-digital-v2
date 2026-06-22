import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// ── Parents Tab ─────────────────────────────────────────────────────────────

class ParentsTab extends ConsumerWidget {
  final String searchQuery;
  const ParentsTab({required this.searchQuery, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(keuanganParentsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganParentsProvider),
      color: AppColors.darkTeal,
      child: parentsAsync.when(
        data: (list) {
          final profiles = list
              .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          final pending = profiles.where((p) => p.isActive != true).toList();

          final filtered = profiles.where((p) {
            final name = (p.fullName ?? '').toLowerCase();
            final email = (p.email ?? '').toLowerCase();
            return name.contains(searchQuery) || email.contains(searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(
              'Tidak ada orang tua yang terdaftar.',
              'Akun orang tua otomatis terbuat saat data siswa baru didaftarkan.',
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Pending verification section
              if (pending.isNotEmpty && searchQuery.isEmpty) ...[
                _sectionHeader('⚠️  PERLU VERIFIKASI (${pending.length})'),
                const SizedBox(height: 8),
                ...pending.map(
                  (p) => _buildParentCard(context, ref, p, isPending: true),
                ),
                const SizedBox(height: 20),
              ],
              // All active parents
              _sectionHeader('SEMUA ORANG TUA (${filtered.length})'),
              const SizedBox(height: 8),
              ...filtered.map(
                (p) => _buildParentCard(context, ref, p, isPending: false),
              ),
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
                  onPressed: () => ref.invalidate(keuanganParentsProvider),
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

  Widget _buildParentCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile parent, {
    required bool isPending,
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
                            _rejectParent(context, ref, parent.id, name),
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
                            _verifyParent(context, ref, parent.id, name),
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
  ) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client
          .from('profiles')
          .update({'is_active': true})
          .eq('id', parentId);
      ref.invalidate(keuanganParentsProvider);
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
  ) async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tolak Pendaftaran'),
        content: Text('Tolak pendaftaran orang tua "$name"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              final client = ref.read(supabaseClientProvider);
              try {
                await client
                    .from('profiles')
                    .update({'is_active': false})
                    .eq('id', parentId);
                ref.invalidate(keuanganParentsProvider);
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
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}
