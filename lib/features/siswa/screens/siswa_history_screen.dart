import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaHistoryScreen extends ConsumerStatefulWidget {
  const SiswaHistoryScreen({super.key});

  @override
  ConsumerState<SiswaHistoryScreen> createState() => _SiswaHistoryScreenState();
}

class _SiswaHistoryScreenState extends ConsumerState<SiswaHistoryScreen> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Jajan, 2: Top-Up

  void _showTransactionDetail(BuildContext context, Map<String, dynamic> tx) {
    final String txId = tx['id']?.toString() ?? '';
    final String type = tx['type']?.toString() ?? 'purchase';
    final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
    final String timeStr = tx['created_at'] != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx['created_at']).toLocal())
        : '-';
    final String canteenName = tx['canteen_operators']?['canteen_name'] ?? 'Kantin';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final itemsAsync = ref.watch(transactionDetailsProvider(txId));

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Detail Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success Banner Indicator
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: type == 'topup' ? AppColors.primary.withAlpha(20) : AppColors.success.withAlpha(20),
                          ),
                          child: Icon(
                            type == 'topup' ? CupertinoIcons.square_arrow_down : CupertinoIcons.check_mark_circled,
                            color: type == 'topup' ? AppColors.primary : AppColors.success,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type == 'topup' ? 'Top-Up Saldo Sukses' : 'Pembayaran Sukses',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ID Transaksi', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                      Text(txId.substring(0, 10).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Waktu', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                      Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode/Lokasi', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                      Text(type == 'topup' ? 'QRIS / Koperasi' : canteenName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                  
                  if (type == 'purchase') ...[
                    const Divider(height: 20),
                    const Text('Rincian Pembelian:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    itemsAsync.when(
                      data: (items) {
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];
                              final String name = item['products']?['name'] ?? 'Jajanan';
                              final double itemPrice = double.tryParse(item['unit_price'].toString()) ?? 0.0;
                              final int qty = int.tryParse(item['quantity'].toString()) ?? 1;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$qty x  $name', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                                    Text(CurrencyFormatter.format(itemPrice * qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(child: CupertinoActivityIndicator()),
                      error: (err, stack) => Text('Gagal memuat detail barang: $err', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                    ),
                  ],

                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type == 'topup' ? 'Total Masuk Saldo:' : 'Total Potong Saldo:', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        CurrencyFormatter.format(amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: type == 'topup' ? AppColors.primary : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // PDF Download button simulation
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Struk PDF berhasil diunduh'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Simpan Struk PDF',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Groups list items into sections based on date
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(List<Map<String, dynamic>> txs) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (var tx in txs) {
      if (tx['created_at'] == null) continue;
      final txDate = DateTime.parse(tx['created_at']).toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(txDate);

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

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          'Riwayat Jajan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
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
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Search Bar Input
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E9EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.search, color: AppColors.textGray, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
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

                      // Pill segmented filter (Semua, Jajan, Top-Up)
                      Row(
                        children: [
                          _buildFilterPill(0, 'Semua'),
                          const SizedBox(width: 8),
                          _buildFilterPill(1, 'Jajan'),
                          const SizedBox(width: 8),
                          _buildFilterPill(2, 'Top-Up'),
                        ],
                      ),
                    ],
                  ),
                ),

                // History Transactions Grouped List
                Expanded(
                  child: transactionsAsync.when(
                    data: (List<Map<String, dynamic>> txs) {
                      // Apply filter & search
                      final filteredTxs = txs.where((tx) {
                        final String type = tx['type']?.toString() ?? 'purchase';
                        final String canteenName = (tx['canteen_operators']?['canteen_name'] ?? 'Kantin').toString().toLowerCase();
                        
                        // Filter match
                        if (_selectedFilterIndex == 1 && type != 'purchase') return false;
                        if (_selectedFilterIndex == 2 && type != 'topup') return false;

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
                        return ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 80),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(CupertinoIcons.tray, color: AppColors.textGray, size: 48),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tidak ada riwayat transaksi',
                                      style: TextStyle(fontSize: 14, color: AppColors.textGray, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textGray,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              // Cards block container
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: sectionItems.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    height: 0.5,
                                    indent: 56,
                                    color: AppColors.borderLight,
                                  ),
                                  itemBuilder: (context, index) {
                                    final tx = sectionItems[index];
                                    final String type = tx['type']?.toString() ?? 'purchase';
                                    final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
                                    final String canteenName = tx['canteen_operators']?['canteen_name'] ?? 'Kantin';
                                    final bool isTopup = type == 'topup';
                                    final String timeStr = tx['created_at'] != null 
                                        ? DateFormat('HH:mm').format(DateTime.parse(tx['created_at']).toLocal())
                                        : '-';

                                    return ListTile(
                                      onTap: () => _showTransactionDetail(context, tx),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isTopup
                                              ? AppColors.primary.withAlpha(20)
                                              : const Color(0xFFF2F2F7),
                                        ),
                                        child: Icon(
                                          isTopup ? CupertinoIcons.square_arrow_down : Icons.restaurant,
                                          color: isTopup ? AppColors.primary : AppColors.textDark,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        isTopup ? 'Top-Up Saldo' : canteenName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
                                      ),
                                      subtitle: Text(
                                        '$timeStr WIB \u2022 ${isTopup ? "Koperasi" : "Jajan"}',
                                        style: const TextStyle(color: AppColors.textGray, fontSize: 11),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: isTopup ? AppColors.primary : AppColors.error,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            isTopup ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                            size: 12,
                                            color: isTopup ? AppColors.primary : AppColors.error,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (err, stack) => Center(child: Text('Gagal memuat riwayat: $err', style: const TextStyle(color: AppColors.error))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final bool isSelected = _selectedFilterIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textGray,
            ),
          ),
        ),
      ),
    );
  }
}
