import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/widgets/cart_item_tile.dart';
import 'package:kantin_digital/features/kantin/widgets/cart_summary_bar.dart';
import 'package:kantin_digital/features/kantin/widgets/nfc_payment_modal.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  // Modal dialog to add manual extra charges
  void _showAddExtraChargeDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(
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
                placeholderStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                style: TextStyle(fontSize: 14, color: context.textPrimary),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.borderLight, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: priceController,
                placeholder: 'Nominal harga (Rp)',
                placeholderStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 14, color: context.textPrimary),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.borderLight, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final String name = nameController.text.trim();
              final int? price = int.tryParse(priceController.text.trim());

              if (name.isNotEmpty && price != null && price > 0) {
                ref.read(cartProvider.notifier).addCustomCharge(name, price);
                Navigator.pop(ctx);
              }
            },
            child: const Text(AppStrings.buttonSave),
          ),
        ],
      ),
    );
  }

  // Real NFC Payment Bottom Sheet
  void _showNfcPaymentSheet(BuildContext context, int totalAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (BuildContext ctx) {
        return NfcPaymentModal(totalAmount: totalAmount);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppStrings.titleCart,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: Text(
                'Kosongkan',
                style: TextStyle(
                  color: Nebula.rose,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: cartState.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.shopping_cart, size: 64, color: context.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Keranjang Belanja Kosong',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${AppStrings.buttonSelect} makanan atau minuman dari katalog kasir.',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => context.pop(),
                        child: Text(
                          'Kembali Belanja',
                          style: TextStyle(color: context.cardBg, fontWeight: FontWeight.bold),
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
                          return CartItemTile(item: item);
                        },
                      ),
                    ),

                    // Cart Summary Block & Bottom Tap Action
                    CartSummaryBar(
                      onAddExtraCharge: () => _showAddExtraChargeDialog(context, ref),
                      onCheckout: () => _showNfcPaymentSheet(context, cartState.totalAmount),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}