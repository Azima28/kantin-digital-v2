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
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

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

class _PromoBannerItemData {
  final ProductWithCanteen item;
  final List<Color> gradient;
  final IconData icon;

  const _PromoBannerItemData({
    required this.item,
    required this.gradient,
    required this.icon,
  });
}

final List<List<Color>> _promoGradients = const [
  [Color(0xFF0D9488), Color(0xFF14B8A6)],
  [Color(0xFF2563EB), Color(0xFF38BDF8)],
  [Color(0xFFD97706), Color(0xFFF59E0B)],
  [Color(0xFFE11D48), Color(0xFFFB7185)],
  [Color(0xFF7C3AED), Color(0xFFA78BFA)],
  [Color(0xFF4F46E5), Color(0xFF818CF8)],
  [Color(0xFFC2410C), Color(0xFFFB923C)],
  [Color(0xFF059669), Color(0xFF34D399)],
];

final List<_CanteenStallInfo> _presetStallsInfo = const [
  _CanteenStallInfo(id: 'semua', name: 'Semua Stan', rating: 5.0, reviewsCount: 450, isOpen: true, emoji: '🍽️'),
  _CanteenStallInfo(id: 'stan-utama', name: 'Stan Utama', rating: 5.0, reviewsCount: 120, isOpen: true, emoji: '🏬'),
  _CanteenStallInfo(id: 'bude-ani', name: 'Bude Ani', rating: 4.8, reviewsCount: 85, isOpen: true, emoji: '🍔'),
  _CanteenStallInfo(id: 'stan-bakso-enak', name: 'Stan Bakso Enak', rating: 4.7, reviewsCount: 60, isOpen: false, emoji: '🍲'),
  _CanteenStallInfo(id: 'stan-nasgor', name: 'Stan Nasgor', rating: 4.6, reviewsCount: 45, emoji: '🍟'),
  _CanteenStallInfo(id: 'stan-jus-segar', name: 'Stan Jus Segar', rating: 4.9, reviewsCount: 100, emoji: '🍹'),
];

class PublicMenuScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? initialCanteenId;

  const PublicMenuScreen({
    super.key,
    this.initialSearch,
    this.initialCanteenId,
  });

  @override
  ConsumerState<PublicMenuScreen> createState() => _PublicMenuScreenState();
}

class _PublicMenuScreenState extends ConsumerState<PublicMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final PageController _promoPageController = PageController(
    initialPage: 0,
    viewportFraction: 1.0,
  );
  Timer? _promoTimer;
  int _promoIndex = 0;
  List<_PromoBannerItemData> _randomPromoBanners = [];

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCanteenId = 'semua';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startPromoTimer();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
      _searchQuery = widget.initialSearch!;
    }
    if (widget.initialCanteenId != null && widget.initialCanteenId!.isNotEmpty) {
      _selectedCanteenId = widget.initialCanteenId!;
    }
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_randomPromoBanners.length > 1 && _promoPageController.hasClients && _promoPageController.page != null) {
        final currentPage = _promoPageController.page!.round();
        final nextPage = (currentPage + 1) % _randomPromoBanners.length;
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<_PromoBannerItemData> _generateRandomPromos(List<ProductWithCanteen> allProducts) {
    final presetList = _getPresetProductsForStall(const _CanteenStallInfo(id: 'semua', name: 'Semua Stan'));
    final List<ProductWithCanteen> pool = [
      ...allProducts.where((p) => p.product.isAvailable),
      ...presetList,
    ];

    final Map<String, ProductWithCanteen> uniqueMap = {};
    for (var p in pool) {
      uniqueMap[p.product.id] = p;
    }
    final List<ProductWithCanteen> uniqueList = uniqueMap.values.toList();

    final withImages = uniqueList.where((p) => p.product.imageUrl != null && p.product.imageUrl!.isNotEmpty).toList()..shuffle();
    final withoutImages = uniqueList.where((p) => p.product.imageUrl == null || p.product.imageUrl!.isEmpty).toList()..shuffle();

    final combined = [...withImages, ...withoutImages];
    final int countToTake = combined.length >= 7 ? (combined.length > 8 ? 8 : combined.length) : combined.length;
    final selectedItems = combined.take(countToTake).toList()..shuffle();

    return List.generate(selectedItems.length, (index) {
      final item = selectedItems[index];
      final cat = item.product.category.toLowerCase();
      IconData icon;

      if (cat == 'minuman' || item.product.name.toLowerCase().contains('jus') || item.product.name.toLowerCase().contains('es')) {
        icon = CupertinoIcons.drop_fill;
      } else if (cat == 'camilan' || item.product.name.toLowerCase().contains('snack') || item.product.name.toLowerCase().contains('roti')) {
        icon = CupertinoIcons.gift_fill;
      } else {
        icon = CupertinoIcons.flame_fill;
      }

      final gradient = _promoGradients[index % _promoGradients.length];

      return _PromoBannerItemData(
        item: item,
        gradient: gradient,
        icon: icon,
      );
    });
  }

  void _checkAutoOpenDetail(List<ProductWithCanteen> items) {
    // Search results are rendered directly in the grid without forced modal push
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoPageController.dispose();
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
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
    final allProductsAsync = ref.watch(publicMenuProvider(null));
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(publicMenuProvider(null));
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Full-Bleed Hero Promo Banner with Overlapping Top Nav and Floating Search Bar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildPromoBannerCarousel(allProductsAsync, activeStall),
                            Positioned(
                              top: 14,
                              left: 16,
                              right: 16,
                              child: _buildTopHeroNav(context),
                            ),
                            Positioned(
                              bottom: -22,
                              left: 16,
                              right: 16,
                              child: _buildSearchInput(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 38),

                        // 2. Section 1: "Sambil kumpul bareng teman" (6 items Horizontal Slider)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPopularSliderSection(allProductsAsync, activeStall),
                        ),
                        const SizedBox(height: 24),

                        // 3. Section 2: "Kuliner sesuai seleramu" (Categories)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildKulinerSesuaiSeleramuSection(),
                        ),
                        const SizedBox(height: 24),

                        // 4. Section 3: Product List in Card Panjang (1x1 List View)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          child: _buildProductsListArea(context, ref, allProductsAsync, activeStall, isDesktop),
                        ),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildTopHeroNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back / Close Circle Button
        GestureDetector(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student');
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.clear, size: 18, color: Colors.black87),
          ),
        ),

        // Location Pill Badge (GoFood style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(CupertinoIcons.location_solid, color: Colors.white, size: 13),
              SizedBox(width: 6),
              Text(
                'Kantin Sekolah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Action icons (Bell & Orders shortcut)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => context.push('/student/notifications'),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.bell, size: 18, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/student/active-orders'),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.doc_text, size: 18, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Lagi mau jajan apa hari ini?',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
          prefixIcon: const Icon(CupertinoIcons.search, color: Nebula.teal, size: 19),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: _resetFilters,
                  child: const Icon(CupertinoIcons.clear_circled_solid, color: Starlight.dim, size: 16),
                )
              : const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.restaurant, color: Nebula.teal, size: 20),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPromoBannerCarousel(AsyncValue<List<ProductWithCanteen>> productsAsync, _CanteenStallInfo activeStall) {
    return productsAsync.when(
      data: (dbProducts) {
        final List<ProductWithCanteen> availableProducts = dbProducts.isNotEmpty
            ? dbProducts
            : _getPresetProductsForStall(activeStall);

        // Regenerate if empty or if db products arrived with real images
        final bool hadDbImages = _randomPromoBanners.any((b) => dbProducts.any((p) => p.product.id == b.item.product.id && p.product.imageUrl != null && p.product.imageUrl!.isNotEmpty));
        if (_randomPromoBanners.isEmpty || (!hadDbImages && dbProducts.any((p) => p.product.imageUrl != null && p.product.imageUrl!.isNotEmpty))) {
          _randomPromoBanners = _generateRandomPromos(availableProducts);
        }

        if (_randomPromoBanners.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          height: 230,
          child: Stack(
            children: [
              Listener(
                onPointerDown: (_) => _promoTimer?.cancel(),
                onPointerUp: (_) => _startPromoTimer(),
                onPointerCancel: (_) => _startPromoTimer(),
                child: PageView.builder(
                  controller: _promoPageController,
                  itemCount: _randomPromoBanners.length,
                  onPageChanged: (index) {
                    setState(() => _promoIndex = index);
                  },
                  itemBuilder: (context, index) {
                    if (index >= _randomPromoBanners.length) return const SizedBox.shrink();
                    final banner = _randomPromoBanners[index];
                    return _buildPromoBannerItem(banner);
                  },
                ),
              ),

              // Slide Dots (Centered above the search bar)
              Positioned(
                bottom: 34,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_randomPromoBanners.length, (i) {
                    final bool isActive = _promoIndex == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isActive ? 18 : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Shimmer(
        child: Container(
          width: double.infinity,
          height: 230,
          decoration: BoxDecoration(
            color: context.cardBg,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPromoBannerItem(_PromoBannerItemData banner) {
    final product = banner.item.product;
    final bool hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    final String formattedPrice = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final double originalPrice = product.price * 1.25;
    final String formattedOriginalPrice = originalPrice
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return PressScale(
      onTap: () => _showProductDetail(context, banner.item),
      child: SizedBox(
        width: double.infinity,
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Real Product Image Background
            if (hasImage)
              CachedNetworkImage(
                imageUrl: product.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 600,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: banner.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: banner.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(banner.icon, color: Colors.white.withValues(alpha: 0.4), size: 40),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: banner.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(banner.icon, color: Colors.white.withValues(alpha: 0.25), size: 48),
                ),
              ),

            // 2. Multi-stop Gradient Scrim (dark on left, clear on right for food photo exposure)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.75, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // 3. Top scrim for the top icons
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),

            // 4. Foreground Hero Content (Stall Logo, Title, Strikethrough & Big Price, CTA)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 58, 18, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stall Name Header
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.item.canteenName.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xFF2DD4BF), size: 13),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Big Headline / Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price Row (Strikethrough + Big Promo Price)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp $formattedOriginalPrice',
                        style: const TextStyle(
                          fontSize: 12.5,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white70,
                          decorationThickness: 2,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rp $formattedPrice',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // "Pesan sekarang >" CTA
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pesan sekarang',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.white, size: 14),
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

  Widget _buildPopularSliderSection(AsyncValue<List<ProductWithCanteen>> productsAsync, _CanteenStallInfo activeStall) {
    return productsAsync.when(
      data: (dbProducts) {
        final List<ProductWithCanteen> allItems = dbProducts.isNotEmpty
            ? dbProducts
            : _getPresetProductsForStall(activeStall);
        final List<ProductWithCanteen> items = allItems.take(6).toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Rekomendasi untukmu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Lihat semua',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 205,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final product = item.product;
                  final double discount = (15 + (index * 7) % 25).toDouble();

                  return PressScale(
                    scale: 0.97,
                    onTap: () => _showProductDetail(context, item),
                    child: SizedBox(
                      width: 155,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Image with discount badge
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Container(
                                  width: 155,
                                  height: 110,
                                  color: context.surfaceBg,
                                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: product.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                          errorWidget: (_, __, ___) => _buildPlaceholderImage(product.category),
                                        )
                                      : _buildPlaceholderImage(product.category),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(CupertinoIcons.percent, size: 10, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${discount.toInt()}% off',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),

                          // Rating badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.star, size: 10, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      '4.8',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Product Name
                          Text(
                            product.name,
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
                            '15-20 min • ${item.canteenName}',
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
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Shimmer(
        child: Container(
          height: 205,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildKulinerSesuaiSeleramuSection() {
    final List<Map<String, dynamic>> categories = [
      {'label': 'Semua Menu', 'val': null, 'icon': Icons.restaurant, 'color': const Color(0xFF0D9488)},
      {'label': 'Aneka Nasi', 'val': 'makanan', 'icon': Icons.rice_bowl, 'color': const Color(0xFFD97706)},
      {'label': 'Nasi Goreng', 'val': 'makanan', 'icon': Icons.lunch_dining, 'color': const Color(0xFFEF4444)},
      {'label': 'Cepat Saji', 'val': 'makanan', 'icon': Icons.fastfood, 'color': const Color(0xFFF59E0B)},
      {'label': 'Minuman', 'val': 'minuman', 'icon': Icons.local_drink, 'color': const Color(0xFF06B6D4)},
      {'label': 'Jajanan', 'val': 'camilan', 'icon': Icons.bakery_dining, 'color': const Color(0xFF8B5CF6)},
      {'label': 'Manis', 'val': 'camilan', 'icon': Icons.cake, 'color': const Color(0xFFEC4899)},
      {'label': 'Kopi & Teh', 'val': 'minuman', 'icon': Icons.coffee, 'color': const Color(0xFF78350F)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Kuliner sesuai seleramu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4-Column Grid of Categories
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final bool isSelected = _selectedCategory == cat['val'] && (index == 0 ? _selectedCategory == null : true);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['val'] as String?;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Nebula.teal : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 22,
                      color: cat['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cat['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Nebula.teal : context.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductsListArea(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductWithCanteen>> productsAsync,
    _CanteenStallInfo activeStall,
    bool isDesktop,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = isDesktop ? (screenWidth >= 1100 ? 4 : 3) : 2;
    final double childAspectRatio = isDesktop
        ? 0.78
        : (screenWidth <= 340 ? 0.62 : (screenWidth <= 400 ? 0.67 : 0.74));

    return productsAsync.when(
      data: (dbItems) {
        final allItems = dbItems.isNotEmpty ? dbItems : _getPresetProductsForStall(activeStall);
        var filtered = allItems;

        // Instant in-memory filter by Category
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          filtered = filtered.where((item) => item.product.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
        }

        // Instant in-memory filter by Search Query
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((item) => item.product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        _checkAutoOpenDetail(filtered);

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.search, size: 36, color: context.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada jajanan yang sesuai',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildSquareProductCard(context, filtered[index]);
          },
        );
      },
      loading: () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const SkeletonProductGridCard(),
      ),
      error: (_, __) {
        final items = _getPresetProductsForStall(activeStall);
        var filtered = items;
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          filtered = filtered.where((item) => item.product.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
        }
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((item) => item.product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildSquareProductCard(context, filtered[index]);
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
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
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
                    // Subtle bottom gradient shadow on image edge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
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
                flex: 5,
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
            imageUrl: 'https://images.unsplash.com/photo-1594041680534-e8c8cdebd659?auto=format&fit=crop&w=600&q=80',
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
            imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
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
            imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
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
            imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=600&q=80',
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
            imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80',
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
            imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=600&q=80',
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
          imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
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
          imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
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
          imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80',
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
          imageUrl: 'https://images.unsplash.com/photo-1594041680534-e8c8cdebd659?auto=format&fit=crop&w=600&q=80',
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
          imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=600&q=80',
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
    final operatorId = item.product.operatorId.isNotEmpty ? item.product.operatorId : 'stan-utama';
    context.push('/public/stan/$operatorId?productId=${item.product.id}');
  }

}
