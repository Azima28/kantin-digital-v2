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
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_student_sheet.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_status_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_password_change.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_rfid_section.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';

class AdminStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<AdminStudentDetailScreen> createState() =>
      _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState
    extends ConsumerState<AdminStudentDetailScreen> {
  void _openAllTransactionsScreen({
    required String studentId,
    required Color primaryColor,
    required Color accentColor,
  }) {
    final detail = ref.read(adminStudentDetailProvider(studentId)).asData?.value;
    final String studentName = detail?.profile.fullName ?? AppStrings.adminStudents;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: studentId,
          title: studentName,
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(adminStudentDetailProvider(widget.studentId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Detail Siswa',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        actions: [
          studentAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(CupertinoIcons.pencil, color: Nebula.teal),
              tooltip: 'Edit Profil Siswa',
              onPressed: () => showEditStudentSheet(
                context,
                ref,
                data.profile,
                data.student,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
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
          final String className = student.class_ ?? 'X RPL 1';
          final int balance = student.balance;
          final double? dailyLimit = student.dailyLimit;
          final String rfidUid = student.rfidUid ?? 'Belum Terdaftar';
          final bool isCardActive = student.isActive;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Student Avatar & Basic Profile Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.dividerCol.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.shadowColor,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.12),
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$className • NISN: ${nisn.isNotEmpty ? nisn : "-"}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Nebula.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Student Info List Card
                AdminStudentStatusCard(
                  isCardActive: isCardActive,
                  isAccountActive: profile.isActive ?? true,
                  rfidUid: rfidUid,
                  username: username,
                  email: email,
                  className: className,
                  balance: balance,
                  dailyLimit: dailyLimit,
                ),
                const SizedBox(height: 14),

                // 3. Action Buttons Row (Ubah Kata Sandi & Bekukan/Aktifkan Kartu RFID)
                Row(
                  children: [
                    // Ubah Kata Sandi Button
                    Expanded(
                      child: PressScale(
                        onTap: () => AdminStudentPasswordChange.show(
                          context,
                          ref,
                          profile.id,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Nebula.teal.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.key,
                                color: Nebula.teal,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Ubah\nKata Sandi',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Nebula.teal,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Bekukan / Aktifkan Kartu RFID Button
                    Expanded(
                      child: AdminStudentRfidSection(
                        studentId: widget.studentId,
                        isCardActive: isCardActive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3b. Finance Quick Action (Top-Up Saldo)
                PressScale(
                  onTap: () {
                    final studentProfile = StudentWithProfile(
                      id: profile.id,
                      fullName: fullName,
                      email: email,
                      nisn: nisn,
                      isActive: profile.isActive ?? true,
                      class_: className,
                      balance: balance,
                      rfidUid: student.rfidUid,
                      cardIsActive: isCardActive,
                    );
                    context.push(
                      '/finance/topup',
                      extra: studentProfile,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Nebula.teal.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          color: Nebula.teal,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Top-Up Saldo Siswa',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Riwayat Transaksi Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Riwayat Transaksi',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openAllTransactionsScreen(
                        studentId: widget.studentId,
                        primaryColor: Nebula.teal,
                        accentColor: Nebula.amber,
                      ),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Transaction History List / Empty State
                if (txs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.dividerCol, width: 0.6),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.noTransactions,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: txs.take(5).map((tx) {
                      final int amount = tx.totalAmount;
                      final bool isTopup = tx.isTopup;
                      final bool isRefund = tx.status?.toString().toLowerCase() == 'refunded' || tx.type == 'refund';
                      final bool isIncoming = isTopup || isRefund;
                      final String canteen =
                          tx.canteenName ?? 'Stan Kantin';
                      final date =
                          tx.createdAt?.toLocal() ?? DateTime.now();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.dividerCol, width: 0.6),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => showTransactionDetailSheet(context, ref, tx),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isIncoming
                                    ? Nebula.teal.withValues(alpha: 0.1)
                                    : Nebula.teal.withValues(alpha: 0.1),
                                child: Icon(
                                  isTopup
                                      ? CupertinoIcons.creditcard
                                      : (isRefund ? CupertinoIcons.arrow_uturn_left : Icons.shopping_bag),
                                  color: Nebula.teal,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTopup
                                          ? 'Top-up Saldo'
                                          : (isRefund ? 'Dana Dikembalikan (Refund)' : canteen),
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy, HH:mm',
                                        'id_ID',
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
                                '${isIncoming ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isIncoming
                                      ? Nebula.teal
                                      : context.textPrimary,
                                ),
                              ),
                            ],
                          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
              Text('${AppStrings.labelFailed} memuat detail siswa: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(adminStudentDetailProvider(widget.studentId)),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
