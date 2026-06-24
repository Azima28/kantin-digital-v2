import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';

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
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron,
              color: AppColors.primary),
          onPressed: () => context.go('/pos'),
        ),
        title: Text(
          canteenName.toUpperCase(),
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right,
                color: AppColors.error),
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (BuildContext ctx) => CupertinoAlertDialog(
                  title: const Text('Keluar Aplikasi'),
                  content: const Text(
                      'Apakah Anda yakin ingin keluar dari akun kasir?'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text(AppStrings.buttonCancel),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authNotifierProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: const Text(AppStrings.buttonLogout),
                    ),
                  ],
                ),
              );
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
                    // Header Revenue Info Card
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.labelBalanceEarned,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            revenueAsync.when(
                              data: (double revenue) => Text(
                                CurrencyFormatter.format(revenue),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              loading: () =>
                                  const CupertinoActivityIndicator(),
                              error: (err, stack) => Text(
                                '${AppStrings.labelFailed} memuat',
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.error,
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
                            selectedColor: AppColors.primary,
                            unselectedColor: AppColors.cardBackground,
                            borderColor: AppColors.borderLight,
                            pressedColor: AppColors.primaryLight,
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
                                    const Text(
                                      'Silakan tambahkan produk di menu "Menu" terlebih dahulu.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.textGray,
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
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child:
                              CupertinoActivityIndicator(radius: 12),
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
                                  color: AppColors.error, fontSize: 14),
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

              // Floating Cart Bar (Orange style iOS bar)
              if (cartState.totalItems > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () {
                        context.push('/pos/cart');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentOrange
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isNarrow = constraints.maxWidth < 320;
                            return Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${cartState.totalItems}',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            isNarrow
                                                ? CurrencyFormatter.format(
                                                    cartState.totalAmount)
                                                : 'Keranjang • ${CurrencyFormatter.format(cartState.totalAmount)}',
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isNarrow) ...[
                                      const Text(
                                        AppStrings.titleDetail,
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    const Icon(
                                      CupertinoIcons.chevron_right,
                                      color: AppColors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.lightGray,
                        child: const Center(
                            child: CupertinoActivityIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.lightGray,
                        child: const Icon(CupertinoIcons.photo,
                            color: AppColors.textGray, size: 28),
                      ),
                    )
                  : Container(
                      color: AppColors.lightGray,
                      child: const Center(
                        child: Icon(CupertinoIcons.cart,
                            color: AppColors.textGray, size: 28),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),

                  // Price + Quantity Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.format(price),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
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
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.add,
                size: 14,
                color: AppColors.primary,
              ),
              SizedBox(width: 4),
              Text(
                'Tambah',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
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
            decoration: const BoxDecoration(
              color: AppColors.lightGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.minus,
              size: 12,
              color: AppColors.textDark,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
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
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.plus,
              size: 12,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
