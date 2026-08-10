import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/kantin/providers/operator_activities_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/kantin/widgets/activities_tab.dart';
import 'package:kantin_digital/features/kantin/widgets/refund_confirmation_dialog.dart';
import 'package:kantin_digital/features/kantin/widgets/transaction_details_sheet.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  Widget _buildDateHeader(String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Nebula.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Nebula.teal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: context.dividerCol,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(operatorTransactionsProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Riwayat Jualan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(
            bottom: BorderSide(color: context.dividerCol, width: 0.5),
          ),
          bottom: TabBar(
            labelColor: Nebula.teal,
            unselectedLabelColor: context.textSecondary,
            indicatorColor: Nebula.teal,
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
                        child: NebulaCard(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PENDAPATAN HARI INI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
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
                                    color: Nebula.teal,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                loading: () =>
                                    const CupertinoActivityIndicator(),
                                error: (err, stack) => Text(
                                  '${AppStrings.labelFailed} menghitung',
                                  style: TextStyle(color: Nebula.rose),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Transactions divider
                      SliverToBoxAdapter(child: GradientLine(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8))),

                      // Transactions title
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Aktivitas Penjualan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
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

                          // Group and flatten transactions by date
                          final List<dynamic> listItems = [];
                          DateTime? lastDate;
                          for (final tx in txs) {
                            final DateTime createdAt = tx.createdAt?.toLocal() ?? DateTime.now();
                            if (lastDate == null ||
                                lastDate.year != createdAt.year ||
                                lastDate.month != createdAt.month ||
                                lastDate.day != createdAt.day) {
                              final String dateHeaderStr =
                                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(createdAt);
                              listItems.add(dateHeaderStr);
                              lastDate = createdAt;
                            }
                            listItems.add(tx);
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = listItems[index];
                                  if (item is String) {
                                    return _buildDateHeader(item);
                                  }

                                  final tx = item as OperatorTransaction;
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

                                  return NebulaCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    onTap: () => showTransactionDetailsSheet(
                                        context, tx),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Icon Status
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isCancelled || isFailed
                                                  ? Nebula.rose
                                                      .withValues(alpha: 0.1)
                                                  : Nebula.teal
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
                                                  ? Nebula.rose
                                                  : Nebula.teal,
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
                                                                ? context.textSecondary
                                                                : context.textPrimary,
                                                            decoration:
                                                                isCancelled
                                                                    ? TextDecoration
                                                                        .lineThrough
                                                                    : null,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(CupertinoIcons
                                                          .info_circle,
                                                          size: 12,
                                                          color: context.textSecondary),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '$timeStr WIB \u2022 $dateStr',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: context.textSecondary,
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
                                                      ? context.textSecondary
                                                      : context.textPrimary,
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
                                                    color: Nebula.rose
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Refunded',
                                                    style: TextStyle(
                                                        color: Nebula.rose,
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
                                                      color: Nebula.rose
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: Nebula.rose
                                                            .withValues(
                                                                alpha: 0.5),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Refund',
                                                      style: TextStyle(
                                                        color: Nebula.rose,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Text(
                                                  AppStrings.labelSuccess,
                                                  style: TextStyle(
                                                    color: Nebula.teal,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                childCount: listItems.length,
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
                                        color: Nebula.rose, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  PressScale(
                                    onTap: () => ref
                                        .invalidate(
                                            operatorTransactionsProvider),
                                    child: ElevatedButton(
                                      onPressed: () => ref
                                          .invalidate(
                                              operatorTransactionsProvider),
                                      child:
                                          const Text(AppStrings.buttonRetry),
                                    ),
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
