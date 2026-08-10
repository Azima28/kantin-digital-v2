import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';

class SiswaDashboardScreen extends ConsumerStatefulWidget {
  const SiswaDashboardScreen({super.key});

  @override
  ConsumerState<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends ConsumerState<SiswaDashboardScreen> {
  int _promoIndex = 0;
  PageController? _pageController;
  bool? _lastIsMobile;
  Timer? _promoTimer;
  int _promoCount = 0;

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _setupPageController(bool isMobile, int totalItems) {
    if (_lastIsMobile == isMobile && _pageController != null) return;
    _lastIsMobile = isMobile;
    _pageController?.dispose();
    
    // Set initial page in the middle of virtual count to allow backward swiping too
    final int initialPage = (totalItems * 500) + _promoIndex;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: isMobile ? 0.88 : 0.60,
    );
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_promoCount > 1 && _pageController != null && _pageController!.hasClients) {
        final nextPage = _pageController!.page!.round() + 1;
        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile != null ? UserProfile.fromJson(authState.profile!) : null;
    final String fullName = profile?.fullName ?? AppStrings.adminStudents;
    final String? profilePhotoUrl = authState.profile?['avatar_url'];
    final studentAsync = ref.watch(siswaStudentProvider);
    final transactionsAsync = ref.watch(siswaTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: profilePhotoUrl != null
                  ? CachedNetworkImageProvider(profilePhotoUrl)
                  : null,
              child: profilePhotoUrl == null
                  ? Icon(Icons.person, color: Nebula.teal)
                  : null,
            ),
            SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $fullName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Beranda',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: Responsive.headingFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: Nebula.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          NotificationBell(color: Nebula.teal),
          Consumer(
            builder: (context, ref, child) {
              final cartState = ref.watch(studentCartProvider);
              final int cartItemsCount = cartState.totalItems;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(CupertinoIcons.cart, color: Nebula.teal),
                    if (cartItemsCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Nebula.rose,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$cartItemsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  context.push('/student/cart');
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaStudentProvider);
          ref.invalidate(siswaTransactionsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Balance Card with Buttons Inside ──
                  studentAsync.when(
                    data: (student) {
                      if (student == null) return const SizedBox();
                      final int balance = student.balance;
                      final bool isActive = student.isActive;

                      return Builder(
                        builder: (context) {
                          final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    // Dark mode: Nebula gradient (Teal + Purple — Siswa role)
                                    gradient: isDarkMode
                                        ? LinearGradient(
                                            colors: [
                                              Nebula.teal,
                                              Nebula.purple,
                                              Nebula.tealDark,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isDarkMode ? null : context.cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isDarkMode
                                        ? null
                                        : Border.all(color: context.borderLight, width: 1),
                                    boxShadow: isDarkMode
                                        ? [
                                            BoxShadow(
                                              color: Nebula.tealGlow,
                                              blurRadius: 24,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Decorative circle in dark mode teal card
                                  if (isDarkMode)
                                    Positioned(
                                      top: -40,
                                      right: -40,
                                      child: Container(
                                        width: 150,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.06),
                                        ),
                                      ),
                                    ),
                                  if (!isDarkMode)
                                    // Decorative blob top-right (light mode)
                                    Positioned(
                                      top: -30,
                                      right: -30,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Nebula.teal.withValues(alpha: 0.08).withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Label + Status badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppStrings.labelBalance,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.white.withValues(alpha: 0.75)
                                                  : context.textSecondary,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Colors.white.withValues(alpha: 0.15)
                                                  : (isActive
                                                      ? Nebula.teal.withValues(alpha: 0.1)
                                                      : Nebula.rose.withValues(alpha: 0.1)),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  isActive ? 'Aktif' : 'Dibekukan',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : (isActive ? Nebula.teal : Nebula.rose),
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  isActive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock_fill,
                                                  size: 13,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : (isActive ? Nebula.teal : Nebula.rose),
                                                ),
                                              ],
                                            ),
                                          ),
                                    ],
                                  ),
                                      const SizedBox(height: 8),
                                      // Balance
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              'Rp',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.white.withValues(alpha: 0.85)
                                                    : context.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              NumberFormat('#,###', 'id_ID').format(balance),
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w800,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Nebula.teal,
                                                letterSpacing: -1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      // Action buttons inside card
                                      Row(
                                        children: [
                                          Expanded(
                                            child: PressScale(
                                              onTap: () => context.push('/student/topup'),
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient: isDarkMode
                                                      ? LinearGradient(
                                                          colors: [
                                                            Colors.white.withValues(alpha: 0.2),
                                                            Colors.white.withValues(alpha: 0.15),
                                                          ],
                                                        )
                                                      : null,
                                                  color: isDarkMode ? null : Nebula.teal,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.add,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Isi Saldo',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: PressScale(
                                              onTap: () => context.push('/student/cards'),
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.white.withValues(alpha: 0.1)
                                                      : context.surfaceBg,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: isDarkMode
                                                      ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.creditcard,
                                                      color: isDarkMode ? Colors.white : context.textPrimary,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Lihat Kartu',
                                                      style: TextStyle(
                                                        color: isDarkMode ? Colors.white : context.textPrimary,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_circle, color: Nebula.rose, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat saldo',
                              style: TextStyle(fontSize: 15, color: Nebula.rose),
                            ),
                            if (err.toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                err.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: context.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(siswaStudentProvider),
                              child: const Text(AppStrings.buttonRetry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Gradient Divider ──
                  const GradientLine(margin: EdgeInsets.symmetric(vertical: 8)),

                  // ── Koleksi Spesial Section ──
                  _buildPromoCarousel(),

                  const GradientLine(margin: EdgeInsets.symmetric(vertical: 16)),

                  // ── Jajan Hari Ini Section ──
                  _buildSectionHeader(
                    title: 'Jajan Hari Ini',
                    actionText: 'Lihat Semua',
                    onTap: () => context.go('/student/history'),
                  ),
                  const SizedBox(height: 12),

                  // Transactions or empty state
                  transactionsAsync.when(
                    data: (List<OperatorTransaction> txs) {
                      final now = DateTime.now();
                      final todayTxs = txs.where((tx) {
                        if (tx.createdAt == null) return false;
                        final txDate = tx.createdAt!.toLocal();
                        return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
                      }).toList();

                      if (todayTxs.isEmpty) {
                        return _buildEmptyTransactionBox(context);
                      }

                      final bool isWide = !Responsive.isMobile(context);

                      if (isWide) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final itemWidth = (width - 12) / 2;
                            const itemHeight = 76.0;
                            final ratio = itemWidth / itemHeight;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: ratio,
                              ),
                              itemCount: todayTxs.length,
                              itemBuilder: (context, index) {
                                final tx = todayTxs[index];
                                return _buildTransactionCard(context, ref, tx);
                              },
                            );
                          },
                        );
                      }

                      return Column(
                        children: todayTxs.map((tx) {
                          return _buildTransactionCard(
                            context,
                            ref,
                            tx,
                            margin: const EdgeInsets.only(bottom: 12),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (err, stack) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${AppStrings.labelFailed} memuat transaksi', style: TextStyle(color: Nebula.rose)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(siswaTransactionsProvider),
                          child: const Text(AppStrings.buttonRetry),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 13,
              color: Nebula.teal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCarousel() {
    final productsAsync = ref.watch(publicMenuProvider(null));

    return productsAsync.when(
      data: (List<ProductWithCanteen> allProducts) {
        // Filter only available products
        final availableProducts = allProducts.where((p) => p.product.isAvailable).toList();
        
        if (availableProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort available products: newest first (so new products are immediately featured)
        availableProducts.sort((a, b) {
          final aDate = a.product.createdAt;
          final bDate = b.product.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        // Update promo count for auto-scroll timer
        _promoCount = availableProducts.length;

        // Keep _promoIndex within bounds
        if (_promoIndex >= availableProducts.length) {
          _promoIndex = 0;
        }

        // Setup the page controller dynamically based on current screen width
        _setupPageController(Responsive.isMobile(context), availableProducts.length);

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: Listener(
                onPointerDown: (_) {
                  _promoTimer?.cancel();
                },
                onPointerUp: (_) {
                  _startPromoTimer();
                },
                onPointerCancel: (_) {
                  _startPromoTimer();
                },
                child: PageView.builder(
                  controller: _pageController!,
                  itemCount: availableProducts.length * 1000,
                  onPageChanged: (virtualIndex) {
                    setState(() => _promoIndex = virtualIndex % availableProducts.length);
                    _startPromoTimer();
                  },
                  itemBuilder: (context, virtualIndex) {
                    final item = availableProducts[virtualIndex % availableProducts.length];
                    return _buildPromoCard(item);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Dot indicators or text page indicator
            if (availableProducts.length <= 10)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(availableProducts.length, (i) {
                  final bool isActive = _promoIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Nebula.teal : context.dividerCol,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              )
            else
              // Slick pill-shaped indicator showing "Page X of Y" for readability
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_promoIndex + 1} dari ${availableProducts.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Nebula.teal,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildPromoCard(ProductWithCanteen item) {
    final bool hasImage = item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.go('/public/menu'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.cardBg,
          border: Border.all(color: Nebula.teal.withValues(alpha: 0.08), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Nebula.teal.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: item.product.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  errorWidget: (context, url, error) => _buildPromoFallbackCard(item),
                )
              : _buildPromoFallbackCard(item),
        ),
      ),
    );
  }

  Widget _buildPromoFallbackCard(ProductWithCanteen item) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Stack(
      children: [
        // Decorative background gradient and circles
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Nebula.teal.withValues(alpha: 0.08),
                  Nebula.teal.withValues(alpha: 0.08).withValues(alpha: 0.3),
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -30,
          bottom: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -40,
          top: -40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Canteen Name Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.canteenName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Product Name
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    // Price
                    Text(
                      currencyFormatter.format(item.product.price),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Nebula.teal,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.cardBg.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.photo,
                  size: 32,
                  color: Nebula.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    OperatorTransaction tx, {
    EdgeInsetsGeometry? margin,
  }) {
    final String type = tx.type ?? 'purchase';
    final int amount = tx.totalAmount;
    final String canteenName = tx.canteenName ?? 'Kantin';
    final txTime = tx.createdAt != null
        ? DateFormat('HH:mm', 'id_ID').format(tx.createdAt!.toLocal())
        : '-';
    final bool isTopup = type == 'topup';

    return InkWell(
      onTap: () => showTransactionDetailSheet(context, ref, tx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderLight, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isTopup
                    ? Nebula.teal.withValues(alpha: 0.1)
                    : context.surfaceBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTopup ? CupertinoIcons.square_arrow_down : Icons.restaurant,
                color: isTopup ? Nebula.teal : context.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isTopup ? 'Top-Up Saldo' : canteenName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$txTime WIB \u2022 ${isTopup ? "Koperasi" : "Jajan"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isTopup ? Nebula.teal : Nebula.rose,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      isTopup ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                      size: 12,
                      color: isTopup ? Nebula.teal : Nebula.rose,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionBox(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                CupertinoIcons.photo,
                size: 32,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada transaksi jajan untuk hari ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            PressScale(
              onTap: () => context.go('/public/menu'),
              child: OutlinedButton(
                onPressed: () => context.go('/public/menu'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Nebula.teal, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Mulai Belanja',
                  style: TextStyle(
                    color: Nebula.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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