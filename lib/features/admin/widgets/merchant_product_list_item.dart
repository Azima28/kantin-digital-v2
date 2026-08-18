import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/models/product.dart';

/// Card item untuk menampilkan produk dalam katalog stan merchant/operator
class MerchantProductListItem extends StatelessWidget {
  final String name;
  final int price;
  final bool isAvailable;
  final String? imageUrl;
  final double rating;
  final int totalSold;
  final int totalReviews;

  const MerchantProductListItem({
    super.key,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.rating = 0.0,
    this.totalSold = 0,
    this.totalReviews = 0,
  });

  factory MerchantProductListItem.fromProduct(Product product) {
    return MerchantProductListItem(
      name: product.name,
      price: product.price,
      isAvailable: product.isAvailable,
      imageUrl: product.imageUrl,
      rating: product.rating,
      totalSold: product.totalSold,
      totalReviews: product.totalReviews,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol, width: 0.6),
      ),
      child: Row(
        children: [
          // 1. Thumbnail Foto Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Nebula.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.fastfood_rounded, size: 22, color: Nebula.teal),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.fastfood_rounded, size: 22, color: Nebula.teal),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Info Produk (Nama, Harga, Terjual & Rating)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(price),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Nebula.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Rating Badge
                    if (rating > 0) ...[
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Total Terjual
                    Text(
                      'Terjual $totalSold',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Status Ketersediaan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAvailable
                  ? Nebula.teal.withValues(alpha: 0.12)
                  : Nebula.rose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAvailable
                    ? Nebula.teal.withValues(alpha: 0.25)
                    : Nebula.rose.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Text(
              isAvailable ? 'Tersedia' : 'Habis',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Nebula.teal : Nebula.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
