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
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_password_change.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_rfid_section.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_status_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_student_sheet.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';

class AdminStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<AdminStudentDetailScreen> createState() =>
      _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState
    extends ConsumerState<AdminStudentDetailScreen> {

  @override
  void dispose() {
    AdminStudentPasswordChange.dispose();
    super.dispose();
  }

  void _openAllTransactionsScreen({
    required String studentId,
    required Color primaryColor,
    required Color accentColor,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: studentId,
          primaryColor: Nebula.teal,
          accentColor: Nebula.amber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(
      adminStudentDetailProvider(widget.studentId),
    );

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
          '${AppStrings.titleDetail} Siswa',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
          ),
        ),
        actions: [
          studentAsync.maybeWhen(
            data: (data) => IconButton(
              icon: Icon(CupertinoIcons.pencil, color: Nebula.teal),
              onPressed: () => showEditStudentSheet(
                context,
                ref,
                data.profile,
                data.student,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (data) {
          final profile = data.profile;
          final student = data.student;
          final List<OperatorTransaction> txs = data.recentTransactions;

          final String fullName = profile.fullName ?? '';
          final String email = profile.email ?? '';
          final String username = profile.username ?? '';
          final String nisn = profile.nisn ?? '';
          final String className = student.class_ ?? 'Belum Diisi';
          final int balance = student.balance;
          final double? dailyLimit = student.dailyLimit;
          final String rfidUid = student.rfidUid ?? 'Belum Terdaftar';
          final bool isCardActive = student.isActive;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                NebulaCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                        child: Icon(
                          CupertinoIcons.person,
                          color: Nebula.teal,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        'Kelas $className • NISN: ${nisn.isNotEmpty ? nisn : "-"}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const GradientLine(),
                const SizedBox(height: 12),

                // Info Bento Card (extracted)
                AdminStudentStatusCard(
                  isCardActive: isCardActive,
                  rfidUid: rfidUid,
                  username: username,
                  email: email,
                  balance: balance,
                  dailyLimit: dailyLimit,
                ),
                const SizedBox(height: 12),

                // Actions grid
                Row(
                  children: [
                    Expanded(
                      child: PressScale(
                        onTap: () => AdminStudentPasswordChange.show(
                          context, ref, profile.id,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: context.surfaceBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.key, color: Nebula.teal),
                              const SizedBox(height: 8),
                              Text(
                                'Ubah\nKata Sandi',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // RFID freeze/unfreeze (extracted)
                    Expanded(
                      child: AdminStudentRfidSection(
                        studentId: widget.studentId,
                        isCardActive: isCardActive,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                const GradientLine(),
                const SizedBox(height: 24),

                // Transaction History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    PressScale(
                      onTap: () => _openAllTransactionsScreen(
                        studentId: widget.studentId,
                        primaryColor: Nebula.teal,
                        accentColor: Nebula.amber,
                      ),
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

                if (txs.isEmpty)
                  NebulaCard(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        AppStrings.noTransactions,
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: txs.map((tx) {
                      final int amount = tx.totalAmount;
                      final bool isTopup = tx.isTopup;
                      final String canteen = tx.canteenName ?? 'Stan Kantin';
                      final date = tx.createdAt?.toLocal() ?? DateTime.now();

                      return NebulaCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isTopup
                                  ? Nebula.amber
                                  : Nebula.teal.withValues(alpha: 0.1),
                              child: Icon(
                                isTopup
                                    ? CupertinoIcons.creditcard
                                    : Icons.shopping_bag,
                                color: isTopup ? Nebula.amber : Nebula.teal,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTopup ? 'Top-up Saldo' : canteen,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, HH:mm', 'id_ID',
                                    ).format(date),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isTopup
                                    ? Nebula.teal
                                    : Nebula.rose,
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
        loading: () =>
            Center(child: CupertinoActivityIndicator(color: Nebula.teal)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminStudentDetailProvider(widget.studentId)),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
