import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';

/// Modal Bottom Sheet to display complete product details, image, customizable options, and quantity.
class ProductDetailBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  final String stanId;
  final String stanName;
  final int deliveryFee;
  final String description;

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
    required this.stanId,
    required this.stanName,
    this.deliveryFee = 2000,
    required this.description,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required String stanId,
    required String stanName,
    int deliveryFee = 2000,
    required String description,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailBottomSheet(
        product: product,
        stanId: stanId,
        stanName: stanName,
        deliveryFee: deliveryFee,
        description: description,
      ),
    );
  }

  @override
  ConsumerState<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();
}

class _ProductDetailBottomSheetState
    extends ConsumerState<ProductDetailBottomSheet> {
  int _quantity = 1;
  final Set<String> _selectedOptions = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _calculatedUnitPrice {
    int price = widget.product.price;
    for (final opt in _selectedOptions) {
      final match = RegExp(r'\(\+?Rp\s*([\d\.]+)\)').firstMatch(opt);
      if (match != null) {
        final clean = match.group(1)!.replaceAll('.', '');
        final addon = int.tryParse(clean) ?? 0;
        price += addon;
      }
    }
    return price;
  }

  int get _calculatedTotalPrice => _calculatedUnitPrice * _quantity;

  Future<void> _addToCart() async {
    final product = widget.product;
    final operatorId =
        product.operatorId.isNotEmpty ? product.operatorId : widget.stanId;
    final canteenName = widget.stanName;

    final cartNotifier = ref.read(studentCartProvider.notifier);
    final hasConflict = cartNotifier.checkCanteenConflict(operatorId);

    final List<String> optionsList = _selectedOptions.toList();
    if (_notesController.text.trim().isNotEmpty) {
      optionsList.add('Catatan: ${_notesController.text.trim()}');
    }

    if (hasConflict) {
      final currentCanteenName =
          ref.read(studentCartProvider).canteenName ?? 'Stan Lain';
      final confirmed = await showAppConfirmationDialog(
        context,
        title: 'Mau ganti stan?',
        message:
            'Keranjangmu saat ini berisi pesanan dari $currentCanteenName. Jika memilih menu dari $canteenName, pesanan sebelumnya akan diganti.',
        confirmLabel: 'Ganti & Tambah',
        confirmColor: Nebula.teal,
        icon: Icons.storefront_rounded,
      );

      if (confirmed && mounted) {
        cartNotifier.addProductWithCanteen(
          canteenId: operatorId,
          canteenName: canteenName,
          deliveryFee: widget.deliveryFee,
          productId: product.id,
          name: product.name,
          price: _calculatedUnitPrice,
          imageUrl: product.imageUrl,
          quantity: _quantity,
          selectedOptions: optionsList,
        );
        Navigator.pop(context);
        _showSuccessSnackbar(product.name);
      }
    } else {
      cartNotifier.addProductWithCanteen(
        canteenId: operatorId,
        canteenName: canteenName,
        deliveryFee: widget.deliveryFee,
        productId: product.id,
        name: product.name,
        price: _calculatedUnitPrice,
        imageUrl: product.imageUrl,
        quantity: _quantity,
        selectedOptions: optionsList,
      );
      Navigator.pop(context);
      _showSuccessSnackbar(product.name);
    }
  }

  void _showSuccessSnackbar(String productName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_quantity x $productName ditambahkan ke keranjang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = context.isDark;
    final bool isAvailable = product.isAvailable;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Grab Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerCol,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Large Image Banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      color: context.surfaceBg,
                      child: product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ShimmerRect(
                                width: double.infinity,
                                height: 200,
                                borderRadius: 18,
                              ),
                              errorWidget: (_, __, ___) =>
                                  _buildFallbackImage(product.category),
                            )
                          : _buildFallbackImage(product.category),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Canteen Name & Category Badge Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 14, color: Nebula.teal),
                          const SizedBox(width: 4),
                          Text(
                            widget.stanName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Nebula.teal,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Product Title
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Rating, Total Sold & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        CurrencyFormatter.format(_calculatedUnitPrice),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Row(
                        children: [
                          if (product.hasRating) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (product.totalSold > 0)
                            Text(
                              '${product.totalSold} Terjual',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              'Menu Baru',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: context.dividerCol, height: 1),
                  const SizedBox(height: 12),

                  // Description Text
                  Text(
                    'DESKRIPSI MENU',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: context.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customizable Options (if any)
                  if (product.customizableOptions.isNotEmpty) ...[
                    Divider(color: context.dividerCol, height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'PILIHAN VARIAN / TAMBAHAN',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.customizableOptions.map((opt) {
                        final isSelected = _selectedOptions.contains(opt);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedOptions.remove(opt);
                              } else {
                                _selectedOptions.add(opt);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : context.surfaceBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : context.dividerCol,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  opt,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes Text Field
                  Divider(color: context.dividerCol, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'CATATAN KHUSUS (OPSIONAL)',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: context.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Sambal dipisah ya, jangan pakai seledri...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 12.5, color: context.textSecondary),
                      filled: true,
                      fillColor: context.surfaceBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: context.dividerCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: context.dividerCol, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF10B981), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 3. Bottom Action Bar (Quantity Stepper + Add to Cart Button)
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(
                  top: BorderSide(color: context.dividerCol, width: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Stepper
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.dividerCol, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: isAvailable && _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            CupertinoIcons.minus,
                            size: 16,
                            color: _quantity > 1
                                ? context.textPrimary
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_quantity',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: isAvailable
                            ? () => setState(() => _quantity++)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 16,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // "+ Tambah Pesanan" Big Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable
                          ? const Color(0xFF10B981)
                          : Colors.grey.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isAvailable ? _addToCart : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          isAvailable
                              ? '+ Tambah • ${CurrencyFormatter.format(_calculatedTotalPrice)}'
                              : 'Stok Habis',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(String category) {
    return Container(
      color: Nebula.teal.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          category == 'minuman'
              ? Icons.local_drink_rounded
              : Icons.restaurant_rounded,
          color: Nebula.teal,
          size: 48,
        ),
      ),
    );
  }
}
