import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final String canteenName =
        authState.profile?['canteen_name'] ?? 'Stan Kantin';
    final String? profilePhotoUrl = authState.profile?['avatar_url'];
    final revenueAsync = ref.watch(todayRevenueProvider);
    final transactionsAsync = ref.watch(operatorTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: context.dividerCol,
            width: 0.5,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: profilePhotoUrl != null
                  ? CachedNetworkImageProvider(profilePhotoUrl)
                  : null,
              child: profilePhotoUrl == null
                  ? Icon(Icons.person, color: Nebula.teal)
                  : null,
            ),
            SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $canteenName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Beranda',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: Responsive.headingFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: Nebula.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          NotificationBell(color: Nebula.teal),
          SizedBox(width: 8),
        ],

      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayRevenueProvider);
          ref.invalidate(operatorTransactionsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Earnings Card
                  revenueAsync.when(
                    data: (revenue) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: isDarkMode
                                        ? const LinearGradient(
                                            colors: [
                                              Nebula.teal,
                                              Nebula.purple,
                                              Nebula.tealDark,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isDarkMode ? null : context.cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isDarkMode
                                        ? null
                                        : Border.all(color: context.borderLight, width: 1),
                                    boxShadow: isDarkMode
                                        ? [
                                            BoxShadow(
                                              color: Nebula.tealGlow,
                                              blurRadius: 24,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Decorative Background Shape
                                      Positioned(
                                        top: -48,
                                        right: -48,
                                        child: Container(
                                          width: 128,
                                          height: 128,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: isDarkMode ? 0.06 : 0.08,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'PENDAPATAN HARI INI',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode ? Colors.white.withValues(alpha: 0.75) : context.textSecondary,
                                                    letterSpacing: 1.1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.white.withValues(alpha: 0.15)
                                                      : Nebula.teal.withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Buka',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDarkMode ? Colors.white : Nebula.teal,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      CupertinoIcons.checkmark_seal_fill,
                                                      size: 14,
                                                      color: isDarkMode ? Colors.white : Nebula.teal,
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  'Rp',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDarkMode ? Colors.white : context.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  NumberFormat(
                                                    '#,###',
                                                    'id_ID',
                                                  ).format(revenue),
                                                  style: TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDarkMode ? Colors.white : Nebula.teal,
                                                    letterSpacing: -0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Nebula.rose,
                          ),
                          const SizedBox(height: 12),
                          Text('${AppStrings.labelFailed} memuat pendapatan'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                ref.invalidate(todayRevenueProvider),
                            child: Text(AppStrings.buttonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Quick Actions Grid Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/pos/terminal'),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Nebula.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.square_grid_2x2,
                                      color: context.cardBg,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kasir POS',
                                      style: TextStyle(
                                        color: context.cardBg,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/pos/check-card'),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: context.surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.creditcard,
                                      color: context.textPrimary,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cek Kartu',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Penjualan Hari Ini Title & Lihat Semua link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Penjualan Hari Ini',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/pos/sales'),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 13,
                            color: Nebula.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Transactions List (Only show today's)
                  transactionsAsync.when(
                    data: (List<OperatorTransaction> txs) {
                      final now = DateTime.now();
                      final todayTxs = txs.where((tx) {
                        if (tx.createdAt == null) return false;
                        final txDate = tx.createdAt!.toLocal();
                        return txDate.year == now.year &&
                            txDate.month == now.month &&
                            txDate.day == now.day;
                      }).toList();

                      if (todayTxs.isEmpty) {
                        return NebulaCard(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: const EmptyStateWidget(
                            message: AppStrings.labelNoData,
                          ),
                        );
                      }

                      return Column(
                        children: todayTxs.map((tx) {
                          final int amount = tx.totalAmount;
                          final String studentName =
                              tx.studentName ?? AppStrings.adminStudents;
                          final String status = tx.status ?? 'success';
                          final bool isCancelled = status == 'cancelled';

                          final txTime = tx.createdAt != null
                              ? DateFormat(
                                  'HH:mm',
                                  'id_ID',
                                ).format(tx.createdAt!.toLocal())
                              : '-';

                          return NebulaCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? Nebula.rose.withValues(
                                            alpha: 0.1,
                                          )
                                        : Nebula.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isCancelled
                                        ? CupertinoIcons.xmark_circle
                                        : CupertinoIcons.creditcard,
                                    color: isCancelled
                                        ? Nebula.rose
                                        : Nebula.teal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCancelled
                                            ? 'Pembelian Dibatalkan'
                                            : studentName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$txTime WIB \u2022 ${isCancelled ? "Refund" : "Penjualan"}',
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${isCancelled ? "-" : "+"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    color: isCancelled
                                        ? Nebula.rose
                                        : Nebula.teal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Nebula.rose,
                          ),
                          const SizedBox(height: 12),
                          Text('${AppStrings.labelFailed} memuat riwayat'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                ref.invalidate(operatorTransactionsProvider),
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
      ),
    );
  }
}