import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// keuanganDashboardProvider is defined in keuangan_providers.dart

class KeuanganDashboardScreen extends ConsumerWidget {
  const KeuanganDashboardScreen({super.key});


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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(keuanganDashboardProvider),
          color: AppColors.darkTeal,
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
                              color: AppColors.mutedGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTeal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Admin Keuangan · $school',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.mutedGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/finance/settings'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTeal,
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
                      child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Total Saldo Beredar Card ───
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkTeal, AppColors.darkTeal2],
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
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: AppColors.success, size: 14),
                  Text(
                    ' +${fmt.format(topupToday)} hari ini',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.success),
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
                iconColor: AppColors.successGreen,
                label: 'Top-Up Tunai',
                value: fmt.format(topupToday),
                sub: '$topupCount Transaksi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                iconColor: AppColors.errorRed2,
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
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickAction(
              context,
              icon: CupertinoIcons.arrow_up_circle_fill,
              color: AppColors.successGreen,
              label: 'Top-Up\nTunai',
              route: '/finance/topup',
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction(
              context,
              icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
              color: AppColors.errorRed2,
              label: 'Koreksi\nSaldo',
              route: '/finance/correction',
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction(
              context,
              icon: CupertinoIcons.chart_bar_fill,
              color: AppColors.darkTeal,
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
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.nearBlack,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/finance/history'),
              child: Text(
                'Lihat Semua →',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTeal,
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
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const EmptyStateWidget(
              message: AppStrings.labelNoData,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
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
                final timeStr = DateFormat('HH:mm', 'id_ID').format(date);

                Color dotColor = AppColors.darkTeal;
                IconData dotIcon = CupertinoIcons.doc_text_fill;
                if (actionType.contains('TOPUP') || actionType.contains('TOP')) {
                  dotColor = AppColors.successGreen;
                  dotIcon = CupertinoIcons.arrow_up_circle_fill;
                } else if (actionType.contains('KOREKSI')) {
                  dotColor = AppColors.errorRed2;
                  dotIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
                } else if (actionType.contains('REGISTRASI')) {
                  dotColor = AppColors.darkOrange;
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
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.nearBlack,
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
                              color: AppColors.mutedGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < logs.length - 1)
                      const Divider(height: 1, thickness: 0.5, indent: 16, color: AppColors.borderGray),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
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
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedGray),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.nearBlack,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedGray),
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
              style: GoogleFonts.inter(
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
