import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final parentDashboardProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, studentId) async {
  final client = ref.read(supabaseClientProvider);
  
  // 1. Fetch profile
  final profile = await client.from('profiles').select().eq('id', studentId).single();
  
  // 2. Fetch student
  final student = await client.from('students').select().eq('id', studentId).single();
  
  // 3. Fetch recent 5 transactions
  final List<dynamic> txs = await client
      .from('transactions')
      .select('id, total_amount, type, status, created_at, canteen_operators(canteen_name), transaction_items(quantity, products(name))')
      .eq('student_id', studentId)
      .order('created_at', ascending: false)
      .limit(5);
      
  return {
    'profile': profile,
    'student': student,
    'transactions': List<Map<String, dynamic>>.from(txs),
  };
});

class ParentDashboardScreen extends ConsumerWidget {
  final String studentId;
  const ParentDashboardScreen({super.key, required this.studentId});

  String _getItemsSummary(Map<String, dynamic> tx) {
    if (tx['type'] == 'topup') {
      return 'Top-up Saldo';
    }
    final items = tx['transaction_items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return 'Pembelian Jajanan';
    }
    return items.map((item) {
      final qty = item['quantity'] ?? 1;
      final name = item['products']?['name'] ?? 'Jajanan';
      return '$name (${qty}x)';
    }).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(parentDashboardProvider(studentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFBDC9C8).withValues(alpha: 0.3), width: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary),
          onPressed: () => context.go('/parent'),
        ),
        title: Text(
          'Dashboard Pantau Anak',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppColors.primary),
            onPressed: () {
              ref.invalidate(parentDashboardProvider(studentId));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentDashboardProvider(studentId));
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: dataAsync.when(
              data: (data) {
                final profile = data['profile'] as Map<String, dynamic>;
                final student = data['student'] as Map<String, dynamic>;
                final txs = data['transactions'] as List<Map<String, dynamic>>;

                final String name = profile['full_name'] ?? 'Siswa';
                final String classStr = student['class'] ?? '-';
                final double balance = double.tryParse(student['balance'].toString()) ?? 0.0;
                final bool isActive = student['is_active'] ?? true;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ganti Kode Siswa Link
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.go('/parent'),
                        icon: const Icon(CupertinoIcons.left_chevron, size: 12, color: AppColors.primary),
                        label: const Text(
                          'Ganti Kode Siswa',
                          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PROFIL SISWA Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROFIL SISWA',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryLight,
                                  child: const Icon(CupertinoIcons.person, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kelas: $classStr  •  SMP Terpadu Kota',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.success.withAlpha(20)
                                        : AppColors.error.withAlpha(20),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktif' : 'Dibekukan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SALDO AKTIF Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SALDO AKTIF SAAT INI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(balance),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  context.push('/parent/topup/$studentId');
                                },
                                child: const Text(
                                  'TOP-UP SALDO ONLINE',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5 AKTIVITAS JAJAN TERAKHIR
                      Text(
                        '5 AKTIVITAS JAJAN TERAKHIR ANAK',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (txs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight, width: 0.5),
                          ),
                          child: const Column(
                            children: [
                              Icon(CupertinoIcons.tray, color: AppColors.textGray, size: 36),
                              SizedBox(height: 8),
                              Text('Belum ada transaksi jajanan anak', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight, width: 0.5),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: txs.length,
                            separatorBuilder: (context, i) => const Divider(height: 0.5, color: AppColors.borderLight, indent: 56),
                            itemBuilder: (context, i) {
                              final tx = txs[i];
                              final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
                              final String type = tx['type'] ?? 'purchase';
                              final bool isTopup = type == 'topup';
                              
                              final DateTime date = tx['created_at'] != null 
                                  ? DateTime.parse(tx['created_at']).toLocal() 
                                  : DateTime.now();
                              final String dateStr = DateFormat('dd MMM, HH:mm').format(date);
                              
                              final String summary = _getItemsSummary(tx);
                              final String canteen = tx['canteen_operators']?['canteen_name'] ?? 'Koperasi';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isTopup ? AppColors.primary.withAlpha(20) : const Color(0xFFF2F2F7),
                                  ),
                                  child: Icon(
                                    isTopup ? CupertinoIcons.square_arrow_down : Icons.restaurant,
                                    color: isTopup ? AppColors.primary : AppColors.textDark,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  isTopup ? 'Top-Up Saldo Sukses' : canteen,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                                ),
                                subtitle: Text(
                                  '$dateStr WIB \u2022 $summary',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textGray, fontSize: 11),
                                ),
                                trailing: Text(
                                  '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isTopup ? AppColors.primary : AppColors.error,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CupertinoActivityIndicator(radius: 12),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal mengambil data dashboard: $err', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
