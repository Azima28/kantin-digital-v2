import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class KeuanganDashboardScreen extends ConsumerStatefulWidget {
  const KeuanganDashboardScreen({super.key});

  @override
  ConsumerState<KeuanganDashboardScreen> createState() => _KeuanganDashboardScreenState();
}

class _KeuanganDashboardScreenState extends ConsumerState<KeuanganDashboardScreen> {
  int _selectedSegment = 0; // 0: Siswa (Top-Up & Jajan), 1: Petugas Kantin (Stan & Pencairan)

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(keuanganDashboardProvider);
    final profile = ref.watch(authNotifierProvider).profile;
    final fullName = profile?['full_name'] ?? 'Admin Keuangan';
    final school = profile?['assigned_school'] ?? 'SMP Terpadu';
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final hour = DateTime.now().hour;
    final greeting = hour < 11 ? 'Selamat Pagi' : hour < 15 ? 'Selamat Siang' : 'Selamat Sore';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(keuanganDashboardProvider),
          color: Nebula.teal,
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Admin Keuangan · $school',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NotificationBell(color: Nebula.teal),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.go('/finance/settings'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                dashAsync.when(
                  data: (data) => _buildContent(context, data, fmt),
                  loading: () => Shimmer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.borderLight, width: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.borderLight, width: 0.8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.borderLight, width: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SkeletonBox(width: 120, height: 14, borderRadius: 4),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(
                            3,
                            (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                                height: 75,
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.borderLight, width: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SkeletonBox(width: 140, height: 14, borderRadius: 4),
                        const SizedBox(height: 12),
                        ...List.generate(3, (i) => const SkeletonListTile()),
                      ],
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                        const SizedBox(height: 12),
                        Text('${AppStrings.labelFailed} memuat data'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(keuanganDashboardProvider),
                          child: const Text(AppStrings.buttonRetry),
                        ),
                      ],
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

  Widget _buildContent(BuildContext context, Map<String, dynamic> data, NumberFormat fmt) {
    final totalSaldo = (data['totalSaldo'] as num?)?.toDouble() ?? 0.0;
    final topupToday = (data['topupToday'] as num?)?.toDouble() ?? 0.0;
    final topupCount = (data['topupCount'] as num?)?.toInt() ?? 0;
    final koreksCount = (data['koreksCount'] as num?)?.toInt() ?? 0;
    final koreksNet = (data['koreksNet'] as num?)?.toDouble() ?? 0.0;
    final logs = data['recentLogs'] as List<Map<String, dynamic>>;

    // Filter logs for Siswa vs Petugas Kantin
    final studentLogs = logs.where((l) {
      final t = (l['type'] ?? l['action_type'] ?? '').toString();
      return t == 'topup' || t == 'purchase' || t == 'refund' || t.contains('TOPUP') || t.contains('BATAL') || t == 'correction';
    }).toList();

    final merchantLogs = logs.where((l) {
      final t = (l['type'] ?? l['action_type'] ?? '').toString();
      return t == 'withdrawal' || t == 'merchant_adjustment' || t.contains('MERCHANT') || t == 'purchase';
    }).toList();

    final activeLogs = _selectedSegment == 0 ? studentLogs : merchantLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Total Saldo Beredar Card ───
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Nebula.teal, Nebula.tealDark],
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
                    'Total Saldo Beredar Siswa',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fmt.format(totalSaldo),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ' +${fmt.format(topupToday)} top-up hari ini',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                context,
                icon: CupertinoIcons.arrow_up_circle_fill,
                iconColor: Nebula.teal,
                label: 'Top-Up Siswa',
                value: fmt.format(topupToday),
                sub: '$topupCount Transaksi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                iconColor: Nebula.rose,
                label: 'Koreksi Saldo',
                value: fmt.format(koreksNet.abs()),
                sub: '$koreksCount Transaksi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Aksi Cepat (Top-Up Siswa, Tarik Saldo Stan, Laporan) ───
        Text(
          'Aksi Cepat',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                context,
                icon: CupertinoIcons.arrow_up_circle_fill,
                color: Nebula.teal,
                label: 'Top-Up\nSiswa',
                route: '/finance/topup',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: CupertinoIcons.money_dollar_circle_fill,
                color: const Color(0xFF0D9488),
                label: 'Tarik Saldo\nStan',
                route: '/finance/users?tab=2',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: CupertinoIcons.chart_bar_fill,
                color: Nebula.amber,
                label: 'Laporan\nKeuangan',
                route: '/finance/report',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ─── Slider / Tab Pemisah (Siswa vs Petugas Kantin) ───
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dividerCol, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedSegment = 0),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedSegment == 0 ? Nebula.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          size: 15,
                          color: _selectedSegment == 0 ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Siswa (${studentLogs.length})',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: _selectedSegment == 0 ? FontWeight.bold : FontWeight.w500,
                            color: _selectedSegment == 0 ? Colors.white : context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedSegment = 1),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedSegment == 1 ? Nebula.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.building_2_fill,
                          size: 15,
                          color: _selectedSegment == 1 ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Petugas Kantin (${merchantLogs.length})',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: _selectedSegment == 1 ? FontWeight.bold : FontWeight.w500,
                            color: _selectedSegment == 1 ? Colors.white : context.textPrimary,
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
        const SizedBox(height: 14),

        // ─── Header Aktivitas ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSegment == 0 ? 'Aktivitas Transaksi Siswa' : 'Aktivitas & Mutasi Stan Kantin',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/finance/history'),
              child: Text(
                'Lihat Semua →',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Nebula.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (activeLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.dividerCol, width: 0.6),
            ),
            child: EmptyStateWidget(
              message: _selectedSegment == 0
                  ? 'Belum ada aktivitas transaksi siswa.'
                  : 'Belum ada aktivitas mutasi stan kantin.',
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.dividerCol, width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: activeLogs.take(5).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final log = entry.value;
                final type = (log['type'] ?? log['action_type'] ?? '').toString();
                final amount = (log['total_amount'] as num?)?.toInt() ?? 0;
                final student = log['student_name']?.toString() ?? 'Siswa';
                final canteen = log['canteen_name']?.toString() ?? 'Kantin';
                String desc = log['description']?.toString() ?? '';

                if (desc.isEmpty) {
                  if (type == 'topup' || type.contains('TOPUP')) {
                    desc = 'Top-up saldo $student sebesar ${fmt.format(amount)}';
                  } else if (type == 'correction' || type.contains('KOREKSI')) {
                    desc = 'Koreksi saldo $student sebesar ${fmt.format(amount)}';
                  } else if (type == 'withdrawal' || type.contains('WITHDRAWAL') || type.contains('PAYOUT')) {
                    desc = 'Pencairan kas $canteen sebesar ${fmt.format(amount)}';
                  } else if (type == 'merchant_adjustment') {
                    desc = 'Koreksi saldo $canteen sebesar ${fmt.format(amount)}';
                  } else if (type == 'purchase') {
                    desc = 'Penjualan di $canteen dari $student (${fmt.format(amount)})';
                  } else if (type == 'refund' || type.contains('BATAL')) {
                    desc = 'Refund pesanan $student sebesar ${fmt.format(amount)}';
                  } else {
                    desc = 'Transaksi $student sebesar ${fmt.format(amount)}';
                  }
                }

                final date = log['created_at'] != null
                    ? DateTime.parse(log['created_at'].toString()).toLocal()
                    : DateTime.now();
                final timeStr = DateFormat('HH:mm', 'id_ID').format(date);

                Color dotColor = Nebula.teal;
                IconData dotIcon = CupertinoIcons.doc_text_fill;
                if (type == 'topup' || type.contains('TOPUP') || type.contains('TOP')) {
                  dotColor = Nebula.teal;
                  dotIcon = CupertinoIcons.arrow_up_circle_fill;
                } else if (type == 'withdrawal' || type.contains('WITHDRAWAL') || type.contains('PAYOUT')) {
                  dotColor = Nebula.rose;
                  dotIcon = CupertinoIcons.money_dollar_circle_fill;
                } else if (type == 'merchant_adjustment') {
                  dotColor = Nebula.amber;
                  dotIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
                } else if (type == 'correction' || type.contains('KOREKSI')) {
                  dotColor = Nebula.rose;
                  dotIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
                } else if (type == 'purchase') {
                  dotColor = Nebula.amber;
                  dotIcon = CupertinoIcons.bag_fill;
                } else if (type == 'refund' || type.contains('BATAL')) {
                  dotColor = Nebula.rose;
                  dotIcon = CupertinoIcons.arrow_counterclockwise_circle_fill;
                } else if (type.contains('REGISTRASI')) {
                  dotColor = Nebula.teal;
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
                            backgroundColor: dotColor.withValues(alpha: 0.12),
                            child: Icon(dotIcon, color: dotColor, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              desc,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < activeLogs.length - 1)
                      Divider(height: 1, thickness: 0.5, indent: 16, color: context.dividerCol),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dividerCol, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
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
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerCol, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
