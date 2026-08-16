/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/hallmark_card.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';

/// Hallmark Student Mobile Native Onboarding & Welcome Screen
/// 3-Slide Interactive Wizard with Autonomous Living RFID Characters & Smart Fintech Showcase
class StudentWelcomeScreen extends ConsumerStatefulWidget {
  const StudentWelcomeScreen({super.key});

  @override
  ConsumerState<StudentWelcomeScreen> createState() => _StudentWelcomeScreenState();
}

class _StudentWelcomeScreenState extends ConsumerState<StudentWelcomeScreen> {
  // Onboarding Wizard Page Controller
  late final PageController _wizardController = PageController();
  int _wizardIndex = 0;

  // Slide 2 Promo Banner Auto-sliding Controller & Timer
  late final PageController _promoPageController = PageController(
    initialPage: 0,
    viewportFraction: 0.92,
  );
  Timer? _promoTimer;
  int _promoIndex = 0;
  int _promoCount = 0;

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_promoCount > 1 && _promoPageController.hasClients && _promoPageController.page != null) {
        final currentPage = _promoPageController.page!.round();
        final nextPage = (currentPage + 1) % _promoCount;
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoPageController.dispose();
    _wizardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final publicMenuAsync = ref.watch(publicMenuProvider(null));

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                // 1. Top App Header Bar
                _buildHeaderBar(context, colors, isDark),

                // 2. Middle Interactive Onboarding Wizard (3 Slides)
                Expanded(
                  child: PageView(
                    controller: _wizardController,
                    onPageChanged: (index) {
                      setState(() => _wizardIndex = index);
                    },
                    children: [
                      // ── SLIDE 1: Panggung Dunia Kartu RFID Hidup ──
                      _buildWizardSlide(
                        visual: const LivingRfidCardsWorldStage(),
                        titleLeading: 'Jajan Cepat ',
                        titleHighlight: 'Tinggal Tap RFID.',
                        subtitle:
                            'Usapkan kartu RFID/NFC untuk transaksi instan milidetik. Bebas antre, higienis, dan tanpa perlu membawa uang tunai.',
                        featureChips: [
                          _FeatureChipData(
                            icon: CupertinoIcons.bolt_horizontal_fill,
                            label: 'Bebas Antre',
                            color: colors.brandPrimary,
                          ),
                          _FeatureChipData(
                            icon: CupertinoIcons.shield_lefthalf_fill,
                            label: 'Anti Hilang',
                            color: colors.brandAccent,
                          ),
                          _FeatureChipData(
                            icon: CupertinoIcons.sparkles,
                            label: '100% Higienis',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                        colors: colors,
                      ),

                      // ── SLIDE 2: Koleksi Menu Favorit & Rekomendasi ──
                      _buildWizardSlide(
                        visual: _buildPromoCarouselSection(colors, isDark, publicMenuAsync),
                        titleLeading: 'Menu Lezat ',
                        titleHighlight: 'Setiap Hari.',
                        subtitle:
                            'Eksplorasi ratusan menu makanan bergizi dan minuman segar dari seluruh stan kantin sekolah dengan harga transparan.',
                        featureChips: [
                          _FeatureChipData(
                            icon: Icons.storefront_rounded,
                            label: '6 Stan Aktif',
                            color: colors.brandPrimary,
                          ),
                          _FeatureChipData(
                            icon: Icons.restaurant_menu_rounded,
                            label: 'Menu Bergizi',
                            color: const Color(0xFFD97706),
                          ),
                          _FeatureChipData(
                            icon: CupertinoIcons.tag_fill,
                            label: 'Harga Pasti',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                        colors: colors,
                      ),

                      // ── SLIDE 3: Saldo Terkontrol & Notifikasi Real-time ──
                      _buildWizardSlide(
                        visual: _buildSmartBalanceAndReceiptShowcase(colors, isDark),
                        titleLeading: 'Saldo Aman & ',
                        titleHighlight: 'Terpantau Real-time.',
                        subtitle:
                            'Setiap transaksi tercatat otomatis dan terhubung langsung ke ponsel orang tua secara transparan dan akurat.',
                        featureChips: [
                          _FeatureChipData(
                            icon: CupertinoIcons.graph_circle_fill,
                            label: 'Laporan Auto',
                            color: colors.brandPrimary,
                          ),
                          _FeatureChipData(
                            icon: CupertinoIcons.lock_shield_fill,
                            label: 'Limit Harian',
                            color: colors.brandAccent,
                          ),
                          _FeatureChipData(
                            icon: CupertinoIcons.person_2_fill,
                            label: 'Pantau Ortu',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                // 3. Wizard Page Indicator Dots
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final bool isActive = _wizardIndex == i;
                      return GestureDetector(
                        onTap: () {
                          _wizardController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? colors.brandPrimary : colors.borderTactile,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 4. Bottom Sticky Action Buttons
                _buildBottomActionButtons(context, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Single Wizard Slide Layout Wrapper with Overflow-safe Feature Chips
  Widget _buildWizardSlide({
    required Widget visual,
    required String titleLeading,
    required String titleHighlight,
    required String subtitle,
    required List<_FeatureChipData> featureChips,
    required HallmarkColorScheme colors,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          visual,
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: HallmarkTypography.titleL3(colors.textPrimary).copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.4,
              ),
              children: [
                TextSpan(text: titleLeading),
                TextSpan(
                  text: titleHighlight,
                  style: TextStyle(color: colors.brandPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: HallmarkTypography.bodySmall(colors.textMuted).copyWith(
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          // 3 Feature Pill Badges (Anti-Emoji, Crisp Icons & Microcopy)
          Row(
            children: featureChips.map((chip) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderTactile, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chip.icon, size: 11, color: chip.color),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          chip.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
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

  /// Top App Header Bar with Theme Switcher
  Widget _buildHeaderBar(BuildContext context, HallmarkColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderTactile, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KANTIN DIGITAL',
                style: HallmarkTypography.titleSmall(colors.brandPrimary).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => ref.read(themeProvider.notifier).toggle(),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: colors.borderTactile, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 13,
                    color: colors.brandPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDark ? 'Mode Terang' : 'Mode Gelap',
                    style: HallmarkTypography.bodySmall(colors.textPrimary).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SLIDE 2 VISUAL: Promo Banner Carousel Section
  // ==========================================================================
  Widget _buildPromoCarouselSection(
    HallmarkColorScheme colors,
    bool isDark,
    AsyncValue<List<ProductWithCanteen>> publicMenuAsync,
  ) {
    return Container(
      height: 270,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderTactile, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: publicMenuAsync.when(
        data: (List<ProductWithCanteen> allProducts) {
          final displayProducts = allProducts.isNotEmpty
              ? allProducts.take(6).toList()
              : [
                  ProductWithCanteen(
                    product: const Product(
                      id: '1',
                      operatorId: 'op1',
                      name: 'Nasi Goreng Spesial',
                      price: 15000,
                      category: 'makanan',
                      imageUrl:
                          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600&auto=format&fit=crop',
                    ),
                    canteenName: 'Stan Bude Ani',
                  ),
                  ProductWithCanteen(
                    product: const Product(
                      id: '2',
                      operatorId: 'op1',
                      name: 'Ayam Geprek Sambal',
                      price: 18000,
                      category: 'makanan',
                      imageUrl:
                          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600&auto=format&fit=crop',
                    ),
                    canteenName: 'Stan Utama',
                  ),
                  ProductWithCanteen(
                    product: const Product(
                      id: '3',
                      operatorId: 'op1',
                      name: 'Es Teh Manis Jumbo',
                      price: 3000,
                      category: 'minuman',
                      imageUrl:
                          'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=600&auto=format&fit=crop',
                    ),
                    canteenName: 'Stan Jus Segar',
                  ),
                ];

          _promoCount = displayProducts.length;
          if (_promoIndex >= displayProducts.length) {
            _promoIndex = 0;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 14, color: colors.brandPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Koleksi Menu Rekomendasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HallmarkTypography.titleSmall(colors.textPrimary).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Listener(
                  onPointerDown: (_) => _promoTimer?.cancel(),
                  onPointerUp: (_) => _startPromoTimer(),
                  onPointerCancel: (_) => _startPromoTimer(),
                  child: PageView.builder(
                    controller: _promoPageController,
                    itemCount: displayProducts.length,
                    onPageChanged: (index) {
                      setState(() => _promoIndex = index);
                      _startPromoTimer();
                    },
                    itemBuilder: (context, index) {
                      if (index >= displayProducts.length) return const SizedBox.shrink();
                      final item = displayProducts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _buildPromoCard(colors, item),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(displayProducts.length, (i) {
                  final bool isActive = _promoIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 20 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive ? colors.brandPrimary : colors.borderTactile,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CupertinoActivityIndicator(color: colors.brandPrimary),
        ),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPromoCard(HallmarkColorScheme colors, ProductWithCanteen item) {
    final bool hasImage = item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty;

    return HallmarkCard(
      padding: EdgeInsets.zero,
      onTap: null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? CachedNetworkImage(
                    imageUrl: item.product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                    errorWidget: (_, __, ___) => _buildPromoFallback(colors, item),
                  )
                : _buildPromoFallback(colors, item),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Top Right Badge (Anti-Emoji)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Text(
                  'PROMO REKOMENDASI',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Bottom Info Overlay
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.canteenName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rp ${item.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF34D399),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
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

  Widget _buildPromoFallback(HallmarkColorScheme colors, ProductWithCanteen item) {
    return Container(
      color: colors.surfaceSubtle,
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 40,
          color: colors.brandPrimary,
        ),
      ),
    );
  }

  // ==========================================================================
  // SLIDE 3 VISUAL: Authentic Kantin Digital Receipt & Parent Sync Showcase
  // ==========================================================================
  Widget _buildSmartBalanceAndReceiptShowcase(HallmarkColorScheme colors, bool isDark) {
    return Container(
      height: 270,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderTactile, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Digital Receipt Paper Card (Authentic Kantin Digital Receipt)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceBase,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderTactile, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Logo & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'KD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KANTIN DIGITAL',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              'KD-TX-20260815 • 10:15 WIB',
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'BERHASIL',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildDashedDivider(colors.borderTactile),

                // Info Rows (Siswa & Stan)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Siswa',
                            style: TextStyle(fontSize: 8, color: colors.textMuted),
                          ),
                          Text(
                            'Ahmad Z. (XII RPL 1)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Stan Kantin',
                            style: TextStyle(fontSize: 8, color: colors.textMuted),
                          ),
                          Text(
                            'Stan 1 (Bude Ani)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildDashedDivider(colors.borderTactile),

                // Itemized Purchases (Real Canteen Items)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '1x Nasi Goreng Spesial',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Rp 12.000',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '1x Es Teh Manis Segar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Rp 3.000',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                _buildDashedDivider(colors.borderTactile),

                // Total & Balance Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sisa Saldo RFID',
                          style: TextStyle(
                            fontSize: 8,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp 45.000',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Bayar (RFID)',
                          style: TextStyle(
                            fontSize: 8,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp 15.000',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: colors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Real-time Parent Notification & Live Tracking Sync Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.brandPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.brandPrimary.withValues(alpha: 0.2), width: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active_rounded, size: 12, color: colors.brandPrimary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Struk & notifikasi real-time terkirim ke ponsel Orang Tua',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: colors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dashed Perforated Divider for Realistic Digital Receipt
  Widget _buildDashedDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 4.0;
          const dashSpace = 3.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor().clamp(1, 100);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(0.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Finger-friendly Bottom Action Buttons with Wizard Next / Enter flow
  Widget _buildBottomActionButtons(BuildContext context, HallmarkColorScheme colors) {
    final bool isLastSlide = _wizardIndex >= 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderTactile, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HallmarkButton(
            label: isLastSlide ? 'MASUK SEKARANG' : 'SELANJUTNYA',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (isLastSlide) {
                context.go('/login?from=/welcome');
              } else {
                _wizardController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          const SizedBox(height: 8),
          HallmarkButton(
            label: 'Lewati',
            isFullWidth: true,
            onPressed: isLastSlide
                ? null
                : () => context.go('/login?from=/welcome'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AUTONOMOUS LIVING HUMAN STUDENTS IN VIBRANT CANTEEN ENVIRONMENT
// 10 Autonomous school students roaming in a lively canteen with food stalls, dining tables & chairs
// ============================================================================

class LivingRfidCardsWorldStage extends StatefulWidget {
  const LivingRfidCardsWorldStage({super.key});

  @override
  State<LivingRfidCardsWorldStage> createState() => _LivingRfidCardsWorldStageState();
}

class _LivingRfidCardsWorldStageState extends State<LivingRfidCardsWorldStage>
    with TickerProviderStateMixin {
  late final Timer _tickerTimer;
  final math.Random _random = math.Random();

  // Exactly 6 Diverse Living Human Student Presets in School Canteen
  final List<Map<String, dynamic>> _studentPresets = [
    {
      'name': 'Ahmad',
      'nisn': '20260012',
      'class': 'XII RPL 1',
      'dialog': 'Bude, Nasi Goreng 1!',
      'colors': [const Color(0xFF2563EB), const Color(0xFF1D4ED8)], // Royal Blue
      'speed': 1.10,
      'variant': 0, // Male Standard
      'isSitting': false,
    },
    {
      'name': 'Siti',
      'nisn': '20260015',
      'class': 'XII RPL 2',
      'dialog': 'Es Teh Jumbo Bude!',
      'colors': [const Color(0xFFEC4899), const Color(0xFFDB2777)], // Pink / Rose
      'speed': 0.85,
      'variant': 1, // Female White Hijab
      'isSitting': false,
    },
    {
      'name': 'Budi',
      'nisn': '20260020',
      'class': 'XI TKJ 1',
      'dialog': 'Bayar Tap RFID Aja!',
      'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber / Coral
      'speed': 1.00,
      'variant': 2, // Male Sporty
      'isSitting': false,
    },
    {
      'name': 'Maya',
      'nisn': '20260024',
      'class': 'X PPLG 1',
      'dialog': 'Soto Ayam Panas!',
      'colors': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Purple
      'speed': 0.95,
      'variant': 3, // Female Ponytail
      'isSitting': false,
    },
    {
      'name': 'Dika',
      'nisn': '20260055',
      'class': 'XII RPL 3',
      'dialog': 'Saldo Masih Aman!',
      'colors': [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Indigo
      'speed': 1.05,
      'variant': 5, // Male with Glasses
      'isSitting': false,
    },
    {
      'name': 'Rian',
      'nisn': '20260031',
      'class': 'XII TKJ 2',
      'dialog': 'Jus Alpukat Segar!',
      'colors': [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald Green
      'speed': 0.90,
      'variant': 0, // Male Standard
      'isSitting': false,
    },
  ];

  // Character States (6 students)
  final List<_CharacterState> _characters = [];
  int? _draggedIndex;

  // Impact Landing Ripple Overlay
  Offset? _rippleCenter;
  late AnimationController _rippleController;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rippleScale = Tween<double>(begin: 0.5, end: 2.2).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
    _rippleOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _initCharacters();

    // 60 FPS Autonomous Movement & Interaction Ticker (16ms)
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      _updateAutonomousWorld();
    });
  }

  void _initCharacters() {
    _characters.clear();
    // 6 students nicely spread out (mencar) across the canteen floor
    final List<Offset> initialAnchors = [
      const Offset(16.0, 140.0),  // 0. Ahmad: far left near gerobak
      const Offset(78.0, 168.0),  // 1. Siti: left foreground near table 1
      const Offset(118.0, 142.0), // 2. Budi: center aisle near cashier
      const Offset(50.0, 138.0),  // 3. Maya: mid-left aisle
      const Offset(152.0, 170.0), // 4. Dika: right foreground near table 2
      const Offset(186.0, 136.0), // 5. Rian: far right near drink counter
    ];

    for (int i = 0; i < _studentPresets.length; i++) {
      final preset = _studentPresets[i];
      final initPos = (i < initialAnchors.length)
          ? initialAnchors[i]
          : Offset(16.0 + i * 34.0, 145.0);

      _characters.add(
        _CharacterState(
          id: 'student_$i',
          name: preset['name'],
          nisn: preset['nisn'],
          className: preset['class'],
          dialog: preset['dialog'],
          colors: preset['colors'],
          speed: preset['speed'],
          variant: preset['variant'],
          isSitting: false,
          position: initPos,
          targetPosition: initPos,
        ),
      );
      _pickNewWaypoint(i);
    }
  }

  @override
  void dispose() {
    _tickerTimer.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  void _pickNewWaypoint(int index) {
    if (index >= _characters.length) return;
    final char = _characters[index];
    if (char.isDragged || char.isInteracting) return;

    char.targetPosition = Offset(
      10.0 + _random.nextDouble() * 185.0,
      135.0 + _random.nextDouble() * 42.0, // Grounded on floor (Y: 135 to 177)
    );
    char.isMoving = true;
  }

  void _updateAutonomousWorld() {
    setState(() {
      final double nowTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      for (int i = 0; i < _characters.length; i++) {
        final char = _characters[i];
        if (char.isDragged) continue;

        char.scale = 0.88 + (char.position.dy / 270.0) * 0.12;

        if (char.isMoving && !char.isInteracting) {
          final delta = char.targetPosition - char.position;
          final dist = delta.distance;

          if (dist < 4.0) {
            char.isMoving = false;
            char.idleTicks = 60 + _random.nextInt(120);
            char.rotation = 0.0;
          } else {
            final moveVector = (delta / dist) * (char.speed * 0.90);
            char.position += moveVector;
            char.rotation = (delta.dx / dist) * 0.07;
            char.bobY = math.sin(nowTime * 8) * 2.0;
          }
        } else {
          char.rotation = 0.0;
          char.bobY = math.sin(nowTime * 3) * 1.5;

          if (char.idleTicks > 0) {
            char.idleTicks--;
          } else if (!char.isInteracting) {
            _pickNewWaypoint(i);
          }
        }
      }
    });
  }

  void _handleTapCard(int index) {
    HapticFeedback.mediumImpact();
    final char = _characters[index];
    setState(() {
      char.isWaving = true;
      char.bobY = -14.0;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        char.isWaving = false;
      });
    });
  }

  void _handlePanStart(int index, DragStartDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _draggedIndex = index;
      _characters[index].isDragged = true;
      _characters[index].isWaving = true;
    });
  }

  void _handlePanUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final char = _characters[index];
      char.position += details.delta;
      char.position = Offset(
        char.position.dx.clamp(6.0, 205.0),
        char.position.dy.clamp(130.0, 182.0),
      );
    });
  }

  void _handlePanEnd(int index, DragEndDetails details) {
    HapticFeedback.mediumImpact();
    final char = _characters[index];

    _rippleCenter = Offset(char.position.dx + 18, char.position.dy + 56);
    _rippleController.forward(from: 0.0);

    setState(() {
      char.isDragged = false;
      char.isWaving = false;
      _draggedIndex = null;
      _pickNewWaypoint(index);
    });
  }

  List<Widget> _buildSortedCharacters(bool isDark) {
    final indices = List<int>.generate(_characters.length, (i) => i);
    indices.sort((a, b) => _characters[a].position.dy.compareTo(_characters[b].position.dy));

    return indices.map((index) {
      final char = _characters[index];
      final bool isDragged = _draggedIndex == index;

      return Positioned(
        left: char.position.dx,
        top: char.position.dy + char.bobY,
        child: GestureDetector(
          onTap: () => _handleTapCard(index),
          onPanStart: (details) => _handlePanStart(index, details),
          onPanUpdate: (details) => _handlePanUpdate(index, details),
          onPanEnd: (details) => _handlePanEnd(index, details),
          child: _buildStudentHumanCharacter(char, isDragged, isDark),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    // Self-healing: Ensure all 6 students are initialized even across hot reloads
    if (_characters.length != _studentPresets.length) {
      _initCharacters();
    }

    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderTactile, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. Full Canteen Atmosphere, Food Stalls, Warung & Checked Floor Painter
          Positioned.fill(
            child: CustomPaint(
              painter: _CanteenMasterScenePainter(
                brandPrimary: colors.brandPrimary,
                borderTactile: colors.borderTactile,
                isDark: isDark,
              ),
            ),
          ),

          // 2. Shockwave Landing Ripple Overlay
          if (_rippleCenter != null)
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return Positioned(
                  left: _rippleCenter!.dx - 30,
                  top: _rippleCenter!.dy - 30,
                  child: Transform.scale(
                    scale: _rippleScale.value,
                    child: Opacity(
                      opacity: _rippleOpacity.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.brandPrimary, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // 3. Render 6 Living Human Student Characters (3 Sitting at tables + 3 Walking, No Shadows)
          ..._buildSortedCharacters(isDark),

          // 4. Bottom Canteen Floor Hint Text Bar
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 11, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Geser atau ketuk siswa untuk berinteraksi di kantin',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Real Human Student Character (Clean, No Name Badge Underneath)
  Widget _buildStudentHumanCharacter(_CharacterState char, bool isDragged, bool isDark) {
    final double currentScale = isDragged ? char.scale * 1.15 : char.scale;
    final int variant = char.variant;
    final bool isFemale = variant == 1 || variant == 3 || variant == 4;

    // Walk cycle leg rotation
    final double walkPhase = char.isMoving ? math.sin(DateTime.now().millisecondsSinceEpoch / 1000.0 * 8) : 0.0;
    final double leftLegRotation = walkPhase * 0.22;
    final double rightLegRotation = -walkPhase * 0.22;

    return Transform(
      transform: Matrix4.diagonal3Values(currentScale, currentScale, 1.0)
        ..rotateZ(char.rotation),
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Canteen Speech Bubble on tap / drag (Anti-Emoji)
          if (char.isWaving || isDragged)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: char.colors[0],
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: char.colors[0].withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Text(
                char.dialog,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),

          // Human Student Body Anatomy (Head, Torso, Arms, Legs)
          SizedBox(
            width: 36,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Lower Body & Legs
                Positioned(
                  top: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: leftLegRotation,
                        child: _buildStudentLeg(isFemale),
                      ),
                      const SizedBox(width: 3),
                      Transform.rotate(
                        angle: rightLegRotation,
                        child: _buildStudentLeg(isFemale),
                      ),
                    ],
                  ),
                ),

                // Torso & Uniform
                Positioned(
                  top: 18,
                  child: _buildStudentTorso(char, isFemale),
                ),

                // Left Arm
                Positioned(
                  top: 20,
                  left: 1,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: char.isWaving ? -0.15 : (isDragged ? -0.22 : 0.02),
                    child: Container(
                      width: 6.5,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFDFBA), // Skin tone
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right Arm (Holding RFID Card / Waving)
                Positioned(
                  top: 20,
                  right: 1,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: char.isWaving ? 0.22 : (isDragged ? 0.28 : -0.05),
                    child: Column(
                      children: [
                        Container(
                          width: 6.5,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFDFBA),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        // Mini RFID Card in Hand!
                        Container(
                          width: 9,
                          height: 6.5,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: char.colors[0],
                            borderRadius: BorderRadius.circular(1.5),
                            border: Border.all(color: Colors.white, width: 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: char.colors[0].withValues(alpha: 0.4),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 2.5,
                              height: 1.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24), // Gold Chip
                                borderRadius: BorderRadius.circular(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Head (Face + Hair / Hijab)
                Positioned(
                  top: 0,
                  child: _buildStudentHead(char, variant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHead(_CharacterState char, int variant) {
    if (variant == 1) {
      // Siti: Siswi SMA Berhijab Putih Rapi
      return SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            Container(
              width: 14,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDFBA),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(char.isWaving),
                      const SizedBox(width: 4),
                      _buildEye(char.isWaving),
                    ],
                  ),
                  const SizedBox(height: 1.5),
                  _buildSmile(),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (variant == 4) {
      // Putri / Annisa: Siswi Berhijab Berwarna (Navy / Cyan / Rose)
      return SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: char.colors[0],
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: char.colors[0].withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            Container(
              width: 14,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDFBA),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(char.isWaving),
                      const SizedBox(width: 4),
                      _buildEye(char.isWaving),
                    ],
                  ),
                  const SizedBox(height: 1.5),
                  _buildSmile(),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (variant == 3) {
      // Maya: Siswi Rambut Kuncir Ponytail
      return SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Face
            Positioned(
              top: 4,
              child: Container(
                width: 16,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDFBA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEye(char.isWaving),
                        const SizedBox(width: 4),
                        _buildEye(char.isWaving),
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    _buildSmile(),
                  ],
                ),
              ),
            ),
            // Hair
            Positioned(
              top: 0,
              child: Container(
                width: 18,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF271C19),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                ),
              ),
            ),
            // Ponytail top tuft
            Positioned(
              top: -3,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: char.colors[0],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Male Students (Ahmad, Budi, Rian, Dika, Fajar, Kevin)
      final Color hairColor = (variant == 2)
          ? const Color(0xFF334155)
          : (variant == 5 ? const Color(0xFF1E293B) : const Color(0xFF0F172A));

      return SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Face
            Positioned(
              top: 4,
              child: Container(
                width: 16,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDFBA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEye(char.isWaving),
                        const SizedBox(width: 5),
                        _buildEye(char.isWaving),
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    _buildSmile(),
                  ],
                ),
              ),
            ),
            // Hair
            Positioned(
              top: 0,
              child: Container(
                width: 19,
                height: 9,
                decoration: BoxDecoration(
                  color: hairColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9), bottom: Radius.circular(3)),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEye(bool isWaving) {
    if (isWaving) {
      return Container(
        width: 2.8,
        height: 1.5,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black87, width: 1.0),
          ),
        ),
      );
    }
    return Container(
      width: 2.4,
      height: 2.4,
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSmile() {
    return Container(
      width: 4,
      height: 1.5,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFBE123C), width: 1.0),
        ),
      ),
    );
  }

  Widget _buildStudentTorso(_CharacterState char, bool isFemale) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: Colors.white, // Kemeja Putih SMA
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.7),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Dasi Abu-abu SMA
          Positioned(
            top: 2,
            child: Container(
              width: 2.5,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF64748B), // Abu-abu SMA
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Lanyard Tali Leher RFID Card
          Positioned(
            top: 1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: char.colors[0], width: 0.8),
                  right: BorderSide(color: char.colors[0], width: 0.8),
                  bottom: BorderSide(color: char.colors[0], width: 0.8),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLeg(bool isFemale) {
    const Color pantsColor = Color(0xFF64748B);

    return Column(
      children: [
        // Pants / Skirt
        Container(
          width: 6.5,
          height: 11,
          decoration: BoxDecoration(
            color: pantsColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        // Shoes (Sneakers Hitam Putih)
        Container(
          width: 7.5,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(1.5),
            border: Border.all(color: Colors.white, width: 0.5),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CANTEEN MASTER SCENE PAINTER (WITH DINING TABLES, CHAIRS & FOOD SHOWCASES)
// ============================================================================

class _CanteenMasterScenePainter extends CustomPainter {
  final Color brandPrimary;
  final Color borderTactile;
  final bool isDark;

  _CanteenMasterScenePainter({
    required this.brandPrimary,
    required this.borderTactile,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double floorY = 124.0;

    // ────────────────────────────────────────────────────────────────────────
    // 1. CANTEEN WALL BACKGROUND WITH SUBWAY CERAMIC TILES
    // ────────────────────────────────────────────────────────────────────────
    final Rect wallRect = Rect.fromLTWH(0, 0, size.width, floorY);
    final Paint wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF0F172A),
                const Color(0xFF1E293B),
              ]
            : [
                const Color(0xFFFFFBEB), // Soft warm cream canteen wall
                const Color(0xFFF1F5F9), // Soft slate gradient
              ],
      ).createShader(wallRect);
    canvas.drawRect(wallRect, wallPaint);

    // Wall Tile Grout Lines
    final Paint wallTilePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.04 : 0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double y = 14.0; y < floorY; y += 14.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), wallTilePaint);
      final bool isOffset = (y ~/ 14) % 2 == 1;
      for (double x = (isOffset ? 14.0 : 0.0); x < size.width; x += 28.0) {
        canvas.drawLine(Offset(x, y - 14.0), Offset(x, y), wallTilePaint);
      }
    }

    // ────────────────────────────────────────────────────────────────────────
    // 2. FESTIVE CANTEEN BUNTING FLAGS (TOP CANOPY PENNANTS)
    // ────────────────────────────────────────────────────────────────────────
    final List<Color> flagColors = [
      brandPrimary,
      const Color(0xFFEA580C),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      brandPrimary,
      const Color(0xFFEA580C),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];

    final double flagWidth = size.width / flagColors.length;
    for (int i = 0; i < flagColors.length; i++) {
      final double x1 = i * flagWidth;
      final double x2 = (i + 1) * flagWidth;
      final double xMid = (x1 + x2) / 2;
      final double flagHeight = 11.0 + (i % 2 == 0 ? 3.0 : 0.0);

      final Path flagPath = Path()
        ..moveTo(x1, 0)
        ..lineTo(x2, 0)
        ..lineTo(xMid, flagHeight)
        ..close();

      final Paint flagPaint = Paint()
        ..color = flagColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawPath(flagPath, flagPaint);
    }

    // ────────────────────────────────────────────────────────────────────────
    // 3. WARM PENDANT LAMPS & GLOW CONES
    // ────────────────────────────────────────────────────────────────────────
    void drawPendantLamp(double xPos) {
      final Paint cordPaint = Paint()
        ..color = isDark ? Colors.white60 : Colors.black87
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, 20), cordPaint);

      // Lamp Shade
      final Path shadePath = Path()
        ..moveTo(xPos - 7, 26)
        ..lineTo(xPos + 7, 26)
        ..lineTo(xPos + 3.5, 20)
        ..lineTo(xPos - 3.5, 20)
        ..close();
      final Paint shadePaint = Paint()
        ..color = isDark ? const Color(0xFF475569) : const Color(0xFF334155)
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadePath, shadePaint);

      // Glowing Bulb
      final Paint bulbPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(xPos, 27), 3.0, bulbPaint);

      // Light Cone
      final Path conePath = Path()
        ..moveTo(xPos - 3.5, 27)
        ..lineTo(xPos + 3.5, 27)
        ..lineTo(xPos + 35, floorY)
        ..lineTo(xPos - 35, floorY)
        ..close();
      final Paint conePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFBBF24).withValues(alpha: isDark ? 0.20 : 0.10),
            const Color(0xFFFBBF24).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(xPos - 35, 27, 70, floorY - 27));
      canvas.drawPath(conePath, conePaint);
    }

    drawPendantLamp(size.width * 0.22);
    drawPendantLamp(size.width * 0.78);

    // ────────────────────────────────────────────────────────────────────────
    // 4. WALL MENU CHALKBOARD (CENTER)
    // ────────────────────────────────────────────────────────────────────────
    final double boardWidth = 115.0;
    final double boardHeight = 20.0;
    final double boardX = (size.width - boardWidth) / 2;
    final double boardY = 14.0;

    final RRect frameRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boardX - 2, boardY - 2, boardWidth + 4, boardHeight + 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(frameRRect, Paint()..color = const Color(0xFF854D0E));

    final RRect boardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boardX, boardY, boardWidth, boardHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(boardRRect, Paint()..color = const Color(0xFF1E293B));

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'WARUNG KANTIN SEHAT',
        style: GoogleFonts.inter(
          fontSize: 7,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFEF08A),
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(boardX + (boardWidth - textPainter.width) / 2, boardY + 3.0));

    final TextPainter subTextPainter = TextPainter(
      text: TextSpan(
        text: '• SOTO • NASI GORENG • ES TEH •',
        style: GoogleFonts.inter(
          fontSize: 5,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subTextPainter.paint(canvas, Offset(boardX + (boardWidth - subTextPainter.width) / 2, boardY + 11.5));

    // ────────────────────────────────────────────────────────────────────────
    // 5. GEROBAK WARUNG MAKANAN (BUDE ANI) - SISI KIRI & TENGAH
    // ────────────────────────────────────────────────────────────────────────
    final double cartLeft = 14.0;
    final double cartWidth = 145.0;

    // Atap Kanopi Gerobak Lengkung
    final Path cartRoofPath = Path()
      ..moveTo(cartLeft - 4, 44)
      ..quadraticBezierTo(cartLeft + cartWidth / 2, 32, cartLeft + cartWidth + 4, 44)
      ..lineTo(cartLeft + cartWidth + 2, 51)
      ..quadraticBezierTo(cartLeft + cartWidth / 2, 40, cartLeft - 2, 51)
      ..close();
    canvas.drawPath(cartRoofPath, Paint()..color = const Color(0xFF15803D));

    // Striping Atap Gerobak
    for (int s = 0; s < 6; s++) {
      if (s % 2 == 1) {
        final double xS1 = cartLeft + s * (cartWidth / 6);
        final double xS2 = cartLeft + (s + 1) * (cartWidth / 6);
        final Path stripePath = Path()
          ..moveTo(xS1, 44)
          ..lineTo(xS2, 44)
          ..lineTo(xS2 - 1, 50)
          ..lineTo(xS1 - 1, 50)
          ..close();
        canvas.drawPath(stripePath, Paint()..color = const Color(0xFFFBBF24));
      }
    }

    // Tiang Penyangga Gerobak Kayu
    final Paint polePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cartLeft + 4, 50), Offset(cartLeft + 4, 122), polePaint);
    canvas.drawLine(Offset(cartLeft + cartWidth - 4, 50), Offset(cartLeft + cartWidth - 4, 122), polePaint);

    // Etalase Kaca Gerobak
    final Rect glassRect = Rect.fromLTWH(cartLeft + 8, 52, cartWidth - 16, 40);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glassRect, const Radius.circular(3)),
      Paint()
        ..color = isDark
            ? const Color(0xFF334155).withValues(alpha: 0.6)
            : const Color(0xFFE0F2FE).withValues(alpha: 0.75)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glassRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Dandang Soto Stainless Steel
    final Rect dandangRect = Rect.fromLTWH(cartLeft + cartWidth - 34, 58, 18, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(dandangRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF94A3B8),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cartLeft + cartWidth - 25, 58), width: 20, height: 4),
      Paint()..color = const Color(0xFFCBD5E1),
    );

    // Toples Kerupuk Kaleng Biru Vintage Kantin
    final Rect kalengRect = Rect.fromLTWH(cartLeft + 46, 74, 15, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(kalengRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF0284C7),
    );
    canvas.drawCircle(Offset(cartLeft + 53.5, 82), 4.5, Paint()..color = Colors.white70);

    // Botol Saus & Kecap
    canvas.drawRect(Rect.fromLTWH(cartLeft + 68, 76, 3.5, 13), Paint()..color = const Color(0xFF451A03));
    canvas.drawRect(Rect.fromLTWH(cartLeft + 74, 76, 3.5, 13), Paint()..color = const Color(0xFFDC2626));

    // Meja Badan Gerobak Kayu
    final Rect cartBodyRect = Rect.fromLTWH(cartLeft + 4, 94, cartWidth - 8, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cartBodyRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFB45309),
    );

    // Papan Nama Gerobak
    final Rect signRect = Rect.fromLTWH(cartLeft + 12, 100, cartWidth - 24, 15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFFEF3C7),
    );
    final TextPainter gerobakSign = TextPainter(
      text: TextSpan(
        text: 'GEROBAK STAN 1: BUDE ANI',
        style: GoogleFonts.inter(
          fontSize: 7,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF92400E),
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gerobakSign.paint(canvas, Offset(cartLeft + 12 + (cartWidth - 24 - gerobakSign.width) / 2, 103.5));

    // Roda Gerobak Kayu di Kiri Bawah
    final Offset wheelCenter = Offset(cartLeft + 18, 126);
    canvas.drawCircle(wheelCenter, 13, Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(wheelCenter, 11, Paint()..color = const Color(0xFFB45309));
    canvas.drawCircle(wheelCenter, 3.0, Paint()..color = const Color(0xFF451A03));

    // ────────────────────────────────────────────────────────────────────────
    // 6. WARUNG MINUMAN & ES SEGAR - SISI KANAN
    // ────────────────────────────────────────────────────────────────────────
    final double barLeft = size.width - 90.0;
    final double barWidth = 78.0;

    final Path drinkRoof = Path()
      ..moveTo(barLeft - 2, 48)
      ..lineTo(barLeft + barWidth + 2, 48)
      ..lineTo(barLeft + barWidth - 2, 54)
      ..lineTo(barLeft + 2, 54)
      ..close();
    canvas.drawPath(drinkRoof, Paint()..color = const Color(0xFF0284C7));

    canvas.drawLine(Offset(barLeft + 2, 54), Offset(barLeft + 2, 122), polePaint);
    canvas.drawLine(Offset(barLeft + barWidth - 2, 54), Offset(barLeft + barWidth - 2, 122), polePaint);

    final Rect drinkBarRect = Rect.fromLTWH(barLeft, 92, barWidth, 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(drinkBarRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF0369A1),
    );

    final TextPainter drinkSign = TextPainter(
      text: TextSpan(
        text: 'ES & JUS SEGAR',
        style: GoogleFonts.inter(
          fontSize: 6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    drinkSign.paint(canvas, Offset(barLeft + (barWidth - drinkSign.width) / 2, 102));

    // Dispenser Es Teh & Sirup
    final Rect dispenserRect = Rect.fromLTWH(barLeft + 6, 62, 16, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(dispenserRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFD97706).withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(dispenserRect, const Radius.circular(2)),
      Paint()..color = Colors.white70..strokeWidth = 0.8..style = PaintingStyle.stroke,
    );

    // Blender Jus
    final Rect blenderRect = Rect.fromLTWH(barLeft + 28, 66, 13, 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(blenderRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.8),
    );

    // ────────────────────────────────────────────────────────────────────────
    // 7. REAL CHECKERED & CERAMIC CANTEEN FLOOR
    // ────────────────────────────────────────────────────────────────────────
    final Rect skirtingRect = Rect.fromLTWH(0, floorY - 2, size.width, 5);
    canvas.drawRect(skirtingRect, Paint()..color = const Color(0xFF78350F));

    final Rect floorRect = Rect.fromLTWH(0, floorY + 3, size.width, size.height - floorY);
    final Paint floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
              ]
            : [
                const Color(0xFFF1F5F9), // Keramik terang bersih
                const Color(0xFFE2E8F0), // Kedalaman perspektif
              ],
      ).createShader(floorRect);
    canvas.drawRect(floorRect, floorPaint);

    final Paint tileGroutPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF94A3B8)).withValues(alpha: isDark ? 0.15 : 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final List<double> horizontalTileY = [
      floorY + 12.0,
      floorY + 32.0,
      floorY + 58.0,
      floorY + 92.0,
      floorY + 134.0,
    ];

    for (final y in horizontalTileY) {
      if (y < size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), tileGroutPaint);
      }
    }

    for (int t = 0; t <= 8; t++) {
      final double xTop = size.width * (t / 8.0);
      final double xBottom = size.width * (0.5 + (t - 4.0) * 0.18);
      canvas.drawLine(Offset(xTop, floorY + 3), Offset(xBottom, size.height), tileGroutPaint);
    }

    // ────────────────────────────────────────────────────────────────────────
    // 8. CANTEEN DINING TABLES & CHAIRS (MEJA & KURSI MAKAN KANTIN)
    // ────────────────────────────────────────────────────────────────────────
    void drawCanteenTableAndChairs({
      required double x,
      required double y,
      required double width,
      required double height,
      required Color tableColor,
      required bool hasSoup,
    }) {
      // 1. Kursi / Bangku Kantin Atas
      for (int c = 0; c < 2; c++) {
        final double chairX = x + 16.0 + c * (width - 32.0);
        // Seat
        canvas.drawOval(
          Rect.fromCenter(center: Offset(chairX, y - 6), width: 14, height: 7),
          Paint()..color = const Color(0xFF78350F),
        );
        // Steel legs
        canvas.drawLine(Offset(chairX - 4, y - 3), Offset(chairX - 4, y + 2), Paint()..color = const Color(0xFF334155)..strokeWidth = 1.0);
        canvas.drawLine(Offset(chairX + 4, y - 3), Offset(chairX + 4, y + 2), Paint()..color = const Color(0xFF334155)..strokeWidth = 1.0);
      }

      // 2. Meja Makan Kayu Panjang
      // Table Leg Shadows
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 8, y + height + 2), width: 12, height: 4), Paint()..color = Colors.black26);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + width - 8, y + height + 2), width: 12, height: 4), Paint()..color = Colors.black26);

      // Steel Table Legs
      final Paint tableLegPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 2.0;
      canvas.drawLine(Offset(x + 8, y + height - 2), Offset(x + 8, y + height + 2), tableLegPaint);
      canvas.drawLine(Offset(x + width - 8, y + height - 2), Offset(x + width - 8, y + height + 2), tableLegPaint);

      // Table Top Surface
      final RRect tableTopRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(tableTopRRect, Paint()..color = tableColor);
      canvas.drawRRect(
        tableTopRRect,
        Paint()..color = const Color(0xFF451A03)..strokeWidth = 1.0..style = PaintingStyle.stroke,
      );

      // Wood Grain Highlight Line
      canvas.drawLine(
        Offset(x + 4, y + 3),
        Offset(x + width - 4, y + 3),
        Paint()..color = Colors.white.withValues(alpha: 0.25)..strokeWidth = 1.0,
      );

      // 3. Makanan & Minuman di Atas Meja Kantin
      if (hasSoup) {
        // Mangkok Soto Putih
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 20, y + height * 0.45), width: 12, height: 7), Paint()..color = Colors.white);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 20, y + height * 0.40), width: 9, height: 4), Paint()..color = const Color(0xFFF59E0B));
        // Gelas Es Teh
        canvas.drawRect(Rect.fromLTWH(x + 36, y + 3, 5, 9), Paint()..color = const Color(0xFFD97706).withValues(alpha: 0.85));
        canvas.drawLine(Offset(x + 38, y + 3), Offset(x + 40, y - 2), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 0.8);
        // Tempat Tissue
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 50, y + 4, 8, 8), const Radius.circular(1)), Paint()..color = Colors.white70);
      } else {
        // Nampan Gorengan
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 16, y + 4, 18, 9), const Radius.circular(1.5)), Paint()..color = const Color(0xFF94A3B8));
        canvas.drawCircle(Offset(x + 22, y + 8), 2.5, Paint()..color = const Color(0xFFD97706));
        canvas.drawCircle(Offset(x + 28, y + 8), 2.5, Paint()..color = const Color(0xFFF59E0B));
        // Gelas Jus Hijau
        canvas.drawRect(Rect.fromLTWH(x + 44, y + 3, 5, 9), Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.85));
        canvas.drawLine(Offset(x + 46, y + 3), Offset(x + 48, y - 2), Paint()..color = const Color(0xFF3B82F6)..strokeWidth = 0.8);
      }

      // 4. Kursi / Bangku Kantin Bawah
      for (int c = 0; c < 2; c++) {
        final double chairX = x + 16.0 + c * (width - 32.0);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(chairX, y + height + 5), width: 14, height: 7),
          Paint()..color = const Color(0xFF78350F),
        );
      }
    }

    // Draw 2 Canteen Dining Tables with Chairs on Floor
    drawCanteenTableAndChairs(
      x: 18.0,
      y: 168.0,
      width: 74.0,
      height: 18.0,
      tableColor: const Color(0xFF92400E),
      hasSoup: true,
    );

    drawCanteenTableAndChairs(
      x: size.width - 98.0,
      y: 174.0,
      width: 70.0,
      height: 18.0,
      tableColor: const Color(0xFFB45309),
      hasSoup: false,
    );

    // ────────────────────────────────────────────────────────────────────────
    // 9. CENTRAL RFID TAP COUNTER ZONE ON FLOOR
    // ────────────────────────────────────────────────────────────────────────
    final Offset tapCenter = Offset(size.width * 0.5, size.height * 0.76);

    // Outer Glow Ring
    canvas.drawOval(
      Rect.fromCenter(center: tapCenter, width: 95, height: 28),
      Paint()..color = brandPrimary.withValues(alpha: isDark ? 0.18 : 0.12)..style = PaintingStyle.fill,
    );

    // Tactile Border
    canvas.drawOval(
      Rect.fromCenter(center: tapCenter, width: 86, height: 24),
      Paint()
        ..color = brandPrimary.withValues(alpha: isDark ? 0.55 : 0.45)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CanteenMasterScenePainter oldDelegate) {
    return oldDelegate.brandPrimary != brandPrimary ||
        oldDelegate.borderTactile != borderTactile ||
        oldDelegate.isDark != isDark;
  }
}

/// Helper Model Class for Autonomous Living Human Student Character State
class _CharacterState {
  final String id;
  final String name;
  final String nisn;
  final String className;
  final String dialog;
  final List<Color> colors;
  final double speed;
  final int variant;
  final bool isSitting;

  Offset position;
  Offset targetPosition;
  double scale;
  double rotation;
  double bobY;
  bool isMoving;
  bool isDragged;
  bool isWaving;
  bool isInteracting;
  int idleTicks;

  _CharacterState({
    required this.id,
    required this.name,
    required this.nisn,
    required this.className,
    required this.dialog,
    required this.colors,
    required this.speed,
    required this.variant,
    required this.isSitting,
    required this.position,
    required this.targetPosition,
  })  : scale = 1.0,
        rotation = 0.0,
        bobY = 0.0,
        isMoving = false,
        isDragged = false,
        isWaving = false,
        isInteracting = false,
        idleTicks = 0;
}

class _FeatureChipData {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChipData({
    required this.icon,
    required this.label,
    required this.color,
  });
}
