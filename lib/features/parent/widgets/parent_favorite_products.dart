import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// List of top favorite products for the Analisis tab.
class ParentFavoriteProducts extends StatelessWidget {
  final List<MapEntry<String, int>> favorites;

  const ParentFavoriteProducts({
    super.key,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
      ),
      child: favorites.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Belum ada produk favorit pada periode ini.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              separatorBuilder: (context, i) =>
                  const Divider(height: 1, color: AppColors.borderGray),
              itemBuilder: (context, i) {
                final item = favorites[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.offWhite2,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    item.key,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  trailing: Text(
                    '${item.value}x dibeli',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
