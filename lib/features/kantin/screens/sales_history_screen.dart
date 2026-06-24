import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/kantin/providers/operator_activities_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/kantin/widgets/activities_tab.dart';
import 'package:kantin_digital/features/kantin/widgets/refund_confirmation_dialog.dart';
import 'package:kantin_digital/features/kantin/widgets/transaction_details_sheet.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(operatorTransactionsProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Riwayat Jualan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGray,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Penjualan'),
              Tab(text: 'Aktivitas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Penjualan list
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(operatorTransactionsProvider);
                ref.invalidate(todayRevenueProvider);
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Revenue statistics header
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.borderLight, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL PENDAPATAN HARI INI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              revenueAsync.when(
                                data: (double revenue) => Text(
                                  CurrencyFormatter.format(revenue),
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                loading: () =>
                                    const CupertinoActivityIndicator(),
                                error: (err, stack) => Text(
                                  '${AppStrings.labelFailed} menghitung',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Transactions title
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Aktivitas Penjualan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),

                      // Transactions list
                      transactionsAsync.when(
                        data: (List<OperatorTransaction> txs) {
                          if (txs.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      EmptyStateWidget(
                                        message: AppStrings.adminNoSales,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final tx = txs[index];
                                  final String id = tx.id;
                                  final int amount = tx.totalAmount;
                                  final String studentName =
                                      tx.studentName ?? AppStrings.adminStudents;
                                  final String status = tx.status ?? 'success';

                                  final DateTime createdAt =
                                      tx.createdAt?.toLocal() ?? DateTime.now();
                                  final String timeStr =
                                      DateFormat('HH:mm', 'id_ID')
                                          .format(createdAt);
                                  final String dateStr =
                                      DateFormat('dd MMM', 'id_ID')
                                          .format(createdAt);

                                  final bool isCancelled = status == 'cancelled';
                                  final bool isFailed = status == 'failed';

                                  final bool isWithinRefundWindow = DateTime
                                          .now()
                                          .difference(createdAt)
                                          .inMinutes <
                                      10;
                                  final bool canRefund = status == 'success' &&
                                      tx.type == 'purchase' &&
                                      isWithinRefundWindow;

                                  return Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.borderLight,
                                          width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon Status
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCancelled || isFailed
                                                ? AppColors.error
                                                    .withValues(alpha: 0.1)
                                                : AppColors.primary
                                                    .withValues(alpha: 0.1),
                                          ),
                                          child: Icon(
                                            isCancelled
                                                ? CupertinoIcons
                                                    .arrow_counterclockwise
                                                : isFailed
                                                    ? CupertinoIcons.xmark
                                                    : CupertinoIcons
                                                        .shopping_cart,
                                            color: isCancelled || isFailed
                                                ? AppColors.error
                                                : AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Description
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    showTransactionDetailsSheet(
                                                        context, tx),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        studentName,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isCancelled
                                                              ? AppColors.textGray
                                                              : AppColors
                                                                  .textDark,
                                                          decoration:
                                                              isCancelled
                                                                  ? TextDecoration
                                                                      .lineThrough
                                                                  : null,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                        CupertinoIcons
                                                            .info_circle,
                                                        size: 12,
                                                        color: AppColors
                                                            .textGray),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$timeStr WIB \u2022 $dateStr',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textGray,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Right actions / values
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isCancelled ? "" : "-"}${CurrencyFormatter.format(amount)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled || isFailed
                                                    ? AppColors.textGray
                                                    : AppColors.textDark,
                                                decoration: isCancelled
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            if (isCancelled)
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Refunded',
                                                  style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              )
                                            else if (canRefund)
                                              GestureDetector(
                                                onTap: () =>
                                                    showRefundConfirmationDialog(
                                                  context,
                                                  ref,
                                                  id,
                                                  amount,
                                                  studentName,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.errorLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    border: Border.all(
                                                      color: AppColors.error
                                                          .withValues(
                                                              alpha: 0.5),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Refund',
                                                    style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              const Text(
                                                AppStrings.labelSuccess,
                                                style: TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                childCount: txs.length,
                              ),
                            ),
                          );
                        },
                        loading: () => const SliverFillRemaining(
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 12),
                          ),
                        ),
                        error: (err, stack) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AppStrings.labelFailed} memuat transaksi',
                                    style: TextStyle(
                                        color: AppColors.error, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => ref
                                        .invalidate(
                                            operatorTransactionsProvider),
                                    child:
                                        const Text(AppStrings.buttonRetry),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab 2: Aktivitas list
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(operatorActivitiesProvider);
              },
              child: const ActivitiesTab(),
            ),
          ],
        ),
      ),
    );
  }
}
