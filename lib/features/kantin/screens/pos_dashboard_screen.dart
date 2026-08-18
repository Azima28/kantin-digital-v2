import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';

class PosDashboardScreen extends ConsumerStatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  ConsumerState<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends ConsumerState<PosDashboardScreen> {
  int _selectedCategoryIndex = 0; // 0: Semua, 1: Makanan, 2: Minuman

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final productsAsync = ref.watch(posProductsProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);
    final cartState = ref.watch(cartProvider);

    final String canteenName =
        authState.profile?['canteen_name'] ?? 'Stan Kantin';

    return Scaffold(
      backgroundColor: context.surfaceBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron,
              color: Nebula.teal),
          onPressed: () => context.go('/pos'),
        ),
        title: Text(
          canteenName.toUpperCase(),
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: context.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right,
                color: Nebula.rose),
            onPressed: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed && context.mounted) {
                ref.read(authNotifierProvider.notifier).logout();
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(posProductsProvider);
                  ref.invalidate(todayRevenueProvider);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Revenue Info Card (Nebula)
                    SliverToBoxAdapter(
                      child: NebulaCard(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.labelBalanceEarned,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            revenueAsync.when(
                              data: (double revenue) => Text(
                                CurrencyFormatter.format(revenue),
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Nebula.teal,
                                ),
                              ),
                              loading: () => Shimmer(
                                child: const SkeletonBox(width: 140, height: 28, borderRadius: 6),
                              ),
                              error: (err, stack) => Text(
                                '${AppStrings.labelFailed} memuat',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: Nebula.rose,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cupertino Segmented Control Category Filter
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: CupertinoSegmentedControl<int>(
                            groupValue: _selectedCategoryIndex,
                            selectedColor: Nebula.teal,
                            unselectedColor: context.cardBg,
                            borderColor: context.borderLight,
                            pressedColor: Nebula.teal.withValues(alpha: 0.08),
                            children: const <int, Widget>{
                              0: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  AppStrings.categoryAll,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              1: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  AppStrings.categoryFood,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              2: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  AppStrings.categoryDrink,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            },
                            onValueChanged: (int val) {
                              setState(() {
                                _selectedCategoryIndex = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Products Grid Catalog
                    productsAsync.when(
                      data: (List<Product> products) {
                        // Filter based on active category
                        final filteredProducts =
                            products.where((product) {
                          final category =
                              product.category.toLowerCase();
                          if (_selectedCategoryIndex == 1) {
                            return category == 'makanan';
                          }
                          if (_selectedCategoryIndex == 2) {
                            return category == 'minuman';
                          }
                          return true; // Semua
                        }).toList();

                        if (filteredProducts.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 80),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    EmptyStateWidget(
                                      message:
                                          'Belum ada jajanan tersedia',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Silakan tambahkan produk di menu "Menu" terlebih dahulu.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final crossAxisCount = Responsive.productGridColumns(context);
                        final childAspectRatio = Responsive.productGridAspectRatio(context);

                        return SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: childAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product =
                                    filteredProducts[index];
                                final id = product.id;
                                final name = product.name;
                                final price = product.price;
                                final imageUrl = product.imageUrl;
                                final cartItem = cartState.items
                                    .where((item) => item.productId == id)
                                    .firstOrNull;
                                final quantity = cartItem?.quantity ?? 0;

                                return _buildProductCard(
                                  id: id,
                                  name: name,
                                  price: price,
                                  imageUrl: imageUrl,
                                  quantity: quantity,
                                );
                              },
                              childCount: filteredProducts.length,
                            ),
                          ),
                        );
                      },
                      loading: () => SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => const SkeletonProductGridCard(),
                            childCount: 6,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.productGridColumns(context),
                            childAspectRatio: Responsive.productGridAspectRatio(context),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                        ),
                      ),
                      error: (err, stack) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '${AppStrings.labelFailed} mengambil katalog jajanan:\n$err',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Nebula.rose, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom spacing for floating cart bar
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: cartState.totalItems > 0 ? 100 : 40),
                    ),
                  ],
                ),
              ),

              // Floating Cart Bar (Teal GoFood/GrabFood style)
              if (cartState.totalItems > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: PressScale(
                      onTap: () {
                        context.push('/pos/cart');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Nebula.teal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Nebula.teal.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Item Count Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.bag_fill,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${cartState.totalItems} Item',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Total Price
                            Expanded(
                              child: Text(
                                CurrencyFormatter.format(cartState.totalAmount),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Action label & Chevron icon
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Keranjang',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.chevron_right,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
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

  /// Builds a single product card for the grid
  Widget _buildProductCard({
    required String id,
    required String name,
    required int price,
    required String? imageUrl,
    required int quantity,
  }) {
    return NebulaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.surfaceBg,
                        child: const Center(
                            child: CupertinoActivityIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.surfaceBg,
                        child: Icon(CupertinoIcons.photo,
                            color: context.textSecondary, size: 28),
                      ),
                    )
                  : Container(
                      color: context.surfaceBg,
                      child: Center(
                        child: Icon(CupertinoIcons.cart,
                            color: context.textSecondary, size: 28),
                      ),
                    ),
            ),
          ),

          // Product Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  // Price + Quantity Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.format(price),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildQuantitySelector(
                        id: id,
                        name: name,
                        price: price,
                        quantity: quantity,
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

  Widget _buildQuantitySelector({
    required String id,
    required String name,
    required int price,
    required int quantity,
  }) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () {
          ref.read(cartProvider.notifier).addProduct(id, name, price);
        },
        child: Container(
          width: double.infinity,
          height: 28,
          decoration: BoxDecoration(
            color: Nebula.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.add,
                size: 14,
                color: Nebula.teal,
              ),
              SizedBox(width: 4),
              Text(
                'Tambah',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Nebula.teal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: () {
            ref
                .read(cartProvider.notifier)
                .decreaseQuantity(id, name);
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: context.surfaceBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.minus,
              size: 12,
              color: context.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            ref
                .read(cartProvider.notifier)
                .increaseQuantity(id, name);
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.plus,
              size: 12,
              color: Nebula.teal,
            ),
          ),
        ),
      ],
    );
  }
}