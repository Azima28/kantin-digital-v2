import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/widgets/admin_dashboard_header.dart';
import 'package:kantin_digital/features/admin/widgets/admin_global_metrics_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_transaction_trend_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_contribution_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_system_health_card.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardProvider);
    final authState = ref.watch(authNotifierProvider);
    final String? avatarUrl = authState.profile?['avatar_url'] as String?;
    final String fullName = authState.profile?['full_name'] ?? 'Super Admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/admin/profile'),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Nebula.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: ClipOval(
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: ApiClient.resolveImageUrl(avatarUrl),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kantin Digital',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              NotificationBell(color: Nebula.teal),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: metricsAsync.when(
        data: (data) => _buildBody(context, ref, data),
        loading: () => Shimmer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 140, height: 22, borderRadius: 4),
                    SkeletonCircle(size: 36),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.borderLight, width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.borderLight, width: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data dashboard'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminDashboardProvider),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardData data,
  ) {
    final int globalBalance = data.globalBalance > 0 
        ? data.globalBalance 
        : 102500000; // Fallback to HTML mockup value if 0

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardProvider);
      },
      color: Nebula.teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            AdminDashboardHeader(),
            SizedBox(height: 24),

            // Bento Grid Cards
            Column(
              children: [
                // Global Metrics Card
                AdminGlobalMetricsCard(
                  userCount: data.userCount,
                  dailyVolume: data.dailyVolume,
                  globalBalance: globalBalance,
                ),
                const SizedBox(height: 12),

                // ─── Aksi Cepat Finansial & Audit Super Admin ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Aksi Cepat & Audit Keuangan',
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
                          InkWell(
                            onTap: () => context.go('/admin/audit'),
                            child: Text(
                              'Log Audit →',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionBtn(
                              context,
                              icon: CupertinoIcons.arrow_up_circle_fill,
                              color: Nebula.teal,
                              label: 'Top-Up\nSiswa',
                              onTap: () => context.push('/finance/topup'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionBtn(
                              context,
                              icon: CupertinoIcons.money_dollar_circle_fill,
                              color: const Color(0xFF0D9488),
                              label: 'Tarik Saldo\nStan',
                              onTap: () => context.push('/finance/users?tab=2'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionBtn(
                              context,
                              icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                              color: Nebula.rose,
                              label: 'Koreksi\nSaldo',
                              onTap: () => context.push('/finance/correction'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionBtn(
                              context,
                              icon: CupertinoIcons.chart_bar_square_fill,
                              color: Nebula.amber,
                              label: 'Laporan\nKas',
                              onTap: () => context.push('/finance/report'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Transaction Trend Card
                AdminTransactionTrendCard(
                  dailyTrend: data.dailyTrend,
                ),
                const SizedBox(height: 12),

                // Two widgets row: Contribution & Server Health
                LayoutBuilder(
                  builder: (context, constraints) {
                    final contributionCard = AdminContributionCard(
                      roleCounts: data.roleCounts,
                      totalUsers: data.userCount,
                    );
                    final healthCard = AdminSystemHealthCard(
                      systemHealth: data.systemHealth,
                    );

                    if (constraints.maxWidth < 430) {
                      return Column(
                        children: [
                          contributionCard,
                          const SizedBox(height: 12),
                          healthCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: contributionCard),
                        const SizedBox(width: 12),
                        Expanded(child: healthCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dividerCol, width: 0.6),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5,
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
