import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';

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
            content: Text('Gagal memperbarui status produk: $e'),
            backgroundColor: AppColors.error,
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
    // Confirm delete dialog
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Jajanan'),
        content: Text('Apakah Anda yakin ingin menghapus "$productName" dari katalog stan Anda?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
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
                      content: Text('Jajanan berhasil dihapus'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus jajanan: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(manageProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          AppStrings.titleManageProducts,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(manageProductsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top CTA Button to Add Product
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.push('/pos/products/form');
                    },
                    icon: const Icon(CupertinoIcons.add, color: Colors.white, size: 18),
                    label: const Text(
                      AppStrings.buttonAddProduct,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Products list
            productsAsync.when(
              data: (List<Map<String, dynamic>> products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.tray_fill, size: 48, color: AppColors.textGray),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada jajanan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gunakan tombol di atas untuk menambahkan produk jualan stan Anda.',
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
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        final String id = product['id']?.toString() ?? '';
                        final String name = product['name']?.toString() ?? 'Jajanan';
                        final String category = product['category']?.toString() ?? 'makanan';
                        final double price = double.tryParse(product['price'].toString()) ?? 0.0;
                        final bool isAvailable = product['is_available'] ?? true;
                        final String? imageUrl = product['image_url']?.toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              // Product Thumbnail/Emoji
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.systemBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              category.toLowerCase() == 'makanan' ? '🍔' : '🍹',
                                              style: const TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          category.toLowerCase() == 'makanan' ? '🍔' : '🍹',
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
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
                                        color: AppColors.textGray,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      CurrencyFormatter.format(price),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Availability Control & CRUD Edit/Delete Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isAvailable ? 'Tersedia' : 'Habis',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isAvailable ? AppColors.primary : AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Transform.scale(
                                        scale: 0.75,
                                        alignment: Alignment.centerRight,
                                        child: CupertinoSwitch(
                                          value: isAvailable,
                                          activeTrackColor: AppColors.primary,
                                          onChanged: (bool val) =>
                                              _toggleProductAvailability(context, ref, id, val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Edit Button
                                      GestureDetector(
                                        onTap: () {
                                          context.push('/pos/products/form', extra: product);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.systemBackground,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.pencil,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Delete Button
                                      GestureDetector(
                                        onTap: () => _deleteProduct(context, ref, id, name),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.errorLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.trash,
                                            size: 14,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: products.length,
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
                      'Gagal memuat daftar produk: $err',
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
