import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/features/siswa/providers/order_providers.dart';

class SiswaActiveOrdersScreen extends ConsumerStatefulWidget {
  const SiswaActiveOrdersScreen({super.key});

  @override
  ConsumerState<SiswaActiveOrdersScreen> createState() =>
      _SiswaActiveOrdersScreenState();
}

class _SiswaActiveOrdersScreenState
    extends ConsumerState<SiswaActiveOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(siswaActiveOrdersProvider);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(siswaActiveOrdersProvider);
    final historyAsync = ref.watch(siswaOrderHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              const Icon(CupertinoIcons.left_chevron, color: AppColors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pesanan Saya',
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.teal),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppColors.teal),
            onPressed: () {
              ref.invalidate(siswaActiveOrdersProvider);
              ref.invalidate(siswaOrderHistoryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.mutedGray,
          indicatorColor: AppColors.teal,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: activeAsync.when(
                data: (orders) => Text(
                    'Aktif${orders.isNotEmpty ? " (${orders.length})" : ""}'),
                loading: () => const Text('Aktif'),
                error: (_, __) => const Text('Aktif'),
              ),
            ),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab: Active
          _OrderList(
            asyncOrders: activeAsync,
            emptyIcon: CupertinoIcons.clock,
            emptyLabel: 'Tidak ada pesanan aktif',
            emptySubLabel: 'Yuk pesan makanan favoritmu!',
            showCta: true,
          ),
          // Tab: History
          _OrderList(
            asyncOrders: historyAsync,
            emptyIcon: CupertinoIcons.square_list,
            emptyLabel: 'Belum ada riwayat pesanan',
            emptySubLabel: '',
            showCta: false,
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final AsyncValue<List<Order>> asyncOrders;
  final IconData emptyIcon;
  final String emptyLabel;
  final String emptySubLabel;
  final bool showCta;
  const _OrderList({
    required this.asyncOrders,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.emptySubLabel,
    required this.showCta,
  });

  @override
  Widget build(BuildContext context) {
    return asyncOrders.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(
        child: Text('Gagal memuat pesanan',
            style: GoogleFonts.inter(color: AppColors.error)),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 56, color: AppColors.gray400),
                const SizedBox(height: 16),
                Text(emptyLabel,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray)),
                if (emptySubLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(emptySubLabel,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.mutedGray)),
                ],
                if (showCta) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push(AppRouter.studentCanteens),
                    icon: const Icon(CupertinoIcons.bag, size: 16),
                    label: const Text('Pesan Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.teal,
          onRefresh: () async {},
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case 'pending':
        return AppColors.accentOrange;
      case 'accepted':
        return AppColors.teal;
      case 'preparing':
        return AppColors.primary;
      case 'ready':
        return AppColors.successGreen;
      case 'completed':
        return AppColors.successGreen;
      case 'cancelled':
        return AppColors.mutedGray;
      default:
        return AppColors.mutedGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRouter.studentOrderDetail.replaceFirst(':orderId', order.id),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm', 'id_ID')
                        .format(order.createdAt.toLocal()),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.mutedGray),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.bag_fill,
                          size: 14, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.canteenName ?? '-',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (order.isDelivery)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.softOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🛵 Antar',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkOrange),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Item list (max 2)
                  ...order.items.take(2).map((item) => Text(
                        '${item.quantity}x ${item.productName}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.mutedGray),
                      )),
                  if (order.items.length > 2)
                    Text(
                      '+${order.items.length - 2} item lainnya',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.mutedGray),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.mutedGray),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer: lihat detail
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: AppColors.grayLight, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lihat Detail',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.teal,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.right_chevron,
                      size: 12, color: AppColors.teal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
