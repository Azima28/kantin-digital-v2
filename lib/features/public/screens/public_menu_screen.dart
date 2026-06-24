import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';

/// Halaman publik daftar menu kantin (tanpa login).
/// Menampilkan semua produk aktif dari semua stan kantin.
class PublicMenuScreen extends ConsumerStatefulWidget {
  const PublicMenuScreen({super.key});

  @override
  ConsumerState<PublicMenuScreen> createState() => _PublicMenuScreenState();
}

class _PublicMenuScreenState extends ConsumerState<PublicMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String?> _categories = [null, 'makanan', 'minuman'];
  final List<String> _tabLabels = [AppStrings.labelAll, 'Makanan', 'Minuman'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.darkTeal),
          onPressed: () => context.go('/public'),
        ),
        title: Text(
          'Menu Kantin',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTeal,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => context.go('/login?from=/public/menu'),
              child: Text(
                'Login',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTeal,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.darkTeal,
          unselectedLabelColor: AppColors.mutedGray,
          indicatorColor: AppColors.darkTeal,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((cat) => _buildMenuTab(cat)).toList(),
      ),
    );
  }

  Widget _buildMenuTab(String? category) {
    final menuAsync = ref.watch(publicMenuProvider(category));

    return menuAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.cart_badge_minus,
                    size: 48, color: AppColors.textGray),
                const SizedBox(height: 12),
                Text(
                  'Belum ada menu tersedia',
                  style: GoogleFonts.inter(
                      fontSize: 15, color: AppColors.mutedGray),
                ),
              ],
            ),
          );
        }

        // Group by canteen
        final Map<String, List<Product>> grouped = {};
        for (final item in items) {
          grouped.putIfAbsent(item.canteenName, () => []).add(item.product);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (ctx, i) {
            final canteen = grouped.keys.elementAt(i);
            final products = grouped[canteen]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Canteen header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.darkTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.house,
                            size: 14, color: AppColors.darkTeal),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canteen,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Products grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (ctx, j) => _buildProductCard(products[j]),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
      loading: () => const Center(
          child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.wifi_slash,
                size: 48, color: AppColors.textGray),
            const SizedBox(height: 12),
            Text(
              '${AppStrings.labelFailed} memuat menu',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.mutedGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(publicMenuProvider(category)),
              child: const Text(AppStrings.buttonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final String name = product.name;
    final int price = product.price;
    final String category = product.category;
    final String? imageUrl = product.imageUrl;
    final bool isAvailable = product.isAvailable;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                      errorWidget: (_, __, ___) => _buildPlaceholderImage(category),
                    )
                  : _buildPlaceholderImage(category),
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedGray,
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed2.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Habis',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.mutedGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
  }

  Widget _buildPlaceholderImage(String category) {
    final bool isMakanan = category == 'makanan';
    return Container(
      color: isMakanan
          ? AppColors.softOrange
          : AppColors.systemBackground,
      child: Icon(
        isMakanan ? CupertinoIcons.flame : CupertinoIcons.drop,
        size: 40,
        color: isMakanan
            ? AppColors.darkOrange.withValues(alpha: 0.5)
            : AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
