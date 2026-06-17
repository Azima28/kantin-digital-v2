import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:intl/intl.dart';

class SiswaDashboardScreen extends ConsumerWidget {
  const SiswaDashboardScreen({super.key});

  Future<void> _toggleFreeze(BuildContext context, WidgetRef ref, bool currentStatus, String studentId) async {
    // Show confirmation dialog first
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(currentStatus ? 'Bekukan Kartu' : 'Aktifkan Kartu'),
        content: Text(currentStatus
            ? 'Apakah Anda yakin ingin membekukan kartu? Kartu tidak akan bisa digunakan jajan sementara waktu.'
            : 'Apakah Anda yakin ingin mengaktifkan kembali kartu Anda?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: currentStatus,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final client = ref.read(supabaseClientProvider);
                await client
                    .from('students')
                    .update({'is_active': !currentStatus})
                    .eq('id', studentId);
                
                ref.invalidate(siswaStudentProvider);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(!currentStatus ? 'Kartu berhasil diaktifkan kembali!' : 'Kartu Anda telah dibekukan sementara.'),
                      backgroundColor: !currentStatus ? AppColors.success : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memproses status kartu: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(currentStatus ? 'Bekukan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }

  // Open transaction detail bottom sheet
  void _showTransactionDetail(BuildContext context, WidgetRef ref, Map<String, dynamic> tx) {
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
                  // iOS Grab Handle
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

                  // Success Centered Checkmark/Plus
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

                  // Details
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
                  
                  // PDF Download button
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Siswa';
    final studentAsync = ref.watch(siswaStudentProvider);
    final transactionsAsync = ref.watch(siswaTransactionsProvider);

    const String avatarUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD6arrvyi-ml6AobqY9iRVH-bAtGVKv5rVu0nJZT7i59FPT_OmA4PkCVPZcxohJcnFeNHKKxMlEGwczp9sGTCXSBRwZ53UWn6wqnvQJ6ESGLnCiLIiN_siAQAl3ysBbcCnbqsWvVJQgzGe7XPjzFZ9SP8Jo8H1m8mKOOxLJ4D4ztLEW7kLenZqki4o7cC7O6heqxWa4pbHjqDA0xw5v3YHUJmVtFdFT1-1kR5VAk7w4jCOrdL8gf41TENBbruzO8EieiPGMS_p5etA';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        backgroundColor: const Color(0xFFF9F9FE),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFBDC9C8).withValues(alpha: 0.3), width: 0.5),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE5E5EA),
              ),
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(CupertinoIcons.person, color: Color(0xFF006767)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $fullName!',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3D4949), fontWeight: FontWeight.w500),
                ),
                Text(
                  'Beranda',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006767),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: Color(0xFF006767)),
            onPressed: () => context.push('/student/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaStudentProvider);
          ref.invalidate(siswaTransactionsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Balance Card
              studentAsync.when(
                data: (student) {
                  if (student == null) return const SizedBox();
                  final double balance = double.tryParse(student['balance'].toString()) ?? 0.0;
                  final bool isActive = student['is_active'] ?? true;
                  final String studentId = student['id'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Decorative Background Shape
                              Positioned(
                                top: -48,
                                right: -48,
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF72D6D6).withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'SALDO SAKU',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF3D4949),
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? const Color(0xFF006767).withValues(alpha: 0.1)
                                              : const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isActive ? 'Aktif' : 'Dibekukan',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isActive ? const Color(0xFF006767) : const Color(0xFFBA1A1A),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              isActive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock_fill,
                                              size: 14,
                                              color: isActive ? const Color(0xFF006767) : const Color(0xFFBA1A1A),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Text(
                                        'Rp',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1C1F),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        NumberFormat('#,###', 'id_ID').format(balance),
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF006767),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Actions Grid
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/student/topup'),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006767),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(CupertinoIcons.add, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Isi Saldo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleFreeze(context, ref, isActive, studentId),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E2E7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isActive ? CupertinoIcons.lock : CupertinoIcons.lock_open,
                                      color: const Color(0xFF1A1C1F),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isActive ? 'Bekukan' : 'Aktifkan',
                                      style: const TextStyle(
                                        color: Color(0xFF1A1C1F),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                error: (err, stack) => Text('Gagal memuat saldo: $err', style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: 28),

              // Jajan Hari Ini Title & Lihat Semua link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jajan Hari Ini',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/student/history'),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transactions List (Only show today's)
              transactionsAsync.when(
                data: (List<Map<String, dynamic>> txs) {
                  final now = DateTime.now();
                  final todayTxs = txs.where((tx) {
                    if (tx['created_at'] == null) return false;
                    final txDate = DateTime.parse(tx['created_at']).toLocal();
                    return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
                  }).toList();

                  if (todayTxs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.tray, color: Color(0xFF7A7A7A), size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada transaksi hari ini',
                            style: TextStyle(fontSize: 13, color: Color(0xFF7A7A7A)),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: todayTxs.map((tx) {
                      final String type = tx['type']?.toString() ?? 'purchase';
                      final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
                      final String canteenName = tx['canteen_operators']?['canteen_name'] ?? 'Kantin';
                      
                      final txTime = tx['created_at'] != null 
                          ? DateFormat('HH:mm').format(DateTime.parse(tx['created_at']).toLocal())
                          : '-';

                      final bool isTopup = type == 'topup';

                      return InkWell(
                        onTap: () => _showTransactionDetail(context, ref, tx),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isTopup
                                      ? const Color(0xFF006767).withValues(alpha: 0.1)
                                      : const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isTopup ? CupertinoIcons.square_arrow_down : Icons.restaurant,
                                  color: isTopup ? const Color(0xFF006767) : const Color(0xFF1A1C1F),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTopup ? 'Top-Up Saldo' : canteenName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                        color: Color(0xFF1A1C1F),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$txTime WIB \u2022 ${isTopup ? "Koperasi" : "Jajan"}',
                                      style: const TextStyle(
                                        color: Color(0xFF3D4949),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: isTopup ? const Color(0xFF006767) : const Color(0xFFBA1A1A),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    isTopup ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                    size: 12,
                                    color: isTopup ? const Color(0xFF006767) : const Color(0xFFBA1A1A),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Text('Gagal memuat transaksi: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
