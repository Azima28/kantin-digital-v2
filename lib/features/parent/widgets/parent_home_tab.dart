import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/parent/widgets/parent_balance_card.dart';
import 'package:kantin_digital/features/parent/widgets/parent_action_grid.dart';
import 'package:kantin_digital/features/parent/widgets/parent_transaction_tile.dart';

/// Home tab of the parent dashboard.
///
/// Shows profile card, saldo card, daily limit progress, and today's transactions.
class ParentHomeTab extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final int balance;
  final double? dailyLimit;
  final List<OperatorTransaction> transactions;
  final VoidCallback onViewAllHistory;

  const ParentHomeTab({
    super.key,
    required this.studentName,
    required this.studentClass,
    required this.balance,
    required this.dailyLimit,
    required this.transactions,
    required this.onViewAllHistory,
  });

  double _getTodaySpending() {
    final now = DateTime.now().toLocal();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    double sum = 0.0;
    for (var tx in transactions) {
      if (tx.status == 'success' && tx.type == 'purchase') {
        final txDateStr = tx.createdAt != null
            ? tx.createdAt!.toLocal().toIso8601String().substring(0, 10)
            : '';
        if (txDateStr == todayStr) {
          sum += tx.totalAmount;
        }
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final double todaySpending = _getTodaySpending();
    final now = DateTime.now().toLocal();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayTxs = transactions.where((tx) {
      final txDateStr = tx.createdAt != null
          ? tx.createdAt!.toLocal().toIso8601String().substring(0, 10)
          : '';
      return txDateStr == todayStr;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profil Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0x1A006767),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.person_fill,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      studentClass,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Saldo Card
        ParentBalanceCard(
          balance: balance,
          studentId: '', // Handled internally
        ),
        const SizedBox(height: 24),

        // Batas Saku Progress
        Text(
          'BATAS SAKU HARIAN',
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ParentDailyLimitCard(
          dailyLimit: dailyLimit,
          todaySpending: todaySpending,
        ),
        const SizedBox(height: 24),

        // Aktivitas Terakhir
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'AKTIVITAS TERAKHIR HARI INI',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onViewAllHistory,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayTxs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray, width: 1),
            ),
            child: const EmptyStateWidget(
              message: AppStrings.labelNoData,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray, width: 1),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayTxs.length,
              separatorBuilder: (context, i) =>
                  const Divider(height: 1, color: AppColors.borderGray),
              itemBuilder: (context, i) {
                final tx = todayTxs[i];
                return ParentTransactionTile(transaction: tx);
              },
            ),
          ),
      ],
    );
  }
}
