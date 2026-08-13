import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/core/models/models.dart';

class _CanteenStallInfo {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final bool isOpen;
  final String emoji;

  const _CanteenStallInfo({
    required this.id,
    required this.name,
    this.rating = 5.0,
    this.reviewsCount = 120,
    this.isOpen = true,
    this.emoji = '🏬',
  });
}

final List<_CanteenStallInfo> _presetStallsInfo = const [
  _CanteenStallInfo(id: 'semua', name: 'Semua Stan', rating: 5.0, reviewsCount: 450, isOpen: true, emoji: '🍽️'),
  _CanteenStallInfo(id: 'stan-utama', name: 'Stan Utama', rating: 5.0, reviewsCount: 120, isOpen: true, emoji: '🏬'),
  _CanteenStallInfo(id: 'bude-ani', name: 'Bude Ani', rating: 4.8, reviewsCount: 85, isOpen: true, emoji: '🍔'),
  _CanteenStallInfo(id: 'stan-bakso-enak', name: 'Stan Bakso Enak', rating: 4.7, reviewsCount: 60, isOpen: false, emoji: '🍲'),
  _CanteenStallInfo(id: 'stan-nasgor', name: 'Stan Nasgor', rating: 4.6, reviewsCount: 45, emoji: '🍟'),
  _CanteenStallInfo(id: 'stan-jus-segar', name: 'Stan Jus Segar', rating: 4.9, reviewsCount: 100, emoji: '🍹'),
];

class PublicMenuScreen extends ConsumerStatefulWidget {
  const PublicMenuScreen({super.key});

  @override
  ConsumerState<PublicMenuScreen> createState() => _PublicMenuScreenState();
}

class _PublicMenuScreenState extends ConsumerState<PublicMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCanteenId = 'semua';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Jalankan infinite scroll lazy loading saat mendekati bagian bawah halaman
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    final bool isSearchingOrFiltered = _selectedCategory != null || _searchQuery.isNotEmpty;
    if (isSearchingOrFiltered) {
      final filter = PaginatedProductsFilter(
        category: _selectedCategory,
        canteenId: _selectedCanteenId,
        searchQuery: _searchQuery,
      );
      ref.read(paginatedProductsProvider(filter).notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedCanteenId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canteensAsync = ref.watch(publicCanteensProvider);
    final allProductsAsync = ref.watch(publicMenuProvider(_selectedCategory));
    final bool isDesktop = Responsive.isDesktop(context) || MediaQuery.of(context).size.width >= 720;

    final _CanteenStallInfo semuaStall = const _CanteenStallInfo(
      id: 'semua',
      name: 'Semua Stan',
      rating: 5.0,
      reviewsCount: 450,
      isOpen: true,
      emoji: '🍽️',
    );

    List<_CanteenStallInfo> stalls = [semuaStall];
    canteensAsync.whenData((dbStalls) {
      if (dbStalls.isNotEmpty) {
        final mapped = dbStalls.asMap().entries.map((entry) {
          final idx = entry.key;
          final op = entry.value;
          final p = _presetStallsInfo[(idx + 1) % _presetStallsInfo.length];
          return _CanteenStallInfo(
            id: op.id,
            name: op.canteenName,
            rating: p.rating,
            reviewsCount: p.reviewsCount,
            isOpen: p.isOpen,
            emoji: p.emoji,
          );
        }).toList();
        stalls = [semuaStall, ...mapped];
      }
    });

    if (stalls.length == 1) {
      stalls = _presetStallsInfo;
    }

    final activeStall = stalls.firstWhere(
      (s) => s.id == (_selectedCanteenId ?? 'semua'),
      orElse: () => stalls.first,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Panel: Stalls List (Daftar Stan Kantin)
                      SizedBox(
                        width: 320,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: context.borderLight, width: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daftar Stan Kantin',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSearchInput(),
                              const SizedBox(height: 14),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: stalls.length,
                                  itemBuilder: (context, index) {
                                    final stall = stalls[index];
                                    final bool isSelected = stall.id == activeStall.id;
                                    return _buildStanCard(context, stall, isSelected);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Panel: Products for Selected Stall
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeStall.name,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCategorySelectorRow(),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _buildProductsListArea(context, ref, allProductsAsync, activeStall),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Stan Kantin',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSearchInput(),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: stalls.length,
                            itemBuilder: (context, index) {
                              final stall = stalls[index];
                              final bool isSelected = stall.id == activeStall.id;
                              return _buildStanCardHorizontal(context, stall, isSelected);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          activeStall.name,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCategorySelectorRow(),
                        const SizedBox(height: 16),
                        _buildProductsListAreaMobile(context, ref, allProductsAsync, activeStall),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
          ),

          // Floating Cart Banner
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildCartFab(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderLight, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari makanan, minuman...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: Starlight.dim),
          prefixIcon: const Icon(CupertinoIcons.search, color: Nebula.teal, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: _resetFilters,
                  child: const Icon(CupertinoIcons.clear_circled_solid, color: Starlight.dim, size: 16),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorRow() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('Semua Kategori', '🍽️', null),
          _buildCategoryChip('Makanan', '🍔', 'makanan'),
          _buildCategoryChip('Minuman', '🥤', 'minuman'),
          _buildCategoryChip('Camilan', '🍿', 'camilan'),
        ],
      ),
    );
  }

  Widget _buildStanCard(BuildContext context, _CanteenStallInfo stall, bool isSelected) {
    final bool isOpen = stall.isOpen;

    return PressScale(
      onTap: () {
        setState(() {
          _selectedCanteenId = stall.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: !isOpen
              ? (context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9))
              : isSelected
                  ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFE6F4F1))
                  : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderLight, width: 0.8),
              ),
              child: Center(
                child: Text(
                  stall.emoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: isOpen ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stall.name,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? context.textPrimary : context.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? const Color(0xFF166534) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFEAB308)),
                      const SizedBox(width: 4),
                      Text(
                        '${stall.rating} (${stall.reviewsCount} reviews)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStanCardHorizontal(BuildContext context, _CanteenStallInfo stall, bool isSelected) {
    final bool isOpen = stall.isOpen;

    return PressScale(
      onTap: () {
        setState(() {
          _selectedCanteenId = stall.id;
        });
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: !isOpen
              ? (context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9))
              : isSelected
                  ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFE6F4F1))
                  : context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(stall.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stall.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? context.textPrimary : context.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFEAB308)),
                      const SizedBox(width: 2),
                      Text(
                        '${stall.rating}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: context.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsListArea(BuildContext context, WidgetRef ref, AsyncValue<List<ProductWithCanteen>> productsAsync, _CanteenStallInfo activeStall) {
    return productsAsync.when(
      data: (dbItems) {
        var filtered = dbItems;

        if (_selectedCanteenId != null && _selectedCanteenId != 'semua') {
          filtered = filtered.where((item) => item.product.operatorId == _selectedCanteenId || item.canteenName.toLowerCase() == activeStall.name.toLowerCase()).toList();
        }

        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((item) => item.product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        final displayItems = filtered.isNotEmpty ? filtered : _getPresetProductsForStall(activeStall);

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            return _buildSquareProductCard(context, displayItems[index]);
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator(color: Nebula.teal)),
      error: (_, __) {
        final items = _getPresetProductsForStall(activeStall);
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildSquareProductCard(context, items[index]);
          },
        );
      },
    );
  }

  Widget _buildProductsListAreaMobile(BuildContext context, WidgetRef ref, AsyncValue<List<ProductWithCanteen>> productsAsync, _CanteenStallInfo activeStall) {
    return productsAsync.when(
      data: (dbItems) {
        var filtered = dbItems;
        if (_selectedCanteenId != null && _selectedCanteenId != 'semua') {
          filtered = filtered.where((item) => item.product.operatorId == _selectedCanteenId || item.canteenName.toLowerCase() == activeStall.name.toLowerCase()).toList();
        }
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((item) => item.product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }
        final displayItems = filtered.isNotEmpty ? filtered : _getPresetProductsForStall(activeStall);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            return _buildSquareProductCard(context, displayItems[index]);
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator(color: Nebula.teal)),
      error: (_, __) {
        final items = _getPresetProductsForStall(activeStall);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildSquareProductCard(context, items[index]);
          },
        );
      },
    );
  }

  Widget _buildSquareProductCard(BuildContext context, ProductWithCanteen item) {
    final product = item.product;
    final bool isAvailable = product.isAvailable;

    String? tagLabel;
    Color tagBg = Nebula.teal;
    Color tagText = Colors.white;

    final lowerName = product.name.toLowerCase();
    if (lowerName.contains('spesial') || lowerName.contains('nasi goreng') || lowerName.contains('komplit')) {
      tagLabel = 'Best Seller';
      tagBg = const Color(0xFF0D9488);
      tagText = Colors.white;
    } else if (lowerName.contains('mie') || lowerName.contains('promo') || product.price <= 12000) {
      tagLabel = 'Promo';
      tagBg = const Color(0xFFEA580C);
      tagText = Colors.white;
    }

    final String formattedPrice = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.55,
      child: PressScale(
        scale: 0.97,
        onTap: () => _showProductDetail(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                errorWidget: (_, __, ___) => _buildPlaceholderImage(product.category),
                              )
                            : _buildPlaceholderImage(product.category),
                      ),
                    ),
                    if (tagLabel != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tagLabel,
                            style: GoogleFonts.inter(
                              color: tagText,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 11, color: Nebula.teal),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  item.canteenName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Nebula.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getProductDescription(product),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: context.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rp $formattedPrice',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Nebula.teal,
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
    );
  }

  String _getProductDescription(Product product) {
    final lower = product.name.toLowerCase();
    if (lower.contains('nasi goreng')) {
      return 'Nasi goreng dengan telur, sosis, dan bakso';
    } else if (lower.contains('mie ayam')) {
      return 'Mie ayam lengkap dengan bakso daging sapi';
    } else if (lower.contains('es jeruk') || lower.contains('jeruk')) {
      return 'Perasan jeruk asli dengan es';
    } else if (lower.contains('bakso')) {
      return 'Bakso sapi dengan mie, bihun, dan sayuran';
    } else if (lower.contains('geprek')) {
      return 'Ayam geprek pedas dengan sambal ijo khas';
    } else if (lower.contains('soto')) {
      return 'Soto ayam gurih kaya rempah dengan koya dan kuah hangat';
    } else if (lower.contains('jus')) {
      return 'Jus buah segar racikan alami tanpa pemanis buatan';
    }
    return 'Menu sehat dan lezat siap dinikmati langsung dari kantin sekolah';
  }

  List<ProductWithCanteen> _getPresetProductsForStall(_CanteenStallInfo stall) {
    if (stall.id == 'semua') {
      return [
        ..._getPresetProductsForStall(const _CanteenStallInfo(id: 'stan-utama', name: 'Stan Utama')),
        ..._getPresetProductsForStall(const _CanteenStallInfo(id: 'bude-ani', name: 'Bude Ani')),
        ..._getPresetProductsForStall(const _CanteenStallInfo(id: 'stan-jus-segar', name: 'Stan Jus Segar')),
        ..._getPresetProductsForStall(const _CanteenStallInfo(id: 'stan-bakso-enak', name: 'Stan Bakso Enak')),
        ..._getPresetProductsForStall(const _CanteenStallInfo(id: 'stan-nasgor', name: 'Stan Nasgor')),
      ];
    }
    if (stall.id == 'stan-bakso-enak') {
      return [
        ProductWithCanteen(
          product: const Product(
            id: 'p-bakso-1',
            operatorId: 'stan-bakso-enak',
            name: 'Bakso Komplit Spesial',
            price: 18000,
            category: 'makanan',
            isAvailable: false,
            customizableOptions: ['Pedas', 'Sedang', 'Tanpa Sambal'],
          ),
          canteenName: stall.name,
        ),
        ProductWithCanteen(
          product: const Product(
            id: 'p-bakso-2',
            operatorId: 'stan-bakso-enak',
            name: 'Mie Bakso Urat',
            price: 15000,
            category: 'makanan',
            isAvailable: false,
          ),
          canteenName: stall.name,
        ),
      ];
    }

    if (stall.id == 'bude-ani') {
      return [
        ProductWithCanteen(
          product: const Product(
            id: 'p-bude-1',
            operatorId: 'bude-ani',
            name: 'Soto Ayam Madura',
            price: 14000,
            category: 'makanan',
            isAvailable: true,
          ),
          canteenName: stall.name,
        ),
        ProductWithCanteen(
          product: const Product(
            id: 'p-bude-2',
            operatorId: 'bude-ani',
            name: 'Nasi Rames Bude',
            price: 12000,
            category: 'makanan',
            isAvailable: true,
          ),
          canteenName: stall.name,
        ),
      ];
    }

    if (stall.id == 'stan-jus-segar') {
      return [
        ProductWithCanteen(
          product: const Product(
            id: 'p-jus-1',
            operatorId: 'stan-jus-segar',
            name: 'Es Jeruk Segar',
            price: 5000,
            category: 'minuman',
            isAvailable: true,
          ),
          canteenName: stall.name,
        ),
        ProductWithCanteen(
          product: const Product(
            id: 'p-jus-2',
            operatorId: 'stan-jus-segar',
            name: 'Jus Alpukat Kocok',
            price: 8000,
            category: 'minuman',
            isAvailable: true,
          ),
          canteenName: stall.name,
        ),
      ];
    }

    return [
      ProductWithCanteen(
        product: const Product(
          id: 'p1',
          operatorId: 'stan-utama',
          name: 'Nasi Goreng Spesial',
          price: 15000,
          category: 'makanan',
          isAvailable: true,
          customizableOptions: ['Tingkat Kepedasan Saus Sambal', 'Saus Tomat', 'Telur Dadar'],
        ),
        canteenName: 'Stan Utama',
      ),
      ProductWithCanteen(
        product: const Product(
          id: 'p2',
          operatorId: 'stan-utama',
          name: 'Mie Ayam Bakso',
          price: 12000,
          category: 'makanan',
          isAvailable: true,
          customizableOptions: ['Sambal Extra', 'Pangsit Goreng'],
        ),
        canteenName: 'Stan Utama',
      ),
      ProductWithCanteen(
        product: const Product(
          id: 'p3',
          operatorId: 'stan-utama',
          name: 'Es Jeruk Segar',
          price: 5000,
          category: 'minuman',
          isAvailable: true,
          customizableOptions: ['Es Batu Separuh (Less Ice)', 'Tanpa Es (No Ice)', 'Sedikit Manis (50% Sugar)'],
        ),
        canteenName: 'Stan Utama',
      ),
      ProductWithCanteen(
        product: const Product(
          id: 'p4',
          operatorId: 'stan-utama',
          name: 'Bakso Komplit',
          price: 18000,
          category: 'makanan',
          isAvailable: true,
        ),
        canteenName: 'Stan Utama',
      ),
      ProductWithCanteen(
        product: const Product(
          id: 'p5',
          operatorId: 'stan-utama',
          name: 'Ayam Geprek Sambal Ijo',
          price: 27000,
          category: 'makanan',
          isAvailable: true,
          customizableOptions: ['Level Pedas 1-5', 'Tahu Tempe'],
        ),
        canteenName: 'Stan Utama',
      ),
    ];
  }

  Widget _buildCartFab(WidgetRef ref) {
    final cart = ref.watch(studentCartProvider);
    final int itemCount = cart.totalItems;

    if (itemCount == 0) return const SizedBox.shrink();

    final String formattedPrice = cart.totalAmount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return PressScale(
      onTap: () => context.push('/student/cart'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Nebula.teal,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Nebula.teal.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$itemCount Items | Total Rp $formattedPrice',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.arrow_right,
                size: 14,
                color: Nebula.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String emoji, String? val) {
    final bool isSelected = _selectedCategory == val;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = val;
        });
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Nebula.teal : Starlight.dim.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Nebula.teal.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Nebula.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPlaceholderImage(String category) {
    final bool isMakanan = category == 'makanan';
    final bool isMinuman = category == 'minuman';
    Gradient grad;
    IconData icon;

    if (isMakanan) {
      grad = const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = CupertinoIcons.flame_fill;
    } else if (isMinuman) {
      grad = const LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = CupertinoIcons.drop_fill;
    } else {
      grad = const LinearGradient(
        colors: [Color(0xFFFFEB3B), Color(0xFFFF9800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = CupertinoIcons.gift_fill;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: grad,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 32,
          color: context.cardBg.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context, ProductWithCanteen item) {
    final product = item.product;
    final bool isAvailable = product.isAvailable;
    final authState = ref.read(authNotifierProvider);
    final bool isStudent = authState.isAuthenticated && authState.profile?['role'] == 'student';
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Starlight.dim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Nebula.teal)),
                          errorWidget: (_, __, ___) => _buildDetailFallbackImage(product.category),
                        )
                      : _buildDetailFallbackImage(product.category),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: Nebula.teal, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        item.canteenName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Nebula.teal,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Nebula.teal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                product.name,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Nebula.teal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAvailable ? Nebula.teal.withValues(alpha: 0.12) : Nebula.rose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAvailable ? 'Tersedia' : 'Habis / Kosong',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAvailable ? Nebula.teal : Nebula.rose,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 24, thickness: 1, color: context.borderLight),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Nebula.teal.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Nebula.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Panduan Belanja',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jajanan ini dibeli secara langsung di stan kantin sekolah. Kunjungi ${item.canteenName} dan tempelkan (tap) kartu RFID Anda pada mesin kasir pedagang untuk memproses pembayaran.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.45,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (isStudent)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Nebula.teal, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isAvailable
                              ? () {
                                  Navigator.pop(context); // Close the detail sheet
                                  _showCustomizationSheet(context, ref, product, item);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            foregroundColor: context.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Pesan Makanan',
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      foregroundColor: context.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Mengerti',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  },
);
}

  void _showCustomizationSheet(
    BuildContext context,
    WidgetRef ref,
    Product product,
    dynamic item,
  ) {
    // Classification helpers
    bool isSpiciness(String option) {
      final lower = option.toLowerCase();
      return (lower.contains('level') ||
              lower.contains('pedas') ||
              lower.contains('spicy') ||
              lower.contains('cabe') ||
              lower.contains('cabai') ||
              (lower.contains('sambal') && !lower.contains('tomat') && !lower.contains('tiram') && !lower.contains('barbekyu') && !lower.contains('teriyaki')) ||
              lower.contains('chili') ||
              lower.contains('chilli')) &&
          !lower.contains('saus');
    }

    bool isSauce(String option) {
      final lower = option.toLowerCase();
      return !isSpiciness(option) && (
        lower.contains('saus') ||
        lower.contains('sauce') ||
        lower.contains('tiram') ||
        lower.contains('barbekyu') ||
        lower.contains('barbecue') ||
        lower.contains('teriyaki') ||
        lower.contains('mayo') ||
        lower.contains('mayonnaise')
      );
    }

    bool isVegetable(String option) {
      final lower = option.toLowerCase();
      return !isSpiciness(option) && !isSauce(option) && (
        lower.contains('tomat') ||
        lower.contains('timun') ||
        lower.contains('bayam') ||
        lower.contains('selada') ||
        lower.contains('kubis') ||
        lower.contains('kol') ||
        lower.contains('kemangi') ||
        lower.contains('kangkung') ||
        lower.contains('wortel') ||
        lower.contains('terong') ||
        lower.contains('bawang') ||
        lower.contains('paprika') ||
        lower.contains('sayur') ||
        lower.contains('lalap') ||
        lower.contains('cucumber') ||
        lower.contains('lettuce') ||
        lower.contains('tomato')
      );
    }

    int getToppingPrice(String option) {
      final regExp = RegExp(r'\(\+Rp\s*([0-9\.]+)\)');
      final match = regExp.firstMatch(option);
      if (match != null) {
        final cleanDigits = match.group(1)!.replaceAll('.', '');
        return int.tryParse(cleanDigits) ?? 0;
      }
      
      final regExpFallback = RegExp(r'\(\+([0-9\.]+)\)');
      final matchFallback = regExpFallback.firstMatch(option);
      if (matchFallback != null) {
        final cleanDigits = matchFallback.group(1)!.replaceAll('.', '');
        return int.tryParse(cleanDigits) ?? 0;
      }
      
      return 0;
    }

    String formatWithDots(int value) {
      final String str = value.toString();
      final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    }

    Map<String, dynamic> parseOptionDetails(String option) {
      final price = getToppingPrice(option);
      String imageUrl = '';
      final imgReg = RegExp(r'\[img:\s*([^\]]+)\]');
      final imgMatch = imgReg.firstMatch(option);
      if (imgMatch != null) {
        imageUrl = imgMatch.group(1)!.trim();
      }

      String name = option
          .replaceAll(imgReg, '')
          .replaceAll(RegExp(r'\s*\(\+Rp\s*[0-9\.]+\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\(\+[0-9\.]+\)', caseSensitive: false), '')
          .trim();
      return {
        'name': name.isEmpty ? option : name,
        'price': price,
        'imageUrl': imageUrl,
      };
    }

    String getOptionEmoji(String option) {
      final lower = option.toLowerCase();
      if (lower.contains('udang')) return '🦐';
      if (lower.contains('telur')) return '🍳';
      if (lower.contains('meatball') || lower.contains('bakso')) return '🧆';
      if (lower.contains('cucumber') || lower.contains('timun')) return '🥒';
      if (lower.contains('tomato') || lower.contains('tomat')) return '🍅';
      if (lower.contains('lettuce') || lower.contains('selada')) return '🥬';
      if (lower.contains('sayur')) return '🥗';
      if (lower.contains('sosis')) return '🌭';
      if (lower.contains('keju')) return '🧀';
      if (lower.contains('cokelat') || lower.contains('chocolate')) return '🍫';
      if (lower.contains('susu')) return '🥛';
      if (lower.contains('level 1')) return '🌶️';
      if (lower.contains('level 2')) return '🌶️🌶️';
      if (lower.contains('level 3')) return '🌶️🌶️🌶️';
      if (lower.contains('pedas')) return '🌶️';
      return '🍽️';
    }

    // Separate options
    final List<String> spicinessOptions = [];
    final List<String> vegetableOptions = [];
    final List<String> toppingOptions = [];

    // Check if any option is spiciness/chili/sambal/saus
    bool hasSpicinessOption = false;
    int spicinessPrice = 0;
    bool hasExplicitLevels = false;

    for (final opt in product.customizableOptions) {
      if (isSpiciness(opt)) {
        hasSpicinessOption = true;
        final price = getToppingPrice(opt);
        if (price > spicinessPrice) {
          spicinessPrice = price;
        }
        final lower = opt.toLowerCase();
        if (lower.contains('level') || lower.contains('tingkat')) {
          hasExplicitLevels = true;
        }
      }
    }

    // Populate spiciness options
    if (hasSpicinessOption) {
      if (hasExplicitLevels) {
        // Use the explicit level options added by the canteen operator
        for (final opt in product.customizableOptions) {
          if (isSpiciness(opt)) {
            spicinessOptions.add(opt);
          }
        }
      } else {
        // Auto-generate levels for generic options like sambal, saus, cabe
        spicinessOptions.addAll([
          'Biasa (Bebas Cabai)',
          'Level 1 🌶️',
          'Level 2 🌶️🌶️',
          'Level 3 🌶️🌶️🌶️',
        ]);
      }
    }

    // Populate other options (excluding any that are categorized as spiciness)
    for (final opt in product.customizableOptions) {
      if (isSpiciness(opt)) {
        // Already handled in spicinessOptions
        continue;
      }
      
      if (isVegetable(opt)) {
        vegetableOptions.add(opt);
      } else {
        toppingOptions.add(opt);
      }
    }

    final Map<String, int> toppingQuantities = {};
    for (final opt in product.customizableOptions) {
      toppingQuantities[opt] = 0;
    }
    
    String? selectedSpiciness;
    if (spicinessOptions.isNotEmpty) {
      selectedSpiciness = spicinessOptions[0]; // default to first spiciness level
    }

    int quantity = 1;
    String deliveryMethod = 'pickup';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            int toppingsPrice = 0;
            if (selectedSpiciness != null) {
              if (hasExplicitLevels) {
                toppingsPrice += getToppingPrice(selectedSpiciness!);
              } else {
                if (selectedSpiciness != 'Biasa (Bebas Cabai)') {
                  toppingsPrice += spicinessPrice;
                }
              }
            }
            for (final opt in vegetableOptions) {
              if ((toppingQuantities[opt] ?? 0) > 0) {
                toppingsPrice += getToppingPrice(opt);
              }
            }
            for (final opt in toppingOptions) {
              final qty = toppingQuantities[opt] ?? 0;
              if (qty > 0) {
                toppingsPrice += getToppingPrice(opt) * qty;
              }
            }
            final int itemPrice = product.price + toppingsPrice;
            final int totalPrice = itemPrice * quantity;

            return Container(
              decoration: BoxDecoration(
                color: context.isDark ? context.surfaceBg : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle Indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Starlight.dim.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Content (Scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER IMAGE WRAPPER (Matching login.html)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: product.imageUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Nebula.teal)),
                                            errorWidget: (_, __, ___) => _buildDetailFallbackImage(product.category),
                                          )
                                        : _buildDetailFallbackImage(product.category),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.85),
                                            Colors.black.withValues(alpha: 0.25),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 14,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          product.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront_rounded, color: Colors.white70, size: 15),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.canteenName,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(alpha: 0.95),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('•', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Rp ${formatWithDots(product.price)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (product.customizableOptions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.borderLight, width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Menu ini tidak menyediakan pilihan toping kustom.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          // 1. Tingkat Kepedasan Section
                          if (spicinessOptions.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  '1  Tingkat Kepedasan ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  '- Pilih salah satu',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.3,
                              ),
                              itemCount: spicinessOptions.length,
                              itemBuilder: (context, index) {
                                final opt = spicinessOptions[index];
                                final bool isSelected = selectedSpiciness == opt;
                                final parsed = parseOptionDetails(opt);
                                final String cleanName = parsed['name'];
                                int price = parsed['price'];
                                if (price == 0 && !hasExplicitLevels && opt != 'Biasa (Bebas Cabai)') {
                                  price = spicinessPrice;
                                }
                                final String emoji = getOptionEmoji(opt);
                                final String subtitleText = opt == 'Biasa (Bebas Cabai)' || opt == 'Biasa'
                                    ? 'Bebas Cabai'
                                    : (price > 0 ? '+Rp ${formatWithDots(price)}' : 'Gratis');

                                return GestureDetector(
                                  onTap: () {
                                    setLocalState(() {
                                      selectedSpiciness = opt;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFF1F5F9))
                                          : (context.isDark ? context.cardBg : Colors.white),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? (context.isDark ? Nebula.teal : const Color(0xFF0F172A)) : context.borderLight,
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          size: 20,
                                          color: isSelected
                                              ? (context.isDark ? Nebula.teal : const Color(0xFF0F172A))
                                              : context.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$cleanName $emoji'.trim(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitleText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: context.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 2. Pilihan Topping Section
                          if (toppingOptions.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  '2  Pilihan Topping ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  '- Boleh lebih dari satu',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: List.generate(toppingOptions.length, (i) {
                                final opt = toppingOptions[i];
                                final count = toppingQuantities[opt] ?? 0;
                                final parsed = parseOptionDetails(opt);
                                final String name = parsed['name'];
                                final int price = parsed['price'];
                                final String imageUrl = parsed['imageUrl'] ?? '';
                                final String emoji = getOptionEmoji(opt);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                        ),
                                        child: imageUrl.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(21),
                                                child: CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => const Center(child: CupertinoActivityIndicator(radius: 8)),
                                                  errorWidget: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                                                ),
                                              )
                                            : Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              price > 0 ? '+Rp ${formatWithDots(price)}' : 'Gratis',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: price > 0 ? const Color(0xFF0F766E) : context.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (count > 0) {
                                                setLocalState(() {
                                                  toppingQuantities[opt] = count - 1;
                                                });
                                              }
                                            },
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: context.borderLight, width: 1.5),
                                                color: context.isDark ? context.cardBg : Colors.white,
                                              ),
                                              child: Icon(Icons.remove, size: 16, color: count > 0 ? context.textPrimary : context.textSecondary),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 44,
                                            child: TextFormField(
                                              key: ValueKey('topping_${opt}_$count'),
                                              initialValue: '$count',
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: context.textPrimary,
                                              ),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                                border: InputBorder.none,
                                                focusedBorder: UnderlineInputBorder(
                                                  borderSide: BorderSide(color: Nebula.teal, width: 1.5),
                                                ),
                                              ),
                                              onChanged: (val) {
                                                final parsed = int.tryParse(val);
                                                if (parsed != null && parsed >= 0) {
                                                  toppingQuantities[opt] = parsed;
                                                  setLocalState(() {});
                                                } else if (val.isEmpty) {
                                                  toppingQuantities[opt] = 0;
                                                  setLocalState(() {});
                                                }
                                              },
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setLocalState(() {
                                                toppingQuantities[opt] = count + 1;
                                              });
                                            },
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                                                color: context.isDark ? context.cardBg : Colors.white,
                                              ),
                                              child: const Icon(Icons.add, size: 16, color: Color(0xFF0F172A)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 3. Lalapan & Sayuran Section
                          if (vegetableOptions.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  '3  Lalapan & Sayuran ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  '- Bisa pilih keduanya',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.3,
                              ),
                              itemCount: vegetableOptions.length,
                              itemBuilder: (context, index) {
                                final opt = vegetableOptions[index];
                                final isSelected = (toppingQuantities[opt] ?? 0) > 0;
                                final parsed = parseOptionDetails(opt);
                                final String name = parsed['name'];
                                final int price = parsed['price'];
                                final String imageUrl = parsed['imageUrl'] ?? '';
                                final String emoji = getOptionEmoji(opt);

                                return GestureDetector(
                                  onTap: () {
                                    setLocalState(() {
                                      toppingQuantities[opt] = isSelected ? 0 : 1;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFF1F5F9))
                                          : (context.isDark ? context.cardBg : Colors.white),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0F172A) : context.borderLight,
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                          ),
                                          child: imageUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(17),
                                                  child: CachedNetworkImage(
                                                    imageUrl: imageUrl,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) => const Center(child: CupertinoActivityIndicator(radius: 8)),
                                                    errorWidget: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                                                  ),
                                                )
                                              : Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                price > 0 ? '+Rp ${formatWithDots(price)}' : 'Gratis',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: context.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check, size: 16, color: Color(0xFF0F172A)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 4. Metode Pengiriman Section
                          Row(
                            children: [
                              Text(
                                '4  Metode Pengiriman',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setLocalState(() {
                                      deliveryMethod = 'pickup';
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: deliveryMethod == 'pickup'
                                          ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFF1F5F9))
                                          : (context.isDark ? context.cardBg : Colors.white),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: deliveryMethod == 'pickup' ? const Color(0xFF0F172A) : context.borderLight,
                                        width: deliveryMethod == 'pickup' ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.storefront_rounded,
                                          color: deliveryMethod == 'pickup' ? const Color(0xFF0F766E) : context.textSecondary,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Ambil di Kantin',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setLocalState(() {
                                      deliveryMethod = 'delivery';
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: deliveryMethod == 'delivery'
                                          ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFF1F5F9))
                                          : (context.isDark ? context.cardBg : Colors.white),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: deliveryMethod == 'delivery' ? const Color(0xFF0F766E) : context.borderLight,
                                        width: deliveryMethod == 'delivery' ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.delivery_dining,
                                          color: deliveryMethod == 'delivery' ? const Color(0xFF0F766E) : context.textSecondary,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Antar ke Tempat',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Jumlah Pesanan & Stepper Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jumlah Pesanan',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rp ${formatWithDots(itemPrice)} / porsi',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (quantity > 1) {
                                        setLocalState(() {
                                          quantity--;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: context.borderLight, width: 1.5),
                                        color: context.isDark ? context.cardBg : Colors.white,
                                      ),
                                      child: Icon(Icons.remove, size: 16, color: quantity > 1 ? context.textPrimary : context.textSecondary),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: TextFormField(
                                      key: ValueKey('main_qty_$quantity'),
                                      initialValue: '$quantity',
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                        border: InputBorder.none,
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Nebula.teal, width: 1.5),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val);
                                        if (parsed != null && parsed > 0) {
                                          quantity = parsed;
                                          setLocalState(() {});
                                        } else if (val.isEmpty) {
                                          quantity = 1;
                                          setLocalState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setLocalState(() {
                                        quantity++;
                                      });
                                    },
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                                        color: context.isDark ? context.cardBg : Colors.white,
                                      ),
                                      child: const Icon(Icons.add, size: 16, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // RINGKASAN Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderLight.withValues(alpha: 0.5), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RINGKASAN',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Harga dasar',
                                      style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                                    ),
                                    Text(
                                      'Rp ${formatWithDots(product.price * quantity)}',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
                                    ),
                                  ],
                                ),
                                if (toppingsPrice > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Topping',
                                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                                      ),
                                      Text(
                                        '+Rp ${formatWithDots(toppingsPrice * quantity)}',
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Divider(height: 1, color: context.borderLight),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: context.textPrimary),
                                    ),
                                    Text(
                                      'Rp ${formatWithDots(totalPrice)}',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  
                  Divider(height: 1, thickness: 1, color: context.borderLight),
                  
                  // Sticky bottom bar (Matching login.html .footer-actions)
                  Container(
                    decoration: BoxDecoration(
                      color: context.isDark ? context.cardBg : Colors.white,
                      border: Border(top: BorderSide(color: context.borderLight, width: 1)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Row(
                      children: [
                        Text(
                          '$quantity item',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: context.textSecondary.withValues(alpha: 0.6), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Batal',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final List<String> finalSelectedOptions = [];
                                      
                                      // 1. Spiciness option
                                      if (selectedSpiciness != null) {
                                        if (hasSpicinessOption) {
                                          if (hasExplicitLevels) {
                                            finalSelectedOptions.add(selectedSpiciness!);
                                          } else {
                                            if (selectedSpiciness != 'Biasa (Bebas Cabai)') {
                                              final originalOpt = product.customizableOptions.firstWhere((o) => isSpiciness(o), orElse: () => 'Pedas');
                                              final cleanName = originalOpt.split(' (+Rp').first.trim();
                                              finalSelectedOptions.add("$cleanName ($selectedSpiciness)");
                                            }
                                          }
                                        } else {
                                          finalSelectedOptions.add(selectedSpiciness!);
                                        }
                                      }
                                      
                                      // 2. Vegetable options
                                      for (final opt in vegetableOptions) {
                                        if ((toppingQuantities[opt] ?? 0) > 0) {
                                          final cleanOpt = opt.replaceAll(RegExp(r'\[img:\s*([^\]]+)\]'), '').trim();
                                          finalSelectedOptions.add(cleanOpt);
                                        }
                                      }
                                      
                                      // 3. Toppings
                                      for (final opt in toppingOptions) {
                                        final qty = toppingQuantities[opt] ?? 0;
                                        if (qty > 0) {
                                          final cleanOpt = opt.replaceAll(RegExp(r'\[img:\s*([^\]]+)\]'), '').trim();
                                          finalSelectedOptions.add("$cleanOpt (${qty}x)");
                                        }
                                      }

                                      ref.read(studentCartProvider.notifier).setDeliveryMethod(deliveryMethod);
                                      ref.read(studentCartProvider.notifier).addProduct(
                                            product.id,
                                            product.name,
                                            itemPrice,
                                            quantity: quantity,
                                            selectedOptions: finalSelectedOptions,
                                          );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$quantity x ${product.name} dimasukkan ke keranjang',
                                            style: GoogleFonts.inter(),
                                          ),
                                          backgroundColor: Nebula.teal,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '+ Keranjang  ·  Rp ${formatWithDots(totalPrice)}',
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailFallbackImage(String category) {
    final String catLower = category.toLowerCase();
    String fallbackUrl = 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?q=80&w=1000&auto=format&fit=crop';
    if (catLower.contains('minum')) {
      fallbackUrl = 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?q=80&w=1000&auto=format&fit=crop';
    } else if (catLower.contains('snack') || catLower.contains('camilan')) {
      fallbackUrl = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=1000&auto=format&fit=crop';
    }

    return CachedNetworkImage(
      imageUrl: fallbackUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Nebula.teal)),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFFFF9800),
        child: const Center(
          child: Icon(Icons.fastfood_rounded, size: 48, color: Colors.white),
        ),
      ),
    );
  }
}