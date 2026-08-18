import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/product.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_product_list_item.dart';

/// Modal bottom sheet untuk menampilkan seluruh katalog produk stan dengan pencarian & filter
class MerchantAllProductsSheet extends StatefulWidget {
  final List<Product> products;
  final String canteenName;

  const MerchantAllProductsSheet({
    super.key,
    required this.products,
    required this.canteenName,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Product> products,
    required String canteenName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MerchantAllProductsSheet(
        products: products,
        canteenName: canteenName,
      ),
    );
  }

  @override
  State<MerchantAllProductsSheet> createState() => _MerchantAllProductsSheetState();
}

class _MerchantAllProductsSheetState extends State<MerchantAllProductsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'semua';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return widget.products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'semua' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final categories = ['semua', 'makanan', 'minuman', 'camilan'];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Produk (${widget.products.length})',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.canteenName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 24),
                color: context.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari menu jajanan...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
              prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: Nebula.teal),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.surfaceBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final label = cat == 'semua' ? 'Semua' : cat[0].toUpperCase() + cat.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : context.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Nebula.teal,
                    backgroundColor: context.surfaceBg,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Nebula.teal : context.dividerCol,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      message: _searchQuery.isNotEmpty
                          ? 'Tidak ada produk dengan kata kunci "$_searchQuery"'
                          : 'Tidak ada produk pada kategori ini',
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return MerchantProductListItem.fromProduct(p);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
