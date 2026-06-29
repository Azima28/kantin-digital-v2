import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/siswa/providers/cart_provider.dart';
import 'package:kantin_digital/features/siswa/providers/order_providers.dart';
import 'package:kantin_digital/core/router/app_router.dart';

class SiswaCanteenListScreen extends ConsumerStatefulWidget {
  const SiswaCanteenListScreen({super.key});

  @override
  ConsumerState<SiswaCanteenListScreen> createState() =>
      _SiswaCanteenListScreenState();
}

class _SiswaCanteenListScreenState
    extends ConsumerState<SiswaCanteenListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canteensAsync = ref.watch(canteensProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron,
              color: AppColors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Kantin',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.teal,
          ),
        ),
        actions: [
          if (!cartState.isEmpty)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.cart,
                      color: AppColors.teal),
                  onPressed: () => context.push(AppRouter.studentCart),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
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
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari stan kantin…',
                hintStyle:
                    GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search,
                    color: AppColors.mutedGray, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid,
                            color: AppColors.mutedGray, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: canteensAsync.when(
              loading: () =>
                  const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    Text('Gagal memuat kantin',
                        style: GoogleFonts.inter(color: AppColors.error)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(canteensProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
              data: (canteens) {
                final filtered = _search.isEmpty
                    ? canteens
                    : canteens
                        .where((c) =>
                            c.canteenName
                                .toLowerCase()
                                .contains(_search) ||
                            c.fullName.toLowerCase().contains(_search))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada kantin ditemukan',
                      style: GoogleFonts.inter(color: AppColors.mutedGray),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: () async => ref.invalidate(canteensProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _CanteenCard(canteen: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating cart bar
      bottomNavigationBar: cartState.isEmpty
          ? null
          : _CartBar(cartState: cartState),
    );
  }
}

class _CanteenCard extends ConsumerWidget {
  final CanteenInfo canteen;
  const _CanteenCard({required this.canteen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartQty = ref.watch(cartProvider).canteens[canteen.id]?.itemCount ?? 0;

    return GestureDetector(
      onTap: () => context.push(
        AppRouter.studentMenu.replaceFirst(':operatorId', canteen.id),
        extra: canteen,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: canteen.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: canteen.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppColors.primaryLight),
                        errorWidget: (_, __, ___) =>
                            _PlaceholderIcon(name: canteen.canteenName),
                      )
                    : _PlaceholderIcon(name: canteen.canteenName),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canteen.canteenName,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canteen.fullName,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.mutedGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Pill(
                          label: '${canteen.productCount} menu',
                          color: AppColors.primaryLight,
                          textColor: AppColors.teal,
                        ),
                        if (canteen.deliveryEnabled) ...[
                          const SizedBox(width: 6),
                          _Pill(
                            label: '🛵 Antar',
                            color: AppColors.softOrange,
                            textColor: AppColors.darkOrange,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Cart qty badge + chevron
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  if (cartQty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cartQty item',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(CupertinoIcons.right_chevron,
                      color: AppColors.mutedGray, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final String name;
  const _PlaceholderIcon({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.teal),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Pill(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

class _CartBar extends ConsumerWidget {
  final CartState cartState;
  const _CartBar({required this.cartState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                '${cartState.totalItems}',
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
              'Rp ${_formatRp(cartState.grandTotal)}',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRp(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
