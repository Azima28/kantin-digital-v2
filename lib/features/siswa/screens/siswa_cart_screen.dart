import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/features/siswa/providers/cart_provider.dart';

class SiswaCartScreen extends ConsumerWidget {
  const SiswaCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Keranjang',
          style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.teal),
        ),
        actions: [
          if (!cartState.isEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, notifier),
              child: Text('Kosongkan',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.error)),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.cart,
                      size: 64, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang masih kosong',
                    style: GoogleFonts.inter(
                        fontSize: 16, color: AppColors.mutedGray),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.push(AppRouter.studentCanteens),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pilih Kantin'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              itemCount: cartState.canteenList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final canteen = cartState.canteenList[i];
                return _CanteenCartCard(entry: canteen);
              },
            ),
      bottomNavigationBar: cartState.isEmpty
          ? null
          : _CheckoutBar(grandTotal: cartState.grandTotal),
    );
  }

  void _confirmClearAll(BuildContext context, CartNotifier notifier) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content:
            const Text('Semua item dari semua kantin akan dihapus.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              notifier.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Kosongkan'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}

class _CanteenCartCard extends ConsumerWidget {
  final CartCanteenEntry entry;
  const _CanteenCartCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Container(
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
              color: AppColors.primaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.bag_fill,
                    color: AppColors.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.canteenName,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      notifier.clearCanteen(entry.operatorId),
                  child: Text('Hapus',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.error)),
                ),
              ],
            ),
          ),

          // Items
          ...entry.items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama & harga
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(item.unitPrice)} / item',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.mutedGray),
                          ),
                        ],
                      ),
                    ),
                    // Qty control
                    Row(
                      children: [
                        _QtyBtn(
                          icon: CupertinoIcons.minus,
                          onTap: () => notifier.decreaseItem(
                              entry.operatorId, item.productId),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        _QtyBtn(
                          icon: CupertinoIcons.add,
                          color: AppColors.teal,
                          iconColor: Colors.white,
                          onTap: () => notifier.addItem(
                            operatorId: entry.operatorId,
                            canteenName: entry.canteenName,
                            deliveryEnabled: entry.deliveryEnabled,
                            deliveryFee: entry.deliveryFee,
                            item: CartItemEntry(
                              productId: item.productId,
                              productName: item.productName,
                              unitPrice: item.unitPrice,
                              imageUrl: item.imageUrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(item.lineTotal)}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal),
                      ),
                    ),
                  ],
                ),
              )),

          // Subtotal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal ${entry.itemCount} item',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.mutedGray)),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(entry.subtotal)}',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  const _QtyBtn({
    required this.icon,
    required this.onTap,
    this.color = AppColors.primaryLight,
    this.iconColor = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final int grandTotal;
  const _CheckoutBar({required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.push(AppRouter.studentCheckout),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lanjut ke Checkout',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(
              '•  Rp ${NumberFormat('#,###', 'id_ID').format(grandTotal)}',
              style:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
