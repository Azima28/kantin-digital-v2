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
  
  // 3. Fetch recent 10 transactions (fetch more to support filtering up to 5 items)
  final List<dynamic> txs = await client
      .from('transactions')
      .select('id, total_amount, type, status, created_at, canteen_operators(canteen_name), transaction_items(quantity, products(name))')
      .eq('student_id', studentId)
      .order('created_at', ascending: false)
      .limit(15);
      
  return {
    'profile': profile,
    'student': student,
    'transactions': List<Map<String, dynamic>>.from(txs),
  };
});

class ParentDashboardScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ParentDashboardScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Pengeluaran', 'Top-up'

  String _getItemsSummary(Map<String, dynamic> tx) {
    if (tx['type'] == 'topup') {
      return 'Top-up Saldo via Bank Transfer';
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
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(parentDashboardProvider(widget.studentId));
    final double screenWidth = MediaQuery.of(context).size.width;

    const Color primaryTeal = Color(0xFF006767);
    const Color orangeAccent = Color(0xFF904D00);
    const Color bgWarm = Color(0xFFFBF9F8);
    const Color borderOutline = Color(0xFFE4E2E1);

    Widget buildHeader() {
      return Container(
        decoration: const BoxDecoration(
          color: bgWarm,
          border: Border(
            bottom: BorderSide(color: borderOutline, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kantin Digital',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal,
                  ),
                ),
                if (screenWidth > 600)
                  Row(
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => context.push('/parent/topup/${widget.studentId}'),
                        child: Text(
                          'Top-up',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.bell, color: primaryTeal, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.profile_circled, color: primaryTeal, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildFooter() {
      final bool isMobileFooter = screenWidth < 600;
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F3F2),
          border: Border(
            top: BorderSide(color: borderOutline, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                isMobileFooter
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Kantin Digital',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Text(
                                'Privacy Policy',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                              ),
                              Text(
                                'Terms of Service',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                              ),
                              Text(
                                'Help Center',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kantin Digital',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryTeal,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Privacy Policy',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Terms of Service',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Help Center',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                              ),
                            ],
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                Align(
                  alignment: isMobileFooter ? Alignment.center : Alignment.centerRight,
                  child: Text(
                    '© 2024 Kantin Digital. All rights reserved.',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildProfileCard(String name, String classStr) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderOutline.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF6F3F2), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCjS_sR94IW489aSAmJ7HRoTVXJOztQGQyyZ2-nw5O28aozVhQQ_M1kOMVW4S4xc_jDUEpVwAYGF9Yg4OPgHWmhFI0b4-GUN6dsThRvYcBmc97J1tjvLECSd785nSMydruGKseWbX94flm1BvtcQFnDW5Oa6mwHZ3sWYzwR86jC8n9XdDWOB5inBE7Ls1enLGPIXU8oZSVB2AVuXI7zdMTnOwFBNbBiB7yWUvlPCdYzUliGZfrA_XRq-QiX2vX61cof4_FjAo9euMI',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryLight,
                      child: const Icon(CupertinoIcons.person_fill, color: primaryTeal, size: 48),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: GoogleFonts.beVietnamPro(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SMP Terpadu Kota',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDED),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                classStr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildBalanceCard(double balance) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderOutline.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            // Ambient glow decorations
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8FF3F2).withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFDCC3).withValues(alpha: 0.25),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SALDO KANTIN SAAT INI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.format(balance),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push('/parent/topup/${widget.studentId}'),
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                  label: Text(
                    'TOP-UP SALDO ONLINE',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildFilterChipItem(String label) {
      final bool isSelected = _selectedFilter == label;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryTeal : const Color(0xFFF0EDED),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textGray,
            ),
          ),
        ),
      );
    }

    Widget buildHistoryCard(List<Map<String, dynamic>> txs) {
      // Filter transactions based on selection
      final filteredTxs = txs.where((tx) {
        if (_selectedFilter == 'Pengeluaran') {
          return tx['type'] == 'purchase';
        } else if (_selectedFilter == 'Top-up') {
          return tx['type'] == 'topup';
        }
        return true;
      }).toList();

      // Take only top 5 for dashboard
      final displayTxs = filteredTxs.take(5).toList();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderOutline.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            screenWidth < 500
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '5 AKTIVITAS JAJAN TERAKHIR ANAK',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          buildFilterChipItem('Semua'),
                          const SizedBox(width: 8),
                          buildFilterChipItem('Pengeluaran'),
                          const SizedBox(width: 8),
                          buildFilterChipItem('Top-up'),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '5 AKTIVITAS JAJAN TERAKHIR ANAK',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          buildFilterChipItem('Semua'),
                          const SizedBox(width: 8),
                          buildFilterChipItem('Pengeluaran'),
                          const SizedBox(width: 8),
                          buildFilterChipItem('Top-up'),
                        ],
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            if (displayTxs.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.tray, color: AppColors.textGray, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi jajanan anak',
                      style: GoogleFonts.beVietnamPro(color: AppColors.textGray, fontSize: 13),
                    ),
                  ],
                ),
              )
            else ...[
              // Table Header Row (Desktop only)
              if (screenWidth >= 600)
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0x0D006767), // 5% Teal opacity
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'TANGGAL & WAKTU',
                          style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGray),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'AKTIVITAS / ITEM',
                          style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGray),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'NOMINAL',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGray),
                        ),
                      ),
                    ],
                  ),
                ),

              // Transaction Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayTxs.length,
                separatorBuilder: (context, i) => const Divider(height: 1, color: borderOutline),
                itemBuilder: (context, i) {
                  final tx = displayTxs[i];
                  final double amount = double.tryParse(tx['total_amount'].toString()) ?? 0.0;
                  final String type = tx['type'] ?? 'purchase';
                  final bool isTopup = type == 'topup';

                  final DateTime date = tx['created_at'] != null 
                      ? DateTime.parse(tx['created_at']).toLocal() 
                      : DateTime.now();
                  final String dateStr = DateFormat('dd MMM yyyy').format(date);
                  final String timeStr = DateFormat('HH:mm').format(date);

                  final String summary = _getItemsSummary(tx);
                  final String canteen = tx['canteen_operators']?['canteen_name'] ?? 'Koperasi Siswa';

                  if (screenWidth < 600) {
                    // Mobile-friendly list layout
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      color: isTopup ? const Color(0xFFFFF2E0).withValues(alpha: 0.3) : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isTopup ? Icons.account_balance : Icons.restaurant,
                                    size: 14,
                                    color: isTopup ? primaryTeal : AppColors.textDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isTopup ? 'Top-Up Saldo' : canteen,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isTopup ? const Color(0xFF006A35) : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateStr \u2022 $timeStr WIB',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Desktop tabular table layout
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      color: isTopup ? const Color(0xFFFFF2E0).withValues(alpha: 0.3) : Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Col 1: Date & Time
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$timeStr WIB',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Col 2: Item & Location/Method
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isTopup ? Icons.account_balance : Icons.restaurant,
                                      size: 12,
                                      color: AppColors.textGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isTopup ? 'Dari Orang Tua' : canteen,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Col 3: Amount
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                              textAlign: TextAlign.end,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isTopup ? const Color(0xFF006A35) : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],

            const SizedBox(height: 24),
            // Show all history action button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Display a simple snackbar or list dialog since this is a 5-item dashboard mockup
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menampilkan semua ${filteredTxs.length} transaksi di riwayat lengkap.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.arrow_right, size: 16, color: primaryTeal),
                label: Text(
                  'Lihat Semua Riwayat',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgWarm,
      body: Column(
        children: [
          buildHeader(),
          Expanded(
            child: dataAsync.when(
              data: (data) {
                final profile = data['profile'] as Map<String, dynamic>;
                final student = data['student'] as Map<String, dynamic>;
                final txs = data['transactions'] as List<Map<String, dynamic>>;

                final String name = profile['full_name'] ?? 'Siswa';
                final String classStr = student['class'] ?? 'Kelas';
                final double balance = double.tryParse(student['balance'].toString()) ?? 0.0;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Change pupil code action
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => context.go('/parent'),
                                  icon: const Icon(CupertinoIcons.left_chevron, size: 14, color: primaryTeal),
                                  label: Text(
                                    'Ganti Kode Siswa',
                                    style: GoogleFonts.beVietnamPro(
                                      color: primaryTeal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Bento layout
                                screenWidth > 992
                                    ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Left Column (width 4/12)
                                          Expanded(
                                            flex: 4,
                                            child: Column(
                                              children: [
                                                buildProfileCard(name, classStr),
                                                const SizedBox(height: 24),
                                                buildBalanceCard(balance),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          // Right Column (width 8/12)
                                          Expanded(
                                            flex: 8,
                                            child: buildHistoryCard(txs),
                                          ),
                                        ],
                                      )
                                    : screenWidth >= 600
                                        ? Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: buildProfileCard(name, classStr),
                                                  ),
                                                  const SizedBox(width: 24),
                                                  Expanded(
                                                    child: buildBalanceCard(balance),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              buildHistoryCard(txs),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              buildProfileCard(name, classStr),
                                              const SizedBox(height: 24),
                                              buildBalanceCard(balance),
                                              const SizedBox(height: 24),
                                              buildHistoryCard(txs),
                                            ],
                                          ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      buildFooter(),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(80.0),
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat dashboard: $err', style: GoogleFonts.beVietnamPro(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
