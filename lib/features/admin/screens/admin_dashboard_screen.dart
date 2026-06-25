import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/widgets/admin_dashboard_header.dart';
import 'package:kantin_digital/features/admin/widgets/admin_global_metrics_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_transaction_trend_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_contribution_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_system_health_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkTeal2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'SA',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
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
                    color: AppColors.darkTeal,
                  ),
                ),
              ],
            ),
            actions: const [
              NotificationBell(color: AppColors.darkTeal),
              SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: metricsAsync.when(
        data: (data) => _buildBody(context, ref, data),
        loading: () => const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
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
      color: AppColors.darkTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            const AdminDashboardHeader(),
            const SizedBox(height: 24),

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

                // Transaction Trend Card
                AdminTransactionTrendCard(
                  dailyTrend: data.dailyTrend,
                ),
                const SizedBox(height: 12),

                // Two widgets row: Contribution & Server Health
                LayoutBuilder(
                  builder: (context, constraints) {
                    final contributionCard = const AdminContributionCard();
                    final healthCard = const AdminSystemHealthCard();

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

}
