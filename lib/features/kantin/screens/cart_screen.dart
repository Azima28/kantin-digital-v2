import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  // Modal dialog to add manual extra charges
  void _showAddExtraChargeDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text(
          AppStrings.labelAddExtraCharge,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: nameController,
                placeholder: 'Nama biaya (contoh: Nasi Tambah)',
                placeholderStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: priceController,
                placeholder: 'Nominal harga (Rp)',
                placeholderStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final String name = nameController.text.trim();
              final double? price = double.tryParse(priceController.text.trim());

              if (name.isNotEmpty && price != null && price > 0) {
                ref.read(cartProvider.notifier).addCustomCharge(name, price);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Real NFC Payment Bottom Sheet
  void _showNfcPaymentSheet(BuildContext context, double totalAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _NfcPaymentModal(totalAmount: totalAmount);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          AppStrings.titleCart,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: const Text(
                'Kosongkan',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.shopping_cart, size: 64, color: AppColors.textGray),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang Belanja Kosong',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih makanan atau minuman dari katalog kasir.',
                    style: TextStyle(color: AppColors.textGray, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Kembali Belanja',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      final isCustom = item.productId == null;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isCustom)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentOrangeLight,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3), width: 0.5),
                                          ),
                                          child: const Text(
                                            'Kustom',
                                            style: TextStyle(
                                              color: AppColors.accentOrange,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${CurrencyFormatter.format(item.price)} x ${item.quantity}',
                                    style: const TextStyle(
                                      color: AppColors.textGray,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Edit Quantity Controls
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.systemBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(cartProvider.notifier).decreaseQuantity(item.productId, item.name);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Icon(
                                            CupertinoIcons.minus,
                                            size: 14,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(cartProvider.notifier).increaseQuantity(item.productId, item.name);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Icon(
                                            CupertinoIcons.plus,
                                            size: 14,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Cart Summary Block & Bottom Tap Action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 0.5),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add Extra Manual Charge Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _showAddExtraChargeDialog(context, ref),
                            icon: const Icon(CupertinoIcons.add, size: 16, color: AppColors.primary),
                            label: const Text(
                              AppStrings.labelAddExtraCharge,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Total Price Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              AppStrings.labelTotal,
                              style: TextStyle(
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(cartState.totalAmount),
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Proceed to payment (NFC)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            onPressed: () => _showNfcPaymentSheet(context, cartState.totalAmount),
                            child: const Text(
                              AppStrings.buttonTapStudentCard,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NfcPaymentModal extends ConsumerStatefulWidget {
  final double totalAmount;
  const _NfcPaymentModal({required this.totalAmount});

  @override
  ConsumerState<_NfcPaymentModal> createState() => _NfcPaymentModalState();
}

class _NfcPaymentModalState extends ConsumerState<_NfcPaymentModal> {
  final TextEditingController _simUidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start NFC payment session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nfcPaymentProvider.notifier).startPaymentSession(widget.totalAmount);
    });
  }

  @override
  void dispose() {
    _simUidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(nfcPaymentProvider);
    final authState = ref.watch(authNotifierProvider);
    final cartState = ref.watch(cartProvider);
    final String operatorId = authState.profile?['id'] ?? '';

    // Auto-close modal on success after 2 seconds
    if (paymentState.status == NfcPaymentStatus.success) {
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          ref.read(nfcPaymentProvider.notifier).resetState();
          Navigator.pop(context);
        }
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // iOS Grab Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),

          // Render layout based on NFC Payment Status
          if (paymentState.status == NfcPaymentStatus.scanning) ...[
            const Text(
              'Total Pembayaran',
              style: TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.format(widget.totalAmount),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 32),
            
            // Scanning Indicator
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.antenna_radiowaves_left_right,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.nfcReadyToScan,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.nfcTapInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGray,
              ),
            ),

            // Warning if NFC hardware is missing
            if (paymentState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentOrangeLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Text(
                  paymentState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Mode Simulasi untuk Testing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.systemBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(CupertinoIcons.device_phone_portrait, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        '🛠️ SIMULASI TAP KARTU SISWA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _simUidController,
                          placeholder: 'Masukkan RFID UID (Contoh: RFID123)',
                          placeholderStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight, width: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final String uid = _simUidController.text.trim();
                          if (uid.isNotEmpty) {
                            ref.read(nfcPaymentProvider.notifier).simulateTagTap(uid, widget.totalAmount);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tap',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (paymentState.status == NfcPaymentStatus.verifyingStudent) ...[
            const SizedBox(height: 40),
            const CupertinoActivityIndicator(radius: 16, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Sedang Memverifikasi Kartu...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 40),
          ] else if (paymentState.status == NfcPaymentStatus.confirmingPayment) ...[
            // Screen 4: Fase B - Konfirmasi Bayar (Saldo Cukup)
            const Text(
              'Konfirmasi Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.systemBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight, width: 0.5),
              ),
              child: Column(
                children: [
                  _buildDataRow(AppStrings.labelStudentName, paymentState.studentName ?? '-'),
                  const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
                  _buildDataRow(AppStrings.labelStudentClass, paymentState.studentClass ?? '-'),
                  const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
                  _buildDataRow(
                    'Saldo Kartu',
                    CurrencyFormatter.format(paymentState.studentBalance),
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Recipient Totals Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Belanja', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                      Text(CurrencyFormatter.format(widget.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sisa Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      Text(
                        CurrencyFormatter.format(paymentState.studentBalance - widget.totalAmount),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Confirm Pay Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  ref.read(nfcPaymentProvider.notifier).confirmPurchase(
                    operatorId: operatorId,
                    items: cartState.items,
                    totalAmount: widget.totalAmount,
                  );
                },
                child: const Text(
                  'KONFIRMASI BAYAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ] else if (paymentState.status == NfcPaymentStatus.insufficientBalance) ...[
            // Screen 4: Fase C - Transaksi Ditolak (Saldo Kurang)
            const Icon(CupertinoIcons.clear_circled_solid, size: 54, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Transaksi Ditolak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
            const Text(
              'Saldo Kartu Siswa Tidak Mencukupi',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.systemBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight, width: 0.5),
              ),
              child: Column(
                children: [
                  _buildDataRow(AppStrings.labelStudentName, paymentState.studentName ?? '-'),
                  const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
                  _buildDataRow(AppStrings.labelStudentClass, paymentState.studentClass ?? '-'),
                  const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
                  _buildDataRow(
                    'Saldo Tersedia',
                    CurrencyFormatter.format(paymentState.studentBalance),
                  ),
                  const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
                  _buildDataRow(
                    'Wajib Bayar',
                    CurrencyFormatter.format(widget.totalAmount),
                  ),
                  const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
                  _buildDataRow(
                    'Kurang',
                    '- ${CurrencyFormatter.format(widget.totalAmount - paymentState.studentBalance)}',
                    valueColor: AppColors.error,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Disabled confirmation button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textGray.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: null, // Disabled
                child: const Text(
                  'SALDO TIDAK CUKUP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ] else if (paymentState.status == NfcPaymentStatus.processingPurchase) ...[
            const SizedBox(height: 40),
            const CupertinoActivityIndicator(radius: 16, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Sedang Memotong Saldo...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 40),
          ] else if (paymentState.status == NfcPaymentStatus.success) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.checkmark_alt, size: 64, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jajan Berhasil!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Saldo berhasil dipotong, transaksi telah dicatat.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 40),
          ] else if (paymentState.status == NfcPaymentStatus.error) ...[
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 54, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Transaksi Gagal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Text(
                paymentState.errorMessage ?? 'Terjadi kesalahan tidak dikenal.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Retry / Reset Scan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  ref.read(nfcPaymentProvider.notifier).startPaymentSession(widget.totalAmount);
                },
                child: const Text(
                  'KEMBALI SCAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),

          // Cancel Action button
          if (paymentState.status != NfcPaymentStatus.success &&
              paymentState.status != NfcPaymentStatus.processingPurchase)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref.read(nfcPaymentProvider.notifier).resetState();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget helper for confirming page rows
  Widget _buildDataRow(String label, String value, {Color valueColor = AppColors.textDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGray,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
