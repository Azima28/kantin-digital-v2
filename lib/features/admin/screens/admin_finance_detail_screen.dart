import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/shared/screens/officer_activities_screen.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_finance_sheet.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';


class AdminFinanceDetailScreen extends ConsumerStatefulWidget {
  final String officerId;
  const AdminFinanceDetailScreen({super.key, required this.officerId});

  @override
  ConsumerState<AdminFinanceDetailScreen> createState() => _AdminFinanceDetailScreenState();
}

class _AdminFinanceDetailScreenState extends ConsumerState<AdminFinanceDetailScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(String profileId) async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) return;

    final client = ref.read(supabaseClientProvider);
    try {
      // Client-side role check before RPC call
      final currentUserRole = ref.read(authNotifierProvider).profile?['role'];
      if (currentUserRole != 'super_admin' && currentUserRole != 'admin' && currentUserRole != 'petugas_keuangan') {
        throw Exception('Tidak memiliki izin untuk mengubah password');
      }

      final currentUserId = ref.read(authNotifierProvider).profile?['id'];
      await client.rpc('update_auth_user_password', params: {
        'p_user_id': profileId,
        'p_new_password': password,
        'p_caller_id': currentUserId,
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPasswordUpdated),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailedChangePassword),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(String profileId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(AppStrings.adminChangePassword),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: _passwordController,
            placeholder: 'Masukkan sandi baru',
            obscureText: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _changePassword(profileId),
            child: const Text(AppStrings.buttonSave),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminFinanceDetailProvider(widget.officerId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile Pegawai',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
          ),
        ),
        actions: [
          detailAsync.maybeWhen(
            data: (data) => IconButton(
              icon: Icon(CupertinoIcons.pencil, color: Nebula.teal),
              onPressed: () => showEditFinanceSheet(
                context,
                ref,
                data.profile,
                FinanceOfficer.fromJson(data.officer),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (data) {
          final profile = data.profile;
          final officer = data.officer;
          final List<AuditLog> logs = data.recentLogs;

          final String fullName = profile.fullName ?? '';
          final String username = profile.username ?? '';
          final String authorityLevel = officer['authority_level'] ?? 'L1';
          final List<dynamic> features = officer['features'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                NebulaCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                        child: Icon(CupertinoIcons.person_solid, color: Nebula.teal, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Staf Tata Usaha',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'USN: $username',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),

                // Change Password Button
                PressScale(
                  onTap: () => _showChangePasswordDialog(profile.id),
                  child: ElevatedButton.icon(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      foregroundColor: context.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(CupertinoIcons.lock_shield),
                    label: Text(
                      AppStrings.adminChangePassword,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const GradientLine(),
                const SizedBox(height: 16),

                // Access Card
                NebulaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user, size: 16, color: context.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'TINGKAT AKSES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Officer $authorityLevel',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: features.map((f) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.toString(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Nebula.teal),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Audit Logs Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aktivitas Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    PressScale(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OfficerActivitiesScreen(
                              officerId: widget.officerId,
                              actorName: fullName,
                              primaryColor: Nebula.teal,
                              accentColor: Nebula.amber,
                            ),
                          ),
                        );
                      },
                      child: TextButton(
                        onPressed: null,
                        child: Text(
                          'Lihat Semua',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (logs.isEmpty)
                  NebulaCard(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateWidget(
                      message: 'Belum ada aktivitas transaksi manual.',
                    )
                  )
                else
                  Column(
                    children: logs.map((log) {
                      final String actionType = log.actionType;
                      final String desc = log.description;
                      final date = log.createdAt?.toLocal() ?? DateTime.now();

                      // Set specific icon & color for action types
                      IconData logIcon = CupertinoIcons.doc_text;
                      Color logColor = Nebula.teal;
                      if (actionType.contains('KOREKSI')) {
                        logIcon = CupertinoIcons.refresh;
                        logColor = Nebula.amber;
                      } else if (actionType.contains('REGISTRASI')) {
                        logIcon = CupertinoIcons.creditcard;
                        logColor = Nebula.teal;
                      }

                      return NebulaCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: logColor.withValues(alpha: 0.1),
                              child: Icon(logIcon, color: logColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        actionType.replaceAll('_', ' '),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: logColor,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('HH:mm', 'id_ID').format(date),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
        loading: () => Shimmer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            SkeletonBox(width: 80, height: 14, borderRadius: 4),
                            Spacer(),
                            SkeletonBox(width: 120, height: 14, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SkeletonBox(width: 140, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                ...List.generate(3, (i) => const SkeletonListTile()),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminFinanceDetailProvider(widget.officerId)),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}