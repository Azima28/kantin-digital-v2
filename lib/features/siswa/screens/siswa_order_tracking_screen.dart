import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/order_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const SiswaOrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<SiswaOrderTrackingScreen> createState() =>
      _SiswaOrderTrackingScreenState();
}

class _SiswaOrderTrackingScreenState
    extends ConsumerState<SiswaOrderTrackingScreen> {
  Timer? _refreshTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    // Poll setiap 10 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
            'Saldo akan dikembalikan ke akun kamu. Pesanan yang sudah diterima tidak bisa dibatalkan.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final authState = ref.read(authNotifierProvider);
      final studentId = authState.profile?['id'] as String?;
      if (studentId == null) throw Exception('Not authenticated');

      final client = ref.read(supabaseClientProvider);
      await client.rpc('cancel_order', params: {
        'p_order_id': widget.orderId,
        'p_student_id': studentId,
      });

      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(siswaActiveOrdersProvider);
      ref.invalidate(siswaStudentProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pesanan dibatalkan. Saldo dikembalikan.'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = 'Gagal membatalkan pesanan';
      if (e.toString().contains('cannot_cancel_status')) {
        msg = 'Pesanan sudah diproses, tidak bisa dibatalkan';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

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
          'Status Pesanan',
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.teal),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(CupertinoIcons.refresh, color: AppColors.teal),
            onPressed: () =>
                ref.invalidate(orderDetailProvider(widget.orderId)),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text('Pesanan tidak ditemukan',
                  style: GoogleFonts.inter(color: AppColors.error)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(orderDetailProvider(widget.orderId)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Text('Pesanan tidak ditemukan',
                  style: GoogleFonts.inter(color: AppColors.mutedGray)),
            );
          }
          return _OrderDetail(
            order: order,
            onCancel: order.canCancel ? () => _cancelOrder(order) : null,
            isCancelling: _isCancelling,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _OrderDetail extends StatelessWidget {
  final Order order;
  final VoidCallback? onCancel;
  final bool isCancelling;
  const _OrderDetail(
      {required this.order, this.onCancel, required this.isCancelling});

  static const _steps = [
    ('Menunggu', CupertinoIcons.clock, 'Pesanan dikirim ke kantin'),
    ('Diterima', CupertinoIcons.checkmark_circle, 'Kantin menerima pesananmu'),
    ('Dimasak', CupertinoIcons.flame, 'Sedang diproses'),
    ('Siap', CupertinoIcons.bag_badge_plus, 'Siap diambil / diantar'),
    ('Selesai', CupertinoIcons.checkmark_seal_fill, 'Pesanan selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.isCancelled;
    final currentStep = isCancelled ? -1 : order.statusStep;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isCancelled
                    ? AppColors.errorLight
                    : order.isCompleted
                        ? AppColors.successGreenLight
                        : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCancelled
                        ? CupertinoIcons.xmark_circle_fill
                        : order.isCompleted
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.clock_fill,
                    color: isCancelled
                        ? AppColors.error
                        : order.isCompleted
                            ? AppColors.successGreen
                            : AppColors.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCancelled
                          ? AppColors.error
                          : order.isCompleted
                              ? AppColors.successGreen
                              : AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Step progress (hanya jika tidak cancelled)
          if (!isCancelled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: List.generate(_steps.length, (i) {
                  final isDone = i <= currentStep;
                  final isCurrent = i == currentStep;
                  final (label, icon, desc) = _steps[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon col
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? (isCurrent
                                      ? AppColors.teal
                                      : AppColors.primaryLight)
                                  : AppColors.surfaceContainerLow,
                              border: isCurrent
                                  ? Border.all(
                                      color: AppColors.teal, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isDone
                                  ? (isCurrent
                                      ? Colors.white
                                      : AppColors.teal)
                                  : AppColors.gray400,
                            ),
                          ),
                          if (i < _steps.length - 1)
                            Container(
                              width: 2,
                              height: 32,
                              color: i < currentStep
                                  ? AppColors.teal
                                  : AppColors.grayLight,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Label
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isDone
                                      ? AppColors.nearBlack
                                      : AppColors.gray400,
                                ),
                              ),
                              if (isCurrent)
                                Text(
                                  desc,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.mutedGray),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

          const SizedBox(height: 16),

          // Order details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Pesanan',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _InfoRow(
                    icon: CupertinoIcons.bag,
                    label: 'Kantin',
                    value: order.canteenName ?? '-'),
                _InfoRow(
                    icon: CupertinoIcons.clock,
                    label: 'Waktu',
                    value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(order.createdAt.toLocal())),
                _InfoRow(
                  icon: order.isDelivery
                      ? CupertinoIcons.location_fill
                      : CupertinoIcons.bag_fill,
                  label: 'Pengiriman',
                  value: order.isDelivery
                      ? 'Diantar ke ${order.deliveryLocation ?? "-"}'
                      : 'Ambil sendiri',
                ),
                if (order.isDelivery && order.studentPhone != null)
                  _InfoRow(
                      icon: CupertinoIcons.phone,
                      label: 'Kontak',
                      value: order.studentPhone!),
                const Divider(height: 20),
                // Items
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text('${item.quantity}x',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.mutedGray,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(item.productName,
                                  style: GoogleFonts.inter(fontSize: 13))),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(item.lineTotal)}',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.mutedGray)),
                    Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(order.subtotal)}',
                        style: GoogleFonts.inter(fontSize: 13)),
                  ],
                ),
                if (order.isDelivery && order.deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ongkir 🛵',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.mutedGray)),
                      Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(order.deliveryFee)}',
                          style: GoogleFonts.inter(fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teal),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cancel button
          if (onCancel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isCancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isCancelling
                  ? const CupertinoActivityIndicator()
                  : Text('Batalkan Pesanan',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mutedGray),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.mutedGray)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
