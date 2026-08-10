import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/models/models.dart';

import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaHistoryScreen extends ConsumerStatefulWidget {
  const SiswaHistoryScreen({super.key});

  @override
  ConsumerState<SiswaHistoryScreen> createState() => _SiswaHistoryScreenState();
}

class _SiswaHistoryScreenState extends ConsumerState<SiswaHistoryScreen> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Jajan, 2: Top-Up, 3: Dibatalkan

  void _showTransactionDetail(BuildContext context, OperatorTransaction tx) {
    final String txId = tx.id;
    final String type = tx.type ?? 'purchase';
    final int amount = tx.totalAmount;
    final String timeStr = tx.createdAt != null 
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt!.toLocal())
        : '-';
    final String canteenName = tx.canteenName ?? 'Kantin';
    final bool isCancelled = tx.status == 'cancelled';
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
      statusLabel = 'Dibatalkan';
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderLight, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header: Order number + Status badge
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${txId.substring(0, 8).toUpperCase()}',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Nebula.teal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID: $txId',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(statusIcon, size: 12, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
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

                            // Metadata
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildReceiptMeta('Waktu Transaksi', timeStr),
                                  const SizedBox(height: 8),
                                  _buildReceiptMeta(
                                    'Kantin / Sumber',
                                    isTopup ? 'Koperasi' : canteenName,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildReceiptMeta(
                                    'Metode',
                                    isTopup ? 'QRIS / Koperasi' : (tx.purchaseMethod == 'app' ? 'Aplikasi' : 'RFID / NFC'),
                                  ),
                                ],
                              ),
                            ),

                            // Dashed divider
                            _buildReceiptDashedDivider(),

                            // Items (for purchases only)
                            if (type == 'purchase')
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item Pembelian:',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    itemsAsync.when(
                                      data: (items) => Column(
                                        children: items.map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: context.surfaceBg,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: context.borderLight, width: 0.5),
                                                  ),
                                                  child: Icon(
                                                    Icons.fastfood_outlined,
                                                    color: context.textSecondary,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
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
                                                        '@Rp ${NumberFormat('#,###', 'id_ID').format(item.unitPrice)}',
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
                                                      'Rp ${NumberFormat('#,###', 'id_ID').format(item.unitPrice * item.quantity)}',
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
                                      ),
                                      loading: () => const Center(child: CupertinoActivityIndicator()),
                                      error: (_, __) => Text(
                                        'Gagal memuat item',
                                        style: GoogleFonts.inter(fontSize: 12, color: Nebula.rose),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // For topup or cancelled, show type note
                            if (isTopup || isCancelled)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isTopup ? CupertinoIcons.square_arrow_down : Icons.cancel_outlined,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isTopup
                                          ? 'Penambahan saldo sebesar Rp ${NumberFormat('#,###', 'id_ID').format(amount)}'
                                          : 'Transaksi ini telah dibatalkan',
                                      style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                                    ),
                                  ],
                                ),
                              ),

                            // Dashed divider
                            _buildReceiptDashedDivider(),

                            // Total
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isTopup ? 'TOTAL MASUK SALDO' : 'TOTAL POTONG SALDO',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isCancelled
                                          ? context.textSecondary
                                          : (isTopup ? Nebula.teal : context.textPrimary),
                                      decoration: isCancelled ? TextDecoration.lineThrough : null,
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

                  // Bottom close button
                  Container(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
                    color: context.cardBg,
                    child: SizedBox(
                      width: double.infinity,
                      child: PressScale(
                        onTap: () => Navigator.pop(context),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Tutup'),
                        ),
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

  Widget _buildReceiptMeta(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
      ],
    );
  }

  Widget _buildReceiptDashedDivider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    final todayStr = DateFormat('yyyy-MM-dd', 'id_ID').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd', 'id_ID').format(now.subtract(const Duration(days: 1)));

    for (var tx in txs) {
      if (tx.createdAt == null) continue;
      final txDate = tx.createdAt!.toLocal();
      final dateKey = DateFormat('yyyy-MM-dd', 'id_ID').format(txDate);

      String sectionTitle;
      if (dateKey == todayStr) {
        sectionTitle = 'HARI INI';
      } else if (dateKey == yesterdayStr) {
        sectionTitle = 'KEMARIN';
      } else {
        sectionTitle = DateFormat('d MMMM yyyy', 'id_ID').format(txDate).toUpperCase();
      }

      if (!groups.containsKey(sectionTitle)) {
        groups[sectionTitle] = [];
      }
      groups[sectionTitle]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(siswaTransactionsProvider);
    final List<OperatorTransaction> txs = transactionsAsync.value ?? <OperatorTransaction>[];

    final int countJajan = txs.where((tx) => (tx.type ?? 'purchase') == 'purchase' && tx.status != 'cancelled').length;
    final int countTopUp = txs.where((tx) => (tx.type ?? 'purchase') == 'topup').length;
    final int countBatal = txs.where((tx) => tx.status == 'cancelled').length;

    final List<Map<String, dynamic>> tabs = [
      {'index': 0, 'label': AppStrings.labelAll, 'count': 0},
      {'index': 1, 'label': AppStrings.labelJajan, 'count': countJajan},
      {'index': 2, 'label': AppStrings.labelTopUp, 'count': countTopUp},
      {'index': 3, 'label': AppStrings.buttonCancel, 'count': countBatal},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Riwayat Jajan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaTransactionsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Search Bar & Filters Header Container
                Container(
                  color: context.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Search Bar Input
                      Container(
                        decoration: BoxDecoration(
                          color: context.surfaceBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.search, color: context.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(fontSize: 14, color: context.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama stan jajan...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sliding segmented control filter (Semua, Jajan, Top-Up, Batal)
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          decoration: BoxDecoration(
                            color: context.surfaceBg,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: context.borderLight,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double tabWidth = constraints.maxWidth / tabs.length;

                              return Stack(
                                children: [
                                  // Sliding indicator
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeInOut,
                                    left: _selectedFilterIndex * tabWidth,
                                    top: 0,
                                    bottom: 0,
                                    width: tabWidth,
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Nebula.teal, // active tab background
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Nebula.teal.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab buttons
                                  Row(
                                    children: tabs.map((tab) {
                                      final int index = tab['index'];
                                      final String label = tab['label'];
                                      final int count = tab['count'];
                                      final bool isSelected = index == _selectedFilterIndex;

                                      return Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              _selectedFilterIndex = index;
                                            });
                                          },
                                          child: AnimatedScale(
                                            scale: isSelected ? 1.03 : 1.0,
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeInOut,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: AnimatedDefaultTextStyle(
                                                      duration: const Duration(milliseconds: 250),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                        color: isSelected ? Colors.white : context.textSecondary,
                                                      ),
                                                      child: Text(
                                                        label,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  if (count > 0) ...[
                                                    const SizedBox(width: 4),
                                                    AnimatedContainer(
                                                      duration: const Duration(milliseconds: 250),
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.blueAccent,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      constraints: const BoxConstraints(
                                                        minWidth: 16,
                                                        minHeight: 16,
                                                      ),
                                                      child: Text(
                                                        '$count',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
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
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // History Transactions Grouped List
                Expanded(
                  child: transactionsAsync.when(
                    data: (List<OperatorTransaction> txs) {
                      // Apply filter & search
                      final filteredTxs = txs.where((tx) {
                        final String type = tx.type ?? 'purchase';
                        final String canteenName = (tx.canteenName ?? 'Kantin').toLowerCase();
                        
                        // Filter match
                        final bool isCancelled = tx.status == 'cancelled';
                        if (_selectedFilterIndex == 1 && (type != 'purchase' || isCancelled)) return false;
                        if (_selectedFilterIndex == 2 && type != 'topup') return false;
                        if (_selectedFilterIndex == 3 && !isCancelled) return false;

                        // Search query match
                        if (_searchQuery.isNotEmpty) {
                          if (type == 'topup') {
                            return 'top-up saldo'.contains(_searchQuery) || 'koperasi'.contains(_searchQuery);
                          }
                          return canteenName.contains(_searchQuery);
                        }
                        return true;
                      }).toList();

                      if (filteredTxs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.tray, color: context.textSecondary, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Tidak ada riwayat transaksi',
                                style: TextStyle(fontSize: 14, color: context.textSecondary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }

                      final groupedTxs = _groupTransactionsByDate(filteredTxs);

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedTxs.length,
                        itemBuilder: (context, sectionIndex) {
                          final sectionTitle = groupedTxs.keys.elementAt(sectionIndex);
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

                              // Transaction Cards
                              Column(
                                children: sectionItems.map((tx) {
                                  final String type = tx.type ?? 'purchase';
                                  final int amount = tx.totalAmount;
                                  final String canteenName = tx.canteenName ?? 'Kantin';
                                  final bool isTopup = type == 'topup';
                                  final bool isCancelled = tx.status == 'cancelled';
                                  final String timeStr = tx.createdAt != null 
                                      ? DateFormat('HH:mm', 'id_ID').format(tx.createdAt!.toLocal())
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
                                    badgeLabel = AppStrings.labelDibatalkan;
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
                                          // Leading status icon container
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: indicatorColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(badgeIcon, color: indicatorColor, size: 20),
                                          ),
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
                                                  '${isTopup ? AppStrings.labelKoperasi : (tx.purchaseMethod == 'app' ? AppStrings.labelJajanAplikasi : AppStrings.labelJajanKasir)} • $timeStr WIB',
                                                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '#${tx.id.substring(0, 8).toUpperCase()}',
                                                  style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Trailing Column (Amount & Status Badge)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: isCancelled
                                                      ? context.textSecondary
                                                      : (isTopup ? Nebula.teal : context.textPrimary),
                                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: badgeBgColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(badgeIcon, size: 10, color: badgeTextColor),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      badgeLabel,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: badgeTextColor,
                                                      ),
                                                    ),
                                                  ],
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
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (err, stack) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GradientLine(),
                            const SizedBox(height: 8),
                            Text('${AppStrings.labelFailed} memuat riwayat', style: TextStyle(color: Nebula.rose)),
                            const SizedBox(height: 8),
                            PressScale(
                              onTap: () => ref.invalidate(siswaTransactionsProvider),
                              child: ElevatedButton(
                                onPressed: () => ref.invalidate(siswaTransactionsProvider),
                                child: const Text(AppStrings.buttonRetry),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}