import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/date_filter_modal.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaHistoryScreen extends ConsumerStatefulWidget {
  const SiswaHistoryScreen({super.key});

  @override
  ConsumerState<SiswaHistoryScreen> createState() => _SiswaHistoryScreenState();
}

class _SiswaHistoryScreenState extends ConsumerState<SiswaHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Jajan, 2: Top-Up, 3: Dibatalkan
  AppDateFilterParam? _dateFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      ref.read(siswaTransactionsNotifierProvider.notifier).loadMore();
    }
  }

  void _showTransactionDetail(BuildContext context, OperatorTransaction tx) {
    final String txId = tx.id;
    final String type = tx.type ?? 'purchase';
    final int amount = tx.totalAmount;
    final String timeStr = tx.createdAt != null
        ? AppDateFormatter.formatShortDateWithTime(tx.createdAt)
        : '-';
    final String canteenName = tx.canteenName ?? 'Kantin';
    final bool isCancelled = tx.status == 'cancelled' || tx.status == 'refunded';
    final bool isTopup = type == 'topup';

    // Status config
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusLabel;
    if (isCancelled) {
      statusColor = Nebula.rose;
      statusBgColor = Nebula.rose.withValues(alpha: 0.08);
      statusIcon = Icons.cancel_outlined;
      statusLabel = tx.status == 'refunded' ? 'Dana Dikembalikan' : 'Dibatalkan';
    } else if (isTopup) {
      statusColor = Nebula.teal;
      statusBgColor = Nebula.teal.withValues(alpha: 0.08);
      statusIcon = CupertinoIcons.square_arrow_down;
      statusLabel = 'Top-Up Berhasil';
    } else {
      statusColor = Nebula.tealDark;
      statusBgColor = Nebula.tealLight;
      statusIcon = Icons.check_circle_outline;
      statusLabel = 'Pembayaran Berhasil';
    }

    final double screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final itemsAsync = ref.watch(transactionDetailsProvider(txId));

            return Container(
              height: screenHeight * 0.85,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle & Title
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.dividerCol,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rincian Transaksi',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 24),
                                color: context.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: context.borderLight),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderLight, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Header: ID & Status
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${tx.id.length >= 8 ? tx.id.substring(0, 8).toUpperCase() : tx.id.toUpperCase()}',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Nebula.teal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID Transaksi Sistem',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 12, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: context.borderLight),

                            // Details Properties Table
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                children: [
                                  _buildReceiptRow('Waktu Transaksi', timeStr),
                                  const SizedBox(height: 8),
                                  _buildReceiptRow('Jenis Transaksi', isTopup ? 'Top-Up Saldo' : 'Pembelian Makanan/Minuman'),
                                  const SizedBox(height: 8),
                                  _buildReceiptRow('Merchant / Lokasi', isTopup ? 'Koperasi Sekolah' : canteenName),
                                  const SizedBox(height: 8),
                                  _buildReceiptRow(
                                    'Metode Transaksi',
                                    isTopup
                                        ? 'Kasir Keuangan'
                                        : tx.purchaseMethodDisplay,
                                  ),
                                ],
                              ),
                            ),

                            // Dashed divider
                            _buildReceiptDashedDivider(),

                            // Itemized Section (if purchase)
                            if (!isTopup && !isCancelled)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rincian Pesanan:',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    itemsAsync.when(
                                      data: (items) {
                                        final effectiveItems = items.isNotEmpty
                                            ? items
                                            : (tx.transactionItems ?? <TransactionItem>[]);

                                        if (effectiveItems.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Transaksi Kasir ($canteenName)',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: context.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyFormatter.format(amount),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: context.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return Column(
                                          children: effectiveItems.map((item) {
                                            final img = item.imageUrl;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10.0),
                                              child: Row(
                                                children: [
                                                  if (img != null && img.isNotEmpty) ...[
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: SizedBox(
                                                        width: 36,
                                                        height: 36,
                                                        child: CachedNetworkImage(
                                                          imageUrl: img,
                                                          fit: BoxFit.cover,
                                                          placeholder: (_, __) => const ShimmerRect(
                                                            width: 36,
                                                            height: 36,
                                                            borderRadius: 8,
                                                          ),
                                                          errorWidget: (_, __, ___) => Container(
                                                            color: Nebula.teal.withValues(alpha: 0.1),
                                                            child: const Icon(Icons.fastfood, color: Nebula.teal, size: 18),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                  ],
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.productName,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: context.textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '@ ${CurrencyFormatter.format(item.unitPrice)}',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            color: context.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'x${item.quantity}',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: context.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        CurrencyFormatter.format(item.unitPrice * item.quantity),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: context.textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                      loading: () => Shimmer(
                                        child: Column(
                                          children: List.generate(
                                            2,
                                            (i) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: const [
                                                  SkeletonBox(width: 110, height: 13, borderRadius: 4),
                                                  SkeletonBox(width: 60, height: 13, borderRadius: 4),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      error: (_, __) => Text(
                                        'Gagal memuat item',
                                        style: GoogleFonts.inter(fontSize: 12, color: Nebula.rose),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Dashed divider
                            _buildReceiptDashedDivider(),

                            // Total Amount
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isTopup ? 'TOTAL TOP-UP' : 'TOTAL PEMBAYARAN',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(amount),
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCancelled ? context.textSecondary : (isTopup ? Nebula.teal : context.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action: Close Button
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Tutup Rincian',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0 ? Colors.transparent : context.dividerCol,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  // Groups list items into sections based on date
  Map<String, List<OperatorTransaction>> _groupTransactionsByDate(List<OperatorTransaction> txs) {
    final Map<String, List<OperatorTransaction>> groups = {};
    final now = DateTime.now();

    for (var tx in txs) {
      if (tx.createdAt == null) continue;
      final txDate = tx.createdAt!.toLocal();

      String sectionTitle;
      if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day) {
        sectionTitle = 'HARI INI';
      } else if (txDate.year == now.year && txDate.month == now.month && txDate.day == (now.day - 1)) {
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

  Widget _buildFilterSlideBar(BuildContext context, List<Map<String, dynamic>> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Nebula.teal : context.surfaceBg,
                    borderRadius: BorderRadius.circular(24),
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
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : context.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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

  Widget _buildLeadingThumbnail(BuildContext context, OperatorTransaction tx, Color indicatorColor, IconData badgeIcon, bool isTopup) {
    final hasImage = tx.imageUrl != null && tx.imageUrl!.isNotEmpty && !isTopup;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CachedNetworkImage(
            imageUrl: tx.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const ShimmerRect(
              width: 48,
              height: 48,
              borderRadius: 10,
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: indicatorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(badgeIcon, color: indicatorColor, size: 20),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(badgeIcon, color: indicatorColor, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(siswaTransactionsNotifierProvider);
    final List<OperatorTransaction> txs = txState.transactions;

    final int countJajan = txs.where((tx) => (tx.type ?? 'purchase') == 'purchase' && tx.status != 'cancelled' && tx.status != 'refunded').length;
    final int countTopUp = txs.where((tx) => (tx.type ?? 'purchase') == 'topup').length;
    final int countBatal = txs.where((tx) => tx.status == 'cancelled' || tx.status == 'refunded').length;

    final List<Map<String, dynamic>> tabs = [
      {'index': 0, 'label': AppStrings.labelAll, 'count': 0},
      {'index': 1, 'label': AppStrings.labelJajan, 'count': countJajan},
      {'index': 2, 'label': AppStrings.labelTopUp, 'count': countTopUp},
      {'index': 3, 'label': AppStrings.buttonCancel, 'count': countBatal},
    ];

    // Filter & search
    final filteredTxs = txs.where((tx) {
      final String type = tx.type ?? 'purchase';
      final String canteenName = (tx.canteenName ?? 'Kantin').toLowerCase();

      // Filter match
      final bool isCancelled = tx.status == 'cancelled' || tx.status == 'refunded';
      if (_selectedFilterIndex == 1 && (type != 'purchase' || isCancelled)) return false;
      if (_selectedFilterIndex == 2 && type != 'topup') return false;
      if (_selectedFilterIndex == 3 && !isCancelled) return false;

      // Date filter match
      if (_dateFilter != null && !_dateFilter!.isAllTime) {
        if (!_dateFilter!.matches(tx.createdAt)) return false;
      }

      // Search query match
      if (_searchQuery.isNotEmpty) {
        final matchesCanteen = canteenName.contains(_searchQuery.toLowerCase());
        final matchesId = tx.id.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesCanteen && !matchesId) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: context.surfaceBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(siswaTransactionsNotifierProvider.notifier).refresh();
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Unified Header Container (Title + Search & Date Filter + Sliding Tabs)
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
                        // Centered Page Title
                        Center(
                          child: Text(
                            'Riwayat',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 1. Full-width Single Unified Sleek Search Bar
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
                              hintText: 'Cari nama stan atau ID transaksi...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: context.textSecondary.withValues(alpha: 0.75),
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

                        // 2. Horizontal Scrolling Filter Chips Bar (Semua, Jajan, Top-Up, Batal)
                        _buildFilterSlideBar(context, tabs),
                        const SizedBox(height: 10),

                        // 3. Date Filter Bar (Di bawah Slide - Jumlah Transaksi di Kiri, Filter Tanggal di Kanan)
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

                  // History Transactions Grouped List with Lazy Loading & Infinite Scroll
                  Expanded(
                    child: _buildTransactionBody(context, txState, filteredTxs),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionBody(
    BuildContext context,
    SiswaTransactionsState txState,
    List<OperatorTransaction> filteredTxs,
  ) {
    if (txState.isLoading && txState.transactions.isEmpty) {
      return Shimmer(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderLight, width: 1.0),
                ),
                child: Row(
                  children: [
                    const SkeletonBox(width: 48, height: 48, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 120, height: 14, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonBox(width: 160, height: 11, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonBox(width: 80, height: 10, borderRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        SkeletonBox(width: 70, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(width: 50, height: 16, borderRadius: 4),
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

    if (txState.error != null && txState.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle, color: Nebula.rose, size: 48),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat riwayat transaksi',
                style: TextStyle(fontSize: 14, color: context.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                txState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(siswaTransactionsNotifierProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Nebula.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredTxs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.tray, color: context.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(
              'Tidak ada riwayat transaksi',
              style: TextStyle(fontSize: 14, color: context.textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final groupedTxs = _groupTransactionsByDate(filteredTxs);
    final groupKeys = groupedTxs.keys.toList();

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: groupKeys.length + (txState.isLoadingMore ? 1 : (txState.hasMore ? 0 : 1)),
      itemBuilder: (context, sectionIndex) {
        // Footer: Loading more or End of list
        if (sectionIndex >= groupKeys.length) {
          if (txState.isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Nebula.teal),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Memuat transaksi lainnya...',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Semua riwayat transaksi telah ditampilkan',
                  style: TextStyle(fontSize: 11, color: context.textSecondary.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
        }

        final sectionTitle = groupKeys[sectionIndex];
        final sectionItems = groupedTxs[sectionTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
              child: Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Transaction Cards in this Date Section
            Column(
              children: sectionItems.map((tx) {
                final String type = tx.type ?? 'purchase';
                final int amount = tx.totalAmount;
                final String canteenName = tx.canteenName ?? 'Kantin';
                final bool isTopup = type == 'topup';
                final bool isCancelled = tx.status == 'cancelled' || tx.status == 'refunded';
                final String timeStr = tx.createdAt != null
                    ? AppDateFormatter.formatTime(tx.createdAt)
                    : '-';

                // Indicator & badge colors
                Color indicatorColor;
                Color badgeBgColor;
                Color badgeTextColor;
                IconData badgeIcon;
                String badgeLabel;

                if (isCancelled) {
                  indicatorColor = Nebula.rose;
                  badgeBgColor = Nebula.rose.withValues(alpha: 0.08);
                  badgeTextColor = Nebula.rose;
                  badgeIcon = Icons.cancel_outlined;
                  badgeLabel = tx.status == 'refunded' ? 'Dikembalikan' : AppStrings.labelDibatalkan;
                } else if (isTopup) {
                  indicatorColor = Nebula.teal;
                  badgeBgColor = Nebula.teal.withValues(alpha: 0.08);
                  badgeTextColor = Nebula.teal;
                  badgeIcon = CupertinoIcons.square_arrow_down;
                  badgeLabel = AppStrings.labelTopUp;
                } else {
                  indicatorColor = Nebula.teal;
                  badgeBgColor = Nebula.tealLight;
                  badgeTextColor = Nebula.tealDark;
                  badgeIcon = Icons.check_circle_outline;
                  badgeLabel = AppStrings.labelSuccess;
                }

                return PressScale(
                  onTap: () => _showTransactionDetail(context, tx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderLight, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: context.shadowColor,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Leading Thumbnail / Icon
                        _buildLeadingThumbnail(context, tx, indicatorColor, badgeIcon, isTopup),
                        const SizedBox(width: 12),
                        // Center Column (Title, Time/ID, Method details)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTopup ? AppStrings.labelTopUpSaldo : canteenName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${isTopup ? AppStrings.labelKoperasi : tx.purchaseMethodDisplay} • $timeStr WIB',
                                style: TextStyle(color: context.textSecondary, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '#${tx.id.length >= 8 ? tx.id.substring(0, 8).toUpperCase() : tx.id.toUpperCase()}',
                                style: TextStyle(
                                  color: context.textSecondary.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Trailing Column (Amount & Status Badge)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isTopup ? '+' : '-'} ${CurrencyFormatter.format(amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isCancelled
                                    ? context.textSecondary
                                    : (isTopup ? Nebula.teal : context.textPrimary),
                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                  color: badgeTextColor,
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
}
