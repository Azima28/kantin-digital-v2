/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/cancel_order_modal.dart';
import 'package:kantin_digital/core/widgets/date_filter_modal.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/order_chat_button.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/order_chat_sheet.dart';
import 'package:kantin_digital/features/siswa/widgets/order_review_section.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

enum StudentOrderFilter {
  menunggu,
  diproses,
  selesai,
  dibatalkan,
  semua,
}

/// Hallmark Siswa Orders Screen with Status Slide Filter
class SiswaActiveOrdersScreen extends ConsumerStatefulWidget {
  const SiswaActiveOrdersScreen({super.key});

  @override
  ConsumerState<SiswaActiveOrdersScreen> createState() => _SiswaActiveOrdersScreenState();
}

class _SiswaActiveOrdersScreenState extends ConsumerState<SiswaActiveOrdersScreen> {
  StudentOrderFilter _selectedFilter = StudentOrderFilter.menunggu;
  AppDateFilterParam? _dateFilter;

  String? _resolveFoodImage(String productName, String? currentImgUrl) {
    if (currentImgUrl != null && currentImgUrl.trim().isNotEmpty) {
      return currentImgUrl.trim();
    }
    final lower = productName.toLowerCase().trim();
    if (lower.contains('dimsum')) return 'https://kantin.zitech.web.id/uploads/products/product_dimsum_goreng.jpg';
    if (lower.contains('nasi goreng') || lower.contains('nasgor')) return 'https://kantin.zitech.web.id/uploads/products/product_nasi_goreng.jpg';
    if (lower.contains('mie ayam') || lower.contains('mie bakso')) return 'https://kantin.zitech.web.id/uploads/products/product_mie_ayam.jpg';
    if (lower.contains('ayam geprek') || lower.contains('geprek')) return 'https://kantin.zitech.web.id/uploads/products/product_ayam_geprek.jpg';
    if (lower.contains('bakso')) return 'https://kantin.zitech.web.id/uploads/products/product_bakso_mercon.jpg';
    if (lower.contains('soto')) return 'https://kantin.zitech.web.id/uploads/products/product_soto_ayam.jpg';
    if (lower.contains('nasi rames') || lower.contains('rames')) return 'https://kantin.zitech.web.id/uploads/products/product_nasi_rames.jpg';
    if (lower.contains('es jeruk') || lower.contains('jeruk')) return 'https://kantin.zitech.web.id/uploads/products/product_es_jeruk.jpg';
    if (lower.contains('es teh') || lower.contains('teh')) return 'https://kantin.zitech.web.id/uploads/products/product_es_teh.jpg';
    if (lower.contains('jus') || lower.contains('alpukat')) return 'https://kantin.zitech.web.id/uploads/products/product_jus_alpukat.jpg';
    if (lower.contains('air') || lower.contains('mineral') || lower.contains('aqua')) return 'https://kantin.zitech.web.id/uploads/products/product_air_mineral.jpg';
    if (lower.contains('pisang')) return 'https://kantin.zitech.web.id/uploads/products/product_pisang_keju.jpg';
    if (lower.contains('risol')) return 'https://kantin.zitech.web.id/uploads/products/product_risoles_mayo.jpg';
    if (lower.contains('tango') || lower.contains('wafer')) return 'https://kantin.zitech.web.id/uploads/products/product_tango_wafer.jpg';
    return null;
  }

  bool _isOrderMenunggu(String status) {
    final s = status.trim().toLowerCase();
    return s == 'baru';
  }

  bool _isOrderDiproses(String status) {
    final s = status.trim().toLowerCase();
    return s == 'sedang dimasak' ||
        s == 'siap diambil' ||
        s == 'siap diantar' ||
        s == 'menunggu pembatalan' ||
        s == 'menunggu persetujuan murid';
  }

  bool _isOrderCompleted(String status) {
    final s = status.trim().toLowerCase();
    return s == 'selesai' || s == 'success';
  }

  bool _isOrderCancelled(String status) {
    final s = status.trim().toLowerCase();
    return s == 'dibatalkan' || s == 'cancelled' || s == 'refunded';
  }

  List<OrderItem> _filterOrders(List<OrderItem> allOrders) {
    List<OrderItem> list;
    switch (_selectedFilter) {
      case StudentOrderFilter.menunggu:
        list = allOrders.where((o) => _isOrderMenunggu(o.status)).toList();
        break;
      case StudentOrderFilter.diproses:
        list = allOrders.where((o) => _isOrderDiproses(o.status)).toList();
        break;
      case StudentOrderFilter.selesai:
        list = allOrders.where((o) => _isOrderCompleted(o.status)).toList();
        break;
      case StudentOrderFilter.dibatalkan:
        list = allOrders.where((o) => _isOrderCancelled(o.status)).toList();
        break;
      case StudentOrderFilter.semua:
        list = List.from(allOrders);
        break;
    }

    if (_dateFilter != null && !_dateFilter!.isAllTime) {
      list = list.where((o) => _dateFilter!.matches(o.createdAt)).toList();
    }
    return list;
  }

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
    final bool confirm = await showAppConfirmationDialog(
      context,
      title: 'Tolak Pembatalan Kantin',
      message: 'Apakah Anda yakin ingin menolak pembatalan dari kantin? Pesanan Anda akan tetap diproses.',
      confirmLabel: 'Tolak Pembatalan',
      isDestructive: true,
      icon: Icons.cancel_schedule_send_rounded,
    );

    if (confirm) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.patch('/orders/${order.id}/status', body: {
          'status': 'Sedang Dimasak',
          'cancel_request_reason': '',
        });

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
    final bool confirm = await showAppConfirmationDialog(
      context,
      title: 'Setujui Pembatalan Pesanan',
      message: 'Apakah Anda setuju membatalkan pesanan ini? Saldo Anda akan segera dikembalikan.',
      confirmLabel: 'Setujui Batal',
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );

    if (confirm) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.patch('/orders/${order.id}/status', body: {
          'status': 'Dibatalkan',
          'cancel_request_reason': order.cancelRequestReason ?? 'Persetujuan Pembatalan oleh Murid',
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
      case 'Selesai':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusColor = colors.statusSuccess;
        statusIcon = Icons.check_circle_outline;
      case 'Dibatalkan':
        statusBgColor = colors.statusError.withValues(alpha: 0.12);
        statusColor = colors.statusError;
        statusIcon = Icons.cancel_outlined;
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
                      // 1. Receipt Details Card (Rincian Pesanan di Atas)
                      _buildReceiptCard(colors, order, statusBgColor, statusColor, statusIcon),
                      const SizedBox(height: 20),

                      // 2. Rating & Ulasan (di Bawah Rincian jika Selesai) / Status Stepper (jika sedang proses)
                      if (order.status == 'Selesai')
                        OrderReviewSection(order: order, colors: colors)
                      else
                        _buildStatusStepper(colors, order),
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final chatAsync = ref.watch(orderChatStreamProvider(order.id));
                    final int unreadCount = chatAsync.maybeWhen(
                      data: (messages) => messages.where((m) => m.senderRole != 'student' && !m.isRead).length,
                      orElse: () => 0,
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            OrderChatSheet.show(context, order: order);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.brandPrimary.withValues(alpha: 0.5), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.chat_bubble_2_fill, size: 16, color: colors.brandPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Chat Pedagang Kantin',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: colors.brandPrimary,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusStepper(HallmarkColorScheme colors, OrderItem order) {
    final List<String> statuses = ['Baru', 'Sedang Dimasak', 'Siap Diambil', 'Selesai'];
    int currentIndex = statuses.indexOf(order.status);
    final bool isDelivery = order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty;

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
          final isCompleted = currentIndex >= index && order.status != 'Dibatalkan';
          final isCurrent = currentIndex == index;
          final isBatal = order.status == 'Dibatalkan';

          Color circleColor;
          if (isBatal) {
            circleColor = colors.statusError;
          } else if (order.status == 'Menunggu Pembatalan' && index == 1) {
            circleColor = colors.statusError;
          } else if (isCompleted) {
            circleColor = colors.brandPrimary;
          } else {
            circleColor = colors.textMuted.withValues(alpha: 0.4);
          }

          IconData icon;
          if (isBatal) {
            icon = Icons.cancel_rounded;
          } else if (order.status == 'Menunggu Pembatalan' && index == 1) {
            icon = Icons.warning_amber_rounded;
          } else {
            switch (index) {
              case 0:
                icon = Icons.receipt_long_rounded;
                break;
              case 1:
                icon = Icons.soup_kitchen_rounded;
                break;
              case 2:
                icon = isDelivery ? Icons.local_shipping_rounded : Icons.shopping_bag_rounded;
                break;
              case 3:
                icon = Icons.check_circle_rounded;
                break;
              default:
                icon = Icons.circle;
            }
          }

          String stepLabel = statuses[index];
          if (index == 2 && isDelivery) {
            stepLabel = 'Siap Diantar';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? colors.surfaceContainer : circleColor,
                  border: isCurrent ? Border.all(color: circleColor, width: 3.5) : null,
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
                    icon,
                    size: 16,
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
                      ? 'Diantar (${order.deliveryLocation!})'
                      : 'Ambil Mandiri di Kantin',
                ),
                const SizedBox(height: 8),
                _buildMetaRow(
                  colors,
                  'Metode Pembelian',
                  order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty
                      ? 'Aplikasi Mobile (Delivery)'
                      : 'Aplikasi / NFC Kasir (Pickup)',
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
                ...(() {
                  final sortedItems = List<OrderSubItem>.from(order.items)
                    ..sort((a, b) => (b.price * b.qty).compareTo(a.price * a.qty));
                  return sortedItems.map((item) {
                    final resolvedImg = _resolveFoodImage(item.name, item.imageUrl);
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
                              child: (resolvedImg != null && resolvedImg.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: resolvedImg,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const ShimmerRect(
                                        width: 40,
                                        height: 40,
                                        borderRadius: 8,
                                      ),
                                      errorWidget: (_, __, ___) => Icon(
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
                                if (item.selectedOptions.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '• ${item.selectedOptions.join(', ')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: colors.brandPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Catatan: ${item.notes!}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: colors.statusWarning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  '@ ${CurrencyFormatter.format(item.price)}',
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
                                CurrencyFormatter.format(item.price * item.qty),
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
                  });
                })(),
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
                  CurrencyFormatter.format(order.totalAmount),
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HallmarkTypography.bodySmall(colors.textPrimary).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSlideBar(HallmarkColorScheme colors, List<OrderItem> allOrders) {
    final int menungguCount = allOrders.where((o) => _isOrderMenunggu(o.status)).length;
    final int diprosesCount = allOrders.where((o) => _isOrderDiproses(o.status)).length;
    final int selesaiCount = allOrders.where((o) => _isOrderCompleted(o.status)).length;
    final int dibatalkanCount = allOrders.where((o) => _isOrderCancelled(o.status)).length;
    final int totalCount = allOrders.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border(
          bottom: BorderSide(color: colors.borderTactile, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(
              colors: colors,
              label: 'Menunggu',
              count: menungguCount,
              isSelected: _selectedFilter == StudentOrderFilter.menunggu,
              icon: Icons.hourglass_empty_rounded,
              onTap: () => setState(() => _selectedFilter = StudentOrderFilter.menunggu),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              colors: colors,
              label: 'Diproses',
              count: diprosesCount,
              isSelected: _selectedFilter == StudentOrderFilter.diproses,
              icon: Icons.soup_kitchen_rounded,
              onTap: () => setState(() => _selectedFilter = StudentOrderFilter.diproses),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              colors: colors,
              label: 'Selesai',
              count: selesaiCount,
              isSelected: _selectedFilter == StudentOrderFilter.selesai,
              icon: Icons.check_circle_outline_rounded,
              onTap: () => setState(() => _selectedFilter = StudentOrderFilter.selesai),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              colors: colors,
              label: 'Dibatalkan',
              count: dibatalkanCount,
              isSelected: _selectedFilter == StudentOrderFilter.dibatalkan,
              icon: Icons.cancel_outlined,
              onTap: () => setState(() => _selectedFilter = StudentOrderFilter.dibatalkan),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              colors: colors,
              label: 'Semua',
              count: totalCount,
              isSelected: _selectedFilter == StudentOrderFilter.semua,
              icon: Icons.list_alt_rounded,
              onTap: () => setState(() => _selectedFilter = StudentOrderFilter.semua),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required HallmarkColorScheme colors,
    required String label,
    required int count,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.brandPrimary : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? colors.brandPrimary : colors.borderTactile,
                width: isSelected ? 1.0 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.brandPrimary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : colors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(HallmarkColorScheme colors, String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.brandPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: colors.borderTactile,
              thickness: 0.5,
            ),
          ),
        ],
      ),
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
          'Pesanan',
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
        child: activeOrdersAsync.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data: (allOrders) {
            final filteredOrders = _filterOrders(allOrders);

            // Group and flatten orders by date
            final List<dynamic> listItems = [];
            DateTime? lastDate;
            for (final order in filteredOrders) {
              final DateTime createdAt = order.createdAt?.toLocal() ?? DateTime.now();
              if (lastDate == null ||
                  lastDate.year != createdAt.year ||
                  lastDate.month != createdAt.month ||
                  lastDate.day != createdAt.day) {
                final String dateHeaderStr = AppDateFormatter.formatDayFullDate(createdAt);
                listItems.add(dateHeaderStr);
                lastDate = createdAt;
              }
              listItems.add(order);
            }

            return Column(
              children: [
                // Slide Filter Bar
                _buildFilterSlideBar(colors, allOrders),

                // Date Filter Toolbar (Di Bawah Slide - Jumlah Pesanan di Kiri, Filter Tanggal di Kanan)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredOrders.length} Pesanan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      DateFilterPillButton(
                        activeFilter: _dateFilter,
                        onFilterChanged: (param) {
                          setState(() {
                            _dateFilter = param;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Order List or Empty State
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: filteredOrders.isEmpty
                          ? _buildEmptyStateForFilter(colors, _selectedFilter)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              itemCount: listItems.length,
                              itemBuilder: (context, index) {
                                final item = listItems[index];
                                if (item is String) {
                                  return _buildDateHeader(colors, item);
                                }

                                final order = item as OrderItem;
                                return KeyedSubtree(
                                  key: ValueKey<String>('student_order_${order.id}'),
                                  child: _buildActiveOrderCard(colors, order),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            children: [
              Container(
                height: 52,
                color: colors.surfaceBase,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: const [
                    SkeletonBox(width: 80, height: 32, borderRadius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 80, height: 32, borderRadius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 90, height: 32, borderRadius: 20),
                  ],
                ),
              ),
              Expanded(
                child: Shimmer(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
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
              ),
            ],
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
                    'Gagal memuat pesanan',
                    textAlign: TextAlign.center,
                    style: HallmarkTypography.bodySmall(colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateForFilter(HallmarkColorScheme colors, StudentOrderFilter filter) {
    IconData icon;
    String title;
    String message;

    switch (filter) {
      case StudentOrderFilter.menunggu:
        icon = CupertinoIcons.hourglass;
        title = 'Belum Ada Pesanan Menunggu';
        message = 'Pesanan yang baru dibuat dan menunggu konfirmasi pedagang kantin akan muncul di sini.';
      case StudentOrderFilter.diproses:
        icon = CupertinoIcons.flame;
        title = 'Belum Ada Pesanan Diproses';
        message = 'Pesanan yang telah diterima dan sedang dimasak / disiapkan akan muncul di sini.';
      case StudentOrderFilter.selesai:
        icon = CupertinoIcons.checkmark_seal;
        title = 'Belum Ada Pesanan Selesai';
        message = 'Pesanan yang telah selesai disiapkan dan diambil/diantar akan muncul di sini.';
      case StudentOrderFilter.dibatalkan:
        icon = CupertinoIcons.xmark_seal;
        title = 'Tidak Ada Pesanan Dibatalkan';
        message = 'Semua pesanan Anda berjalan lancar tanpa riwayat pembatalan.';
      case StudentOrderFilter.semua:
        icon = CupertinoIcons.square_list;
        title = 'Belum Ada Pesanan';
        message = 'Mulai pesan makanan lezat dari berbagai stan kantin sekarang!';
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 240,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colors.brandPrimary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: HallmarkTypography.titleL3(colors.textPrimary).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HallmarkTypography.bodyMain(colors.textMuted).copyWith(
                fontSize: 13,
              ),
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
    String statusLabel = order.status;

    switch (order.status) {
      case 'Baru':
        statusBgColor = colors.statusWarning.withValues(alpha: 0.12);
        statusTextColor = colors.statusWarning;
        statusIcon = Icons.hourglass_empty_rounded;
        statusLabel = 'Menunggu';
      case 'Sedang Dimasak':
        statusBgColor = colors.brandPrimary.withValues(alpha: 0.12);
        statusTextColor = colors.brandPrimary;
        statusIcon = Icons.soup_kitchen_rounded;
        statusLabel = 'Dimasak';
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
        statusLabel = 'Siap Diambil';
      case 'Siap Diantar':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusTextColor = colors.statusSuccess;
        statusIcon = Icons.delivery_dining;
        statusLabel = 'Diantar';
      case 'Selesai':
        statusBgColor = colors.statusSuccess.withValues(alpha: 0.12);
        statusTextColor = colors.statusSuccess;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Selesai';
      case 'Dibatalkan':
        statusBgColor = colors.statusError.withValues(alpha: 0.12);
        statusTextColor = colors.statusError;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Dibatalkan';
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
                        // Food Image Thumbnail of Most Expensive Item (Produk Termahal)
                        Builder(
                          builder: (context) {
                            final topItem = order.mostExpensiveItem;
                            final String? rawImg = topItem?.imageUrl;
                            final String? resolvedImg = topItem != null ? _resolveFoodImage(topItem.name, rawImg) : null;
                            final bool isDelivery = order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty;

                            final fallbackChild = Container(
                              color: colors.brandPrimary.withValues(alpha: 0.1),
                              child: Center(
                                child: Icon(
                                  isDelivery ? Icons.delivery_dining : Icons.restaurant_menu_rounded,
                                  color: colors.brandPrimary,
                                  size: 24,
                                ),
                              ),
                            );

                            return Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.borderTactile, width: 0.8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: (resolvedImg != null && resolvedImg.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: resolvedImg,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const ShimmerRect(
                                          width: 56,
                                          height: 56,
                                          borderRadius: 11,
                                        ),
                                        errorWidget: (_, __, ___) => fallbackChild,
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
                              Builder(
                                builder: (context) {
                                  final sortedItems = List<OrderSubItem>.from(order.items)
                                    ..sort((a, b) => (b.price * b.qty).compareTo(a.price * a.qty));
                                  final previewItems = sortedItems.take(2).toList();
                                  final remainingCount = sortedItems.length - previewItems.length;

                                  String summary;
                                  if (previewItems.isNotEmpty) {
                                    summary = previewItems.map((i) => '${i.qty}x ${i.name}').join(', ');
                                    if (remainingCount > 0) {
                                      summary += ', +$remainingCount lainnya...';
                                    }
                                  } else {
                                    summary = 'Pesanan Kantin';
                                  }

                                  return Text(
                                    summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: HallmarkTypography.titleSmall(colors.textPrimary).copyWith(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
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
                                    order.time.isNotEmpty ? order.time : '-',
                                    style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: HallmarkTypography.bodySmall(colors.textMuted),
                                  ),
                                  if (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty) ...[
                                    Icon(
                                      Icons.delivery_dining,
                                      size: 14,
                                      color: colors.brandPrimary,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        'Diantar: ${order.deliveryLocation!}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: HallmarkTypography.bodySmall(colors.brandPrimary).copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 13,
                                      color: colors.textMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        'Ambil di Kantin',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(
                                          fontSize: 11.5,
                                        ),
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
                          CurrencyFormatter.format(order.totalAmount),
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
