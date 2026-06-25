import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/core/utils/responsive.dart';

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
  String? _selectedCanteenId;
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
    // Memuat daftar stan pedagang untuk filter di bagian atas
    final canteensAsync = ref.watch(publicCanteensProvider);

    // Mengecek apakah siswa sedang memfilter atau mencari jajanan
    final bool isSearchingOrFiltered = _selectedCategory != null || _searchQuery.isNotEmpty;

    // Filter paginated untuk infinite scroll
    final paginatedFilter = PaginatedProductsFilter(
      category: _selectedCategory,
      canteenId: _selectedCanteenId,
      searchQuery: _searchQuery,
    );

    // Memuat data dengan lazy loading hanya jika sedang memfilter/mencari
    final paginatedState = isSearchingOrFiltered
        ? ref.watch(paginatedProductsProvider(paginatedFilter))
        : const PaginatedProductsState(items: []);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Menu Kantin',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTeal,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Greeting & Title Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mau Jajan Apa Hari Ini?',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkTeal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih makanan sehat dan bergizi langsung dari stan kantin sekolahmu',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar (Debounced 500ms)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari makanan, minuman, camilan...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray,
                    ),
                    prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.gray, size: 18),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Category Selector Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip('Semua', '🍽️', null),
                    _buildCategoryChip('Makanan', '🍔', 'makanan'),
                    _buildCategoryChip('Minuman', '🥤', 'minuman'),
                    _buildCategoryChip('Camilan', '🍿', 'camilan'),
                  ],
                ),
              ),
            ),
          ),

          // Canteen Stalls Filter Bar
          SliverToBoxAdapter(
            child: canteensAsync.when(
              data: (stalls) {
                if (stalls.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        'Pilih Stan Kantin',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: stalls.length + 1,
                        itemBuilder: (context, index) {
                          final bool isAll = index == 0;
                          final stall = isAll ? null : stalls[index - 1];
                          final bool isSelected = isAll
                              ? _selectedCanteenId == null
                              : _selectedCanteenId == stall!.id;

                          final String label = isAll ? 'Semua Stan' : stall!.canteenName;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCanteenId = isAll ? null : stall!.id;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                                  width: 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAll ? CupertinoIcons.house_fill : CupertinoIcons.house,
                                    size: 13,
                                    color: isSelected ? AppColors.white : AppColors.mutedGray,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? AppColors.white : AppColors.darkTeal,
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
              loading: () => const SizedBox(
                height: 38,
                child: Center(child: CupertinoActivityIndicator(color: AppColors.primary)),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // Branching Content
          if (isSearchingOrFiltered)
            ..._buildPaginatedSlivers(context, ref, paginatedState, paginatedFilter)
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    _buildPreviewSection(context, ref, 'Makanan Utama', 'makanan', '🍔'),
                    _buildPreviewSection(context, ref, 'Camilan & Jajanan', 'camilan', '🍿'),
                    _buildPreviewSection(context, ref, 'Minuman Segar', 'minuman', '🥤'),
                  ],
                ),
              ),
            ),
        ],
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
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.darkTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, WidgetRef ref, String sectionName, String categoryKey, String emoji) {
    final filter = PreviewFilter(category: categoryKey, canteenId: _selectedCanteenId);
    final previewAsync = ref.watch(categoryPreviewProvider(filter));

    return previewAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox();

        final bool isDesktop = Responsive.isDesktop(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$emoji $sectionName',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkTeal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = categoryKey;
                      });
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.71,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(context, items[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CupertinoActivityIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  List<Widget> _buildPaginatedSlivers(BuildContext context, WidgetRef ref, PaginatedProductsState state, PaginatedProductsFilter filter) {
    if (state.isLoading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CupertinoActivityIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }

    if (state.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.wifi_slash, size: 48, color: AppColors.gray),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat menu: ${state.error}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedGray,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(paginatedProductsProvider(filter)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.search,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Jajanan Tidak Ditemukan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Coba reset filter atau gunakan kata kunci pencarian lainnya.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'Reset Semua Filter',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final bool isDesktop = Responsive.isDesktop(context);

    return [
      // Hasil temuan title
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Katalog Menu',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkTeal,
                ),
              ),
              Text(
                '${state.items.length} menu dimuat',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedGray,
                ),
              ),
            ],
          ),
        ),
      ),

      // Grid view jajanan terpaginasi
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.71,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildProductCard(context, state.items[index]);
            },
            childCount: state.items.length,
          ),
        ),
      ),

      // Loader di bagian bawah untuk Infinite Scroll
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: state.isLoadingMore
                ? const CupertinoActivityIndicator(color: AppColors.primary)
                : state.hasReachedMax
                    ? Text(
                        'Semua menu telah dimuat',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedGray,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox(),
          ),
        ),
      ),
    ];
  }

  Widget _buildProductCard(BuildContext context, ProductWithCanteen item) {
    final product = item.product;
    final bool isAvailable = product.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.6,
      child: GestureDetector(
        onTap: () => _showProductDetail(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? 'Tersedia' : 'Habis',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.house, size: 10, color: AppColors.mutedGray),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.canteenName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mutedGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isAvailable ? AppColors.primary : AppColors.gray,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.add,
                              color: AppColors.white,
                              size: 12,
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
          color: AppColors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context, ProductWithCanteen item) {
    final product = item.product;
    final bool isAvailable = product.isAvailable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
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
                    color: AppColors.grayLight,
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
                          placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
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
                      const Icon(CupertinoIcons.house_fill, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        item.canteenName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                product.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? AppColors.successLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable ? 'Tersedia' : 'Habis / Kosong',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAvailable ? AppColors.successGreen : AppColors.errorRed2,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: AppColors.borderLight),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.creditcard_fill, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Panduan Belanja',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jajanan ini dibeli secara langsung di stan kantin sekolah. Kunjungi ${item.canteenName} dan tempelkan (tap) kartu RFID Anda pada mesin kasir pedagang untuk memproses pembayaran.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
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
  }

  Widget _buildDetailFallbackImage(String category) {
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
          size: 48,
          color: AppColors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
