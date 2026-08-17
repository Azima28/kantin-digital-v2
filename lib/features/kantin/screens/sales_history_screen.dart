import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/date_filter_modal.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/kantin/widgets/refund_confirmation_dialog.dart';
import 'package:kantin_digital/features/kantin/widgets/transaction_details_sheet.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Diproses, 2: Berhasil, 3: Dibatalkan
  AppDateFilterParam? _dateFilter;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isDiproses(String? status) {
    if (status == null) return false;
    final s = status.trim().toLowerCase();
    return s == 'pending' ||
        s == 'processing' ||
        s == 'diproses' ||
        s == 'sedang dimasak' ||
        s == 'siap diambil' ||
        s == 'siap diantar' ||
        s == 'menunggu pembatalan' ||
        s == 'menunggu persetujuan murid';
  }

  bool _isDibatalkan(String? status) {
    if (status == null) return false;
    final s = status.trim().toLowerCase();
    return s == 'cancelled' || s == 'refunded' || s == 'dibatalkan' || s == 'failed';
  }

  bool _isBerhasil(String? status) {
    if (status == null) return true;
    final s = status.trim().toLowerCase();
    if (_isDiproses(s) || _isDibatalkan(s)) return false;
    return s == 'success' || s == 'completed' || s == 'selesai';
  }

  // Groups list items into sections based on date
  Map<String, List<OperatorTransaction>> _groupTransactionsByDate(
      List<OperatorTransaction> txs) {
    final Map<String, List<OperatorTransaction>> groups = {};
    final now = DateTime.now();

    for (var tx in txs) {
      if (tx.createdAt == null) continue;
      final txDate = tx.createdAt!.toLocal();

      String sectionTitle;
      if (txDate.year == now.year &&
          txDate.month == now.month &&
          txDate.day == now.day) {
        sectionTitle = 'HARI INI';
      } else if (txDate.year == now.year &&
          txDate.month == now.month &&
          txDate.day == (now.day - 1)) {
        sectionTitle = 'KEMARIN';
      } else {
        sectionTitle = AppDateFormatter.formatDayFullDate(txDate).toUpperCase();
      }

      if (!groups.containsKey(sectionTitle)) {
        groups[sectionTitle] = [];
      }
      groups[sectionTitle]!.add(tx);
    }
    return groups;
  }

  Widget _buildFilterSlideBar(
      BuildContext context, List<Map<String, dynamic>> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        children: tabs.map((tab) {
          final int index = tab['index'];
          final String label = tab['label'];
          final int count = tab['count'];
          final bool isSelected = index == _selectedFilterIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Nebula.teal : context.surfaceBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Nebula.teal : context.borderLight,
                      width: isSelected ? 1.0 : 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Nebula.teal.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : context.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Nebula.teal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeadingThumbnail(
      BuildContext context, OperatorTransaction tx, bool isCancelled, bool isProcessing) {
    final String? imgUrl = tx.imageUrl;
    final bool hasImage = imgUrl != null && imgUrl.isNotEmpty;
    final Color badgeColor = isCancelled
        ? Nebula.rose
        : (isProcessing ? Nebula.amber : Nebula.teal);

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: CachedNetworkImage(
            imageUrl: imgUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const ShimmerRect(
              width: 44,
              height: 44,
              borderRadius: 10,
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCancelled
                    ? CupertinoIcons.arrow_counterclockwise
                    : (isProcessing ? CupertinoIcons.hourglass : CupertinoIcons.shopping_cart),
                color: badgeColor,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isCancelled
            ? CupertinoIcons.arrow_counterclockwise
            : (isProcessing ? CupertinoIcons.hourglass : CupertinoIcons.shopping_cart),
        color: badgeColor,
        size: 20,
      ),
    );
  }

  String _derivePrimaryTitle(OperatorTransaction tx) {
    if (tx.transactionItems != null && tx.transactionItems!.isNotEmpty) {
      final firstItem = tx.transactionItems!.first;
      final firstName = firstItem.productName;
      if (firstName != '-' && firstName.isNotEmpty) {
        final remainingCount = tx.transactionItems!.length - 1;
        if (remainingCount > 0) {
          return '$firstName (+$remainingCount)';
        }
        return firstName;
      }
    }
    return tx.studentName ?? 'Siswa';
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(operatorTransactionsProvider);

    return Scaffold(
      backgroundColor: context.surfaceBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(operatorTransactionsProvider);
            ref.invalidate(todayRevenueProvider);
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: transactionsAsync.when(
                data: (List<OperatorTransaction> allTxs) {
                  final int countDiproses =
                      allTxs.where((tx) => _isDiproses(tx.status)).length;
                  final int countBerhasil =
                      allTxs.where((tx) => _isBerhasil(tx.status)).length;
                  final int countBatal =
                      allTxs.where((tx) => _isDibatalkan(tx.status)).length;

                  final List<Map<String, dynamic>> tabs = [
                    {'index': 0, 'label': AppStrings.labelAll, 'count': allTxs.length},
                    {'index': 1, 'label': 'Diproses', 'count': countDiproses},
                    {'index': 2, 'label': 'Berhasil', 'count': countBerhasil},
                    {'index': 3, 'label': 'Dibatalkan', 'count': countBatal},
                  ];

                  // Filter data based on active filters
                  final filteredTxs = allTxs.where((tx) {
                    // Tab filter
                    if (_selectedFilterIndex == 1 && !_isDiproses(tx.status)) {
                      return false;
                    }
                    if (_selectedFilterIndex == 2 && !_isBerhasil(tx.status)) {
                      return false;
                    }
                    if (_selectedFilterIndex == 3 && !_isDibatalkan(tx.status)) {
                      return false;
                    }

                    // Date filter
                    if (_dateFilter != null && !_dateFilter!.isAllTime) {
                      if (!_dateFilter!.matches(tx.createdAt)) return false;
                    }

                    // Search query filter
                    if (_searchQuery.isNotEmpty) {
                      final studentName = (tx.studentName ?? '').toLowerCase();
                      final id = tx.id.toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      bool matchesItem = false;
                      if (tx.transactionItems != null) {
                        for (final item in tx.transactionItems!) {
                          if (item.productName.toLowerCase().contains(query)) {
                            matchesItem = true;
                            break;
                          }
                        }
                      }
                      if (!studentName.contains(query) &&
                          !id.contains(query) &&
                          !matchesItem) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Header Container: Title, Search, Slide Filter, Date Bar
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          border: Border(
                            bottom: BorderSide(
                              color: context.borderLight,
                              width: 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Page Title
                            Center(
                              child: Text(
                                'Riwayat Jualan',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Single Unified Sleek Search Bar
                            SizedBox(
                              height: 40,
                              child: TextField(
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: context.isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  hintText: 'Cari nama siswa, menu, atau ID...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: context.textSecondary
                                        .withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    CupertinoIcons.search,
                                    size: 16,
                                    color: Nebula.teal,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                          child: Icon(
                                            CupertinoIcons.clear_circled_solid,
                                            size: 16,
                                            color: context.textSecondary,
                                          ),
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: context.isDark
                                          ? context.borderLight
                                          : const Color(0xFFE2E8F0),
                                      width: 0.8,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: context.isDark
                                          ? context.borderLight
                                          : const Color(0xFFE2E8F0),
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Nebula.teal,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Filter Chips Slide Bar (Semua, Diproses, Berhasil, Dibatalkan)
                            _buildFilterSlideBar(context, tabs),
                            const SizedBox(height: 10),

                            // Count & Date Filter Row (Jumlah di kiri, filter di kanan)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${filteredTxs.length} Transaksi',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                DateFilterPillButton(
                                  activeFilter: _dateFilter,
                                  onFilterChanged: (param) {
                                    setState(() {
                                      _dateFilter = param;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Transactions List
                      Expanded(
                        child: _buildTransactionList(context, filteredTxs),
                      ),
                    ],
                  );
                },
                loading: () => _buildLoadingSkeleton(context),
                error: (err, stack) => _buildErrorState(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
      BuildContext context, List<OperatorTransaction> txs) {
    if (txs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              EmptyStateWidget(
                message: AppStrings.adminNoSales,
              ),
            ],
          ),
        ),
      );
    }

    final groupedTxs = _groupTransactionsByDate(txs);
    final groupKeys = groupedTxs.keys.toList();

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: groupKeys.length,
      itemBuilder: (context, sectionIndex) {
        final sectionTitle = groupKeys[sectionIndex];
        final sectionItems = groupedTxs[sectionTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6, top: 8),
              child: Text(
                sectionTitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Compact Transaction Cards
            Column(
              children: sectionItems.map((tx) {
                final String id = tx.id;
                final int amount = tx.totalAmount;
                final String studentName = tx.studentName ?? 'Siswa';
                final String status = tx.status ?? 'success';
                final bool isCancelled = _isDibatalkan(status);
                final bool isProcessing = _isDiproses(status);

                final DateTime createdAt =
                    tx.createdAt?.toLocal() ?? DateTime.now();
                final String timeStr = AppDateFormatter.formatTime(createdAt);

                final bool isWithinRefundWindow =
                    DateTime.now().difference(createdAt).inMinutes < 10;
                final bool canRefund = _isBerhasil(status) &&
                    (tx.type == null || tx.type == 'purchase') &&
                    isWithinRefundWindow;

                final String primaryTitle = _derivePrimaryTitle(tx);

                return PressScale(
                  onTap: () => showTransactionDetailsSheet(context, tx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: context.borderLight, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: context.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Leading Product Image / Fallback Icon (44x44, radius 10)
                        _buildLeadingThumbnail(context, tx, isCancelled, isProcessing),
                        const SizedBox(width: 10),

                        // Center: Title, Subtitle, ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                primaryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isCancelled
                                      ? context.textSecondary
                                      : context.textPrimary,
                                  decoration: isCancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tx.purchaseMethodDisplay} • $studentName • $timeStr WIB',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '#${id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Trailing: Amount & Status Badge / Action
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isCancelled ? "" : "+ "}${CurrencyFormatter.format(amount)}',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isCancelled
                                    ? context.textSecondary
                                    : (isProcessing ? Nebula.amber : Nebula.teal),
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isCancelled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Nebula.rose.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Dikembalikan',
                                  style: GoogleFonts.inter(
                                    color: Nebula.rose,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isProcessing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Nebula.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Diproses',
                                  style: GoogleFonts.inter(
                                    color: Nebula.amber,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (canRefund)
                              GestureDetector(
                                onTap: () => showRefundConfirmationDialog(
                                  context,
                                  ref,
                                  id,
                                  amount,
                                  studentName,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Nebula.rose.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Nebula.rose.withValues(alpha: 0.4),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    'Kembalikan',
                                    style: GoogleFonts.inter(
                                      color: Nebula.rose,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Nebula.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Berhasil',
                                  style: GoogleFonts.inter(
                                    color: Nebula.teal,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderLight, width: 0.8),
              ),
              child: Row(
                children: [
                  const SkeletonBox(width: 44, height: 44, borderRadius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 110, height: 13, borderRadius: 4),
                        SizedBox(height: 5),
                        SkeletonBox(width: 140, height: 10, borderRadius: 4),
                        SizedBox(height: 4),
                        SkeletonBox(width: 60, height: 9, borderRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      SkeletonBox(width: 65, height: 13, borderRadius: 4),
                      SizedBox(height: 5),
                      SkeletonBox(width: 45, height: 14, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle,
                color: Nebula.rose, size: 44),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat riwayat transaksi',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(operatorTransactionsProvider);
                ref.invalidate(todayRevenueProvider);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(AppStrings.buttonRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
