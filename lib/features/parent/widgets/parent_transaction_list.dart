import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/parent/widgets/parent_transaction_tile.dart';

class ParentTransactionList extends StatelessWidget {
  final List<OperatorTransaction> transactions;
  final TextEditingController searchController;
  final String historyTypeFilter;
  final ValueChanged<String> onHistoryTypeFilterChanged;
  final DateTimeRange? historyDateRange;
  final VoidCallback onPickDateRange;
  final VoidCallback onResetDateRange;
  final String Function(OperatorTransaction) getItemsSummary;
  final void Function(OperatorTransaction) onTransactionTap;

  const ParentTransactionList({
    super.key,
    required this.transactions,
    required this.searchController,
    required this.historyTypeFilter,
    required this.onHistoryTypeFilterChanged,
    this.historyDateRange,
    required this.onPickDateRange,
    required this.onResetDateRange,
    required this.getItemsSummary,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = AppColors.teal;

    // Apply search filter
    final String query = searchController.text.toLowerCase().trim();
    var filtered = transactions.where((tx) {
      if (query.isEmpty) return true;
      final summary = getItemsSummary(tx).toLowerCase();
      final canteen = (tx.canteenName ?? '').toLowerCase();
      return summary.contains(query) || canteen.contains(query);
    }).toList();

    // Apply type filter
    if (historyTypeFilter == 'Belanja') {
      filtered = filtered.where((tx) => tx.type == 'purchase').toList();
    } else if (historyTypeFilter == 'Top-up') {
      filtered = filtered.where((tx) => tx.type == 'topup').toList();
    }

    // Apply date range filter
    if (historyDateRange != null) {
      final start = DateTime(historyDateRange!.start.year,
          historyDateRange!.start.month, historyDateRange!.start.day);
      final end = DateTime(historyDateRange!.end.year,
              historyDateRange!.end.month, historyDateRange!.end.day)
          .add(const Duration(days: 1));
      filtered = filtered.where((tx) {
        final date = tx.createdAt?.toLocal() ?? DateTime.now();
        return date.isAfter(start) && date.isBefore(end);
      }).toList();
    }

    // Group by Date for display
    Map<String, List<OperatorTransaction>> grouped = {};
    for (var tx in filtered) {
      final date = tx.createdAt?.toLocal() ?? DateTime.now();
      final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      if (grouped[dateStr] == null) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray, width: 1),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.search,
                  color: AppColors.textGray, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (_) {},
                  decoration: const InputDecoration(
                    hintText: 'Cari transaksi atau nama stan...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid,
                      color: AppColors.textGray, size: 16),
                  onPressed: () {
                    searchController.clear();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Type Segment Filter
        Row(
          children: [
            Expanded(
              child: CupertinoSegmentedControl<String>(
                groupValue: historyTypeFilter,
                selectedColor: primaryTeal,
                unselectedColor: AppColors.white,
                borderColor: AppColors.borderGray,
                pressedColor: AppColors.teal.withValues(alpha: 0.1),
                children: const {
                  'Semua': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(AppStrings.labelAll, style: TextStyle(fontSize: 11))),
                  'Belanja': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Belanja', style: TextStyle(fontSize: 11))),
                  'Top-up': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Top-up', style: TextStyle(fontSize: 11))),
                },
                onValueChanged: onHistoryTypeFilterChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date Picker button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderGray),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPickDateRange,
          icon: const Icon(CupertinoIcons.calendar,
              color: primaryTeal, size: 16),
          label: Text(
            historyDateRange != null
                ? '${DateFormat('dd MMM', 'id_ID').format(historyDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(historyDateRange!.end)}'
                : '${AppStrings.buttonSelect} Rentang Tanggal...',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: primaryTeal),
          ),
        ),
        if (historyDateRange != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onResetDateRange,
              child: const Text('Reset Tanggal',
                  style: TextStyle(fontSize: 11, color: AppColors.error)),
            ),
          ),
        const SizedBox(height: 16),

        // Grouped List
        if (grouped.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                children: [
                  const Icon(CupertinoIcons.tray,
                      color: AppColors.textGray, size: 40),
                  const SizedBox(height: 12),
                  Text('${AppStrings.labelTransaction} tidak ditemukan.',
                      style: GoogleFonts.inter(
                          color: AppColors.textGray, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateHeader = grouped.keys.elementAt(index);
              final dayTxs = grouped[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Text(
                      dateHeader.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGray,
                          letterSpacing: 0.5),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.borderGray, width: 1),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayTxs.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1, color: AppColors.borderGray),
                      itemBuilder: (context, i) {
                        final tx = dayTxs[i];
                        return ParentTransactionTile(
                          transaction: tx,
                          onTap: () => onTransactionTap(tx),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
