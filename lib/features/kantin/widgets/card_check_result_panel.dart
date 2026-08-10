import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/nfc_pulse_animator.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// Displays the scanning/idle state when no card has been read yet.
class ScanningView extends StatelessWidget {
  final String? errorMessage;

  const ScanningView({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          // Visual Scanning indicator
          const NfcPulseAnimator(
            size: 100,
            color: Nebula.teal,
            child: Icon(
              CupertinoIcons.creditcard,
              size: 48,
              color: Nebula.teal,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Siap Memindai Kartu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tempelkan kartu RFID/NFC siswa pada bagian belakang HP untuk membaca data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 20),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Nebula.amber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Displays an error state when card verification fails.
class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Nebula.rose.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 36,
              color: Nebula.rose,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Verifikasi ${AppStrings.labelFailed}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: Text(AppStrings.buttonRetry,
                  style: TextStyle(color: context.cardBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays student info card with balance and recent transactions.
class StudentCardView extends StatelessWidget {
  final Student student;
  final String studentName;
  final String studentEmail;
  final List<OperatorTransaction> transactions;
  final VoidCallback onReset;

  const StudentCardView({
    super.key,
    required this.student,
    required this.studentName,
    required this.studentEmail,
    required this.transactions,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final studentClass = student.class_ ?? 'Belum Diisi';
    final balance = student.balance;
    final isActive = student.isActive;
    final nis = studentEmail.split('@').first; // extract NIS from email local-part

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Initials / Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      studentName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Nebula.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: $nis \u2022 Kelas $studentClass',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0.5, color: context.borderLight),
          // Body Card Info (Balance)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUS KARTU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Nebula.teal.withValues(alpha: 0.1)
                            : Nebula.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.lock_fill,
                            size: 11,
                            color: isActive ? Nebula.teal : Nebula.rose,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktif' : 'Dibekukan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Nebula.teal : Nebula.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SALDO AKTIF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(balance),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Nebula.teal,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0.5, color: context.borderLight),
          // Riwayat Transaksi Card
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RIWAYAT TRANSAKSI (10 TERAKHIR)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentTransactionsScreen(
                              studentId: student.id,
                              primaryColor: Nebula.teal,
                              accentColor: Nebula.amber,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                    children: transactions.map((tx) {
                      final type = tx.type ?? 'purchase';
                      final isTopup = type == 'topup';
                      final status = tx.status ?? 'success';
                      final isSuccess = status == 'success';
                      final amount = tx.totalAmount;
                      final timestamp = tx.createdAt?.toLocal() ?? DateTime.now();
                      final timeStr = DateFormat('dd MMM, HH:mm', 'id_ID').format(timestamp);
                      final canteenName = tx.canteenName ?? 'Top-up';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isTopup
                                      ? Nebula.teal.withValues(alpha: 0.08)
                                      : Nebula.teal.withValues(alpha: 0.08),
                                  child: Icon(
                                    isTopup ? CupertinoIcons.arrow_up : CupertinoIcons.cart,
                                    size: 14,
                                    color: isTopup ? Nebula.teal : Nebula.teal,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTopup ? 'Top-Up Saldo' : canteenName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isTopup ? "+" : "-"}${CurrencyFormatter.format(amount)}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isTopup ? Nebula.teal : Nebula.teal,
                                  ),
                                ),
                                if (!isSuccess)
                                  Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Nebula.rose,
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
          Divider(height: 0.5, color: context.borderLight),
          // Footer actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Nebula.teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onReset,
                child: Text(
                  'Scan Kartu Lain',
                  style: TextStyle(color: context.cardBg, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}