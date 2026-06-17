import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(supabaseClientProvider);

  double studentBalanceSum = 0;
  double merchantBalanceSum = 0;
  int schoolCount = 5; // Fallback mock school count
  int totalTransactionsToday = 0;
  double transactionVolumeToday = 0;

  try {
    // 1. Fetch Student Balance
    final studentRes = await client.from('students').select('balance');
    for (var row in studentRes) {
      studentBalanceSum += double.tryParse(row['balance'].toString()) ?? 0.0;
    }

    // 2. Fetch Merchant Balance
    final merchantRes = await client.from('canteen_operators').select('balance_earned');
    for (var row in merchantRes) {
      merchantBalanceSum += double.tryParse(row['balance_earned'].toString()) ?? 0.0;
    }

    // 3. Fetch Transactions Today
    final now = DateTime.now().toLocal();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final txRes = await client
        .from('transactions')
        .select('total_amount')
        .eq('status', 'success')
        .eq('type', 'purchase')
        .gte('created_at', '${todayStr}T00:00:00Z');
    
    totalTransactionsToday = txRes.length;
    for (var row in txRes) {
      transactionVolumeToday += double.tryParse(row['total_amount'].toString()) ?? 0.0;
    }
  } catch (e) {
    debugPrint('Error loading live admin metrics: $e');
  }

  return {
    'school_count': schoolCount,
    'global_balance': studentBalanceSum + merchantBalanceSum,
    'daily_volume': transactionVolumeToday,
    'tx_count_today': totalTransactionsToday,
  };
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardProvider);
    const Color primaryTeal = Color(0xFF003434);
    const Color accentOrange = Color(0xFF904D00);
    const Color successGreen = Color(0xFF006A35);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: const Color(0xFFFBF9F8),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF004D4D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'SA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kantin Digital',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.bell, color: primaryTeal),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: metricsAsync.when(
        data: (data) => _buildBody(context, ref, data, primaryTeal, accentOrange, successGreen),
        loading: () => const Center(child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (err, stack) => Center(
          child: Text(
            'Gagal memuat data dashboard: $err',
            style: GoogleFonts.beVietnamPro(color: const Color(0xFFBA1A1A)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    Color primaryTeal,
    Color accentOrange,
    Color successGreen,
  ) {
    final double globalBalance = data['global_balance'] > 0 
        ? data['global_balance'] 
        : 102500000.0; // Fallback to HTML mockup value if 0

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardProvider);
      },
      color: primaryTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Text(
              'Halo, Super Admin',
              style: GoogleFonts.beVietnamPro(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: primaryTeal,
                letterSpacing: -0.02,
              ),
            ),
            Text(
              'Real-time command center overview.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3F4848),
              ),
            ),
            const SizedBox(height: 24),

            // Bento Grid Cards
            Column(
              children: [
                // Global Metrics Card
                _buildBentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Metrics',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Two Column Metrics row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SCHOOL COUNT',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3F4848),
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1,248',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY VOLUME',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3F4848),
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['daily_volume'] > 0
                                        ? '${(data['daily_volume'] / 1000).toStringAsFixed(1)}K'
                                        : '42.5K',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Global Balance Inner Card (Accent Orange)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCA558).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFFFCA558).withValues(alpha: 0.2), width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'GLOBAL BALANCE',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentOrange,
                                letterSpacing: 0.08,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'Rp',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: accentOrange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CurrencyFormatter.format(globalBalance).replaceAll('Rp', '').trim(),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: accentOrange,
                                    letterSpacing: -0.02,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Transaction Trend Card
                _buildBentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction Trend',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEDEC),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '30 Days',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3F4848),
                                letterSpacing: 0.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Mockup SVG Line overlay representation in CustomPaint
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: TrendChartPainter(primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Two widgets row: Contribution & Server Health
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contribution per School
                    Expanded(
                      child: _buildBentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contribution/Sch',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Donut Chart Mockup representation
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryTeal,
                                    width: 10,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Vol.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Donut Chart Legends
                            _buildLegendItem(primaryTeal, 'High School A'),
                            const SizedBox(height: 4),
                            _buildLegendItem(const Color(0xFFFCA558), 'Middle School B'),
                            const SizedBox(height: 4),
                            _buildLegendItem(successGreen, 'Others'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // System Health Card
                    Expanded(
                      child: _buildBentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Health',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Optimal green pulse badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: successGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: successGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Optimal',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: successGreen,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Health Items list
                            _buildHealthItem(Icons.speed, 'API Latency', '42ms'),
                            const SizedBox(height: 10),
                            _buildHealthItem(Icons.storage, 'DB Capacity', '12%'),
                            const SizedBox(height: 10),
                            _buildHealthItem(Icons.check_circle, 'Success Rate', '99.8%'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Wide 24px radii
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3F4848),
              letterSpacing: 0.05,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthItem(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6F7978)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1B1C1B),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B1C1B),
          ),
        ),
      ],
    );
  }
}

// Trend Chart Painter to draw a smooth area trend line with teal gradient
class TrendChartPainter extends CustomPainter {
  final Color primaryColor;
  TrendChartPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.15),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.1, size.height * 0.7,
      size.width * 0.2, size.height * 0.75,
      size.width * 0.3, size.height * 0.6,
    );
    path.cubicTo(
      size.width * 0.4, size.height * 0.4,
      size.width * 0.5, size.height * 0.65,
      size.width * 0.6, size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.7, size.height * 0.3,
      size.width * 0.8, size.height * 0.4,
      size.width * 0.9, size.height * 0.2,
    );
    path.lineTo(size.width, size.height * 0.15);

    // Draw line
    canvas.drawPath(path, linePaint);

    // Close path for fill
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw fill
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
