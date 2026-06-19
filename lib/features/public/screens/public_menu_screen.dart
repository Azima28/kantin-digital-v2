import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ─── Provider untuk fetch menu publik ───
final publicMenuProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, category) async {
  final client = ref.read(supabaseClientProvider);

  List<dynamic> res;
  if (category != null && category.isNotEmpty) {
    res = await client
        .from('products')
        .select(
            'id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
        .eq('is_available', true)
        .eq('category', category)
        .order('name', ascending: true);
  } else {
    res = await client
        .from('products')
        .select(
            'id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
        .eq('is_available', true)
        .order('name', ascending: true);
  }

  return List<Map<String, dynamic>>.from(res);
});

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
  final List<String> _tabLabels = ['Semua', 'Makanan', 'Minuman'];

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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF003434)),
          onPressed: () => context.go('/public'),
        ),
        title: Text(
          'Menu Kantin',
          style: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF003434),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => context.go('/login?from=/public/menu'),
              child: Text(
                'Login',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF003434),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF003434),
          unselectedLabelColor: const Color(0xFF6F7978),
          indicatorColor: const Color(0xFF003434),
          indicatorWeight: 2,
          labelStyle: GoogleFonts.beVietnamPro(
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
                    size: 48, color: Color(0xFFC7C7CC)),
                const SizedBox(height: 12),
                Text(
                  'Belum ada menu tersedia',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 15, color: const Color(0xFF6F7978)),
                ),
              ],
            ),
          );
        }

        // Group by canteen
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final item in items) {
          final String canteen =
              item['canteen_operators']?['canteen_name'] as String? ??
                  'Stan Lainnya';
          grouped.putIfAbsent(canteen, () => []).add(item);
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
                              const Color(0xFF003434).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.house,
                            size: 14, color: Color(0xFF003434)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canteen,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF003434),
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
          child: CupertinoActivityIndicator(color: Color(0xFF003434))),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.wifi_slash,
                size: 48, color: Color(0xFFC7C7CC)),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat menu: $e',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13, color: const Color(0xFF6F7978)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final String name = product['name'] as String? ?? '-';
    final double price =
        double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final String category = product['category'] as String? ?? 'makanan';
    final String? imageUrl = product['image_url'] as String?;
    final bool isAvailable = product['is_available'] as bool? ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(category),
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
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006767),
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Habis',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 9,
                              color: const Color(0xFFBA1A1A),
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
          ? const Color(0xFFFFF3E8)
          : const Color(0xFFE8F4FF),
      child: Icon(
        isMakanan ? CupertinoIcons.flame : CupertinoIcons.drop,
        size: 40,
        color: isMakanan
            ? const Color(0xFF904D00).withValues(alpha: 0.5)
            : const Color(0xFF0066CC).withValues(alpha: 0.5),
      ),
    );
  }
}
