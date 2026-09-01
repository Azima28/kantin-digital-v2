import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';

/// Full Screen Modal / View to customize purchase options (Custom Pembelian / Ubah Pilihan)
class ProductDetailBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  final String stanId;
  final String stanName;
  final int deliveryFee;
  final String description;
  final List<String>? initialSelectedOptions;
  final String? initialNotes;
  final int? initialQuantity;
  final bool isEditing;
  final void Function(List<String> newOptions, String? newNotes, int newUnitPrice, int newQuantity)? onSaveEditedItem;

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
    required this.stanId,
    required this.stanName,
    this.deliveryFee = 2000,
    required this.description,
    this.initialSelectedOptions,
    this.initialNotes,
    this.initialQuantity,
    this.isEditing = false,
    this.onSaveEditedItem,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required String stanId,
    required String stanName,
    int deliveryFee = 2000,
    required String description,
    List<String>? initialSelectedOptions,
    String? initialNotes,
    int? initialQuantity,
    bool isEditing = false,
    void Function(List<String> newOptions, String? newNotes, int newUnitPrice, int newQuantity)? onSaveEditedItem,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailBottomSheet(
        product: product,
        stanId: stanId,
        stanName: stanName,
        deliveryFee: deliveryFee,
        description: description,
        initialSelectedOptions: initialSelectedOptions,
        initialNotes: initialNotes,
        initialQuantity: initialQuantity,
        isEditing: isEditing,
        onSaveEditedItem: onSaveEditedItem,
      ),
    );
  }

  @override
  ConsumerState<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();
}

class _CustomOptionGroup {
  final String title;
  final bool isSingleSelect;
  final List<String> rawOptions;

  _CustomOptionGroup({
    required this.title,
    required this.isSingleSelect,
    required this.rawOptions,
  });
}

class _ProductDetailBottomSheetState
    extends ConsumerState<ProductDetailBottomSheet> {
  int _quantity = 1;
  final Set<String> _selectedOptions = {};
  final TextEditingController _notesController = TextEditingController();
  late List<_CustomOptionGroup> _optionGroups;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity ?? 1;
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }
    _optionGroups = _groupOptions(widget.product.customizableOptions);

    if (widget.initialSelectedOptions != null && widget.initialSelectedOptions!.isNotEmpty) {
      for (final raw in widget.product.customizableOptions) {
        final cleanRaw = raw.replaceAll(RegExp(r'^\[(PILIH 1|PILIH BANYAK|SINGLE|MULTI|\*|1)\]\s*', caseSensitive: false), '').trim();
        for (final initOpt in widget.initialSelectedOptions!) {
          final cleanInit = initOpt.replaceAll(RegExp(r'^\[(PILIH 1|PILIH BANYAK|SINGLE|MULTI|\*|1)\]\s*', caseSensitive: false), '').trim();
          if (cleanRaw == cleanInit || cleanRaw.endsWith(cleanInit) || cleanInit.endsWith(cleanRaw)) {
            _selectedOptions.add(raw);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<_CustomOptionGroup> _groupOptions(List<String> rawOptions) {
    final Map<String, ({bool? explicitSingle, List<String> options})> map = {};
    for (final opt in rawOptions) {
      final clean = opt.trim();
      if (clean.isEmpty) continue;

      bool? explicitSingle;
      String optionBody = clean;

      if (clean.startsWith(RegExp(r'^\[(PILIH 1|SINGLE|1)\]\s*', caseSensitive: false))) {
        explicitSingle = true;
        optionBody = clean.replaceFirst(RegExp(r'^\[(PILIH 1|SINGLE|1)\]\s*', caseSensitive: false), '');
      } else if (clean.startsWith(RegExp(r'^\[(PILIH BANYAK|MULTI|\*)\]\s*', caseSensitive: false))) {
        explicitSingle = false;
        optionBody = clean.replaceFirst(RegExp(r'^\[(PILIH BANYAK|MULTI|\*)\]\s*', caseSensitive: false), '');
      }

      String groupTitle = 'Pilihan Tambahan';
      if (optionBody.contains(': ')) {
        groupTitle = optionBody.split(': ')[0].trim();
      }

      final existing = map[groupTitle];
      if (existing == null) {
        map[groupTitle] = (
          explicitSingle: explicitSingle,
          options: [clean],
        );
      } else {
        map[groupTitle] = (
          explicitSingle: existing.explicitSingle ?? explicitSingle,
          options: [...existing.options, clean],
        );
      }
    }

    final List<_CustomOptionGroup> groups = [];
    map.forEach((title, data) {
      bool isSingle;
      if (data.explicitSingle != null) {
        isSingle = data.explicitSingle!;
      } else {
        final lower = title.toLowerCase();
        isSingle = lower.contains('level') ||
            lower.contains('pedas') ||
            lower.contains('asin') ||
            lower.contains('rasa') ||
            lower.contains('porsi') ||
            lower.contains('ukuran') ||
            lower.contains('suhu') ||
            lower.contains('es') ||
            lower.contains('gula') ||
            lower.contains('pilih 1');
      }

      groups.add(_CustomOptionGroup(
        title: title,
        isSingleSelect: isSingle,
        rawOptions: data.options,
      ));
    });

    return groups;
  }

  void _toggleOption(String opt, bool isSingleSelect, List<String> groupOptions) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isSingleSelect) {
        if (_selectedOptions.contains(opt)) {
          _selectedOptions.remove(opt);
        } else {
          // Deselect other options in this single-select group
          for (final o in groupOptions) {
            _selectedOptions.remove(o);
          }
          _selectedOptions.add(opt);
        }
      } else {
        if (_selectedOptions.contains(opt)) {
          _selectedOptions.remove(opt);
        } else {
          _selectedOptions.add(opt);
        }
      }
    });
  }

  ({String name, String priceLabel, int price}) _parseOption(String opt) {
    var cleanOpt = opt.replaceAll(RegExp(r'^\[(PILIH 1|PILIH BANYAK|SINGLE|MULTI|\*|1)\]\s*', caseSensitive: false), '').trim();
    int addon = 0;
    String priceLabel = 'Gratis';

    final match = RegExp(r'\(\+?Rp?\s*([\d\.]+)\)').firstMatch(cleanOpt);
    if (match != null) {
      final cleanNum = match.group(1)!.replaceAll('.', '');
      addon = int.tryParse(cleanNum) ?? 0;
      if (addon > 0) {
        priceLabel = '+${CurrencyFormatter.format(addon)}';
      }
      cleanOpt = cleanOpt.replaceAll(RegExp(r'\s*\(\+?Rp?\s*[\d\.]+\)'), '').trim();
    }

    if (cleanOpt.contains(': ')) {
      final parts = cleanOpt.split(': ');
      cleanOpt = parts.sublist(1).join(': ').trim();
    }

    return (
      name: cleanOpt,
      priceLabel: priceLabel,
      price: addon,
    );
  }

  int get _calculatedUnitPrice {
    int price = widget.product.price;
    for (final opt in _selectedOptions) {
      final parsed = _parseOption(opt);
      price += parsed.price;
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

    final List<String> optionsList = _selectedOptions.map((opt) {
      return opt.replaceAll(RegExp(r'^\[(PILIH 1|PILIH BANYAK|SINGLE|MULTI|\*|1)\]\s*', caseSensitive: false), '').trim();
    }).toList();
    final String noteText = _notesController.text.trim();

    if (hasConflict) {
      final currentCanteenName =
          ref.read(studentCartProvider).canteenName ?? 'Stan Lain';
      final confirmed = await showAppConfirmationDialog(
        context,
        title: 'Mau ganti stan?',
        message:
            'Keranjangmu saat ini berisi pesanan dari $currentCanteenName. Jika memilih menu dari $canteenName, pesanan sebelumnya akan diganti.',
        confirmLabel: 'Ganti & Tambah',
        confirmColor: const Color(0xFF10B981),
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
          notes: noteText.isNotEmpty ? noteText : null,
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
        notes: noteText.isNotEmpty ? noteText : null,
      );
      Navigator.pop(context);
      _showSuccessSnackbar(product.name);
    }
  }

  void _saveChanges() {
    final List<String> optionsList = _selectedOptions.map((opt) {
      return opt.replaceAll(RegExp(r'^\[(PILIH 1|PILIH BANYAK|SINGLE|MULTI|\*|1)\]\s*', caseSensitive: false), '').trim();
    }).toList();
    final String noteText = _notesController.text.trim();

    if (widget.onSaveEditedItem != null) {
      widget.onSaveEditedItem!(
        optionsList,
        noteText.isNotEmpty ? noteText : null,
        _calculatedUnitPrice,
        _quantity,
      );
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Pilihan menu berhasil diperbarui'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  Widget _buildFallbackImage(String category) {
    return Container(
      color: const Color(0xFF10B981).withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          category == 'minuman' ? Icons.local_drink_rounded : Icons.restaurant_rounded,
          color: const Color(0xFF10B981),
          size: 44,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDark = context.isDark;
    final bool isAvailable = product.isAvailable;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height,
      color: context.cardBg,
      child: Column(
        children: [
          // ─── 1. TOP APP BAR (Custom pembelian) ───
          Container(
            padding: EdgeInsets.only(
              top: topPadding > 0 ? topPadding + 4 : 12,
              bottom: 12,
              left: 6,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(bottom: BorderSide(color: context.dividerCol, width: 0.8)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_left, size: 22),
                  color: context.textPrimary,
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Kembali',
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isEditing ? 'Ubah Pilihan Menu' : 'Custom pembelian',
                  style: GoogleFonts.inter(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // ─── 2. SCROLLABLE CUSTOMIZATION OPTIONS BODY ───
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. GAMBAR PRODUCT BERADA DI ATAS DENGAN HEIGHT RAMPING (130px)
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 130, // Compact height as requested
                        color: context.surfaceBg,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerRect(
                            width: double.infinity,
                            height: 130,
                            borderRadius: 16,
                          ),
                          errorWidget: (_, __, ___) => _buildFallbackImage(product.category),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // B. NAMA PRODUK & HARGA DIBAWAH GAMBAR (Matching Request)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Canteen & Category & Rating Info Row
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        widget.stanName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      if (product.hasRating) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Description (only if not empty)
                  if (widget.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.description.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: context.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Divider(color: context.dividerCol, height: 1, thickness: 1.0),
                  const SizedBox(height: 16),

                  // ─── C. PILIHAN VARIAN / TAMBAHAN (GROUPED & CLICKABLE CARD ROWS) ───
                  if (_optionGroups.isNotEmpty) ...[
                    for (int gIdx = 0; gIdx < _optionGroups.length; gIdx++) ...[
                      () {
                        final group = _optionGroups[gIdx];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        group.isSingleSelect ? 'Pilih 1 pilihan' : 'Bisa pilih lebih dari 1',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: group.isSingleSelect ? const Color(0xFF10B981) : Nebula.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: group.isSingleSelect
                                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                        : Nebula.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    group.isSingleSelect ? 'PILIH 1' : 'PILIH BANYAK',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: group.isSingleSelect ? const Color(0xFF10B981) : Nebula.amber,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // List of options (Full card row clickable to toggle selection)
                            Container(
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.dividerCol, width: 0.8),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: group.rawOptions.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  thickness: 1.0,
                                  color: context.dividerCol,
                                  indent: 14,
                                  endIndent: 14,
                                ),
                                itemBuilder: (context, idx) {
                                  final opt = group.rawOptions[idx];
                                  final parsed = _parseOption(opt);
                                  final bool isSelected = _selectedOptions.contains(opt);

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _toggleOption(opt, group.isSingleSelect, group.rawOptions),
                                      borderRadius: BorderRadius.vertical(
                                        top: idx == 0 ? const Radius.circular(16) : Radius.zero,
                                        bottom: idx == group.rawOptions.length - 1
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                parsed.name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              parsed.priceLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: parsed.price > 0
                                                    ? const Color(0xFF10B981)
                                                    : context.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            // Checkbox/Radio Circle Indicator
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 180),
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: group.isSingleSelect ? BoxShape.circle : BoxShape.rectangle,
                                                borderRadius: group.isSingleSelect ? null : BorderRadius.circular(6),
                                                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                                border: Border.all(
                                                  color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400,
                                                  width: isSelected ? 2 : 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? Center(
                                                      child: Icon(
                                                        group.isSingleSelect ? Icons.circle : Icons.check,
                                                        size: group.isSingleSelect ? 10 : 14,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        );
                      }(),
                    ],
                    Divider(color: context.dividerCol, height: 1, thickness: 1.0),
                    const SizedBox(height: 16),
                  ],

                  // ─── D. CATATAN KHUSUS SECTION ───
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Catatan Khusus',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(Opsional)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
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
                          hintText: 'Contoh: Sambal dipisah ya, jangan pakai seledri...',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
                          filled: true,
                          fillColor: context.surfaceBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ─── E. STICKY BOTTOM ACTION BAR ───
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              bottomPadding > 0 ? bottomPadding + 10 : 20,
            ),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(top: BorderSide(color: context.dividerCol, width: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Jumlah pembelian" Row with Counter (- 1 +)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jumlah pembelian',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        // Minus Button
                        PressScale(
                          scale: 0.90,
                          onTap: isAvailable && _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _quantity > 1 ? Colors.grey.shade400 : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.minus,
                              size: 16,
                              color: _quantity > 1 ? context.textPrimary : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$_quantity',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        // Plus Button
                        PressScale(
                          scale: 0.90,
                          onTap: isAvailable ? () => setState(() => _quantity++) : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.plus,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Big Green Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: PressScale(
                    scale: 0.98,
                    onTap: isAvailable
                        ? (widget.isEditing ? _saveChanges : _addToCart)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: isAvailable
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.40),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isAvailable
                              ? (widget.isEditing
                                  ? 'Simpan Perubahan · ${CurrencyFormatter.format(_calculatedTotalPrice)}'
                                  : 'Tambah pembelian + ${CurrencyFormatter.format(_calculatedTotalPrice)}')
                              : 'Menu Habis',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
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
}
