/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/hallmark_card.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/features/kantin/widgets/daily_sales_volume_widget.dart';
import 'package:kantin_digital/features/kantin/widgets/top_selling_food_widget.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

/// Hallmark POS Kasir Workbench Master Screen
class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);
    final String canteenName =
        authState.profile?['canteen_name'] ?? 'Stan Kantin';
    final String? profilePhotoUrl = authState.profile?['avatar_url'];
    final revenueAsync = ref.watch(todayRevenueProvider);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colors.borderTactile,
            width: 0.5,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.surfaceSubtle,
              backgroundImage: profilePhotoUrl != null
                  ? CachedNetworkImageProvider(profilePhotoUrl)
                  : null,
              child: profilePhotoUrl == null
                  ? Icon(Icons.person, color: colors.brandPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $canteenName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HallmarkTypography.bodySmall(colors.textMuted),
                  ),
                  Text(
                    'Kasir Workbench',
                    style: HallmarkTypography.titleL3(colors.brandPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          NotificationBell(color: colors.brandPrimary),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayRevenueProvider);
          ref.invalidate(operatorTransactionsProvider);
          ref.invalidate(topSellingFoodProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Earnings Hallmark Card
                  revenueAsync.when(
                    data: (revenue) {
                      return HallmarkCard(
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PENDAPATAN HARI INI',
                                  style: HallmarkTypography.labelButton(colors.textMuted),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.statusSuccess.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: colors.statusSuccess.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Stand Buka',
                                        style: HallmarkTypography.bodySmall(colors.statusSuccess),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 14,
                                        color: colors.statusSuccess,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Rp ',
                                    style: HallmarkTypography.titleL3(colors.textMuted),
                                  ),
                                  Text(
                                    NumberFormat('#,###', 'id_ID').format(revenue),
                                    style: HallmarkTypography.financialNumeral(
                                      color: colors.brandPrimary,
                                      fontSize: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Shimmer(
                      child: HallmarkCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                SkeletonBox(width: 130, height: 14, borderRadius: 4),
                                SkeletonBox(width: 80, height: 22, borderRadius: 12),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const SkeletonBox(width: 180, height: 32, borderRadius: 6),
                          ],
                        ),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colors.statusError,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${AppStrings.labelFailed} memuat pendapatan',
                            style: HallmarkTypography.bodyMain(colors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          HallmarkButton(
                            label: AppStrings.buttonRetry,
                            onPressed: () => ref.invalidate(todayRevenueProvider),
                            isFullWidth: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions Grid Row
                  Row(
                    children: [
                      Expanded(
                        child: HallmarkButton(
                          label: 'Kasir POS Terminal',
                          icon: CupertinoIcons.square_grid_2x2,
                          onPressed: () => context.push('/pos/terminal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HallmarkButton(
                          label: 'Cek Kartu RFID',
                          icon: CupertinoIcons.creditcard,
                          onPressed: () => context.push('/pos/check-card'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sales Volume & Food Distribution Charts Section
                  Builder(
                    builder: (context) {
                      if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              Expanded(
                                flex: 1,
                                child: DailySalesVolumeWidget(),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                flex: 1,
                                child: TopSellingFoodWidget(),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: const [
                          DailySalesVolumeWidget(),
                          SizedBox(height: 16),
                          TopSellingFoodWidget(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
