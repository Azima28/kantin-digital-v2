import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/theme/nebula_tokens.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_payment_animation_overlay.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/features/public/widgets/product_detail_bottom_sheet.dart';

class SiswaCartScreen extends ConsumerStatefulWidget {
  const SiswaCartScreen({super.key});

  @override
  ConsumerState<SiswaCartScreen> createState() => _SiswaCartScreenState();
}

class _SiswaCartScreenState extends ConsumerState<SiswaCartScreen> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationController.text = ref.read(studentCartProvider).deliveryLocation;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _openEditBottomSheet(StudentCartItem item) async {
    // 1. Cari data produk lengkap dari cache publicMenuProvider
    final menuItems = ref.read(publicMenuProvider(null)).valueOrNull ?? [];
    Product? foundProduct;
    for (final m in menuItems) {
      if (m.product.id == item.productId) {
        foundProduct = m.product;
        break;
      }
    }

    // 2. Jika tidak ada di cache, coba fetch dari API
    if (foundProduct == null) {
      try {
        final apiClient = ref.read(apiClientProvider);
        final res = await apiClient.get('/products/${item.productId}');
        if (res.success && res.data != null) {
          foundProduct = Product.fromJson(res.data as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    // 3. Fallback jika offline
    foundProduct ??= Product(
      id: item.productId,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      operatorId: ref.read(studentCartProvider).canteenId ?? '',
      customizableOptions: item.selectedOptions,
      isAvailable: true,
      category: 'makanan',
    );

    if (!mounted) return;

    final cart = ref.read(studentCartProvider);
    ProductDetailBottomSheet.show(
      context,
      product: foundProduct,
      stanId: cart.canteenId ?? '',
      stanName: cart.canteenName ?? 'Stan Kantin',
      deliveryFee: cart.deliveryFee,
      description: '${foundProduct.category} · ${cart.canteenName ?? "Stan Kantin"}',
      initialSelectedOptions: item.selectedOptions,
      initialNotes: item.notes,
      initialQuantity: item.quantity,
      isEditing: true,
      onSaveEditedItem: (newOptions, newNotes, newUnitPrice, newQuantity) {
        ref.read(studentCartProvider.notifier).updateItem(
              oldItem: item,
              newSelectedOptions: newOptions,
              newNotes: newNotes,
              newPrice: newUnitPrice,
              newQuantity: newQuantity,
            );
      },
    );
  }

  Future<void> _handleCheckout(int totalAmount) async {
    final student = ref.read(siswaStudentProvider).value;
    if (student != null) {
      // 1. Validasi saldo akun mencukupi
      if (student.balance < totalAmount) {
        final goToTopup = await showAppConfirmationDialog(
          context,
          title: 'Saldo Tidak Mencukupi',
          message:
              'Saldo akun Anda saat ini (${CurrencyFormatter.format(student.balance)}) tidak mencukupi untuk melakukan pembayaran sebesar ${CurrencyFormatter.format(totalAmount)}.\n\nApakah Anda ingin mengisi saldo (top up) sekarang?',
          confirmLabel: 'Top Up Saldo',
          cancelLabel: 'Tutup',
          icon: Icons.account_balance_wallet_outlined,
          confirmColor: Nebula.teal,
        );
        if (goToTopup && mounted) {
          context.push('/student/topup');
        }
        return;
      }

      // 2. Validasi batas saku harian
      if (student.hasDailyLimit) {
        final remainingLimit = student.remainingDailyLimit;
        if (totalAmount > remainingLimit) {
          await showAppAlertDialog(
            context,
            title: 'Melebihi Batas Saku Harian',
            message:
                'Total pesanan belanja Anda (${CurrencyFormatter.format(totalAmount)}) melebihi batas saku harian yang telah diatur oleh orang tua.\n\n'
                '• Batas Saku Harian: ${CurrencyFormatter.format(student.dailyLimit!)}\n'
                '• Terpakai Hari Ini: ${CurrencyFormatter.format(student.todaySpent)}\n'
                '• Sisa Batas Hari Ini: ${CurrencyFormatter.format(remainingLimit)}',
            buttonLabel: 'Mengerti',
            icon: Icons.warning_amber_rounded,
            isDestructive: true,
          );
          return;
        }
      }
    }

    _showPinDialog(totalAmount);
  }

  void _showPinDialog(int totalAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StudentPinPaymentModal(
          totalAmount: totalAmount,
          onSuccess: () {
            ref.read(studentCartProvider.notifier).clearCart();
            ref.invalidate(siswaStudentProvider);
            ref.invalidate(siswaTransactionsProvider);
            ref.invalidate(siswaActiveOrdersProvider);
            if (mounted) {
              Navigator.pop(context); // Close cart screen
              context.go('/student'); // Go back to student home
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(studentCartProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: Nebula.teal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          children: [
            Text(
              'Keranjang Belanja',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Nebula.teal,
              ),
            ),
            if (cart.canteenName != null)
              Text(
                'Stan: ${cart.canteenName}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: cart.items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // ─── SCROLLABLE CONTENT: PRODUCT LIST & RINGKASAN PEMBAYARAN ───
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. UNIFIED SINGLE CARD CONTAINER UNTUK SEMUA ITEM
                            Container(
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.dividerCol,
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: context.isDark ? 0.25 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cart.items.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  thickness: 1.0,
                                  color: context.dividerCol,
                                  indent: 14,
                                  endIndent: 14,
                                ),
                                itemBuilder: (context, index) {
                                  final item = cart.items[index];
                                  return _SiswaCartProductTile(
                                    item: item,
                                    onEditOptions: () => _openEditBottomSheet(item),
                                    onDecrease: () {
                                      ref.read(studentCartProvider.notifier).decreaseQuantity(
                                            item.productId,
                                            selectedOptions: item.selectedOptions,
                                            notes: item.notes,
                                          );
                                    },
                                    onIncrease: () {
                                      final student = ref.read(siswaStudentProvider).value;
                                      if (student != null && student.hasDailyLimit) {
                                        final nextTotal = cart.totalAmount + item.price;
                                        if (nextTotal > student.remainingDailyLimit) {
                                          showAppAlertDialog(
                                            context,
                                            title: 'Batas Saku Terlampaui',
                                            message:
                                                'Menambah porsi item ini akan membuat total belanja (${CurrencyFormatter.format(nextTotal)}) melebihi sisa batas saku harian Anda (${CurrencyFormatter.format(student.remainingDailyLimit)}).',
                                            buttonLabel: 'Mengerti',
                                            icon: Icons.warning_amber_rounded,
                                            isDestructive: true,
                                          );
                                          return;
                                        }
                                      }
                                      ref.read(studentCartProvider.notifier).increaseQuantity(
                                            item.productId,
                                            selectedOptions: item.selectedOptions,
                                            notes: item.notes,
                                          );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. RINGKASAN PEMBAYARAN (Ikut scroll di bawah item produk)
                            _buildRingkasanPembayaranCard(cart),
                          ],
                        ),
                      ),
                    ),

                    // ─── STICKY BOTTOM ACTION BAR (Pickup/Antar + Tombol Bayar Tetap Nempel) ───
                    _buildStickyBottomBar(cart),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return NebulaEmptyState(
      icon: const Icon(CupertinoIcons.cart),
      title: 'Keranjang Belanja Kosong',
      description: 'Pilih makanan lezat dari Menu Kantin untuk memesan.',
      actionLabel: 'Kembali Belanja',
      onAction: () => context.pop(),
      iconColor: Nebula.teal,
    );
  }

  /// Ringkasan Pembayaran yang ikut scroll bersama item produk di bagian bawah
  Widget _buildRingkasanPembayaranCard(StudentCartState cart) {
    final bool isDelivery = cart.deliveryMethod == 'delivery';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerCol, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.20 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.doc_plaintext, size: 15, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Ringkasan Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtotal Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal Menu (${cart.totalItems} item)',
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
              Text(
                CurrencyFormatter.format(cart.itemsTotal),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Metode Pesanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metode Pesanan',
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
              Text(
                isDelivery ? 'Delivery (Diantar)' : 'Pickup (Ambil Sendiri)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Biaya Ongkir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Ongkir / Antar',
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
              Text(
                isDelivery ? '+${CurrencyFormatter.format(cart.deliveryFee)}' : 'Gratis (Rp 0)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDelivery ? const Color(0xFF10B981) : context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Biaya Layanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Layanan Aplikasi',
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
              Text(
                'Gratis',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Divider(height: 1, thickness: 1.0, color: context.dividerCol),
          const SizedBox(height: 10),

          // Total Pembayaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    'Termasuk pajak & biaya lainnya',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(cart.totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),

          // Info Saldo & Batas Saku Siswa
          Consumer(
            builder: (context, ref, child) {
              final student = ref.watch(siswaStudentProvider).value;
              if (student == null) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1.0, color: context.dividerCol),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo Akun Anda',
                        style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
                      ),
                      Text(
                        CurrencyFormatter.format(student.balance),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: student.balance < cart.totalAmount ? Nebula.rose : Nebula.teal,
                        ),
                      ),
                    ],
                  ),
                  if (student.hasDailyLimit) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sisa Batas Saku Hari Ini',
                          style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.format(student.remainingDailyLimit),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: cart.totalAmount > student.remainingDailyLimit ? Nebula.rose : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (student.balance < cart.totalAmount) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Nebula.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Nebula.rose.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Nebula.rose, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo tidak mencukupi untuk tagihan ini (kurang ${CurrencyFormatter.format(cart.totalAmount - student.balance)}).',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Nebula.rose,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (student.hasDailyLimit && cart.totalAmount > student.remainingDailyLimit) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tagihan melebihi sisa batas saku harian Anda (lebih ${CurrencyFormatter.format(cart.totalAmount - student.remainingDailyLimit)}).',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom Bar: Pilihan Pickup/Antar & Tombol Pesan & Bayar Sekarang
  Widget _buildStickyBottomBar(StudentCartState cart) {
    final bool isDelivery = cart.deliveryMethod == 'delivery';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: context.dividerCol, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metode Pengiriman Selector (Pickup / Antar)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(studentCartProvider.notifier).setDeliveryMethod('pickup');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !isDelivery ? const Color(0xFF10B981) : context.surfaceBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isDelivery ? const Color(0xFF10B981) : context.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Pickup',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: !isDelivery ? Colors.white : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(studentCartProvider.notifier).setDeliveryMethod('delivery');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isDelivery ? const Color(0xFF10B981) : context.surfaceBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDelivery ? const Color(0xFF10B981) : context.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Antar (+Rp ${cart.deliveryFee})',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDelivery ? Colors.white : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Input Lokasi Pengantaran (Jika Delivery)
          if (isDelivery) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              onChanged: (val) {
                ref.read(studentCartProvider.notifier).setDeliveryLocation(val);
              },
              style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tulis Lokasi (Contoh: Kelas XII RPL 1 / Meja 4)',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                prefixIcon: const Icon(CupertinoIcons.location_solid,
                    size: 16, color: Color(0xFF10B981)),
                filled: true,
                fillColor: context.surfaceBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 3. Tombol Pesan & Bayar Sekarang
          SizedBox(
            width: double.infinity,
            height: 48,
            child: PressScale(
              scale: 0.98,
              onTap: () => _handleCheckout(cart.totalAmount),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'PESAN & BAYAR SEKARANG',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Tile within the Unified Cart Container with Dropdown / Modal Option Trigger
class _SiswaCartProductTile extends StatelessWidget {
  final StudentCartItem item;
  final VoidCallback onEditOptions;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _SiswaCartProductTile({
    required this.item,
    required this.onEditOptions,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDetails = item.selectedOptions.isNotEmpty ||
        (item.notes != null && item.notes!.trim().isNotEmpty);
    final bool hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ShimmerRect(
                            width: 52,
                            height: 52,
                            borderRadius: 12,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            child: const Icon(CupertinoIcons.cube_box,
                                color: Color(0xFF10B981), size: 20),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(CupertinoIcons.cube_box,
                              color: Color(0xFF10B981), size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Name & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CurrencyFormatter.format(item.price),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Stepper buttons (- qty +)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: onDecrease,
                    icon: Icon(CupertinoIcons.minus_circle,
                        color: context.textSecondary, size: 22),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: onIncrease,
                    icon: const Icon(CupertinoIcons.plus_circle,
                        color: Color(0xFF10B981), size: 22),
                  ),
                ],
              ),
            ],
          ),

          // ─── CLICKABLE OPTION PILL / DROP WINDOW TRIGGER ───
          if (hasDetails) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onEditOptions();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.selectedOptions.isNotEmpty
                            ? 'Pilihan: ${item.selectedOptions.join(', ')}'
                            : 'Catatan: ${item.notes}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ubah',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PIN TRANSACTION MODAL ───
class StudentPinPaymentModal extends ConsumerStatefulWidget {
  final int totalAmount;
  final VoidCallback onSuccess;

  const StudentPinPaymentModal({
    super.key,
    required this.totalAmount,
    required this.onSuccess,
  });

  @override
  ConsumerState<StudentPinPaymentModal> createState() =>
      _StudentPinPaymentModalState();
}

class _StudentPinPaymentModalState
    extends ConsumerState<StudentPinPaymentModal> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String _statusText = 'Masukkan PIN Kartu Siswa Anda';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(String pin) async {
    final navigator = Navigator.of(context);
    final cartState = ref.read(studentCartProvider);
    final cartSnapshot = cartState.items.toList();
    final overlayState = Overlay.of(context);

    if (pin.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan PIN Kartu terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusText = 'Verifikasi PIN...';
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authNotifierProvider);
      final studentId = authState.profile?['id'];
      final studentName = authState.profile?['full_name'] ?? 'Siswa';

      if (studentId == null) {
        throw Exception('User tidak terautentikasi.');
      }

      // Verifikasi PIN ke endpoint /student/verify-pin
      final pinVerifyResponse = await apiClient.post(
        '/student/verify-pin',
        body: {'pin': pin.trim()},
      );

      if (!pinVerifyResponse.success) {
        throw Exception(pinVerifyResponse.message ?? 'PIN yang Anda masukkan salah.');
      }

      setState(() {
        _statusText = 'Memproses Pembayaran...';
      });

      final String loc = cartState.deliveryLocation.trim();
      final String deliveryLocation = cartState.deliveryMethod == 'delivery'
          ? (loc.isNotEmpty ? 'Diantar: $loc' : 'Diantar')
          : 'Ambil Sendiri (Pickup)';

      final List<Map<String, dynamic>> orderItems = cartSnapshot.map((item) {
        return {
          'product_id': item.productId,
          'product_name': item.name,
          'quantity': item.quantity,
          'price': item.price,
          'selected_options': item.selectedOptions,
          'notes': item.notes ?? '',
        };
      }).toList();

      final response = await apiClient.post(
        '/orders',
        body: {
          'student_id': studentId,
          'student_name': studentName,
          'operator_id': cartState.canteenId,
          'delivery_location': deliveryLocation,
          'total_amount': widget.totalAmount,
          'items': orderItems,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal membuat pesanan');
      }

      // Invalidate student providers
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(siswaActiveOrdersProvider);

      if (mounted) {
        navigator.pop(); // Close bottom sheet

        // Show animation overlay
        showGeneralDialog(
          context: overlayState.context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.65),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return SiswaPaymentAnimationOverlay(
              totalAmount: widget.totalAmount,
              cartItems: cartSnapshot,
              onComplete: widget.onSuccess,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
        setState(() {
          _isLoading = false;
          _errorMessage = cleanMsg;
          _statusText = 'Gagal Memproses';
        });

        await showAppAlertDialog(
          context,
          title: 'Pembayaran Ditolak',
          message: cleanMsg,
          buttonLabel: 'Tutup',
          icon: Icons.error_outline_rounded,
          isDestructive: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: NebulaShadows.elevate3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Konfirmasi PIN Transaksi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                color: context.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Nebula.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Tagihan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(widget.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _errorMessage != null ? Nebula.rose : context.textSecondary,
              fontWeight: _errorMessage != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Nebula.rose,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PIN Transaksi:',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _pinController.text = '123456';
                          _errorMessage = null;
                        });
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.number_square, size: 12, color: Nebula.teal),
                      const SizedBox(width: 4),
                      Text(
                        'PIN Bawaan (123456)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Nebula.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            enabled: !_isLoading,
            style: GoogleFonts.inter(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
              color: Nebula.teal,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: GoogleFonts.inter(
                fontSize: 24,
                letterSpacing: 8,
                color: context.textSecondary.withValues(alpha: 0.3),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  color: context.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              filled: true,
              fillColor: context.surfaceBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Nebula.teal, width: 2),
              ),
            ),
            onSubmitted: (value) => _processPayment(value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _processPayment(_pinController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      'KONFIRMASI BAYAR',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
