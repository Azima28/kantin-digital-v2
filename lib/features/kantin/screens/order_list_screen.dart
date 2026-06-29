import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/providers/order_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Refresh setiap 8 detik (selaras cacheFor di provider)
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidate(kantinOrdersProvider);
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
    final ordersAsync = ref.watch(kantinOrdersProvider);
    final historyAsync = ref.watch(kantinOrderHistoryProvider);
    final newCount = ref.watch(newOrderCountProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Pesanan Masuk',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.teal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppColors.teal),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(kantinOrdersProvider);
              ref.invalidate(kantinOrderHistoryProvider);
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
            // Tab Baru
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Baru'),
                  if (newCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$newCount',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Tab(text: 'Diproses'),
            const Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text('Gagal memuat pesanan',
                  style: GoogleFonts.inter(color: AppColors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(kantinOrdersProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (orders) {
          final pending =
              orders.where((o) => o.isPending).toList();
          final inProgress = orders
              .where((o) => o.isAccepted || o.isPreparing || o.isReady)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Baru (pending)
              _OrderTabContent(
                orders: pending,
                emptyMessage: 'Belum ada pesanan baru',
                emptyIcon: CupertinoIcons.bell_slash,
              ),
              // Tab 2: Diproses
              _OrderTabContent(
                orders: inProgress,
                emptyMessage: 'Tidak ada pesanan dalam proses',
                emptyIcon: CupertinoIcons.time,
              ),
              // Tab 3: Selesai / Riwayat
              historyAsync.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (_, __) => Center(
                  child: Text('Gagal memuat riwayat',
                      style:
                          GoogleFonts.inter(color: AppColors.error)),
                ),
                data: (history) => _OrderTabContent(
                  orders: history,
                  emptyMessage: 'Belum ada pesanan selesai',
                  emptyIcon: CupertinoIcons.checkmark_circle,
                  isHistory: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _OrderTabContent extends ConsumerWidget {
  final List<Order> orders;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isHistory;

  const _OrderTabContent({
    required this.orders,
    required this.emptyMessage,
    required this.emptyIcon,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 56, color: AppColors.gray400),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray),
            ),
            const SizedBox(height: 6),
            Text(
              isHistory
                  ? ''
                  : 'Pesanan baru akan muncul otomatis di sini',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.mutedGray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: () async {
        ref.invalidate(kantinOrdersProvider);
        ref.invalidate(kantinOrderHistoryProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _KantinOrderCard(order: orders[i], isHistory: isHistory),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _KantinOrderCard extends ConsumerStatefulWidget {
  final Order order;
  final bool isHistory;
  const _KantinOrderCard({required this.order, this.isHistory = false});

  @override
  ConsumerState<_KantinOrderCard> createState() =>
      _KantinOrderCardState();
}

class _KantinOrderCardState extends ConsumerState<_KantinOrderCard> {
  bool _isLoading = false;

  Color get _indicatorColor {
    switch (widget.order.status) {
      case 'pending':
        return AppColors.primary;
      case 'accepted':
        return AppColors.accentOrange;
      case 'preparing':
        return AppColors.accentOrange2;
      case 'ready':
        return AppColors.successGreen;
      case 'completed':
        return AppColors.successGreen;
      case 'cancelled':
        return AppColors.mutedGray;
      default:
        return AppColors.gray;
    }
  }

  Future<void> _doAction(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      if (newStatus == 'completed') {
        await completeOrder(ref: ref, orderId: widget.order.id);
      } else if (newStatus == 'cancelled') {
        await cancelOrderByOperator(ref: ref, orderId: widget.order.id);
      } else {
        await updateOrderStatus(
            ref: ref,
            orderId: widget.order.id,
            newStatus: newStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: ${e.toString().split(':').last}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left indicator bar
              Container(width: 5, color: _indicatorColor),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row: nama siswa + status badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.studentName ?? 'Siswa',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          _StatusBadge(status: o.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Waktu + delivery info
                      Row(
                        children: [
                          const Icon(CupertinoIcons.clock,
                              size: 12, color: AppColors.mutedGray),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm', 'id_ID')
                                .format(o.createdAt.toLocal()),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.mutedGray),
                          ),
                          if (o.isDelivery) ...[
                            const SizedBox(width: 10),
                            const Icon(CupertinoIcons.location_fill,
                                size: 12, color: AppColors.accentOrange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Antar ke: ${o.deliveryLocation ?? "-"}',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.accentOrange,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (o.isDelivery && o.studentPhone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(CupertinoIcons.phone,
                                size: 12, color: AppColors.mutedGray),
                            const SizedBox(width: 4),
                            Text(o.studentPhone!,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.mutedGray)),
                          ],
                        ),
                      ],
                      if (o.note != null && o.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(CupertinoIcons.pencil,
                                size: 12, color: AppColors.mutedGray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(o.note!,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.mutedGray),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 16),

                      // Items
                      ...o.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text('${item.quantity}×',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mutedGray)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(item.productName,
                                        style: GoogleFonts.inter(
                                            fontSize: 13))),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(item.lineTotal)}',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )),

                      const Divider(height: 12),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subtotal',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.mutedGray)),
                              Text(
                                'Rp ${NumberFormat('#,###', 'id_ID').format(o.subtotal)}',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (o.isDelivery && o.deliveryFee > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Ongkir 🛵',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.mutedGray)),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(o.deliveryFee)}',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentOrange),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Action buttons (jika bukan riwayat)
                      if (!widget.isHistory && !o.isCompleted && !o.isCancelled) ...[
                        const SizedBox(height: 12),
                        _ActionButtons(
                          order: o,
                          isLoading: _isLoading,
                          onAction: _doAction,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'pending':
        bg = AppColors.primaryLight;
        fg = AppColors.teal;
        label = '🔔 Baru';
        break;
      case 'accepted':
        bg = AppColors.softOrange;
        fg = AppColors.darkOrange;
        label = '✅ Diterima';
        break;
      case 'preparing':
        bg = AppColors.softOrange;
        fg = AppColors.darkOrange;
        label = '🍳 Dimasak';
        break;
      case 'ready':
        bg = AppColors.successGreenLight;
        fg = AppColors.successGreen;
        label = '🎉 Siap';
        break;
      case 'completed':
        bg = AppColors.successGreenLight;
        fg = AppColors.successGreen;
        label = '✔ Selesai';
        break;
      case 'cancelled':
        bg = AppColors.grayLighter;
        fg = AppColors.mutedGray;
        label = '✗ Batal';
        break;
      default:
        bg = AppColors.grayLighter;
        fg = AppColors.mutedGray;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final Order order;
  final bool isLoading;
  final void Function(String) onAction;
  const _ActionButtons(
      {required this.order,
      required this.isLoading,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: CupertinoActivityIndicator(),
      ));
    }

    final isPending = order.isPending;
    final isAccepted = order.isAccepted;
    final isPreparing = order.isPreparing;
    final isReady = order.isReady;

    return Row(
      children: [
        // Tolak (hanya saat pending)
        if (isPending)
          Expanded(
            child: OutlinedButton(
              onPressed: () => onAction('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text('Tolak',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        if (isPending) const SizedBox(width: 8),

        // Primary action
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              if (isPending) onAction('accepted');
              if (isAccepted) onAction('preparing');
              if (isPreparing) onAction('ready');
              if (isReady) onAction('completed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady
                  ? AppColors.successGreen
                  : AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              isPending
                  ? '✅ Terima'
                  : isAccepted
                      ? '🍳 Mulai Masak'
                      : isPreparing
                          ? '🎉 Siap'
                          : '✔ Selesaikan',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
