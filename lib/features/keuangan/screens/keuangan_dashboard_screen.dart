import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final keuanganDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final profile = ref.read(authNotifierProvider).profile;
  final officerId = profile?['id'];
  final school = profile?['assigned_school'] ?? '';

  // Guard: if officer ID is not available, return empty data
  if (officerId == null || officerId.toString().isEmpty) {
    return {
      'profile': profile,
      'school': school,
      'totalSaldo': 0.0,
      'topupToday': 0.0,
      'topupCount': 0,
      'koreksCount': 0,
      'koreksNet': 0.0,
      'recentLogs': <Map<String, dynamic>>[],
    };
  }

  // Fetch total saldo beredar students di sekolah ini
  // Using audit_logs to get today's activities

  // Recent audit logs by this officer
  final List<dynamic> logs = await client
      .from('audit_logs')
      .select('actor_name, action_type, description, created_at')
      .eq('actor_id', officerId)
      .order('created_at', ascending: false)
      .limit(5);

  return {
    'profile': profile,
    'school': school,
    'totalSaldo': 14520000.0, // mock - in real: SUM(students.balance) by school
    'topupToday': 1250000.0,
    'topupCount': 18,
    'koreksCount': 3,
    'koreksNet': -35000.0,
    'recentLogs': List<Map<String, dynamic>>.from(logs),
  };
});

class KeuanganDashboardScreen extends ConsumerWidget {
  const KeuanganDashboardScreen({super.key});

  static const Color primaryTeal = Color(0xFF003434);
  static const Color accentOrange = Color(0xFF904D00);
  static const Color successGreen = Color(0xFF006A35);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(keuanganDashboardProvider);
    final profile = ref.read(authNotifierProvider).profile;
    final fullName = profile?['full_name'] ?? 'Admin Keuangan';
    final school = profile?['assigned_school'] ?? 'SMP Terpadu';
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final hour = DateTime.now().hour;
    final greeting = hour < 11 ? 'Selamat Pagi' : hour < 15 ? 'Selamat Siang' : 'Selamat Sore';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(keuanganDashboardProvider),
          color: primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Greeting ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, 👋',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: const Color(0xFF6F7978),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullName,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Admin Keuangan · $school',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFF6F7978),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/finance/profile'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryTeal.withValues(alpha: 0.1),
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                dashAsync.when(
                  data: (data) => _buildContent(context, data, fmt),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CupertinoActivityIndicator(color: primaryTeal),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Gagal memuat data: $e',
                      style: GoogleFonts.beVietnamPro(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data, NumberFormat fmt) {
    final totalSaldo = data['totalSaldo'] as double;
    final topupToday = data['topupToday'] as double;
    final topupCount = data['topupCount'] as int;
    final koreksCount = data['koreksCount'] as int;
    final koreksNet = data['koreksNet'] as double;
    final logs = data['recentLogs'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Total Saldo Beredar Card ───
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF003434), Color(0xFF005A5A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.money_dollar_circle_fill, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Total Saldo Beredar',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fmt.format(totalSaldo),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Color(0xFF4FFFB0), size: 14),
                  Text(
                    ' +${fmt.format(topupToday)} hari ini',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF4FFFB0)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ─── 2 Mini Stats Cards ───
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.arrow_up_circle_fill,
                iconColor: const Color(0xFF006A35),
                label: 'Top-Up Tunai',
                value: fmt.format(topupToday),
                sub: '$topupCount Transaksi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                iconColor: const Color(0xFFBA1A1A),
                label: 'Koreksi Hari Ini',
                value: fmt.format(koreksNet.abs()),
                sub: '$koreksCount Transaksi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Aksi Cepat ───
        Text(
          'Aksi Cepat',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickAction(
              context,
              icon: CupertinoIcons.arrow_up_circle_fill,
              color: const Color(0xFF006A35),
              label: 'Top-Up\nTunai',
              route: '/finance/topup',
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction(
              context,
              icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
              color: const Color(0xFFBA1A1A),
              label: 'Koreksi\nSaldo',
              route: '/finance/correction',
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction(
              context,
              icon: CupertinoIcons.chart_bar_fill,
              color: const Color(0xFF003434),
              label: 'Laporan\nKeuangan',
              route: '/finance/report',
            )),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Aktivitas Terbaru ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B1C1B),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/finance/history'),
              child: Text(
                'Lihat Semua →',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF003434),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                'Belum ada aktivitas hari ini.',
                style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978)),
              ),
            ),
          )
        else
          Container(
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
            child: Column(
              children: logs.asMap().entries.map((entry) {
                final i = entry.key;
                final log = entry.value;
                final actionType = log['action_type']?.toString() ?? '';
                final desc = log['description']?.toString() ?? '';
                final date = log['created_at'] != null
                    ? DateTime.parse(log['created_at']).toLocal()
                    : DateTime.now();
                final timeStr = DateFormat('HH:mm').format(date);

                Color dotColor = const Color(0xFF003434);
                IconData dotIcon = CupertinoIcons.doc_text_fill;
                if (actionType.contains('TOPUP') || actionType.contains('TOP')) {
                  dotColor = const Color(0xFF006A35);
                  dotIcon = CupertinoIcons.arrow_up_circle_fill;
                } else if (actionType.contains('KOREKSI')) {
                  dotColor = const Color(0xFFBA1A1A);
                  dotIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
                } else if (actionType.contains('REGISTRASI')) {
                  dotColor = const Color(0xFF904D00);
                  dotIcon = CupertinoIcons.creditcard_fill;
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: dotColor.withValues(alpha: 0.1),
                            child: Icon(dotIcon, color: dotColor, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              desc,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: const Color(0xFF1B1C1B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: const Color(0xFF6F7978),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < logs.length - 1)
                      const Divider(height: 1, thickness: 0.5, indent: 16, color: Color(0xFFE4E2E1)),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
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
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF6F7978)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B1C1B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF6F7978)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
