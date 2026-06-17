import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
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

    final String canteenName = authState.profile?['canteen_name'] ?? 'Stan Kantin';

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary),
          onPressed: () => context.go('/pos'),
        ),
        title: Text(
          canteenName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 1.1),
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
            icon: const Icon(CupertinoIcons.square_arrow_right, color: AppColors.error),
            onPressed: () {
              // Sign out dialog
              showCupertinoDialog(
                context: context,
                builder: (BuildContext ctx) => CupertinoAlertDialog(
                  title: const Text('Keluar Aplikasi'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun kasir?'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authNotifierProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: const Text('Keluar'),
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
                      border: Border.all(color: AppColors.borderLight, width: 0.5),
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
                          loading: () => const CupertinoActivityIndicator(),
                          error: (err, stack) => const Text(
                            'Gagal memuat',
                            style: TextStyle(fontSize: 18, color: AppColors.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cupertino Segmented Control Category Filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoSegmentedControl<int>(
                        groupValue: _selectedCategoryIndex,
                        selectedColor: AppColors.primary,
                        unselectedColor: AppColors.cardBackground,
                        borderColor: AppColors.borderLight,
                        pressedColor: AppColors.primaryLight,
                        children: const <int, Widget>{
                          0: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              AppStrings.categoryAll,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          1: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              AppStrings.categoryFood,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          2: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              AppStrings.categoryDrink,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                  data: (List<Map<String, dynamic>> products) {
                    // Filter based on active category
                    final filteredProducts = products.where((product) {
                      final category = product['category']?.toString().toLowerCase();
                      if (_selectedCategoryIndex == 1) return category == 'makanan';
                      if (_selectedCategoryIndex == 2) return category == 'minuman';
                      return true; // Semua
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.tray, size: 48, color: AppColors.textGray),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada jajanan tersedia',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Silakan tambahkan produk di menu "Menu" terlebih dahulu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textGray, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 1200
                              ? 6
                              : MediaQuery.of(context).size.width > 900
                                  ? 5
                                  : MediaQuery.of(context).size.width > 600
                                      ? 3
                                      : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext ctx, int index) {
                            final product = filteredProducts[index];
                            final id = product['id']?.toString() ?? '';
                            final name = product['name']?.toString() ?? 'Jajanan';
                            final category = product['category']?.toString() ?? 'makanan';
                            final price = double.tryParse(product['price'].toString()) ?? 0.0;
                            final imageUrl = product['image_url']?.toString();

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderLight, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image/Placeholder Emojis
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                        color: AppColors.systemBackground,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(13),
                                          topRight: Radius.circular(13),
                                        ),
                                      ),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(13),
                                                topRight: Radius.circular(13),
                                              ),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    category.toLowerCase() == 'makanan' ? '🍔' : '🍹',
                                                    style: const TextStyle(fontSize: 48),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                category.toLowerCase() == 'makanan' ? '🍔' : '🍹',
                                                style: const TextStyle(fontSize: 48),
                                              ),
                                            ),
                                    ),
                                  ),

                                  // Product Info & Price
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              CurrencyFormatter.format(price),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            // Circular Add to Cart Button
                                            GestureDetector(
                                              onTap: () {
                                                ref.read(cartProvider.notifier).addProduct(id, name, price);
                                                // Small haptic feel / micro-animation could go here
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  CupertinoIcons.add,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 12),
                    ),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Gagal mengambil katalog jajanan:\n$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom spacing for floating cart bar
                SliverToBoxAdapter(
                  child: SizedBox(height: cartState.totalItems > 0 ? 100 : 40),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentOrange.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${cartState.totalItems}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Keranjang • ${CurrencyFormatter.format(cartState.totalAmount)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text(
                              'Detail',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
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
}
