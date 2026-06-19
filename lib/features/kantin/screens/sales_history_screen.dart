import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

final operatorActivitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final profile = ref.read(authNotifierProvider).profile;
  final operatorId = profile?['id'];
  
  if (operatorId == null) return [];
  
  final List<dynamic> res = await client
      .from('audit_logs')
      .select('id, action_type, description, created_at, old_value, new_value')
      .eq('actor_id', operatorId)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(res);
});

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _selectedActivity = 'Semua Aktivitas';

  Future<void> _handleRefund(
    BuildContext context,
    String txId,
    double amount,
    String studentName,
  ) async {
    final authState = ref.read(authNotifierProvider);
    final String? operatorId = authState.profile?['id'];
    if (operatorId == null) return;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Refund Transaksi'),
        content: Text('Apakah Anda yakin ingin membatalkan transaksi belanja senilai ${CurrencyFormatter.format(amount)} oleh $studentName? Saldo siswa akan dikembalikan.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final client = ref.read(supabaseClientProvider);
                
                await client.rpc(
                  'process_refund',
                  params: {
                    'p_transaction_id': txId,
                    'p_operator_id': operatorId,
                    'p_reason': 'Dibatalkan oleh petugas kantin',
                  },
                );

                // Write to audit log
                try {
                  final actorName = authState.profile?['full_name'] ?? 'Petugas Kantin';
                  await client.from('audit_logs').insert({
                    'actor_id': operatorId,
                    'actor_name': actorName,
                    'action_type': 'REFUND_TRANSAKSI',
                    'description': 'Refund transaksi $txId senilai ${CurrencyFormatter.format(amount)} untuk siswa $studentName.',
                    'target_id': txId,
                    'new_value': {'amount': amount, 'student_name': studentName},
                  });
                } catch (_) {}

                // Refresh state
                ref.invalidate(operatorTransactionsProvider);
                ref.invalidate(todayRevenueProvider);
                ref.invalidate(siswaStudentProvider);
                ref.invalidate(siswaTransactionsProvider);
                ref.invalidate(operatorActivitiesProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi berhasil dibatalkan dan saldo dikembalikan.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memproses refund: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, OperatorTransaction tx) {
    final String txId = tx.id;
    final double amount = tx.totalAmount;
    final String studentName = tx.studentName ?? 'Siswa';
    final String timeStr = tx.createdAt != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt!.toLocal())
        : '-';

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
                      'Rincian Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pelanggan', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                      Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                  const Text(
                    'Item Jajanan:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                  ),
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
                            final String name = item.productName;
                            final double itemPrice = item.unitPrice;
                            final int qty = item.quantity;

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
                    error: (err, stack) => Text('Gagal memuat item: $err', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        CurrencyFormatter.format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(operatorTransactionsProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.systemBackground,
        appBar: AppBar(
          title: const Text(
            'Riwayat Jualan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          centerTitle: true,
          backgroundColor: AppColors.cardBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGray,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Penjualan'),
              Tab(text: 'Aktivitas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Penjualan list
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(operatorTransactionsProvider);
                ref.invalidate(todayRevenueProvider);
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Revenue statistics header
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL PENDAPATAN HARI INI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              revenueAsync.when(
                                data: (double revenue) => Text(
                                  CurrencyFormatter.format(revenue),
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                loading: () => const CupertinoActivityIndicator(),
                                error: (err, stack) => const Text('Gagal menghitung', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        ),
                      ),
      
                      // Transactions title
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Aktivitas Penjualan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                      ),
      
                      // Transactions list
                      transactionsAsync.when(
                        data: (List<OperatorTransaction> txs) {
                          if (txs.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(CupertinoIcons.square_list, size: 48, color: AppColors.textGray),
                                      SizedBox(height: 12),
                                      Text(
                                        'Belum ada penjualan',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Transaksi jajan dari kasir POS akan muncul di sini.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.textGray, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
      
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final tx = txs[index];
                                  final String id = tx.id;
                                  final double amount = tx.totalAmount;
                                  final String studentName = tx.studentName ?? 'Siswa';
                                  final String status = tx.status ?? 'success';
                                  
                                  final DateTime createdAt = tx.createdAt?.toLocal() ?? DateTime.now();
                                  final String timeStr = DateFormat('HH:mm').format(createdAt);
                                  final String dateStr = DateFormat('dd MMM').format(createdAt);
      
                                  final bool isCancelled = status == 'cancelled';
                                  final bool isFailed = status == 'failed';
                                  
                                  // Can refund only if it is a successful purchase and less than 10 minutes ago
                                  final bool isWithinRefundWindow = DateTime.now().difference(createdAt).inMinutes < 10;
                                  final bool canRefund = status == 'success' && tx.type == 'purchase' && isWithinRefundWindow;
      
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.borderLight, width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon Status
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCancelled || isFailed
                                                ? AppColors.error.withValues(alpha: 0.1)
                                                : AppColors.primary.withValues(alpha: 0.1),
                                          ),
                                          child: Icon(
                                            isCancelled
                                                ? CupertinoIcons.arrow_counterclockwise
                                                : isFailed
                                                    ? CupertinoIcons.xmark
                                                    : CupertinoIcons.shopping_cart,
                                            color: isCancelled || isFailed ? AppColors.error : AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
      
                                        // Description Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _showTransactionDetails(context, tx),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      studentName,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textDark,
                                                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(CupertinoIcons.info_circle, size: 12, color: AppColors.textGray),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$timeStr WIB \u2022 $dateStr',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                                              ),
                                            ],
                                          ),
                                        ),
      
                                        // Right actions / values
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isCancelled ? "" : "-"}${CurrencyFormatter.format(amount)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled || isFailed ? AppColors.textGray : AppColors.textDark,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            if (isCancelled)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Refunded',
                                                  style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              )
                                            else if (canRefund)
                                              GestureDetector(
                                                onTap: () => _handleRefund(context, id, amount, studentName),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.errorLight,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 0.5),
                                                  ),
                                                  child: const Text(
                                                    'Refund',
                                                    style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              )
                                            else
                                              const Text(
                                                'Berhasil',
                                                style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                childCount: txs.length,
                              ),
                            ),
                          );
                        },
                        loading: () => const SliverFillRemaining(
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 12),
                          ),
                        ),
                        error: (err, stack) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Gagal memuat transaksi: $err',
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Tab 2: Aktivitas list
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(operatorActivitiesProvider);
              },
              child: _buildActivitiesTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    final activitiesAsync = ref.watch(operatorActivitiesProvider);
    
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Dropdown Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivity,
                    isExpanded: true,
                    style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedActivity = val;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'Semua Aktivitas', child: Text('Semua Aktivitas')),
                      DropdownMenuItem(value: 'Tambah Menu', child: Text('Tambah Menu')),
                      DropdownMenuItem(value: 'Ubah Menu', child: Text('Ubah Menu')),
                      DropdownMenuItem(value: 'Refund Transaksi', child: Text('Refund Transaksi')),
                    ],
                  ),
                ),
              ),
            ),
            
            // Activities List
            Expanded(
              child: activitiesAsync.when(
                data: (logs) {
                  // Filter logs
                  final filtered = logs.where((log) {
                    final type = log['action_type']?.toString() ?? '';
                    if (_selectedActivity == 'Tambah Menu') {
                      return type == 'TAMBAH_PRODUK';
                    } else if (_selectedActivity == 'Ubah Menu') {
                      return type == 'UBAH_PRODUK';
                    } else if (_selectedActivity == 'Refund Transaksi') {
                      return type == 'REFUND_TRANSAKSI';
                    }
                    return true; // Semua Aktivitas
                  }).toList();
                  
                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(80.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.list_bullet, size: 48, color: AppColors.textGray),
                                SizedBox(height: 12),
                                Text(
                                  'Tidak ada aktivitas',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final log = filtered[index];
                      final type = log['action_type']?.toString() ?? '';
                      final desc = log['description']?.toString() ?? '';
                      final createdAt = log['created_at'] != null 
                          ? DateTime.tryParse(log['created_at'].toString())?.toLocal() 
                          : null;
                      final timeStr = createdAt != null 
                          ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt) 
                          : '-';
                          
                      IconData iconData = CupertinoIcons.info;
                      Color iconColor = AppColors.primary;
                      
                      if (type == 'TAMBAH_PRODUK') {
                        iconData = CupertinoIcons.add_circled;
                        iconColor = AppColors.success;
                      } else if (type == 'UBAH_PRODUK') {
                        iconData = CupertinoIcons.pencil_circle;
                        iconColor = Colors.orange;
                      } else if (type == 'REFUND_TRANSAKSI') {
                        iconData = CupertinoIcons.arrow_counterclockwise_circle;
                        iconColor = AppColors.error;
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(iconData, color: iconColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(child: Text('Gagal memuat aktivitas: $err', style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
