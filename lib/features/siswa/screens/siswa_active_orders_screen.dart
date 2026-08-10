import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/cancel_order_modal.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class SiswaActiveOrdersScreen extends ConsumerStatefulWidget {
  const SiswaActiveOrdersScreen({super.key});

  @override
  ConsumerState<SiswaActiveOrdersScreen> createState() => _SiswaActiveOrdersScreenState();
}

class _SiswaActiveOrdersScreenState extends ConsumerState<SiswaActiveOrdersScreen> {
  Future<void> _cancelStudentOrder(String orderId, int totalAmount) async {
    final success = await CancelOrderModal.show(
      context,
      orderId: orderId,
      onSuccess: () {
        ref.invalidate(siswaActiveOrdersProvider);
        ref.invalidate(siswaStudentProvider);
        ref.invalidate(siswaTransactionsProvider);
      },
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan berhasil dibatalkan. Saldo telah dikembalikan.'),
          backgroundColor: Nebula.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleStudentRejectMerchantCancel(OrderItem order) async {
    final bool confirm = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Tolak Pembatalan'),
            content: const Text('Apakah Anda yakin ingin menolak pembatalan dari kantin? Pesanan Anda akan tetap diproses.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Tolak Pembatalan'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.from('orders').update({
          'status': 'Sedang Dimasak',
          'cancel_request_reason': null,
        }).eq('id', order.id);

        ref.invalidate(siswaActiveOrdersProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permohonan pembatalan dari kantin ditolak. Pesanan dilanjutkan.'),
              backgroundColor: Nebula.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menolak permohonan: $e'),
              backgroundColor: Nebula.rose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleStudentApproveMerchantCancel(OrderItem order) async {
    final bool confirm = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Setujui Pembatalan'),
            content: const Text('Apakah Anda setuju membatalkan pesanan ini? Saldo Anda akan segera dikembalikan.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Setujui Batal'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.rpc('cancel_order', params: {
          'p_order_id': order.id,
          'p_reason': order.cancelRequestReason ?? 'Persetujuan Pembatalan oleh Murid',
        });

        ref.invalidate(siswaActiveOrdersProvider);
        ref.invalidate(siswaStudentProvider);
        ref.invalidate(siswaTransactionsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan berhasil dibatalkan. Saldo telah dikembalikan.'),
              backgroundColor: Nebula.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyetujui pembatalan: $e'),
              backgroundColor: Nebula.rose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersAsync = ref.watch(siswaActiveOrdersProvider);

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
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        title: Text(
          'Pesanan Aktif',
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Nebula.teal,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaActiveOrdersProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: activeOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _AnimatedActiveOrderCard(
                      order: order,
                      builder: (context, isHighlight) {
                        return _buildActiveOrderCard(order, isHighlight);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CupertinoActivityIndicator(radius: 12),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: Nebula.rose, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat pesanan aktif: $err',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Nebula.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.square_list,
                color: Nebula.teal,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Pesanan Aktif',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai belanja makanan lezat Anda di tab Menu sekarang!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(OrderItem order, bool isHighlight) {
    final bool isMerchantCancelRequest = order.status == 'Menunggu Persetujuan Murid';
    final bool canCancel = (order.status == 'Baru' || order.status == 'Sedang Dimasak') && !isMerchantCancelRequest;
    Color statusColor;
    IconData statusIcon;
    switch (order.status) {
      case 'Baru':
        statusColor = Nebula.teal;
        statusIcon = Icons.access_time;
      case 'Sedang Dimasak':
        statusColor = Nebula.amber;
        statusIcon = Icons.soup_kitchen;
      case 'Menunggu Pembatalan':
        statusColor = Nebula.rose;
        statusIcon = Icons.report_problem_outlined;
      case 'Menunggu Persetujuan Murid':
        statusColor = Nebula.amber;
        statusIcon = Icons.report_problem_outlined;
      case 'Siap Diambil':
        statusColor = Nebula.teal;
        statusIcon = Icons.shopping_bag_outlined;
      case 'Siap Diantar':
        statusColor = Nebula.teal;
        statusIcon = Icons.delivery_dining;
      default:
        statusColor = context.textSecondary;
        statusIcon = Icons.access_time;
    }

    final mainRow = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.items.map((i) => '${i.qty}x ${i.name}').join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${isMerchantCancelRequest ? "Kantin Minta Batal" : (order.status == 'Baru' ? 'Sedang Diproses' : order.status)} • ${order.time}',
                style: TextStyle(color: context.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        if (!isMerchantCancelRequest)
          canCancel
              ? SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () => _cancelStudentOrder(order.id, order.totalAmount),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: Nebula.rose,
                      backgroundColor: Nebula.rose.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      order.status == 'Sedang Dimasak' ? 'Minta Batal' : 'Batalkan',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status == 'Baru'
                          ? 'Sedang Diproses'
                          : order.status.startsWith('Siap') ? 'Siap' : order.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? Nebula.teal
              : isMerchantCancelRequest
                  ? Nebula.amber.withValues(alpha: 0.5)
                  : context.dividerCol,
          width: (isHighlight || isMerchantCancelRequest) ? 1.5 : 1.0,
        ),
        boxShadow: isHighlight
            ? [
                BoxShadow(
                  color: Nebula.teal.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: isMerchantCancelRequest
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                mainRow,
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Nebula.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kantin meminta pembatalan pesanan:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.cancelRequestReason ?? 'Tidak ada alasan khusus.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _handleStudentRejectMerchantCancel(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textSecondary,
                        side: BorderSide(color: context.borderLight),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Tolak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleStudentApproveMerchantCancel(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.rose,
                        foregroundColor: context.cardBg,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Setujui Batal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : mainRow,
    );
  }
}

class _AnimatedActiveOrderCard extends StatefulWidget {
  final OrderItem order;
  final Widget Function(BuildContext, bool isHighlight) builder;

  const _AnimatedActiveOrderCard({
    required this.order,
    required this.builder,
  });

  @override
  State<_AnimatedActiveOrderCard> createState() => _AnimatedActiveOrderCardState();
}

class _AnimatedActiveOrderCardState extends State<_AnimatedActiveOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  bool _highlight = false;

  @override
  void initState() {
    super.initState();
    final bool isNew = widget.order.createdAt != null &&
        DateTime.now().difference(widget.order.createdAt!).inSeconds < 8;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _slideAnimation = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    if (isNew) {
      _highlight = true;
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _highlight = false;
          });
        }
      });
    } else {
      _controller.value = 1.0;
    }
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
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.builder(context, _highlight),
          ),
        );
      },
    );
  }
}

