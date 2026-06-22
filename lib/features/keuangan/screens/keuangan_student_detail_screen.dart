import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/features/keuangan/widgets/student_detail_header.dart';
import 'package:kantin_digital/features/keuangan/widgets/student_detail_password_change.dart';
import 'package:kantin_digital/features/keuangan/widgets/student_detail_status_toggle.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// keuanganStudentDetailProvider is defined in keuangan_providers.dart

class KeuanganStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const KeuanganStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<KeuanganStudentDetailScreen> createState() =>
      _KeuanganStudentDetailScreenState();
}

class _KeuanganStudentDetailScreenState
    extends ConsumerState<KeuanganStudentDetailScreen> {

  @override
  void initState() {
    super.initState();
    // Ensure password controller is disposed when this screen is disposed
  }

  @override
  void dispose() {
    StudentDetailPasswordChange.dispose();
    super.dispose();
  }

  void _openAllTransactionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: widget.studentId,
          primaryColor: AppColors.darkTeal,
          accentColor: AppColors.darkOrange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      keuanganStudentDetailProvider(widget.studentId),
    );
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Siswa',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: detailAsync.when(
          data: (data) {
            final profile = data.profile;
            final student = data.student;
            final txs = data.recentTransactions;

            final fullName = profile.fullName ?? AppStrings.adminStudents;
            final email = profile.email ?? '-';
            final nisn = profile.nisn ?? '-';
            final isAccountActive = profile.isActive == true;
            final isCardActive = student.isActive == true;

            final sClass = student.class_ ?? 'Belum Diisi';
            final int balance = student.balance;
            final String? rfid = student.rfidUid;
            final hasCard = rfid != null && rfid.isNotEmpty;

            final String lastTapStr =
                txs.isNotEmpty && txs.first.createdAt != null
                ? DateFormat(
                    'dd MMM yyyy, HH:mm', 'id_ID',
                  ).format(txs.first.createdAt!.toLocal())
                : '-';

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                keuanganStudentDetailProvider(widget.studentId),
              ),
              color: AppColors.darkTeal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentDetailHeader(
                      fullName: fullName,
                      email: email,
                      nisn: nisn,
                      isAccountActive: isAccountActive,
                      isCardActive: isCardActive,
                      hasCard: hasCard,
                      sClass: sClass,
                      balance: balance,
                      rfid: rfid,
                      lastTapStr: lastTapStr,
                      fmt: fmt,
                    ),
                    const SizedBox(height: 16),

                    // ─── Aksi Admin Card ───
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              top: 16,
                              right: 20,
                              bottom: 8,
                            ),
                            child: Text(
                              'Aksi Admin',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.nearBlack,
                              ),
                            ),
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.arrow_up_circle,
                            iconColor: AppColors.successGreen,
                            title: 'Top-Up Saldo Tunai',
                            onTap: () {
                              final studentProfile = StudentWithProfile(
                                id: widget.studentId,
                                fullName: fullName,
                                email: email,
                                nisn: nisn,
                                isActive: isAccountActive,
                                class_: sClass,
                                balance: balance,
                                rfidUid: rfid,
                                cardIsActive: isCardActive,
                              );
                              context.push(
                                '/finance/topup',
                                extra: studentProfile,
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: AppColors.borderGray,
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.arrow_right_arrow_left_circle,
                            iconColor: AppColors.errorRed2,
                            title: AppStrings.keuanganKoreksiSaldo,
                            onTap: () {
                              final studentProfile = StudentWithProfile(
                                id: widget.studentId,
                                fullName: fullName,
                                email: email,
                                nisn: nisn,
                                isActive: isAccountActive,
                                class_: sClass,
                                balance: balance,
                                rfidUid: rfid,
                                cardIsActive: isCardActive,
                              );
                              context.push(
                                '/finance/correction',
                                extra: studentProfile,
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: AppColors.borderGray,
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.wifi,
                            iconColor: AppColors.darkTeal,
                            title: 'Registrasi / Ganti Kartu NFC',
                            onTap: () {
                              context.push(
                                '/finance/students/${widget.studentId}/card',
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: AppColors.borderGray,
                          ),
                          _buildActionTile(
                            icon: Icons.key,
                            iconColor: AppColors.darkOrange,
                            title: AppStrings.adminChangePassword,
                            onTap: () => StudentDetailPasswordChange.show(
                              context, ref, profile.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Riwayat Transaksi Card ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Riwayat Transaksi (10 Terakhir)',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.nearBlack,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _openAllTransactionsScreen,
                                child: Text(
                                  'Lihat Semua',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (txs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  AppStrings.noTransactions,
                                  style: GoogleFonts.inter(
                                    color: AppColors.mutedGray,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: txs.map((tx) {
                                final isTopup = tx.isTopup;
                                final isSuccess = tx.isSuccess;
                                final int amount = tx.totalAmount;
                                final timestamp =
                                    tx.createdAt?.toLocal() ?? DateTime.now();
                                final timeStr = DateFormat(
                                  'dd MMM, HH:mm', 'id_ID',
                                ).format(timestamp);
                                final canteenName = tx.canteenName ?? 'Top-up';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: isTopup
                                                ? AppColors.successGreen.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : AppColors.darkTeal.withValues(
                                                    alpha: 0.08,
                                                  ),
                                            child: Icon(
                                              isTopup
                                                  ? CupertinoIcons.arrow_up
                                                  : CupertinoIcons.cart,
                                              size: 14,
                                              color: isTopup
                                                  ? AppColors.successGreen
                                                  : AppColors.darkTeal,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isTopup
                                                    ? 'Top-Up Saldo'
                                                    : canteenName,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: const Color(
                                                    0xFF1B1C1B,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                timeStr,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF6F7978,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isTopup ? "+" : "-"}${fmt.format(amount)}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isTopup
                                                  ? AppColors.successGreen
                                                  : AppColors.darkTeal,
                                            ),
                                          ),
                                          if (!isSuccess)
                                            Text(
                                              tx.status
                                                  .toString()
                                                  .toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.errorRed2,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Block Account Button ───
                    StudentDetailStatusToggle(
                      studentId: widget.studentId,
                      isAccountActive: isAccountActive,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CupertinoActivityIndicator(color: AppColors.darkTeal),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                  const SizedBox(height: 12),
                  Text('${AppStrings.labelFailed} memuat profil'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(keuanganStudentDetailProvider(widget.studentId)),
                    child: const Text(AppStrings.buttonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withValues(alpha: 0.08),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.nearBlack,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 16,
        color: AppColors.mutedGray,
      ),
      onTap: onTap,
    );
  }
}
