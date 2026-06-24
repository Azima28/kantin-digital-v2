import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/shared/screens/officer_activities_screen.dart';

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
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailedChangePassword),
            backgroundColor: AppColors.errorRed2,
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
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.darkTeal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile Pegawai',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
                        child: const Icon(CupertinoIcons.person_solid, color: AppColors.darkTeal, size: 36),
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
                                color: AppColors.nearBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Staf Tata Usaha',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.offWhite2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'USN: $username',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Change Password Button
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(profile.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield),
                  label: const Text(
                    AppStrings.adminChangePassword,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Access Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_user, size: 16, color: AppColors.textGray),
                          SizedBox(width: 6),
                          Text(
                            'TINGKAT AKSES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Officer $authorityLevel',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: features.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.darkTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.toString(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.darkTeal),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Audit Logs Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aktivitas Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.nearBlack,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OfficerActivitiesScreen(
                              officerId: widget.officerId,
                              actorName: fullName,
                              primaryColor: AppColors.darkTeal,
                              accentColor: AppColors.darkOrange,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (logs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
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
                      Color logColor = AppColors.darkTeal;
                      if (actionType.contains('KOREKSI')) {
                        logIcon = CupertinoIcons.refresh;
                        logColor = AppColors.darkOrange;
                      } else if (actionType.contains('REGISTRASI')) {
                        logIcon = CupertinoIcons.creditcard;
                        logColor = AppColors.successGreen;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
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
                                          color: AppColors.textGray,
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
                                      color: AppColors.nearBlack,
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
        loading: () => const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
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
