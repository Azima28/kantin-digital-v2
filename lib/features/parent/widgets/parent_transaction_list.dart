import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/features/parent/widgets/parent_transaction_tile.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

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
      final dateStr = AppDateFormatter.formatFullDate(date);
      if (grouped[dateStr] == null) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }

    final bool hasDateFilter = historyDateRange != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search bar with rounded 16px corners
        TextField(
          controller: searchController,
          onChanged: (_) {},
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.surfaceBg,
            hintText: 'Cari transaksi atau nama stan...',
            hintStyle: GoogleFonts.inter(
              color: context.textSecondary.withValues(alpha: 0.75),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              CupertinoIcons.search,
              color: Nebula.teal,
              size: 18,
            ),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: context.textSecondary,
                      size: 16,
                    ),
                    onPressed: () {
                      searchController.clear();
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.dividerCol, width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.dividerCol, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Full-Width Sliding Segmented Type Filter Tabs
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dividerCol, width: 0.8),
          ),
          child: Row(
            children: [
              _buildTypeTab(context, 'Semua', AppStrings.labelAll),
              _buildTypeTab(context, 'Belanja', 'Belanja'),
              _buildTypeTab(context, 'Top-up', 'Top-up'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Dedicated Date Filter Bar
        InkWell(
          onTap: onPickDateRange,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: hasDateFilter
                  ? Nebula.teal.withValues(alpha: 0.12)
                  : context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasDateFilter ? Nebula.teal : context.dividerCol,
                width: hasDateFilter ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      hasDateFilter ? Icons.event_available_rounded : CupertinoIcons.calendar,
                      size: 16,
                      color: hasDateFilter ? Nebula.teal : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasDateFilter
                          ? 'Rentang: ${AppDateFormatter.formatDate(historyDateRange!.start)} - ${AppDateFormatter.formatDate(historyDateRange!.end)}'
                          : 'Pilih Rentang Tanggal...',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: hasDateFilter ? FontWeight.w800 : FontWeight.w600,
                        color: hasDateFilter ? Nebula.teal : context.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (hasDateFilter)
                  InkWell(
                    onTap: onResetDateRange,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.close_rounded, size: 16, color: context.textSecondary),
                    ),
                  )
                else
                  Icon(CupertinoIcons.chevron_right, size: 14, color: context.textSecondary.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Grouped List of Transactions
        if (grouped.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 64),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderLight, width: 0.8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.tray, color: context.textSecondary.withValues(alpha: 0.5), size: 40),
                  const SizedBox(height: 10),
                  Text(
                    '${AppStrings.labelTransaction} tidak ditemukan.',
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grouped.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final dateHeader = grouped.keys.elementAt(index);
              final dayTxs = grouped[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Text(
                      dateHeader.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.borderLight, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayTxs.length,
                      separatorBuilder: (context, i) => Divider(height: 1, color: context.dividerCol),
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

  Widget _buildTypeTab(BuildContext context, String key, String label) {
    final isSelected = historyTypeFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => onHistoryTypeFilterChanged(key),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Nebula.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
