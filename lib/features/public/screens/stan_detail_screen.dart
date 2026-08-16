import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Halaman Detail Stan / Toko Kantin bergaya GoFood
class StanDetailScreen extends ConsumerStatefulWidget {
  final String canteenId;
  final String? initialProductId;

  const StanDetailScreen({
    super.key,
    required this.canteenId,
    this.initialProductId,
  });

  @override
  ConsumerState<StanDetailScreen> createState() => _StanDetailScreenState();
}

class _StanDetailScreenState extends ConsumerState<StanDetailScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _cartKey = GlobalKey();
  final Map<String, GlobalKey> _categoryHeaderKeys = {};

  // State
  String _selectedDeliveryMode = 'pickup'; // 'delivery' or 'pickup'
  String? _highlightedProductId;
  bool _hasTriggeredPulse = false;

  // Pulse Controller for the chosen product highlight
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseGlow;

  // Flying Cart Animation Overlay State
  OverlayEntry? _flyingCartOverlay;
  late AnimationController _flyingController;
  Offset _startFlyPos = Offset.zero;
  Offset _endFlyPos = Offset.zero;
  String _flyingImageUrl = '';

  @override
  void initState() {
    super.initState();
    _highlightedProductId = widget.initialProductId;

    // Green pulse animation controller (runs 1x smoothly)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 0.99).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.99, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 30),
    ]).animate(_pulseController);

    _pulseGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_pulseController);

    // Flying cart controller
    _flyingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasTriggeredPulse && _highlightedProductId != null) {
        _hasTriggeredPulse = true;
        _pulseController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flyingController.dispose();
    _scrollController.dispose();
    _removeFlyingOverlay();
    super.dispose();
  }

  void _removeFlyingOverlay() {
    _flyingCartOverlay?.remove();
    _flyingCartOverlay = null;
  }

  /// Memulai animasi terbang produk ke arah keranjang menggunakan BuildContext
  void _triggerFlyingCartAnimationFromContext(BuildContext sourceContext, String imageUrl, VoidCallback onComplete) {
    HapticFeedback.lightImpact();

    final RenderBox? sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final RenderBox? cartBox = _cartKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceBox == null) {
      onComplete();
      return;
    }

    final Size screenSize = MediaQuery.of(context).size;
    final Offset sourcePos = sourceBox.localToGlobal(Offset.zero);
    final Offset targetPos = cartBox != null
        ? cartBox.localToGlobal(Offset.zero) + Offset(cartBox.size.width / 2, cartBox.size.height / 2)
        : Offset(screenSize.width / 2, screenSize.height - 70);

    _startFlyPos = sourcePos + Offset(sourceBox.size.width / 2 - 20, sourceBox.size.height / 2 - 20);
    _endFlyPos = targetPos - const Offset(20, 20);
    _flyingImageUrl = imageUrl;

    _removeFlyingOverlay();

    _flyingCartOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _flyingController,
          builder: (context, child) {
            final double t = _flyingController.value;
            final double x = (1 - t) * _startFlyPos.dx + t * _endFlyPos.dx;
            final double controlY = math.min(_startFlyPos.dy, _endFlyPos.dy) - 90;
            final double y = (1 - t) * (1 - t) * _startFlyPos.dy + 2 * (1 - t) * t * controlY + t * t * _endFlyPos.dy;

            final double scale = 1.0 - (0.65 * t);
            final double opacity = t > 0.85 ? ((1.0 - t) / 0.15).clamp(0.0, 1.0) : 1.0;
            final double rotation = t * math.pi;

            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            blurRadius: 14,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF10B981), width: 2),
                      ),
                      child: ClipOval(
                        child: _flyingImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _flyingImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                errorWidget: (_, __, ___) => const Icon(Icons.restaurant, color: Nebula.teal),
                              )
                            : const Icon(Icons.fastfood, color: Nebula.teal),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final overlay = Overlay.of(context);
    overlay.insert(_flyingCartOverlay!);

    _flyingController.forward(from: 0.0).then((_) {
      _removeFlyingOverlay();
      onComplete();
    });
  }

  /// Menangani penambahan produk dengan proteksi Single-Merchant GoFood
  void _handleAddToCart({
    required BuildContext sourceContext,
    required String stanId,
    required String stanName,
    required int deliveryFee,
    required Product product,
  }) {
    final cartNotifier = ref.read(studentCartProvider.notifier);
    final currentCart = ref.read(studentCartProvider);

    if (cartNotifier.checkCanteenConflict(stanId)) {
      // Tampilkan Modal Dialog Ganti Stan ala GoFood
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: context.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Mau ganti stan?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: context.textPrimary),
            ),
            content: Text(
              'Keranjang Anda saat ini berisi pesanan dari "${currentCart.canteenName ?? 'Stan Lain'}". Jika menambah menu dari "$stanName", pesanan sebelumnya akan diganti.',
              style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.3),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _triggerFlyingCartAnimationFromContext(
                    sourceContext,
                    product.imageUrl ?? '',
                    () {
                      cartNotifier.addProductWithCanteen(
                        canteenId: stanId,
                        canteenName: stanName,
                        deliveryFee: deliveryFee,
                        productId: product.id,
                        name: product.name,
                        price: product.price.toInt(),
                        imageUrl: product.imageUrl,
                      );
                    },
                  );
                },
                child: Text(
                  'Ganti & Tambah',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Tidak ada konflik, tambahkan langsung dengan animasi terbang
      _triggerFlyingCartAnimationFromContext(
        sourceContext,
        product.imageUrl ?? '',
        () {
          cartNotifier.addProductWithCanteen(
            canteenId: stanId,
            canteenName: stanName,
            deliveryFee: deliveryFee,
            productId: product.id,
            name: product.name,
            price: product.price.toInt(),
            imageUrl: product.imageUrl,
          );
        },
      );
    }
  }

  void _scrollToCategoryHeader(String category) {
    final key = _categoryHeaderKeys[category];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.0, // Aligns exactly to the top of the viewport!
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProductsAsync = ref.watch(publicMenuProvider(null));
    final canteensAsync = ref.watch(publicCanteensProvider);
    final bool isDesktop = Responsive.isDesktop(context) || MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: context.surfaceBg,
      body: allProductsAsync.when(
        data: (allProducts) {
          // 1. Resolve Stan Info & Delivery Settings
          final String stanId = widget.canteenId;
          String stanName = 'Stan Kantin';
          String stanAvatar = '🍔';
          bool isDeliveryEnabled = true;
          int deliveryFee = 2000;

          canteensAsync.whenData((stalls) {
            final match = stalls.where((s) => s.id == stanId).firstOrNull;
            if (match != null) {
              stanName = match.canteenName;
              isDeliveryEnabled = match.isDeliveryEnabled;
              deliveryFee = match.deliveryFee;
            }
          });

          final matchingProducts = allProducts.where((p) => p.product.operatorId == stanId).toList();
          if (matchingProducts.isNotEmpty) {
            stanName = matchingProducts.first.canteenName;
          } else if (stanId == 'bude-ani' || stanId.contains('bude')) {
            stanName = 'Bude Ani';
            stanAvatar = '👩‍🍳';
          } else if (stanId == 'stan-bakso-enak' || stanId.contains('bakso')) {
            stanName = 'Stan Bakso Enak';
            stanAvatar = '🍲';
          } else if (stanId == 'stan-jus-segar' || stanId.contains('jus')) {
            stanName = 'Stan Jus Segar';
            stanAvatar = '🍹';
          } else if (stanId == 'stan-nasgor' || stanId.contains('nasgor')) {
            stanName = 'Stan Nasgor';
            stanAvatar = '🍳';
          } else {
            stanName = 'Stan Utama';
            stanAvatar = '🏬';
          }

          // If delivery is disabled by merchant, force mode to pickup
          if (!isDeliveryEnabled && _selectedDeliveryMode == 'delivery') {
            _selectedDeliveryMode = 'pickup';
          }

          // 2. Resolve Products for this Stan
          List<ProductWithCanteen> stanProducts = matchingProducts;
          if (stanProducts.isEmpty) {
            stanProducts = _getFallbackProductsForStan(stanId, stanName);
          }

          // 3. Resolve Highlighted Product
          ProductWithCanteen? highlightedProduct;
          if (_highlightedProductId != null) {
            highlightedProduct = stanProducts.where((p) => p.product.id == _highlightedProductId).firstOrNull;
          }
          highlightedProduct ??= stanProducts.firstOrNull;

          // 4. Hero Banner Image from chosen product
          final String heroImageUrl = highlightedProduct?.product.imageUrl ??
              'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=1200&q=80';

          // Group products by category
          final Map<String, List<ProductWithCanteen>> categorized = {};
          for (var p in stanProducts) {
            final cat = _formatCategoryTitle(p.product.category);
            categorized.putIfAbsent(cat, () => []).add(p);
          }

          return Stack(
            children: [
              // Main Scrollable Body
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Image + Overlay App Bar (Height reduced by 30% to 168)
                    _buildHeroHeader(heroImageUrl, stanName),

                    // Store Info Card
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildStoreInfoCard(stanName, stanAvatar, isDeliveryEnabled, deliveryFee),
                            const SizedBox(height: 14),

                            // Highlighted Selected Product Card with Green Pulse
                            if (highlightedProduct != null)
                              _buildHighlightedProductCard(highlightedProduct, stanId, stanName, deliveryFee),
                          ],
                        ),
                      ),
                    ),

                    // "Orang-orang pada doyan ini" (Popular Items Horizontal Slider)
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildPopularHorizontalSlider(stanProducts, stanId, stanName, deliveryFee),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Product List grouped by Category
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCategorizedProductList(categorized, isDesktop, stanId, stanName, deliveryFee),
                    ),
                  ],
                ),
              ),

              // Floating Controls at the Bottom (Keranjang + Menu Category Button)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildFloatingControls(categorized.keys.toList()),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CupertinoActivityIndicator(radius: 16)),
        ),
        error: (err, _) => Scaffold(
          body: Center(
            child: Text('Gagal memuat produk stan: $err'),
          ),
        ),
      ),
    );
  }

  // ─── 1. HERO HEADER WITH BACK BUTTON ONLY ───
  Widget _buildHeroHeader(String imageUrl, String stanName) {
    return Stack(
      children: [
        // Hero Background Image (Height reduced by 30% from 240 to 168)
        SizedBox(
          height: 168,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey.shade300),
            errorWidget: (_, __, ___) => Container(
              color: Nebula.teal,
              child: const Icon(Icons.restaurant, size: 48, color: Colors.white),
            ),
          ),
        ),

        // Dark gradient scrims
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),

        // Top Navigation Bar (Back button only)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Back Button
                _buildCircleActionButton(
                  icon: CupertinoIcons.arrow_left,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/public/menu');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleActionButton({required IconData icon, required VoidCallback onTap}) {
    return PressScale(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }

  // ─── 2. STORE INFO CARD DENGAN ANIMASI GESER DELIVERY/PICKUP & STATUS STAN ───
  Widget _buildStoreInfoCard(String stanName, String stanAvatar, bool isDeliveryEnabled, int deliveryFee) {
    final String formattedFee = deliveryFee
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name & Verified Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  stanName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),

          // Rating, Reviews & Service Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(250+)',
                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Row(
                children: const [
                  Icon(Icons.verified_user_rounded, color: Color(0xFFEF4444), size: 14),
                  SizedBox(width: 3),
                  Text(
                    'Pelayanan Prima',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Distance & Time
          Text(
            '10-20 min • Stan Kantin Sekolah',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Delivery / Pickup Selector
          if (!isDeliveryEnabled)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.surfaceBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.borderLight, width: 0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    'Hanya Melayani Ambil Sendiri (Pickup)',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double tabWidth = (totalWidth - 6) / 2;
                final bool isDelivery = _selectedDeliveryMode == 'delivery';

                return Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.surfaceBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.borderLight, width: 0.6),
                  ),
                  child: Stack(
                    children: [
                      // Animated Sliding Green Indicator
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
                        alignment: isDelivery ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          width: tabWidth,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Clickable Labels
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_selectedDeliveryMode != 'delivery') {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedDeliveryMode = 'delivery');
                                  ref.read(studentCartProvider.notifier).setDeliveryMethod('delivery');
                                  ref.read(studentCartProvider.notifier).setDeliveryFee(deliveryFee);
                                }
                              },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isDelivery ? FontWeight.w800 : FontWeight.w600,
                                    color: isDelivery ? Colors.white : context.textSecondary,
                                  ),
                                  child: Text('Delivery (+$formattedFee)'),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_selectedDeliveryMode != 'pickup') {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedDeliveryMode = 'pickup');
                                  ref.read(studentCartProvider.notifier).setDeliveryMethod('pickup');
                                }
                              },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: !isDelivery ? FontWeight.w800 : FontWeight.w600,
                                    color: !isDelivery ? Colors.white : context.textSecondary,
                                  ),
                                  child: const Text('Pickup (Ambil)'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── 3. SELECTED PRODUCT HIGHLIGHT WITH GREEN PULSE WAVE ───
  Widget _buildHighlightedProductCard(
    ProductWithCanteen item,
    String stanId,
    String stanName,
    int deliveryFee,
  ) {
    final product = item.product;
    final String formattedPrice = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double scale = _pulseScale.value;
        final double glow = _pulseGlow.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: glow > 0.05
                    ? const Color(0xFF10B981).withValues(alpha: (0.4 + 0.6 * glow).clamp(0.0, 1.0))
                    : const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5 + (1.5 * glow),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: (0.35 * glow).clamp(0.0, 0.4)),
                  blurRadius: 16 + (10 * glow),
                  spreadRadius: 2 + (4 * glow),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: context.surfaceBg,
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                            errorWidget: (_, __, ___) => const Icon(Icons.restaurant, color: Nebula.teal),
                          )
                        : const Icon(Icons.restaurant, color: Nebula.teal),
                  ),
                ),
                const SizedBox(width: 10),

                // Info & Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge "Pilihan Anda"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 10, color: Color(0xFF10B981)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'Pilihan Anda',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp $formattedPrice',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // "+ Tambah" Button with Single-Merchant Guard
                Builder(
                  builder: (btnCtx) {
                    return PressScale(
                      scale: 0.94,
                      onTap: () {
                        _handleAddToCart(
                          sourceContext: btnCtx,
                          stanId: stanId,
                          stanName: stanName,
                          deliveryFee: deliveryFee,
                          product: product,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 14, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              'Tambah',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 4. "ORANG-ORANG PADA DOYAN INI" HORIZONTAL SLIDER ───
  Widget _buildPopularHorizontalSlider(
    List<ProductWithCanteen> products,
    String stanId,
    String stanName,
    int deliveryFee,
  ) {
    final popularItems = products.take(6).toList();
    if (popularItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orang-orang pada doyan ini',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: popularItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = popularItems[index];
              final product = item.product;

              final String formattedPrice = product.price
                  .toStringAsFixed(0)
                  .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

              return PressScale(
                scale: 0.96,
                onTap: () {
                  setState(() => _highlightedProductId = product.id);
                  _pulseController.forward(from: 0.0);
                },
                child: Container(
                  width: 145,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? 0.20 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with "👑 Paling Laku" and "⚡ 20 min" Badge
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 145,
                              height: 110,
                              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                      errorWidget: (_, __, ___) => const Icon(Icons.restaurant, color: Nebula.teal),
                                    )
                                  : const Icon(Icons.restaurant, color: Nebula.teal),
                            ),

                            // Top Left "👑 Paling Laku" Badge
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('👑', style: TextStyle(fontSize: 9)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Paling laku',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom Left "⚡ 20 min" Badge
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.bolt, size: 10, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      '20 min',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
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

                      // Title & Price
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rp $formattedPrice',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),

                                // Mini Add Circle with Single-Merchant Guard
                                Builder(
                                  builder: (btnCtx) {
                                    return GestureDetector(
                                      onTap: () {
                                        _handleAddToCart(
                                          sourceContext: btnCtx,
                                          stanId: stanId,
                                          stanName: stanName,
                                          deliveryFee: deliveryFee,
                                          product: product,
                                        );
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, size: 15, color: Colors.white),
                                      ),
                                    );
                                  },
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
            },
          ),
        ),
      ],
    );
  }

  // ─── 5. CATEGORIZED NORMAL PRODUCT ROWS (LIST VIEW) ───
  Widget _buildCategorizedProductList(
    Map<String, List<ProductWithCanteen>> categorized,
    bool isDesktop,
    String stanId,
    String stanName,
    int deliveryFee,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorized.entries.map((entry) {
        final String category = entry.key;
        final List<ProductWithCanteen> items = entry.value;
        final headerKey = _categoryHeaderKeys.putIfAbsent(category, () => GlobalKey());

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header Title with Exact Scroll Target Key
              Container(
                key: headerKey,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.surfaceBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Product Rows
              ...items.map((item) => _buildProductRowTile(item, stanId, stanName, deliveryFee)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductRowTile(ProductWithCanteen item, String stanId, String stanName, int deliveryFee) {
    final product = item.product;
    final String formattedPrice = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Name, Description, Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getProductDescription(product),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.textSecondary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp $formattedPrice',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right side: Image thumbnail + Clean round '+' button at right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                          errorWidget: (_, __, ___) => const Icon(Icons.restaurant, color: Nebula.teal),
                        )
                      : const Icon(Icons.restaurant, color: Nebula.teal),
                ),
              ),
              const SizedBox(width: 8),

              Builder(
                builder: (btnCtx) {
                  return PressScale(
                    scale: 0.90,
                    onTap: () {
                      _handleAddToCart(
                        sourceContext: btnCtx,
                        stanId: stanId,
                        stanName: stanName,
                        deliveryFee: deliveryFee,
                        product: product,
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 6. FLOATING CONTROLS: KERANJANG + TOMBOL MENU KATEGORI ───
  Widget _buildFloatingControls(List<String> categories) {
    final cart = ref.watch(studentCartProvider);
    final int itemCount = cart.totalItems;
    final String formattedPrice = cart.totalAmount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A. Floating Cart Bar (if items > 0)
        if (itemCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PressScale(
              scale: 0.98,
              onTap: () => _openCartModalSheet(context),
              child: Container(
                key: _cartKey,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.cart_fill, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$itemCount Menu • Rp $formattedPrice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 13),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // B. Floating "Menu" Pill Button (Centered under Cart Bar)
        Center(
          child: PressScale(
            scale: 0.94,
            onTap: () => _showCategoryMenuSelector(categories),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48), // GoFood signature red
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.room_service_rounded, color: Colors.white, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    'Menu',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 7. MODAL KERANJANG BELANJA (AMAN UNTUK SEMUA ROLE & GUEST) ───
  void _openCartModalSheet(BuildContext context) {
    final authState = ref.read(authNotifierProvider);
    final bool isStudent = authState.isAuthenticated && authState.profile?['role'] == 'student';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final cart = ref.watch(studentCartProvider);
            final String formattedItemsTotal = cart.itemsTotal
                .toStringAsFixed(0)
                .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
            final String formattedDeliveryFee = cart.deliveryFee
                .toStringAsFixed(0)
                .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
            final String formattedTotal = cart.totalAmount
                .toStringAsFixed(0)
                .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
            final bool isDelivery = cart.deliveryMethod == 'delivery';

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.cart_fill, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Keranjang Pesanan',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (cart.canteenName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Stan: ${cart.canteenName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Cart Items List
                  Expanded(
                    child: cart.items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.cart, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Keranjang belanja kosong',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: cart.items.length,
                            separatorBuilder: (_, __) => const Divider(height: 12),
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              final String itemPrice = item.price
                                  .toStringAsFixed(0)
                                  .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                              final bool hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

                              return Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: hasImage
                                          ? CachedNetworkImage(
                                              imageUrl: item.imageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                                child: const Center(
                                                  child: CupertinoActivityIndicator(radius: 6),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                                child: const Icon(CupertinoIcons.cube_box, color: Color(0xFF10B981), size: 18),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(CupertinoIcons.cube_box, color: Color(0xFF10B981), size: 20),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Rp $itemPrice',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.minus_circle_fill, color: Colors.grey, size: 22),
                                        onPressed: () {
                                          ref.read(studentCartProvider.notifier).decreaseQuantity(item.productId, selectedOptions: item.selectedOptions);
                                        },
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFF10B981), size: 22),
                                        onPressed: () {
                                          ref.read(studentCartProvider.notifier).increaseQuantity(item.productId, selectedOptions: item.selectedOptions);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  // Bottom Summary & Action
                  if (cart.items.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal Menu',
                          style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                        ),
                        Text(
                          'Rp $formattedItemsTotal',
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                        ),
                      ],
                    ),
                    if (isDelivery) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ongkos Kirim (Delivery)',
                            style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                          ),
                          Text(
                            '+Rp $formattedDeliveryFee',
                            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Rp $formattedTotal',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (isStudent) {
                            context.push('/student/cart');
                          } else {
                            context.push('/login?from=/student/cart');
                          }
                        },
                        child: Text(
                          isStudent ? 'Lanjut ke Pembayaran' : 'Masuk / Login untuk Bayar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryMenuSelector(List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Menu Stan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...categories.map((cat) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restaurant_menu, color: Color(0xFF10B981)),
                  title: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    // Scrolls directly and exactly so the category header lands at the top of the screen!
                    _scrollToCategoryHeader(cat);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatCategoryTitle(String rawCat) {
    final lower = rawCat.toLowerCase();
    if (lower == 'makanan') return 'Makanan Utama';
    if (lower == 'minuman') return 'Minuman Segar';
    if (lower == 'camilan') return 'Jajanan & Camilan';
    return rawCat.substring(0, 1).toUpperCase() + rawCat.substring(1);
  }

  String _getProductDescription(Product product) {
    final lower = product.name.toLowerCase();
    if (lower.contains('nasi goreng')) {
      return 'Nasi goreng racikan khas dengan telur, sosis gurih, dan acar segar';
    } else if (lower.contains('mie')) {
      return 'Mie kenyal lezat dengan kuah kaldu istimewa dan pangsit renyah';
    } else if (lower.contains('jeruk') || lower.contains('es')) {
      return 'Minuman perasan jeruk asli manis menyegarkan dahaga';
    } else if (lower.contains('bakso')) {
      return 'Bakso daging sapi asli kenyal dengan kuah kaldu rempah nikmat';
    } else if (lower.contains('jus')) {
      return 'Jus buah asli kaya vitamin tanpa pemanis buatan';
    }
    return 'Menu lezat dan sehat higienis siap disajikan dari stan kantin sekolah';
  }

  List<ProductWithCanteen> _getFallbackProductsForStan(String stanId, String stanName) {
    if (stanId.contains('bude')) {
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
          canteenName: stanName,
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
          canteenName: stanName,
        ),
      ];
    } else if (stanId.contains('bakso')) {
      return [
        ProductWithCanteen(
          product: const Product(
            id: 'p-bakso-1',
            operatorId: 'stan-bakso-enak',
            name: 'Bakso Komplit Spesial',
            price: 18000,
            category: 'makanan',
            imageUrl: 'https://images.unsplash.com/photo-1594041680534-e8c8cdebd659?auto=format&fit=crop&w=600&q=80',
            isAvailable: true,
          ),
          canteenName: stanName,
        ),
        ProductWithCanteen(
          product: const Product(
            id: 'p-bakso-2',
            operatorId: 'stan-bakso-enak',
            name: 'Mie Bakso Urat',
            price: 15000,
            category: 'makanan',
            imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
            isAvailable: true,
          ),
          canteenName: stanName,
        ),
      ];
    }

    return [
      ProductWithCanteen(
        product: const Product(
          id: 'p-main-1',
          operatorId: 'stan-utama',
          name: 'Nasi Goreng Spesial',
          price: 15000,
          category: 'makanan',
          imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
          isAvailable: true,
        ),
        canteenName: stanName,
      ),
      ProductWithCanteen(
        product: const Product(
          id: 'p-main-2',
          operatorId: 'stan-utama',
          name: 'Mie Ayam Bakso',
          price: 12000,
          category: 'makanan',
          imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
          isAvailable: true,
        ),
        canteenName: stanName,
      ),
      ProductWithCanteen(
        product: const Product(
          id: 'p-main-3',
          operatorId: 'stan-utama',
          name: 'Es Jeruk Segar',
          price: 5000,
          category: 'minuman',
          imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80',
          isAvailable: true,
        ),
        canteenName: stanName,
      ),
    ];
  }
}
