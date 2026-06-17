import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:intl/intl.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun kasir?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final String canteenName = authState.profile?['canteen_name'] ?? 'Stan Kantin';
    final revenueAsync = ref.watch(todayRevenueProvider);
    final transactionsAsync = ref.watch(operatorTransactionsProvider);

    const String avatarUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAj9v7hCFkrRMAey43LSqCsH44EKtneScrHLtAbaq6ds1WZOLUwWuTjULCt-RAxdUsHfVqA4YVlpA0Xt52989-Cz_lGBEGQ_lC4s82hTAGoVB_0f0MrONfgiu-EWk-JYao2dwaXApSFQsp41tQzh38H1K1sf7Zgy0D21UR-tkIBvJCscPwhynCK-7XZjwElD3qjwM9pLSA6WjPWAXPHBBDTjXQ2U_RmLDJyBviDR4jfZvqq0SfKYRC8BGNieqbbXrKyYBwE5NEVcbY';

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
                  'Halo, $canteenName!',
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
            icon: const Icon(CupertinoIcons.square_arrow_right, color: AppColors.error),
            onPressed: () => _handleLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayRevenueProvider);
          ref.invalidate(operatorTransactionsProvider);
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
              // Earnings Card
              revenueAsync.when(
                data: (revenue) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                        'PENDAPATAN HARI INI',
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
                                          color: const Color(0xFF006767).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'Buka',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF006767),
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              CupertinoIcons.checkmark_seal_fill,
                                              size: 14,
                                              color: Color(0xFF006767),
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
                                        NumberFormat('#,###', 'id_ID').format(revenue),
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
                    ],
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                error: (err, stack) => Text('Gagal memuat pendapatan: $err', style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: 12),

              // Quick Actions Grid Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/pos/terminal'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006767),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.square_grid_2x2, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Kasir POS',
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
                      onTap: () => context.go('/pos/check-card'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.creditcard, color: Color(0xFF1A1C1F), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Cek Kartu',
                              style: TextStyle(
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
              const SizedBox(height: 28),

              // Penjualan Hari Ini Title & Lihat Semua link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Penjualan Hari Ini',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/pos/sales'),
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
                            'Belum ada penjualan hari ini',
                            style: TextStyle(fontSize: 13, color: Color(0xFF7A7A7A)),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: todayTxs.map((tx) {
                      final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
                      final String studentName = tx['students']?['profiles']?['full_name'] ?? 'Siswa';
                      final String status = tx['status']?.toString() ?? 'success';
                      final bool isCancelled = status == 'cancelled';
                      
                      final txTime = tx['created_at'] != null 
                          ? DateFormat('HH:mm').format(DateTime.parse(tx['created_at']).toLocal())
                          : '-';

                      return Container(
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
                                color: isCancelled
                                    ? const Color(0xFFBA1A1A).withValues(alpha: 0.1)
                                    : const Color(0xFF006767).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCancelled ? CupertinoIcons.xmark_circle : CupertinoIcons.creditcard,
                                color: isCancelled ? const Color(0xFFBA1A1A) : const Color(0xFF006767),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCancelled ? 'Pembelian Dibatalkan' : studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: Color(0xFF1A1C1F),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$txTime WIB \u2022 ${isCancelled ? "Refund" : "Penjualan"}',
                                    style: const TextStyle(
                                      color: Color(0xFF3D4949),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isCancelled ? "-" : "+"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: isCancelled ? const Color(0xFFBA1A1A) : const Color(0xFF006767),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Text('Gagal memuat riwayat: $err', style: const TextStyle(color: AppColors.error)),
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
