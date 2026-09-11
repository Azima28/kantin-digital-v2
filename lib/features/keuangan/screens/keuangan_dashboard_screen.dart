import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_closing_shift_modal.dart';

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
    final acadSchool = ref.watch(academicStructureProvider).valueOrNull?.schoolName;
    final String fullName = (profile?['full_name']?.toString().trim().isNotEmpty == true)
        ? profile!['full_name'].toString()
        : 'Admin Keuangan';
    final String school = (acadSchool != null && acadSchool.trim().isNotEmpty)
        ? acadSchool
        : ((profile?['assigned_school']?.toString().trim().isNotEmpty == true)
            ? profile!['assigned_school'].toString()
            : 'Sekolah Digital');

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Greeting ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, 👋',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            (profile?['role'] == 'super_admin' || profile?['role'] == 'admin')
                                ? 'Super Admin · Sistem Utama'
                                : 'Admin Keuangan · $school',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NotificationBell(color: Nebula.teal),
                        const SizedBox(width: 8),
                        AppAvatar(
                          radius: 20,
                          photoUrl: profile?['avatar_url'],
                          role: profile?['role'] ?? 'petugas_keuangan',
                          name: fullName,
                          borderColor: Nebula.teal.withValues(alpha: 0.3),
                          onTap: () => context.go('/finance/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                dashAsync.when(
                  data: (data) => _buildContent(context, data),
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
                  error: (e, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat data dasbor: $e',
                            style: GoogleFonts.inter(color: Nebula.rose, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(keuanganDashboardProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(AppStrings.buttonRetry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Nebula.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final totalSaldo = (data['totalSaldo'] as num?)?.toDouble() ?? 0.0;
    final topupToday = (data['topupToday'] as num?)?.toDouble() ?? 0.0;
    final topupCount = (data['topupCount'] as num?)?.toInt() ?? 0;
    final payoutToday = (data['payoutToday'] as num?)?.toDouble() ?? 0.0;
    final payoutCount = (data['payoutCount'] as num?)?.toInt() ?? 0;

    final rawLogs = data['recentLogs'];
    final List<Map<String, dynamic>> logs = [];
    if (rawLogs is List) {
      for (final item in rawLogs) {
        if (item is Map) {
          logs.add(Map<String, dynamic>.from(item));
        }
      }
    }

    // Filter logs for Siswa vs Petugas Kantin
    final studentLogs = logs.where((l) {
      final t = (l['type'] ?? l['action_type'] ?? '').toString();
      return t == 'topup' || t == 'purchase' || t == 'refund' || t.contains('TOPUP') || t.contains('BATAL');
    }).toList();

    final merchantLogs = logs.where((l) {
      final t = (l['type'] ?? l['action_type'] ?? '').toString();
      return t == 'withdrawal' || t.contains('PAYOUT') || t.contains('MERCHANT') || t == 'purchase';
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
                  const Icon(CupertinoIcons.creditcard_fill, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Total Saldo Beredar Siswa',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(totalSaldo),
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
                      ' +${CurrencyFormatter.format(topupToday)} top-up hari ini',
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

        // ─── 2 Mini Stats Cards (Top-Up Masuk & Tarik Stan Keluar) ───
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.arrow_down_left_circle_fill,
                iconColor: Nebula.teal,
                label: 'Top-Up Hari Ini',
                value: CurrencyFormatter.format(topupToday),
                sub: '$topupCount Transaksi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.arrow_up_right_circle_fill,
                iconColor: Nebula.rose,
                label: 'Pencairan Stan',
                value: CurrencyFormatter.format(payoutToday),
                sub: '$payoutCount Transaksi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Aksi Cepat (Top-Up Siswa, Tarik Saldo Stan, Laporan, Tutup Kasir) ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aksi Cepat',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => _openClosingShiftModal(context, data),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.lock_shield_fill, size: 14, color: Nebula.teal),
                    const SizedBox(width: 4),
                    Text(
                      'Tutup Kasir (Shift)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Nebula.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: CupertinoIcons.arrow_up_right_circle_fill,
                color: const Color(0xFF0D9488),
                label: 'Tarik Saldo\nStan',
                route: '/finance/users?tab=2',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: CupertinoIcons.chart_bar_fill,
                color: Nebula.amber,
                label: 'Laporan\nKas',
                route: '/finance/report',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: CupertinoIcons.lock_shield_fill,
                color: const Color(0xFF0284C7),
                label: 'Tutup\nKasir',
                onTap: () => _openClosingShiftModal(context, data),
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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedSegment == 0 ? Nebula.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          size: 14,
                          color: _selectedSegment == 0 ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Siswa (${studentLogs.length})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: _selectedSegment == 0 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedSegment == 0 ? Colors.white : context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedSegment == 1 ? Nebula.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.building_2_fill,
                          size: 14,
                          color: _selectedSegment == 1 ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Stan (${merchantLogs.length})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: _selectedSegment == 1 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedSegment == 1 ? Colors.white : context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            Expanded(
              child: Text(
                _selectedSegment == 0 ? 'Aktivitas Transaksi Siswa' : 'Aktivitas & Mutasi Kas Stan',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/finance/history'),
              child: Text(
                'Lihat Semua →',
                style: GoogleFonts.inter(
                  fontSize: 12,
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
                    desc = 'Top-up saldo $student sebesar ${CurrencyFormatter.format(amount)}';
                  } else if (type == 'correction' || type.contains('KOREKSI')) {
                    desc = 'Koreksi saldo $student sebesar ${CurrencyFormatter.format(amount)}';
                  } else if (type == 'withdrawal' || type.contains('WITHDRAWAL') || type.contains('PAYOUT')) {
                    desc = 'Pencairan kas $canteen sebesar ${CurrencyFormatter.format(amount)}';
                  } else if (type == 'merchant_adjustment') {
                    desc = 'Koreksi saldo $canteen sebesar ${CurrencyFormatter.format(amount)}';
                  } else if (type == 'purchase') {
                    desc = 'Penjualan di $canteen dari $student (${CurrencyFormatter.format(amount)})';
                  } else if (type == 'refund' || type.contains('BATAL')) {
                    desc = 'Refund pesanan $student sebesar ${CurrencyFormatter.format(amount)}';
                  } else {
                    desc = 'Transaksi $student sebesar ${CurrencyFormatter.format(amount)}';
                  }
                }

                final date = log['created_at'] != null
                    ? (DateTime.tryParse(log['created_at'].toString())?.toLocal() ?? DateTime.now())
                    : DateTime.now();
                final timeStr = AppDateFormatter.formatTime(date);

                Color dotColor = Nebula.teal;
                IconData dotIcon = CupertinoIcons.doc_text_fill;
                if (type == 'topup' || type.contains('TOPUP') || type.contains('TOP')) {
                  dotColor = Nebula.teal;
                  dotIcon = CupertinoIcons.arrow_up_circle_fill;
                } else if (type == 'withdrawal' || type.contains('WITHDRAWAL') || type.contains('PAYOUT')) {
                  dotColor = Nebula.rose;
                  dotIcon = CupertinoIcons.arrow_up_right_circle_fill;
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
                    InkWell(
                      onTap: () => _showTransactionDetailDialog(context, log),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
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
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 13,
                              color: context.textSecondary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
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

  void _showTransactionDetailDialog(BuildContext context, Map<String, dynamic> log) {
    final String txId = (log['id'] ?? '').toString();
    final String type = (log['type'] ?? log['action_type'] ?? 'transaksi').toString().toLowerCase();
    final int amount = (log['total_amount'] as num?)?.toInt() ?? (log['amount'] as num?)?.toInt() ?? 0;
    final String status = (log['status'] ?? 'success').toString().toLowerCase();
    final String student = log['student_name']?.toString() ?? '';
    final String studentNisn = log['student_nisn']?.toString() ?? '';
    final String canteen = log['canteen_name']?.toString() ?? '';
    final String opName = log['operator_name']?.toString() ?? '';
    final String opRole = log['operator_role']?.toString() ?? '';
    final String method = (log['purchase_method'] ?? 'cashless').toString().toLowerCase();

    final date = log['created_at'] != null
        ? (DateTime.tryParse(log['created_at'].toString())?.toLocal() ?? DateTime.now())
        : DateTime.now();
    final fullDateStr = AppDateFormatter.formatFullDateWithTimeSeconds(date);

    String typeLabel = 'Transaksi';
    Color themeColor = Nebula.teal;
    IconData themeIcon = CupertinoIcons.doc_text_fill;

    if (type.contains('topup')) {
      typeLabel = 'Top-Up Saldo Siswa';
      themeColor = Nebula.teal;
      themeIcon = CupertinoIcons.arrow_up_circle_fill;
    } else if (type.contains('withdrawal') || type.contains('payout')) {
      typeLabel = 'Pencairan Kas Stan';
      themeColor = Nebula.rose;
      themeIcon = CupertinoIcons.arrow_up_right_circle_fill;
    } else if (type.contains('purchase')) {
      typeLabel = 'Pembelian Kantin';
      themeColor = Nebula.amber;
      themeIcon = CupertinoIcons.bag_fill;
    } else if (type.contains('correction') || type.contains('koreksi')) {
      typeLabel = 'Koreksi Saldo';
      themeColor = Nebula.rose;
      themeIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
    } else if (type.contains('refund') || type.contains('batal')) {
      typeLabel = 'Pengembalian Dana (Refund)';
      themeColor = Nebula.rose;
      themeIcon = CupertinoIcons.arrow_counterclockwise_circle_fill;
    }

    String methodDisplay = 'Tap Kartu RFID';
    if (method == 'qris') {
      methodDisplay = 'QRIS (Instan)';
    } else if (method == 'cash') {
      methodDisplay = 'Tunai ke Petugas Keuangan';
    } else if (method == 'app' || method == 'app_order') {
      methodDisplay = 'Aplikasi Mobile';
    }

    String actorDisplay = opName.isNotEmpty ? opName : 'Petugas Keuangan';
    if (opRole == 'petugas_keuangan') {
      actorDisplay = '$opName (Petugas Keuangan)';
    } else if (opRole == 'student') {
      actorDisplay = '$opName (Siswa Mandiri)';
    } else if (opRole == 'parent') {
      actorDisplay = '$opName (Orang Tua / Wali)';
    } else if (opRole == 'admin' || opRole == 'super_admin') {
      actorDisplay = '$opName (Administrator)';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(themeIcon, color: themeColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Aktivitas Keuangan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, thickness: 0.5, color: context.dividerCol),

                // Amount Highlight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        type.contains('topup')
                            ? 'TOTAL SALDO MASUK'
                            : (type.contains('withdrawal') ? 'TOTAL PENCAIRAN' : 'TOTAL TRANSAKSI'),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(amount),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Information list
                if (txId.isNotEmpty) ...[
                  _buildDetailModalRow('ID Transaksi', '#${txId.length > 8 ? txId.substring(0, 8).toUpperCase() : txId}'),
                  const SizedBox(height: 8),
                ],
                _buildDetailModalRow('Waktu Transaksi', fullDateStr),
                const SizedBox(height: 8),
                if (student.isNotEmpty) ...[
                  _buildDetailModalRow('Siswa', studentNisn.isNotEmpty ? '$student ($studentNisn)' : student),
                  const SizedBox(height: 8),
                ],
                if (canteen.isNotEmpty) ...[
                  _buildDetailModalRow('Stan / Merchant', canteen),
                  const SizedBox(height: 8),
                ],
                _buildDetailModalRow('Metode Pembayaran', methodDisplay),
                const SizedBox(height: 8),
                _buildDetailModalRow('Diproses Oleh', actorDisplay),
                const SizedBox(height: 8),
                _buildDetailModalRow(
                  'Status',
                  status == 'success' ? 'Sukses / Berhasil' : status.toUpperCase(),
                  isStatus: true,
                ),
                const SizedBox(height: 22),

                // Button Close
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                      elevation: 0,
                    ),
                    child: Text(
                      'TUTUP',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailModalRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
        ),
        const SizedBox(width: 12),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal),
            ),
          )
        else
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
          ),
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

  void _openClosingShiftModal(
      BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KeuanganClosingShiftModal(
        dashboardData: data,
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    String? route,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? (route != null ? () => context.push(route) : null),
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
                fontSize: 11,
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
