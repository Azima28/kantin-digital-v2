/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/widgets/cancel_order_modal.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/order_chat_button.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/order_chat_sheet.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Hallmark Siswa Active Orders Screen
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
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan. Saldo telah dikembalikan.'),
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
            const SnackBar(
              content: Text('Permohonan pembatalan dari kantin ditolak. Pesanan dilanjutkan.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menolak permohonan: $e'),
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
            const SnackBar(
              content: Text('Pesanan berhasil dibatalkan. Saldo telah dikembalikan.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyetujui pembatalan: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showOrderDetailSheet(BuildContext context, OrderItem order) {
    final colors = context.colors;
    final isMerchantCancel = order.status == 'Menunggu Persetujuan Murid';
    final canCancel = (order.status == 'Baru' || order.status == 'Sedang Dimasak') && !isMerchantCancel;

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (order.status) {
      case 'Baru':
        statusBgColor = colors.brandPrimary.withValues(alpha: 0.12);
        statusColor = colors.brandPrimary;
        statusIcon = Icons.access_time;
      case 'Sedang Dimasak':
        statusBgColor = colors.statusWarning.withValues(alpha: 0.12);
        statusColor = colors.statusWarning;
        statusIcon = Icons.soup_kitchen;
      case 'Menunggu Pembatalan':
        statusBgColor = colors.statusError.withValues(alpha: 0.12);
        statusColor = colors.statusError;
        statusIcon = Icons.report_problem_outlined;
      case 'Menunggu Persetujuan Murid':
        statusBgColor = colors.statusWarning.withValues(alpha: 0.12);
        statusColor = colors.statusWarning;
        statusIcon = Icons.report_problem_outlined;
      case 'Siap Diambil':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusColor = colors.statusSuccess;
        statusIcon = Icons.shopping_bag_outlined;
      case 'Siap Diantar':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusColor = colors.statusSuccess;
        statusIcon = Icons.delivery_dining;
      default:
        statusBgColor = colors.textMuted.withValues(alpha: 0.12);
        statusColor = colors.textMuted;
        statusIcon = Icons.access_time;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.borderTactile, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle & Top Header Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rincian Pesanan',
                            style: HallmarkTypography.titleL3(colors.textPrimary).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 24),
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderTactile),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Student Profile Banner Card
                      _buildStudentBanner(colors, order),
                      const SizedBox(height: 20),

                      // 2. Interactive Stepper/Progress Tracker
                      _buildStatusStepper(colors, order),
                      const SizedBox(height: 20),

                      // 3. Receipt Details Card
                      _buildReceiptCard(colors, order, statusBgColor, statusColor, statusIcon),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Actions Bar
              Container(
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  border: Border(top: BorderSide(color: colors.borderTactile, width: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HallmarkButton(
                      label: 'Chat Pedagang',
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      onPressed: () {
                        Navigator.pop(context);
                        OrderChatSheet.show(context, order: order);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (canCancel)
                          Expanded(
                            child: HallmarkButton(
                              label: order.status == 'Sedang Dimasak' ? 'Minta Batal' : 'Batalkan',
                              isError: true,
                              onPressed: () {
                                Navigator.pop(context);
                                _cancelStudentOrder(order.id, order.totalAmount);
                              },
                            ),
                          ),
                        if (canCancel) const SizedBox(width: 12),
                        Expanded(
                          child: HallmarkButton(
                            label: 'Tutup Rincian',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentBanner(HallmarkColorScheme colors, OrderItem order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.brandPrimary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.brandPrimary,
            child: Text(
              order.studentName.isNotEmpty ? order.studentName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.studentName,
                  style: HallmarkTypography.titleSmall(colors.textPrimary).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Siswa Pembeli',
                  style: HallmarkTypography.bodySmall(colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(HallmarkColorScheme colors, OrderItem order) {
    final List<String> statuses = ['Baru', 'Sedang Dimasak', 'Siap Diambil', 'Selesai'];
    int currentIndex = statuses.indexOf(order.status);

    if (order.status == 'Siap Diantar') currentIndex = 2;
    if (order.status == 'Menunggu Pembatalan') currentIndex = 1;
    if (order.status == 'Dibatalkan') currentIndex = -1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderTactile, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(statuses.length, (index) {
          final isCompleted = currentIndex >= index;
          final isCurrent = currentIndex == index;
          final isBatal = order.status == 'Dibatalkan';

          Color circleColor;
          IconData icon;
          if (isBatal) {
            circleColor = colors.statusError;
            icon = Icons.cancel;
          } else if (order.status == 'Menunggu Pembatalan' && index == 1) {
            circleColor = colors.statusError;
            icon = Icons.warning_amber_rounded;
          } else if (isCompleted) {
            circleColor = colors.brandPrimary;
            icon = Icons.check;
          } else {
            circleColor = colors.textMuted.withValues(alpha: 0.4);
            icon = Icons.circle;
          }

          String stepLabel = statuses[index];
          if (index == 2 && order.status == 'Siap Diantar') {
            stepLabel = 'Siap Diantar';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? colors.surfaceContainer : circleColor,
                  border: isCurrent ? Border.all(color: circleColor, width: 4) : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: circleColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Icon(
                    isCurrent ? Icons.play_arrow : icon,
                    size: 14,
                    color: isCurrent ? circleColor : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stepLabel,
                style: HallmarkTypography.bodySmall(
                  isCurrent || isCompleted ? colors.textPrimary : colors.textMuted,
                ).copyWith(
                  fontSize: 10,
                  fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReceiptCard(
    HallmarkColorScheme colors,
    OrderItem order,
    Color statusBgColor,
    Color statusColor,
    IconData statusIcon,
  ) {
    final String orderNum = '#A-${order.id.substring(0, order.id.length > 6 ? 6 : order.id.length).toUpperCase()}';
    final String statusText = order.status == 'Baru' ? 'Sedang Diproses' : order.status;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderTactile, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header Number & Status Badge
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNum,
                        style: HallmarkTypography.titleL3(colors.brandPrimary).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${order.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: HallmarkTypography.bodySmall(statusColor).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderTactile),

          // Metadata properties
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildMetaRow(colors, 'Waktu Transaksi', order.time),
                const SizedBox(height: 8),
                _buildMetaRow(
                  colors,
                  'Tipe Pengambilan',
                  order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty
                      ? order.deliveryLocation!
                      : 'Ambil Mandiri di Kantin',
                ),
                const SizedBox(height: 8),
                _buildMetaRow(
                  colors,
                  'Metode Pembelian',
                  order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty
                      ? 'Aplikasi Mobile'
                      : 'Aplikasi / NFC Kasir',
                ),
              ],
            ),
          ),

          // Dashed border separating meta from items list
          _buildDashedDivider(colors),

          // Items listing
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Pesanan:',
                  style: HallmarkTypography.titleSmall(colors.textPrimary).copyWith(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        // Product photo thumbnail
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.borderTactile, width: 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    item.imageUrl!,
                                    width: 40,
                                    height: 40,
                                    cacheWidth: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: colors.brandPrimary,
                                      size: 18,
                                    ),
                                  )
                                : Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: colors.brandPrimary,
                                    size: 18,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name & Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: HallmarkTypography.bodyMain(colors.textPrimary).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@ Rp ${NumberFormat('#,###', 'id_ID').format(item.price)}',
                                style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        // Quantity & Subtotal
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'x${item.qty}',
                              style: HallmarkTypography.bodyMain(colors.textPrimary).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(item.price * item.qty)}',
                              style: HallmarkTypography.financialNumeral(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Dashed border separating items from subtotal/total
          _buildDashedDivider(colors),

          // Receipt Footer Totals
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'TOTAL PEMBAYARAN',
                    style: HallmarkTypography.titleSmall(colors.textPrimary).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                  style: HallmarkTypography.financialNumeral(
                    color: colors.brandPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(HallmarkColorScheme colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(fontSize: 12),
        ),
        Text(
          value,
          style: HallmarkTypography.bodySmall(colors.textPrimary).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeOrdersAsync = ref.watch(siswaActiveOrdersProvider);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: colors.borderTactile, width: 0.5),
        ),
        title: Text(
          'Pesanan Aktif',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
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
                  return _buildEmptyState(colors);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildActiveOrderCard(colors, order);
                  },
                );
              },
              loading: () => Shimmer(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.borderTactile, width: 0.8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: colors.borderTactile,
                                  width: 6,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    SkeletonBox(width: 85, height: 24, borderRadius: 8),
                                    SkeletonBox(width: 75, height: 14, borderRadius: 4),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const SkeletonBox(width: 140, height: 16, borderRadius: 4),
                                const SizedBox(height: 6),
                                const SkeletonBox(width: 90, height: 12, borderRadius: 4),
                                const SizedBox(height: 16),
                                const SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                                const SizedBox(height: 8),
                                const SkeletonBox(width: 160, height: 14, borderRadius: 4),
                                const SizedBox(height: 16),
                                Container(
                                  height: 0.8,
                                  color: colors.borderTactile,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    SkeletonBox(width: 70, height: 14, borderRadius: 4),
                                    SkeletonBox(width: 90, height: 18, borderRadius: 4),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle, color: colors.statusError, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat pesanan aktif',
                        textAlign: TextAlign.center,
                        style: HallmarkTypography.bodySmall(colors.textMuted),
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

  Widget _buildEmptyState(HallmarkColorScheme colors) {
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
                color: colors.brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.square_list,
                color: colors.brandPrimary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Pesanan Aktif',
              style: HallmarkTypography.titleL3(colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai belanja makanan lezat Anda di tab Menu sekarang!',
              textAlign: TextAlign.center,
              style: HallmarkTypography.bodyMain(colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(HallmarkColorScheme colors, OrderItem order) {
    final bool isMerchantCancelRequest = order.status == 'Menunggu Persetujuan Murid';
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;
    String statusLabel = order.status == 'Baru' ? 'Proses' : order.status;

    switch (order.status) {
      case 'Baru':
        statusBgColor = colors.brandPrimary.withValues(alpha: 0.12);
        statusTextColor = colors.brandPrimary;
        statusIcon = Icons.access_time;
      case 'Sedang Dimasak':
        statusBgColor = colors.statusWarning.withValues(alpha: 0.12);
        statusTextColor = colors.statusWarning;
        statusIcon = Icons.soup_kitchen;
      case 'Menunggu Pembatalan':
        statusBgColor = colors.statusError.withValues(alpha: 0.12);
        statusTextColor = colors.statusError;
        statusIcon = Icons.report_problem_outlined;
        statusLabel = 'Minta Batal';
      case 'Menunggu Persetujuan Murid':
        statusBgColor = colors.statusWarning.withValues(alpha: 0.12);
        statusTextColor = colors.statusWarning;
        statusIcon = Icons.report_problem_outlined;
        statusLabel = 'Kantin Minta Batal';
      case 'Siap Diambil':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusTextColor = colors.statusSuccess;
        statusIcon = Icons.shopping_bag_outlined;
      case 'Siap Diantar':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusTextColor = colors.statusSuccess;
        statusIcon = Icons.delivery_dining;
      default:
        statusBgColor = colors.textMuted.withValues(alpha: 0.12);
        statusTextColor = colors.textMuted;
        statusIcon = Icons.access_time;
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderTactile, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showOrderDetailSheet(context, order),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: statusTextColor, width: 6)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row: Status Badge Box (Left) + Order ID + Chat Button + Chevron
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status Badge Box
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusTextColor.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: statusTextColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    statusLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HallmarkTypography.bodySmall(statusTextColor).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Right actions: Order ID Code, Chat Button, Chevron
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.borderTactile, width: 0.5),
                              ),
                              child: Text(
                                '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                                style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OrderChatIconButton(
                              order: order,
                              myRole: 'student',
                              onTap: () => OrderChatSheet.show(context, order: order),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: colors.textMuted.withValues(alpha: 0.6),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Main Content Row: Food Image Thumbnail + Itemized List Summary
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Image Thumbnail of Most Expensive Item
                        Builder(
                          builder: (context) {
                            final topItem = order.mostExpensiveItem;
                            final String? imgUrl = topItem?.imageUrl;
                            final bool isDelivery = order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty;

                            final fallbackChild = Icon(
                              isDelivery ? Icons.delivery_dining : Icons.restaurant_menu_rounded,
                              color: colors.brandPrimary,
                              size: 22,
                            );

                            return Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.borderTactile, width: 0.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (imgUrl != null && imgUrl.isNotEmpty)
                                    ? Image.network(
                                        imgUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => fallbackChild,
                                      )
                                    : fallbackChild,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Items list preview
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.items.map((i) => '${i.qty}x ${i.name}').join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: HallmarkTypography.titleSmall(colors.textPrimary).copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.time,
                                    size: 12,
                                    color: colors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.time,
                                    style: HallmarkTypography.bodySmall(colors.textMuted),
                                  ),
                                  if (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty) ...[
                                    Text(
                                      ' • ',
                                      style: HallmarkTypography.bodySmall(colors.textMuted),
                                    ),
                                    Icon(
                                      Icons.delivery_dining,
                                      size: 13,
                                      color: colors.brandPrimary,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        order.deliveryLocation!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: HallmarkTypography.bodySmall(colors.brandPrimary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dashed Divider Line
                    _buildDashedDivider(colors),
                    const SizedBox(height: 10),

                    // Bottom Total Amount Summary Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Harga',
                          style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                          style: HallmarkTypography.financialNumeral(
                            color: colors.brandPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    // If Merchant Cancel Request, show action banner & buttons
                    if (isMerchantCancelRequest) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.statusWarning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kantin meminta pembatalan pesanan:',
                              style: HallmarkTypography.bodySmall(colors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.cancelRequestReason ?? 'Tidak ada alasan khusus.',
                              style: HallmarkTypography.bodySmall(colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          HallmarkButton(
                            label: 'Tolak',
                            isFullWidth: false,
                            onPressed: () => _handleStudentRejectMerchantCancel(order),
                          ),
                          const SizedBox(width: 8),
                          HallmarkButton(
                            label: 'Setujui Batal',
                            isError: true,
                            isFullWidth: false,
                            onPressed: () => _handleStudentApproveMerchantCancel(order),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashedDivider(HallmarkColorScheme colors) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: colors.borderTactile),
              ),
            );
          }),
        );
      },
    );
  }
}
