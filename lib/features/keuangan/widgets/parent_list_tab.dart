import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';

// ── Parents Tab ─────────────────────────────────────────────────────────────

class ParentsTab extends ConsumerWidget {
  final String searchQuery;
  const ParentsTab({required this.searchQuery, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(keuanganParentsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganParentsProvider),
      color: Nebula.teal,
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
              context,
              'Tidak ada orang tua yang terdaftar.',
              'Akun orang tua otomatis terbuat saat data siswa baru didaftarkan.',
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Pending verification section
              if (pending.isNotEmpty && searchQuery.isEmpty) ...[
                _sectionHeader(context, '⚠️  PERLU VERIFIKASI (${pending.length})'),
                const SizedBox(height: 8),
                ...pending.map(
                  (p) => _buildParentCard(context, ref, p, isPending: true),
                ),
                const SizedBox(height: 20),
              ],
              // All active parents
              _sectionHeader(context, 'SEMUA ORANG TUA (${filtered.length})'),
              const SizedBox(height: 8),
              ...filtered.map(
                (p) => _buildParentCard(context, ref, p, isPending: false),
              ),
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
                const Icon(
                  CupertinoIcons.xmark_circle,
                  size: 48,
                  color: Nebula.rose,
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppStrings.labelFailed} memuat data',
                  style: GoogleFonts.inter(color: Nebula.rose),
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isPending
              ? Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isPending
                        ? Colors.amber.withValues(alpha: 0.1)
                        : Nebula.teal.withValues(alpha: 0.08),
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPending ? Colors.amber : Nebula.teal,
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
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    _statusBadge('PENDING', Colors.amber)
                  else if (isActive)
                    _statusBadge('AKTIF', Nebula.teal)
                  else
                    _statusBadge('DIBLOKIR', Nebula.rose),
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
                          foregroundColor: Nebula.rose,
                          side: const BorderSide(color: Nebula.rose),
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
                          backgroundColor: Nebula.teal,
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
                            color: Colors.white,
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

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.person_2,
          size: 64,
          color: context.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.textSecondary,
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
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.patch('/users/$parentId/status', body: {'is_active': true});
      ref.invalidate(keuanganParentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name berhasil diverifikasi'),
            backgroundColor: Nebula.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.labelFailed), backgroundColor: Nebula.rose),
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
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Tolak Pendaftaran',
      message: 'Apakah Anda yakin ingin menolak pendaftaran orang tua "$name"?',
      confirmLabel: 'Tolak',
      isDestructive: true,
      icon: Icons.person_remove_rounded,
    );

    if (!confirmed) return;

    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.patch('/users/$parentId/status', body: {'is_active': false});
      ref.invalidate(keuanganParentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran $name ditolak'),
            backgroundColor: Nebula.rose,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailed),
            backgroundColor: Nebula.rose,
          ),
        );
      }
    }
  }
}
