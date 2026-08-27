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
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';

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
    this.rating = 0.0,
    this.reviewsCount = 0,
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
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final PageController _promoPageController = PageController(
    initialPage: 0,
    viewportFraction: 1.0,
  );
  Timer? _promoTimer;
  int _promoIndex = 0;
  List<_PromoBannerItemData> _randomPromoBanners = [];
  List<ProductWithCanteen> _shuffledRecommendations = [];

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCanteenId = 'semua';
  Timer? _debounce;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onFocusChange);
    _startPromoTimer();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
      _searchQuery = widget.initialSearch!;
      _isSearchFocused = true;
    }
    if (widget.initialCanteenId != null && widget.initialCanteenId!.isNotEmpty) {
      _selectedCanteenId = widget.initialCanteenId!;
    }
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0);
      }
    }
    if (_searchFocusNode.hasFocus != _isSearchFocused) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _randomPromoBanners.isEmpty) return;
      if (_randomPromoBanners.length > 1 && _promoPageController.hasClients && _promoPageController.page != null) {
        final nextPage = (_promoPageController.page!.round() + 1) % _randomPromoBanners.length;
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 550),
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
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _promoTimer?.cancel();
    _promoPageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    // Jalankan infinite scroll lazy loading saat mendekati bagian bawah halaman
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    if (!mounted) return;
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
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      _searchQuery = '';
      _isSearchFocused = false;
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
      rating: 0.0,
      reviewsCount: 0,
      isOpen: true,
      emoji: '🍽️',
    );

    List<_CanteenStallInfo> stalls = [semuaStall];
    canteensAsync.whenData((dbStalls) {
      if (dbStalls.isNotEmpty) {
        final mapped = dbStalls.map((op) {
          return _CanteenStallInfo(
            id: op.id,
            name: op.canteenName,
            rating: op.rating,
            reviewsCount: op.totalReviews,
            isOpen: true,
            emoji: '🏬',
          );
        }).toList();
        stalls = [semuaStall, ...mapped];
      }
    });

    final activeStall = stalls.firstWhere(
      (s) => s.id == (_selectedCanteenId ?? 'semua'),
      orElse: () => stalls.first,
    );

    final bool isSearchActive = _isSearchFocused || _searchQuery.trim().isNotEmpty;

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
                    setState(() {
                      _shuffledRecommendations.clear();
                      _randomPromoBanners.clear();
                    });
                    ref.invalidate(publicMenuProvider(null));
                    ref.invalidate(publicCanteensProvider);
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Full-Bleed Hero Promo Banner with Overlapping Top Nav (Collapses smoothly to 0 on search)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: isSearchActive
                              ? const SizedBox(width: double.infinity, height: 0)
                              : Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildPromoBannerCarousel(allProductsAsync, activeStall),
                                    Positioned(
                                      top: 14,
                                      left: 16,
                                      right: 16,
                                      child: _buildTopHeroNav(context),
                                    ),
                                  ],
                                ),
                        ),

                        // 2. Persistent Single Search Bar Row (Preserves focus & key)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            isSearchActive ? 12 : 0,
                            16,
                            isSearchActive ? 8 : 14,
                          ),
                          child: Transform.translate(
                            offset: Offset(0, isSearchActive ? 0 : -22),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Slide-in Back Button
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOutCubic,
                                  child: isSearchActive
                                      ? Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: GestureDetector(
                                            onTap: _closeSearch,
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: context.cardBg,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: context.borderLight, width: 0.8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(CupertinoIcons.left_chevron, size: 18),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),

                                // The Persistent Search Input Field
                                Expanded(
                                  child: _buildSearchInputField(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 3. Body Content (Smooth Transition between Discovery and Search Results)
                        Transform.translate(
                          offset: Offset(0, isSearchActive ? 0 : -10),
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            firstCurve: Curves.easeInOutCubic,
                            secondCurve: Curves.easeInOutCubic,
                            crossFadeState: isSearchActive
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: _buildDiscoveryView(context, ref, allProductsAsync, activeStall, isDesktop),
                            secondChild: _buildSearchResultsView(context, ref, allProductsAsync, canteensAsync, isDesktop),
                          ),
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

  Widget _buildDiscoveryView(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductWithCanteen>> allProductsAsync,
    _CanteenStallInfo activeStall,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Section 1: "Rekomendasi untukmu" (Horizontal Slider)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPopularSliderSection(allProductsAsync, activeStall),
        ),
        const SizedBox(height: 24),

        // 2. Section 2: "Kuliner sesuai seleramu" (Categories)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildKulinerSesuaiSeleramuSection(),
        ),
        const SizedBox(height: 24),

        // 3. Section 3: Product List in Card Panjang (1x1 List View)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          child: _buildProductsListArea(context, ref, allProductsAsync, activeStall, isDesktop),
        ),
      ],
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

  Widget _buildSearchInputField() {
    final bool hasText = _searchController.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isSearchFocused ? Nebula.teal : context.borderLight,
          width: _isSearchFocused ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Lagi mau jajan apa hari ini?',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            prefixIcon: const Icon(CupertinoIcons.search, color: Nebula.teal, size: 19),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Icon(CupertinoIcons.clear_circled_solid, color: Starlight.dim, size: 17),
                  )
                : const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(Icons.restaurant, color: Nebula.teal, size: 19),
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          ),
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

                  // Price Row
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

  List<ProductWithCanteen> _generateDiverseRecommendations(List<ProductWithCanteen> allItems) {
    if (allItems.isEmpty) return [];

    final available = allItems.where((p) => p.product.isAvailable).toList();
    if (available.isEmpty) return allItems.take(8).toList();

    // Urutkan berdasarkan rating produk tertinggi
    final sortedByRating = List<ProductWithCanteen>.from(available)
      ..sort((a, b) => b.product.rating.compareTo(a.product.rating));

    // 1. 60% Top-Rated Pool dengan Multi-Stall Diversity Constraint (Maksimal 2 produk per stan agar adil)
    final List<ProductWithCanteen> topDiverse = [];
    final Map<String, int> stallCounts = {};

    for (final item in sortedByRating) {
      final stallKey = item.product.operatorId.isNotEmpty ? item.product.operatorId : item.canteenName;
      final currentCount = stallCounts[stallKey] ?? 0;
      if (currentCount < 2) {
        topDiverse.add(item);
        stallCounts[stallKey] = currentCount + 1;
        if (topDiverse.length >= 6) break;
      }
    }

    if (topDiverse.length < 6) {
      for (final item in sortedByRating) {
        if (!topDiverse.any((p) => p.product.id == item.product.id)) {
          topDiverse.add(item);
          if (topDiverse.length >= 6) break;
        }
      }
    }

    // 2. 40% Randomized Pool dari produk stan lain yang belum terpilih
    final remaining = available
        .where((p) => !topDiverse.any((top) => top.product.id == p.product.id))
        .toList()
      ..shuffle();
    final randomItems = remaining.take(4).toList();

    return [...topDiverse, ...randomItems];
  }

  Widget _buildPopularSliderSection(AsyncValue<List<ProductWithCanteen>> productsAsync, _CanteenStallInfo activeStall) {
    return productsAsync.when(
      data: (dbProducts) {
        final List<ProductWithCanteen> allItems = dbProducts.isNotEmpty
            ? dbProducts
            : _getPresetProductsForStall(activeStall);

        if (_shuffledRecommendations.isEmpty && allItems.isNotEmpty) {
          _shuffledRecommendations = _generateDiverseRecommendations(allItems);
        }
        final items = _shuffledRecommendations.isNotEmpty
            ? _shuffledRecommendations
            : _generateDiverseRecommendations(allItems);

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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: Container(
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
                  final String formattedPrice = product.price
                      .toStringAsFixed(0)
                      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

                  return PressScale(
                    scale: 0.97,
                    onTap: () => _showProductDetail(context, item),
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 150,
                              height: 105,
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.borderLight, width: 0.5),
                              ),
                              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const ShimmerRect(
                                        width: double.infinity,
                                        height: 105,
                                        borderRadius: 14,
                                      ),
                                      errorWidget: (_, __, ___) => _buildPlaceholderImage(product.category),
                                    )
                                  : _buildPlaceholderImage(product.category),
                            ),
                          ),
                          const SizedBox(height: 7),

                          // Rating & Canteen Row
                          Row(
                            children: [
                              if (product.hasRating) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 9.5, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              if (product.totalSold > 0) ...[
                                Text(
                                  '${product.totalSold} terjual',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('•', style: TextStyle(color: Colors.grey, fontSize: 9)),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  item.canteenName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

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

                          // Product Price
                          Text(
                            'Rp $formattedPrice',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
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
      {
        'label': 'Semua',
        'val': null,
        'icon': Icons.restaurant_menu_rounded,
        'color': Nebula.teal,
      },
      {
        'label': 'Makanan',
        'val': 'makanan',
        'icon': Icons.lunch_dining_rounded,
        'color': const Color(0xFFE11D48),
      },
      {
        'label': 'Minuman',
        'val': 'minuman',
        'icon': Icons.local_drink_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'label': 'Camilan',
        'val': 'camilan',
        'icon': Icons.bakery_dining_rounded,
        'color': const Color(0xFFD97706),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kuliner sesuai seleramu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 4 Category Items (Semua, Makanan, Minuman, Camilan)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((cat) {
            final String? val = cat['val'] as String?;
            final bool isSelected = _selectedCategory == val;
            final Color color = cat['color'] as Color;

            return Expanded(
              child: PressScale(
                scale: 0.92,
                onTap: () {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        size: 24,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? color : context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── INSTANT SEARCH RESULTS VIEW (STALLS + PRODUCTS) ───
  Widget _buildSearchResultsView(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductWithCanteen>> productsAsync,
    AsyncValue<List<CanteenOperator>> canteensAsync,
    bool isDesktop,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    final List<CanteenOperator> allCanteens = canteensAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final List<ProductWithCanteen> allProducts = productsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    if (query.isEmpty) {
      return _buildSearchSuggestions(context, allProducts);
    }

    // 1. Matching Canteens / Stalls (Misal pencarian: "sta", "bude", "ani", "bakso", "utama")
    final matchingCanteens = allCanteens.where((c) {
      return c.canteenName.toLowerCase().contains(query);
    }).toList();

    // 2. Matching Products / Menu Items
    final matchingProducts = allProducts.where((p) {
      final pName = p.product.name.toLowerCase();
      final cName = p.canteenName.toLowerCase();
      final cat = p.product.category.toLowerCase();
      return pName.contains(query) || cName.contains(query) || cat.contains(query);
    }).toList();

    // 3. Empty State if nothing matches
    if (matchingCanteens.isEmpty && matchingProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.search, size: 34, color: Nebula.teal),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak Ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada toko atau menu yang cocok dengan "$_searchQuery". Coba gunakan kata kunci lain.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Nebula.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: Text(
                  'Hapus Pencarian',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Nebula.teal),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SECTION 1: TOKO / STAN KANTIN ──
          if (matchingCanteens.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 18, color: Nebula.teal),
                const SizedBox(width: 6),
                Text(
                  'Stan / Toko Kantin (${matchingCanteens.length})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...matchingCanteens.map((canteen) => _buildCanteenSearchResultCard(context, canteen, allProducts)),
            const SizedBox(height: 24),
          ],

          // ── SECTION 2: MENU MAKANAN & MINUMAN ──
          if (matchingProducts.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.restaurant_menu_rounded, size: 18, color: Nebula.teal),
                const SizedBox(width: 6),
                Text(
                  'Menu Makanan & Minuman (${matchingProducts.length})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matchingProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildSingleColumnProductCard(context, matchingProducts[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions(BuildContext context, List<ProductWithCanteen> allProducts) {
    final List<String> popularKeywords = [
      'Bakso',
      'Nasi Goreng',
      'Es Jeruk',
      'Dimsum',
      'Ayam Geprek',
      'Mie Ayam',
      'Soto',
      'Jus Alpukat',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.flame_fill, size: 16, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Text(
                'Pencarian Populer',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularKeywords.map((kw) {
              return PressScale(
                scale: 0.95,
                onTap: () {
                  _searchController.text = kw;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: kw.length),
                  );
                  setState(() {
                    _searchQuery = kw;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.search, size: 13, color: Nebula.teal),
                      const SizedBox(width: 6),
                      Text(
                        kw,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCanteenSearchResultCard(BuildContext context, CanteenOperator canteen, List<ProductWithCanteen> allProducts) {
    final stallProducts = allProducts.where((p) => p.product.operatorId == canteen.id).toList();
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/public/stan/${canteen.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Stan Avatar, Name, Rating, and "Kunjungi" button
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, color: Nebula.teal, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canteen.canteenName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (canteen.rating > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text(
                                        canteen.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Buka',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                canteen.isDeliveryEnabled ? 'Bisa Antar' : 'Ambil di Stan',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Kunjungi',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Nebula.teal,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(CupertinoIcons.chevron_right, size: 11, color: Nebula.teal),
                        ],
                      ),
                    ),
                  ],
                ),

                // Preview 2-3 popular menus from this stall
                if (stallProducts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: context.dividerCol, height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Menu dari ${canteen.canteenName}:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stallProducts.take(3).map((sp) {
                      final p = sp.product;
                      final formattedPrice = CurrencyFormatter.format(p.price);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.surfaceBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderLight, width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedPrice,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsListArea(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductWithCanteen>> productsAsync,
    _CanteenStallInfo activeStall,
    bool isDesktop,
  ) {
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

        // If searching or single category filtered, display flat 1-column list
        if (_searchQuery.isNotEmpty || (_selectedCategory != null && _selectedCategory!.isNotEmpty)) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildSingleColumnProductCard(context, filtered[index]);
            },
          );
        }

        // Group into Separate Categories with max 6 preview and "Lihat lainnya"
        return _buildCategorizedSections(context, allItems);
      },
      loading: () => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const SkeletonProductGridCard(),
      ),
      error: (_, __) {
        final items = _getPresetProductsForStall(activeStall);
        return _buildCategorizedSections(context, items);
      },
    );
  }

  Widget _buildCategorizedSections(BuildContext context, List<ProductWithCanteen> allItems) {
    // 1. Minuman Segar
    final minumanItems = allItems.where((p) => p.product.category.toLowerCase() == 'minuman' || p.product.name.toLowerCase().contains('jus') || p.product.name.toLowerCase().contains('es') || p.product.name.toLowerCase().contains('teh') || p.product.name.toLowerCase().contains('aqua')).toList();

    // 2. Makanan Utama
    final makananItems = allItems.where((p) => (p.product.category.toLowerCase() == 'makanan' || p.product.category.toLowerCase() == 'utama') && !minumanItems.contains(p)).toList();

    // 3. Camilan & Snack
    final camilanItems = allItems.where((p) => p.product.category.toLowerCase() == 'camilan' || p.product.category.toLowerCase() == 'snack' || (!minumanItems.contains(p) && !makananItems.contains(p))).toList();

    final List<Map<String, dynamic>> categorySections = [
      if (minumanItems.isNotEmpty)
        {'name': 'Minuman Segar', 'category': 'minuman', 'items': minumanItems},
      if (makananItems.isNotEmpty)
        {'name': 'Makanan Utama', 'category': 'makanan', 'items': makananItems},
      if (camilanItems.isNotEmpty)
        {'name': 'Camilan & Snack', 'category': 'camilan', 'items': camilanItems},
    ];

    if (categorySections.isEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: allItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildSingleColumnProductCard(context, allItems[index]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorySections.map((section) {
        final String categoryName = section['name'] as String;
        final List<ProductWithCanteen> items = section['items'] as List<ProductWithCanteen>;
        const int previewLimit = 6;
        final previewItems = items.take(previewLimit).toList();
        final bool hasMore = items.length > previewLimit;

        return Padding(
          padding: const EdgeInsets.only(bottom: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header Row (Title + Count Badge + Lihat Lainnya Action)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        categoryName,
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${items.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasMore)
                    GestureDetector(
                      onTap: () => _openCategoryCatalogModal(categoryName, items),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              'Lihat lainnya',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Nebula.teal,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(CupertinoIcons.chevron_right, size: 12, color: Nebula.teal),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 1-Column Product List Cards (Max 6 preview)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: previewItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildSingleColumnProductCard(context, previewItems[index]);
                },
              ),

              // Bottom "Lihat Semua (N) Menu" Button if more than 6
              if (hasMore) ...[
                const SizedBox(height: 10),
                Center(
                  child: OutlinedButton(
                    onPressed: () => _openCategoryCatalogModal(categoryName, items),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Nebula.teal,
                      side: BorderSide(color: Nebula.teal.withValues(alpha: 0.4), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat semua ${items.length} menu $categoryName',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.arrow_right, size: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleColumnProductCard(BuildContext context, ProductWithCanteen item) {
    final product = item.product;
    final bool isAvailable = product.isAvailable;
    final String formattedPrice = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final String desc = _getProductDescription(product);

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.55,
      child: PressScale(
        scale: 0.98,
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
                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Rounded Product Image (Slightly larger thumbnail)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 84,
                    height: 84,
                    color: context.surfaceBg,
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ShimmerRect(
                              width: 84,
                              height: 84,
                              borderRadius: 14,
                            ),
                            errorWidget: (_, __, ___) => _buildPlaceholderImage(product.category),
                          )
                        : _buildPlaceholderImage(product.category),
                  ),
                ),
                const SizedBox(width: 14),

                // Right Content Area: Name, Description, Price & Add (+) Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 12, color: Nebula.teal),
                          const SizedBox(width: 3.5),
                          Flexible(
                            child: Text(
                              item.canteenName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: item.isDeliveryEnabled
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.isDeliveryEnabled ? Icons.delivery_dining : Icons.shopping_bag_outlined,
                                  size: 11,
                                  color: item.isDeliveryEnabled ? const Color(0xFF10B981) : Colors.grey,
                                ),
                                const SizedBox(width: 2.5),
                                Text(
                                  item.isDeliveryEnabled ? 'Bisa Antar' : 'Ambil di Stan',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: item.isDeliveryEnabled ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (product.hasRating) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 9.5, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (product.totalSold > 0) ...[
                            Text(
                              '${product.totalSold} terjual',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textSecondary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Rp $formattedPrice',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Nebula.teal,
                            ),
                          ),
                          GestureDetector(
                            onTap: isAvailable ? () => _handleAddToCart(item) : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isAvailable ? Nebula.teal : context.textSecondary.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                boxShadow: isAvailable
                                    ? [
                                        BoxShadow(
                                          color: Nebula.teal.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
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
      ),
    );
  }

  Future<void> _handleAddToCart(ProductWithCanteen item) async {
    final product = item.product;
    final operatorId = product.operatorId.isNotEmpty ? product.operatorId : 'stan-utama';
    final canteenName = item.canteenName;

    final cartNotifier = ref.read(studentCartProvider.notifier);
    final hasConflict = cartNotifier.checkCanteenConflict(operatorId);

    if (hasConflict) {
      final currentCanteenName = ref.read(studentCartProvider).canteenName ?? 'Stan Lain';
      final confirmed = await showAppConfirmationDialog(
        context,
        title: 'Mau ganti stan?',
        message: 'Keranjangmu saat ini berisi pesanan dari $currentCanteenName. Jika memilih menu dari $canteenName, pesanan sebelumnya akan diganti.',
        confirmLabel: 'Ganti & Tambah',
        confirmColor: Nebula.teal,
        icon: Icons.storefront_rounded,
      );

      if (confirmed) {
        cartNotifier.addProductWithCanteen(
          canteenId: operatorId,
          canteenName: canteenName,
          deliveryFee: 2000,
          productId: product.id,
          name: product.name,
          price: product.price,
          imageUrl: product.imageUrl,
        );
        _showAddedSnackbar(product.name);
      }
    } else {
      cartNotifier.addProductWithCanteen(
        canteenId: operatorId,
        canteenName: canteenName,
        deliveryFee: 2000,
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _showAddedSnackbar(product.name);
    }
  }

  void _showAddedSnackbar(String productName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$productName ditambahkan ke keranjang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Nebula.teal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openCategoryCatalogModal(String categoryName, List<ProductWithCanteen> categoryProducts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryCatalogSheet(
          categoryName: categoryName,
          allProducts: categoryProducts,
          onAddToCart: (item) => _handleAddToCart(item),
          onProductTap: (item) => _showProductDetail(context, item),
          placeholderBuilder: (cat) => _buildPlaceholderImage(cat),
          descBuilder: (prod) => _getProductDescription(prod),
        );
      },
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

/// Full Category Catalog Bottom Sheet Modal (Lihat Lainnya)
class _CategoryCatalogSheet extends StatefulWidget {
  final String categoryName;
  final List<ProductWithCanteen> allProducts;
  final Function(ProductWithCanteen) onAddToCart;
  final Function(ProductWithCanteen) onProductTap;
  final Widget Function(String) placeholderBuilder;
  final String Function(Product) descBuilder;

  const _CategoryCatalogSheet({
    required this.categoryName,
    required this.allProducts,
    required this.onAddToCart,
    required this.onProductTap,
    required this.placeholderBuilder,
    required this.descBuilder,
  });

  @override
  State<_CategoryCatalogSheet> createState() => _CategoryCatalogSheetState();
}

class _CategoryCatalogSheetState extends State<_CategoryCatalogSheet> {
  String _catalogSearch = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allProducts.where((p) {
      if (_catalogSearch.isEmpty) return true;
      final q = _catalogSearch.toLowerCase();
      return p.product.name.toLowerCase().contains(q) ||
          p.canteenName.toLowerCase().contains(q);
    }).toList();

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag handle & Title Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerCol,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Katalog ${widget.categoryName}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.allProducts.length}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 24),
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderLight),

          // Search Bar inside catalog
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderLight, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search, size: 16, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari menu di ${widget.categoryName}...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: context.textSecondary.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: TextStyle(fontSize: 13, color: context.textPrimary),
                      onChanged: (val) {
                        setState(() {
                          _catalogSearch = val.trim();
                        });
                      },
                    ),
                  ),
                  if (_catalogSearch.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _catalogSearch = ''),
                      child: Icon(CupertinoIcons.clear_circled_solid, size: 16, color: context.textSecondary),
                    ),
                ],
              ),
            ),
          ),

          // Products List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.search, size: 36, color: context.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada menu yang sesuai',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final product = item.product;
                      final bool isAvailable = product.isAvailable;
                      final String formattedPrice = product.price
                          .toStringAsFixed(0)
                          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                      final String desc = widget.descBuilder(product);

                      return Opacity(
                        opacity: isAvailable ? 1.0 : 0.55,
                        child: PressScale(
                          scale: 0.98,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onProductTap(item);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderLight, width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left Rounded Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 84,
                                      height: 84,
                                      color: context.surfaceBg,
                                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: product.imageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => const ShimmerRect(
                                                width: 84,
                                                height: 84,
                                                borderRadius: 14,
                                              ),
                                              errorWidget: (_, __, ___) => widget.placeholderBuilder(product.category),
                                            )
                                          : widget.placeholderBuilder(product.category),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Right Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront_rounded, size: 12, color: Nebula.teal),
                                            const SizedBox(width: 3.5),
                                            Flexible(
                                              child: Text(
                                                item.canteenName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Nebula.teal,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: item.isDeliveryEnabled
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                    : Colors.grey.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    item.isDeliveryEnabled ? Icons.delivery_dining : Icons.shopping_bag_outlined,
                                                    size: 11,
                                                    color: item.isDeliveryEnabled ? const Color(0xFF10B981) : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 2.5),
                                                  Text(
                                                    item.isDeliveryEnabled ? 'Bisa Antar' : 'Ambil di Stan',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: item.isDeliveryEnabled ? const Color(0xFF10B981) : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          desc,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: context.textSecondary,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Rp $formattedPrice',
                                              style: GoogleFonts.inter(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: Nebula.teal,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: isAvailable ? () => widget.onAddToCart(item) : null,
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isAvailable ? Nebula.teal : context.textSecondary.withValues(alpha: 0.3),
                                                  shape: BoxShape.circle,
                                                  boxShadow: isAvailable
                                                      ? [
                                                          BoxShadow(
                                                            color: Nebula.teal.withValues(alpha: 0.35),
                                                            blurRadius: 6,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: const Icon(Icons.add, color: Colors.white, size: 20),
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

