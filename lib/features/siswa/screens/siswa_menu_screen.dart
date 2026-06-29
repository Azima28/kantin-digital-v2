import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/features/siswa/providers/cart_provider.dart';
import 'package:kantin_digital/features/siswa/providers/order_providers.dart';

class SiswaMenuScreen extends ConsumerStatefulWidget {
  final CanteenInfo canteen;
  const SiswaMenuScreen({super.key, required this.canteen});

  @override
  ConsumerState<SiswaMenuScreen> createState() => _SiswaMenuScreenState();
}

class _SiswaMenuScreenState extends ConsumerState<SiswaMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Semua', 'Makanan', 'Minuman', 'Camilan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> products, String tab) {
    if (tab == 'Semua') return products;
    final catMap = {
      'Makanan': 'makanan',
      'Minuman': 'minuman',
      'Camilan': 'camilan',
    };
    return products.where((p) => p.category == catMap[tab]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(canteenMenuProvider(widget.canteen.id));
    final cartState = ref.watch(cartProvider);
    final canteenCart = cartState.canteens[widget.canteen.id];
    final totalQty = canteenCart?.itemCount ?? 0;
    final totalPrice = canteenCart?.subtotal ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.left_chevron),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!cartState.isEmpty)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon:
                          const Icon(CupertinoIcons.cart, color: Colors.white),
                      onPressed: () => context.push(AppRouter.studentCart),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: AppColors.error, shape: BoxShape.circle),
                        child: Text(
                          '${cartState.totalItems}',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.canteen.canteenName,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.canteen.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.canteen.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.darkTeal),
                  // gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.teal.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  // Delivery badge
                  if (widget.canteen.deliveryEnabled)
                    Positioned(
                      bottom: 52,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🛵  Antar  •  Rp ${NumberFormat('#,###', 'id_ID').format(widget.canteen.deliveryFee)}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ],
        body: menuAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle,
                    color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text('Gagal memuat menu',
                    style: GoogleFonts.inter(color: AppColors.error)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(canteenMenuProvider(widget.canteen.id)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (products) {
            return TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filter(products, tab);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.bag,
                            size: 48, color: AppColors.gray400),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada menu $tab',
                          style: GoogleFonts.inter(
                              color: AppColors.mutedGray),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) =>
                      _ProductTile(product: filtered[i], canteen: widget.canteen),
                );
              }).toList(),
            );
          },
        ),
      ),
      // Bottom cart bar
      bottomNavigationBar: totalQty > 0
          ? _MenuCartBar(
              qty: totalQty,
              total: totalPrice,
              canteenName: widget.canteen.canteenName,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ProductTile extends ConsumerWidget {
  final Product product;
  final CanteenInfo canteen;
  const _ProductTile({required this.product, required this.canteen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider.select((s) =>
        s.canteens[canteen.id]
            ?.items
            .where((e) => e.productId == product.id)
            .firstOrNull
            ?.quantity ??
        0));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 90,
              height: 90,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.primaryLight),
                      errorWidget: (_, __, ___) => _FoodPlaceholder(),
                    )
                  : _FoodPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.category,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(product.price)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Qty control
          Padding(
            padding: const EdgeInsets.all(12),
            child: qty == 0
                ? _AddButton(
                    onTap: () => _addToCart(ref),
                  )
                : _QtyControl(
                    qty: qty,
                    onDecrease: () => ref
                        .read(cartProvider.notifier)
                        .decreaseItem(canteen.id, product.id),
                    onIncrease: () => _addToCart(ref),
                  ),
          ),
        ],
      ),
    );
  }

  void _addToCart(WidgetRef ref) {
    ref.read(cartProvider.notifier).addItem(
          operatorId: canteen.id,
          canteenName: canteen.canteenName,
          deliveryEnabled: canteen.deliveryEnabled,
          deliveryFee: canteen.deliveryFee,
          item: CartItemEntry(
            productId: product.id,
            productName: product.name,
            unitPrice: product.price,
            imageUrl: product.imageUrl,
          ),
        );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(CupertinoIcons.bag, color: AppColors.teal, size: 28),
        ),
      );
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 20),
        ),
      );
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  const _QtyControl(
      {required this.qty,
      required this.onDecrease,
      required this.onIncrease});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.minus,
                color: AppColors.teal, size: 16),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.add,
                color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

class _MenuCartBar extends ConsumerWidget {
  final int qty;
  final int total;
  final String canteenName;
  const _MenuCartBar(
      {required this.qty, required this.total, required this.canteenName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.push(AppRouter.studentCart),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$qty item',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lihat Keranjang',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
