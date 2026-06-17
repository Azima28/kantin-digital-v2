import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final adminMerchantDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final client = ref.read(supabaseClientProvider);
  
  // 1. Fetch profile
  final profile = await client.from('profiles').select().eq('id', id).single();
  
  // 2. Fetch merchant operator details
  final operator = await client.from('canteen_operators').select().eq('id', id).single();
  
  // 3. Fetch products catalog
  final List<dynamic> products = await client
      .from('products')
      .select('name, price, category, is_available')
      .eq('operator_id', id)
      .order('name', ascending: true);

  // 4. Fetch recent transactions
  final List<dynamic> txs = await client
      .from('transactions')
      .select('id, total_amount, created_at, student_id, profiles!transactions_student_id_fkey(nisn)')
      .eq('operator_id', id)
      .eq('status', 'success')
      .eq('type', 'purchase')
      .order('created_at', ascending: false)
      .limit(10);

  // Calculate live sales metrics
  double dailySales = 0;
  double monthlySales = 0;
  final now = DateTime.now().toLocal();
  final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  final startOfMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

  // Fetch all transactions this month for live aggregation
  final List<dynamic> monthTxs = await client
      .from('transactions')
      .select('total_amount, created_at')
      .eq('operator_id', id)
      .eq('status', 'success')
      .eq('type', 'purchase')
      .gte('created_at', '${startOfMonthStr}T00:00:00Z');

  for (var tx in monthTxs) {
    final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
    monthlySales += amount;

    final txDateStr = tx['created_at'] != null 
        ? DateTime.parse(tx['created_at']).toLocal().toIso8601String().substring(0, 10)
        : '';
    if (txDateStr == todayStr) {
      dailySales += amount;
    }
  }
      
  return {
    'profile': profile,
    'operator': operator,
    'products': List<Map<String, dynamic>>.from(products),
    'transactions': List<Map<String, dynamic>>.from(txs),
    'daily_sales_aggregated': dailySales,
    'monthly_sales_aggregated': monthlySales,
  };
});

class AdminMerchantDetailScreen extends ConsumerStatefulWidget {
  final String merchantId;
  const AdminMerchantDetailScreen({super.key, required this.merchantId});

  @override
  ConsumerState<AdminMerchantDetailScreen> createState() => _AdminMerchantDetailScreenState();
}

class _AdminMerchantDetailScreenState extends ConsumerState<AdminMerchantDetailScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(String profileId) async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) return;

    final client = ref.read(supabaseClientProvider);
    try {
      await client.from('profiles').update({'password': password}).eq('id', profileId);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi operator kantin berhasil diperbarui!'),
            backgroundColor: Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah kata sandi: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(String profileId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ubah Kata Sandi'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: _passwordController,
            placeholder: 'Masukkan sandi baru',
            obscureText: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _changePassword(profileId),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminMerchantDetailProvider(widget.merchantId));
    const Color primaryTeal = Color(0xFF003434);
    const Color successGreen = Color(0xFF006A35);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: primaryTeal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Operator',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (data) {
          final profile = data['profile'];
          final operator = data['operator'];
          final List<Map<String, dynamic>> products = data['products'];
          final List<Map<String, dynamic>> txs = data['transactions'];
          
          final String fullName = profile['full_name'] ?? '';
          final String username = profile['username'] ?? '';
          final String canteenName = operator['canteen_name'] ?? 'Stan Kantin';

          final double dailySales = data['daily_sales_aggregated'];
          final double monthlySales = data['monthly_sales_aggregated'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryTeal.withValues(alpha: 0.1),
                        child: Icon(Icons.shopping_bag, color: primaryTeal, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1C1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.storefront, size: 14, color: AppColors.textGray),
                                const SizedBox(width: 4),
                                Text(
                                  canteenName,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    color: AppColors.textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'USN: $username',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6F7978),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Change Password Button
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(profile['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield),
                  label: const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Performance grid
                Row(
                  children: [
                    // Daily Sales Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY SALES',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              CurrencyFormatter.format(dailySales),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1C1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+12% from yesterday',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                color: successGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Monthly Sales Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY SALES',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              CurrencyFormatter.format(monthlySales),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1C1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'On track for target',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                color: primaryTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2 columns section: Product Catalog (left) & Recent Sales (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catalog Column
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Product Catalog',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFEDEC),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'Read-Only',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (products.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(child: Text('Tidak ada produk.', style: TextStyle(fontSize: 12))),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: products.length,
                                separatorBuilder: (context, i) => const Divider(height: 16, color: Color(0xFFE4E2E1)),
                                itemBuilder: (context, i) {
                                  final p = products[i];
                                  final String name = p['name'] ?? '';
                                  final double price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
                                  final bool isAvailable = p['is_available'] ?? true;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1B1C1B),
                                              ),
                                            ),
                                            Text(
                                              CurrencyFormatter.format(price),
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 11,
                                                color: AppColors.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isAvailable 
                                              ? const Color(0xFFEAF9EE) 
                                              : const Color(0xFFFFDAD6),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isAvailable ? 'Avail' : 'Sold Out',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isAvailable ? successGreen : const Color(0xFFBA1A1A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Recent Sales Column
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Sales',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (txs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(child: Text('Belum ada penjualan.', style: TextStyle(fontSize: 12))),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: txs.length,
                                separatorBuilder: (context, i) => const Divider(height: 16, color: Color(0xFFE4E2E1)),
                                itemBuilder: (context, i) {
                                  final tx = txs[i];
                                  final double amount = double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
                                  final date = tx['created_at'] != null 
                                      ? DateTime.parse(tx['created_at']).toLocal() 
                                      : DateTime.now();
                                  final String nisn = tx['profiles']?['nisn'] ?? '-';

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'NISN: $nisn',
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1B1C1B),
                                              ),
                                            ),
                                            Text(
                                              DateFormat('HH:mm').format(date),
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 11,
                                                color: AppColors.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(amount),
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1B1C1B),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
