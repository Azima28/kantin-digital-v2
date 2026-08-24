import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/product.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';

int extractOptionAddonPrice(String optionText) {
  final regExp = RegExp(r'\(\+\s*(?:Rp\s*)?([0-9\.\,]+)\)', caseSensitive: false);
  final match = regExp.firstMatch(optionText);
  if (match != null) {
    final rawNum = match.group(1)?.replaceAll('.', '').replaceAll(',', '') ?? '0';
    return int.tryParse(rawNum) ?? 0;
  }
  return 0;
}

/// Modal Bottom Sheet for POS Cashier to customize product options, toppings, and notes
class PosProductOptionSheet extends ConsumerStatefulWidget {
  final Product product;

  const PosProductOptionSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PosProductOptionSheet(product: product),
    );
  }

  @override
  ConsumerState<PosProductOptionSheet> createState() => _PosProductOptionSheetState();
}

class _PosProductOptionSheetState extends ConsumerState<PosProductOptionSheet> {
  final Set<String> _selectedOptions = <String>{};
  final TextEditingController _notesController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _addonPricePerItem {
    int sum = 0;
    for (final opt in _selectedOptions) {
      sum += extractOptionAddonPrice(opt);
    }
    return sum;
  }

  int get _unitPrice => widget.product.price + _addonPricePerItem;
  int get _totalPrice => _unitPrice * _quantity;

  void _toggleOption(String option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        _selectedOptions.add(option);
      }
    });
  }

  void _handleAddToCart() {
    final notes = _notesController.text.trim();
    ref.read(cartProvider.notifier).addProduct(
      widget.product.id,
      widget.product.name,
      _unitPrice,
      basePrice: widget.product.price,
      selectedOptions: _selectedOptions.toList(),
      notes: notes.isNotEmpty ? notes : null,
      quantity: _quantity,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.product.name} x$_quantity berhasil ditambahkan ke keranjang',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Nebula.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.product.customizableOptions;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grab Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Section with Product Info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: 64,
                              height: 64,
                              color: context.surfaceBg,
                              child: const Icon(CupertinoIcons.photo, color: Nebula.teal, size: 24),
                            ),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            color: Nebula.teal.withValues(alpha: 0.1),
                            child: const Icon(CupertinoIcons.cart, color: Nebula.teal, size: 28),
                          ),
                  ),
                  const SizedBox(width: 14),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(widget.product.price),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Nebula.teal,
                              ),
                            ),
                            if (_addonPricePerItem > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Nebula.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${CurrencyFormatter.format(_addonPricePerItem)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Nebula.teal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                    color: context.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Options & Notes Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Options Heading
                    if (options.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18, color: Nebula.teal),
                          const SizedBox(width: 8),
                          Text(
                            'Pilihan Varian & Tambahan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih opsi yang dipesan siswa (bisa pilih lebih dari satu)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Options List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          final isSelected = _selectedOptions.contains(opt);
                          final addonPrice = extractOptionAddonPrice(opt);

                          return InkWell(
                            onTap: () => _toggleOption(opt),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Nebula.teal.withValues(alpha: 0.08)
                                    : context.surfaceBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Nebula.teal : context.dividerCol,
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Custom Checkbox
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Nebula.teal : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? Nebula.teal : context.textSecondary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Option Name
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Nebula.teal : context.textPrimary,
                                      ),
                                    ),
                                  ),

                                  // Price Tag (if extra cost)
                                  if (addonPrice > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Nebula.teal.withValues(alpha: 0.18)
                                            : context.cardBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? Nebula.teal : context.borderLight,
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Text(
                                        '+${CurrencyFormatter.format(addonPrice)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? Nebula.teal : context.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Custom Notes Section
                    Row(
                      children: [
                        const Icon(CupertinoIcons.bubble_left_bubble_right_fill, size: 16, color: Nebula.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Catatan Khusus Pesanan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Jangan pakai seledri, bungkus terpisah',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                        filled: true,
                        fillColor: context.surfaceBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.dividerCol),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.dividerCol),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Bottom Action & Quantity Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  // Quantity Stepper
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.dividerCol, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.minus, size: 14),
                          color: _quantity > 1 ? context.textPrimary : context.textSecondary,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text(
                          '$_quantity',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.plus, size: 14),
                          color: context.textPrimary,
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Add to Cart Button with Computed Total
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '+ Tambah',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(_totalPrice),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
