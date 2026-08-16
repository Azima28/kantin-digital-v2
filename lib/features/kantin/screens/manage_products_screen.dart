import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  // Toggle availability of product in database
  Future<void> _toggleProductAvailability(
    BuildContext context,
    WidgetRef ref,
    String productId,
    bool newValue,
  ) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('products')
          .update({'is_available': newValue})
          .eq('id', productId);

      // Invalidate both catalog and management providers
      ref.invalidate(posProductsProvider);
      ref.invalidate(manageProductsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memperbarui status produk'),
            backgroundColor: Nebula.rose,
          ),
        );
      }
    }
  }

  // Delete product from database with confirmation
  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    String productId,
    String productName,
  ) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Jajanan'),
        content: Text('Apakah Anda yakin ingin menghapus "$productName" dari katalog stan Anda?'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final client = ref.read(supabaseClientProvider);
                await client.from('products').delete().eq('id', productId);

                // Refresh providers
                ref.invalidate(posProductsProvider);
                ref.invalidate(manageProductsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.successProductDeleted),
                      backgroundColor: Nebula.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppStrings.labelFailed} menghapus jajanan'),
                      backgroundColor: Nebula.rose,
                    ),
                  );
                }
              }
            },
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );
  }

  // Preset fallback background colors for products without custom image
  Color _getFallbackBgColor(int index, String category) {
    final List<Color> colors = [
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(manageProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(manageProductsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section matching user reference screenshot
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Jajanan',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "+ TAMBAH PRODUK BARU" Button
                      PressScale(
                        onTap: () {
                          context.push('/pos/products/form');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Nebula.teal,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Nebula.teal.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+ TAMBAH PRODUK BARU',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Grid Layout
              productsAsync.when(
                data: (List<Product> products) {
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.tray_fill, size: 48, color: context.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada jajanan',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gunakan tombol di atas untuk menambahkan produk jualan stan Anda.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          final String id = product.id;
                          final String name = product.name;
                          final String category = product.category;
                          final int price = product.price;
                          final bool isAvailable = product.isAvailable;
                          final String? imageUrl = product.imageUrl;
                          final Color fallbackBg = _getFallbackBgColor(index, category);

                          return Container(
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.borderLight.withValues(alpha: 0.6),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Product Image Container
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      height: 120,
                                      width: double.infinity,
                                      color: fallbackBg.withValues(alpha: 0.15),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (c, i) => const Center(child: CupertinoActivityIndicator()),
                                              errorWidget: (c, i, e) => Container(
                                                color: fallbackBg,
                                                child: Center(
                                                  child: Text(
                                                    category.toLowerCase() == 'makanan' ? '🍔' : '🍹',
                                                    style: const TextStyle(fontSize: 40),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: fallbackBg,
                                              child: Center(
                                                child: Text(
                                                  category.toLowerCase() == 'makanan' ? '🍔' : '🍹',
                                                  style: const TextStyle(fontSize: 40),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                // Product Info & Controls
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Name, Category, Price
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              category.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: context.textSecondary,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              CurrencyFormatter.format(price),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Footer Controls (Availability Switch + Edit/Delete)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Availability Switch
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Tersedia',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isAvailable ? Nebula.teal : context.textSecondary,
                                                  ),
                                                ),
                                                Transform.scale(
                                                  scale: 0.65,
                                                  alignment: Alignment.centerLeft,
                                                  child: CupertinoSwitch(
                                                    value: isAvailable,
                                                    activeTrackColor: Nebula.teal,
                                                    onChanged: (bool val) =>
                                                        _toggleProductAvailability(context, ref, id, val),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Action Buttons (Edit + Delete)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Edit Button
                                                PressScale(
                                                  onTap: () {
                                                    context.push('/pos/products/form', extra: product);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Nebula.teal.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      CupertinoIcons.pencil,
                                                      size: 14,
                                                      color: Nebula.teal,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Delete Button
                                                PressScale(
                                                  onTap: () => _deleteProduct(context, ref, id, name),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Nebula.rose.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      CupertinoIcons.trash,
                                                      size: 14,
                                                      color: Nebula.rose,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const SkeletonProductGridCard(),
                      childCount: 6,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppStrings.labelFailed} memuat daftar produk',
                            style: GoogleFonts.inter(color: Nebula.rose, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(manageProductsProvider),
                            child: const Text(AppStrings.buttonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}