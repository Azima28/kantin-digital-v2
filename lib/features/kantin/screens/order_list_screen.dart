import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/kantin/widgets/order_item_card.dart';
import 'package:kantin_digital/features/kantin/widgets/order_status_tabs.dart';
import 'package:kantin_digital/core/widgets/cancel_order_modal.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  String _selectedTab = 'baru';
  late final PageController _pageController;
  final List<String> _tabsKeys = ['baru', 'proses', 'selesai', 'batal'];

  @override
  void initState() {
    super.initState();
    final int initialIndex = _tabsKeys.indexOf(_selectedTab);
    _pageController = PageController(initialPage: initialIndex >= 0 ? initialIndex : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String id, String newStatus, String studentId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      
      if (newStatus == 'Dibatalkan') {
        final success = await CancelOrderModal.show(
          context,
          orderId: id,
          onSuccess: () {
            ref.invalidate(canteenOrdersProvider);
          },
        );
        
        if (success == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pesanan berhasil dibatalkan. Saldo telah dikembalikan.'),
              backgroundColor: Nebula.teal,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Ambil status sebelum update untuk notifikasi spesifik
      final orderData = await client
          .from('orders')
          .select('status, student_name, student_id, total_amount, order_items(product_name, quantity)')
          .eq('id', id)
          .maybeSingle();

      final String prevStatus = orderData?['status'] as String? ?? '';
      final num totalAmount = (orderData?['total_amount'] as num?) ?? 0;
      final String operatorId = orderData?['operator_id'] as String? ?? '';
      
      await client.from('orders').update({'status': newStatus}).eq('id', id);

      // Escrow Release: If status becomes 'Selesai', release held escrow funds to canteen operator
      if (newStatus == 'Selesai' && prevStatus != 'Selesai') {
        try {
          await client.rpc('complete_order_release_escrow', params: {'p_order_id': id});
        } catch (_) {
          // Fallback if RPC not yet deployed to remote DB
          if (operatorId.isNotEmpty && totalAmount > 0) {
            final opData = await client
                .from('canteen_operators')
                .select('balance_earned')
                .eq('id', operatorId)
                .maybeSingle();
            if (opData != null) {
              final double opEarned = (opData['balance_earned'] as num).toDouble();
              await client
                  .from('canteen_operators')
                  .update({'balance_earned': opEarned + totalAmount.toDouble()})
                  .eq('id', operatorId);
            }
          }
          if (studentId.isNotEmpty && totalAmount > 0) {
            await client
                .from('transactions')
                .update({'status': 'success'})
                .eq('student_id', studentId)
                .eq('type', 'purchase')
                .filter('status', 'in', '("pending_escrow","pending")');
          }
        }
      }

      // Send notification to student based on status
      if (studentId.isNotEmpty) {
        String title = '';
        String message = '';
        
        String itemSummary = '';
        if (orderData != null && orderData['order_items'] != null) {
          final List<dynamic> items = orderData['order_items'];
          itemSummary = items.map((item) => "${item['quantity']}x ${item['product_name']}").join(', ');
        }

        final String prefix = itemSummary.isNotEmpty ? "($itemSummary) " : "";

        if (newStatus == 'Sedang Dimasak') {
          if (prevStatus == 'Menunggu Pembatalan') {
            title = 'Pengajuan Batal Ditolak 🍳';
            message = 'Pengajuan pembatalan untuk pesanan Anda ${prefix}telah ditolak. Pesanan Anda tetap diproses dan sedang dimasak.';
          } else {
            title = 'Pesanan Diterima! 🍳';
            message = 'Pesanan Anda ${prefix}telah diterima oleh kantin dan sedang dimasak.';
          }
        } else if (newStatus == 'Siap Diambil') {
          title = 'Pesanan Siap Diambil! 🛍️';
          message = 'Pesanan Anda ${prefix}siap diambil di stan kantin.';
        } else if (newStatus == 'Siap Diantar') {
          title = 'Pesanan Siap Diantar! 🚴';
          message = 'Pesanan Anda ${prefix}sedang diantar.';
        } else if (newStatus == 'Selesai') {
          title = 'Pesanan Selesai! 🎉';
          message = 'Pesanan Anda ${prefix}telah selesai. Dana yang ditahan sistem telah diserahkan ke kantin.';
        }

        if (title.isNotEmpty && message.isNotEmpty) {
          await client.from('notifications').insert({
            'student_id': studentId,
            'title': title,
            'message': message,
            'type': 'system',
          });
        }
      }

      ref.invalidate(canteenOrdersProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(operatorTransactionsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan berhasil diubah menjadi "$newStatus"'),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status pesanan: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<OrderItem> _getFilteredOrders(List<OrderItem> orders, String tab) {
    final now = DateTime.now();
    return orders.where((order) {
      final bool isToday = order.createdAt != null &&
          order.createdAt!.year == now.year &&
          order.createdAt!.month == now.month &&
          order.createdAt!.day == now.day;

      if (tab == 'baru') {
        return order.status == 'Baru';
      } else if (tab == 'proses') {
        return order.status == 'Sedang Dimasak' ||
            order.status == 'Siap Diambil' ||
            order.status == 'Siap Diantar' ||
            order.status == 'Menunggu Pembatalan' ||
            order.status == 'Menunggu Persetujuan Murid';
      } else if (tab == 'selesai') {
        return order.status == 'Selesai' && isToday;
      } else if (tab == 'batal') {
        return order.status == 'Dibatalkan' && isToday;
      }
      return false;
    }).toList();
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom Shopping Basket + Magnifier Illustration matching user reference image
                SizedBox(
                  width: 130,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 4,
                        child: Icon(
                          Icons.shopping_basket_rounded,
                          size: 88,
                          color: Nebula.teal,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Nebula.teal, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada pesanan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesanan yang kamu buat akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                PressScale(
                  onTap: () {
                    context.go('/pos/products');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Nebula.teal,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Nebula.teal.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Lihat Produk',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(canteenOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        centerTitle: false,
        title: Text(
          'Daftar Pesanan',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Nebula.teal,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.bell,
              color: Nebula.teal,
              size: 22,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: 3,
          itemBuilder: (context, index) => const SkeletonCard(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Nebula.rose),
                const SizedBox(height: 16),
                Text(
                  'Gagal Memuat Pesanan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(canteenOrdersProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (orders) {
          // Count status statistics
          final now = DateTime.now();
          final int countBaru = orders.where((o) => o.status == 'Baru').length;
          final int countProses = orders.where((o) =>
              o.status == 'Sedang Dimasak' ||
              o.status == 'Siap Diambil' ||
              o.status == 'Siap Diantar' ||
              o.status == 'Menunggu Pembatalan' ||
              o.status == 'Menunggu Persetujuan Murid').length;
          final int countSelesai = orders.where((o) {
            final bool isToday = o.createdAt != null &&
                o.createdAt!.year == now.year &&
                o.createdAt!.month == now.month &&
                o.createdAt!.day == now.day;
            return o.status == 'Selesai' && isToday;
          }).length;
          final int countBatal = orders.where((o) {
            final bool isToday = o.createdAt != null &&
                o.createdAt!.year == now.year &&
                o.createdAt!.month == now.month &&
                o.createdAt!.day == now.day;
            return o.status == 'Dibatalkan' && isToday;
          }).length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(canteenOrdersProvider);
            },
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Segmented Tabs Header Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: OrderStatusTabs(
                          selectedTab: _selectedTab,
                          countBaru: countBaru,
                          countProses: countProses,
                          countSelesai: countSelesai,
                          countBatal: countBatal,
                          onTabChanged: (tab) {
                            setState(() => _selectedTab = tab);
                            final int index = _tabsKeys.indexOf(tab);
                            if (index >= 0) {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),

                      // Order Cards List wrapped in PageView (ViewPager transition)
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedTab = _tabsKeys[index];
                            });
                          },
                          itemCount: _tabsKeys.length,
                          itemBuilder: (context, pageIndex) {
                            final String tabKey = _tabsKeys[pageIndex];
                            final List<OrderItem> filteredOrders = _getFilteredOrders(orders, tabKey);

                            if (filteredOrders.isEmpty) {
                              return _buildEmptyState();
                            }

                            return ListView.builder(
                              key: PageStorageKey<String>(tabKey),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                return _AnimatedCardEntry(
                                  index: index,
                                  child: OrderItemCard(
                                    order: filteredOrders[index],
                                    onStatusChanged: _updateOrderStatus,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Stagger entrance animation
class _AnimatedCardEntry extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedCardEntry({
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedCardEntry> createState() => _AnimatedCardEntryState();
}

class _AnimatedCardEntryState extends State<_AnimatedCardEntry> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
