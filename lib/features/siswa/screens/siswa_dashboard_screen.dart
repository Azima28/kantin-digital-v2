/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/widgets/hallmark_card.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';

/// Hallmark Siswa Dashboard Screen — Specimen Balance Macrostructure with Promo Banner Carousel
class SiswaDashboardScreen extends ConsumerStatefulWidget {
  const SiswaDashboardScreen({super.key});

  @override
  ConsumerState<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends ConsumerState<SiswaDashboardScreen> {
  int _promoIndex = 0;
  static const int _virtualPromoOffset = 12000;
  late final PageController _pageController = PageController(
    initialPage: _virtualPromoOffset,
    viewportFraction: 0.85,
  );
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
    _pageController.dispose();
    super.dispose();
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_promoCount > 1 && _pageController.hasClients && _pageController.page != null) {
        final currentVirtualPage = _pageController.page!.round();
        _pageController.animateToPage(
          currentVirtualPage + 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _showAccountBlockedDialog(BuildContext context) {
    showAppConfirmationDialog(
      context,
      title: 'Aksi Ditolak',
      message: 'Akun digital Anda sedang dinonaktifkan oleh pihak sekolah. Seluruh transaksi pemesanan online, top-up digital, dan chat dinonaktifkan.',
      confirmLabel: 'Mengerti',
      icon: Icons.block_rounded,
      isDestructive: true,
    );
  }

  Widget _buildBlockedAccountBanner(BuildContext context, HallmarkColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.statusError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.statusError.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.exclamationmark_shield_fill, color: colors.statusError, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AKUN DIGITAL DIBLOKIR',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colors.statusError,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Akun digital Anda sedang dinonaktifkan oleh pihak sekolah. Seluruh transaksi pemesanan online, top-up digital, dan chat dinonaktifkan.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: colors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(CupertinoIcons.info_circle, size: 14, color: colors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Anda tetap bisa menggunakan kartu fisik RFID untuk jajan di kantin selama kartu Anda aktif.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersSection(BuildContext context, HallmarkColorScheme colors) {
    final activeOrdersAsync = ref.watch(siswaActiveOrdersProvider);

    return activeOrdersAsync.maybeWhen(
      data: (orders) {
        final activeList = orders.where((o) {
          final s = o.status.trim().toLowerCase();
          return s != 'selesai' && s != 'dibatalkan' && s != 'cancelled' && s != 'refunded';
        }).toList();

        if (activeList.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Pesanan Sedang Diproses',
                      style: HallmarkTypography.titleL3(colors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Nebula.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Nebula.amber.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Text(
                        '${activeList.length} Aktif',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push('/student/active-orders'),
                  child: Text(
                    'Lihat Semua',
                    style: HallmarkTypography.labelButton(colors.brandPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderTactile, width: 0.8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeList.length > 3 ? 3 : activeList.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1.0,
                  color: colors.textMuted.withValues(alpha: 0.28),
                  indent: 14,
                  endIndent: 14,
                ),
                itemBuilder: (context, index) {
                  final order = activeList[index];
                  final String itemNames = order.items.isNotEmpty
                      ? order.items.map((i) => '${i.qty}x ${i.name}').join(', ')
                      : 'Pesanan #${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}';

                  Color statusColor = Nebula.amber;
                  Color statusBg = Nebula.amber.withValues(alpha: 0.12);
                  if (order.status == 'Sedang Disiapkan' || order.status == 'Sedang Dimasak') {
                    statusColor = const Color(0xFF0284C7);
                    statusBg = const Color(0xFF0284C7).withValues(alpha: 0.12);
                  } else if (order.status == 'Siap Diambil' || order.status == 'Sedang Diantar' || order.status == 'Siap Diantar') {
                    statusColor = Nebula.teal;
                    statusBg = Nebula.teal.withValues(alpha: 0.12);
                  }

                  final bool isFirst = index == 0;
                  final bool isLast = index == (activeList.length > 3 ? 2 : activeList.length - 1);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/student/active-orders'),
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(16) : Radius.zero,
                        bottom: isLast ? const Radius.circular(16) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colors.brandPrimary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(CupertinoIcons.bag_fill, size: 14, color: colors.brandPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      order.time.isNotEmpty ? order.time : 'Hari Ini',
                                      style: HallmarkTypography.bodySmall(colors.textMuted),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              itemNames,
                              style: HallmarkTypography.titleSmall(colors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (order.deliveryLocation != null &&
                                              (order.deliveryLocation!.toLowerCase().contains('pickup') ||
                                                  order.deliveryLocation!.toLowerCase().contains('ambil') ||
                                                  order.deliveryLocation!.toLowerCase().contains('stan') ||
                                                  order.deliveryLocation!.toLowerCase().contains('dimakan')))
                                          ? CupertinoIcons.bag
                                          : CupertinoIcons.location_solid,
                                      size: 12,
                                      color: colors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty)
                                          ? order.deliveryLocation!
                                          : 'Ambil di Stan',
                                      style: HallmarkTypography.bodySmall(colors.textMuted),
                                    ),
                                  ],
                                ),
                                Text(
                                  CurrencyFormatter.format(order.totalAmount),
                                  style: HallmarkTypography.financialNumeral(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);
    final bool isAccountBlocked = authState.profile != null && authState.profile!['is_active'] == false;
    final profile = authState.profile != null ? UserProfile.fromJson(authState.profile!) : null;
    final String fullName = profile?.fullName ?? AppStrings.adminStudents;
    final String? profilePhotoUrl = authState.profile?['avatar_url'];
    final studentAsync = ref.watch(siswaStudentProvider);
    final transactionsAsync = ref.watch(siswaTransactionsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: colors.surfaceBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: colors.borderTactile, width: 0.5),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              radius: 20,
              photoUrl: profilePhotoUrl,
              role: 'student',
              name: fullName,
              borderColor: colors.borderTactile,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HallmarkTypography.titleL3(colors.textPrimary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Dashboard Siswa',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          NotificationBell(color: colors.brandPrimary),
          Consumer(
            builder: (context, ref, child) {
              final cartState = ref.watch(studentCartProvider);
              final int cartItemsCount = cartState.totalItems;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(CupertinoIcons.cart, color: colors.brandPrimary),
                    if (cartItemsCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.statusError,
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
                  if (isAccountBlocked) {
                    _showAccountBlockedDialog(context);
                  } else {
                    context.push('/student/cart');
                  }
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
          ref.invalidate(publicMenuProvider(null));
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
                  if (isAccountBlocked) _buildBlockedAccountBanner(context, colors),

                  // Specimen Hero Balance Card
                  studentAsync.when(
                    data: (student) {
                      if (student == null) return const SizedBox();
                      final int balance = student.balance;
                      final bool isActive = student.isActive;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.labelBalance,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isActive ? 'Kartu Aktif' : 'Terblokir',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isActive
                                            ? CupertinoIcons.checkmark_seal_fill
                                            : CupertinoIcons.lock_fill,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Rp ',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatWithoutPrefix(balance),
                                    style: GoogleFonts.inter(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final bool isSmallScreen = MediaQuery.of(context).size.width <= 360;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Material(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            if (isAccountBlocked) {
                                              _showAccountBlockedDialog(context);
                                            } else {
                                              context.push('/student/topup');
                                            }
                                          },
                                          child: Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  CupertinoIcons.add,
                                                  size: 15,
                                                  color: Color(0xFF0F766E),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  isSmallScreen ? 'Top Up' : 'Top-Up Saldo',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF0F766E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Material(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            if (isAccountBlocked) {
                                              _showAccountBlockedDialog(context);
                                            } else {
                                              context.push('/student/cards');
                                            }
                                          },
                                          child: Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.35),
                                                width: 0.8,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  CupertinoIcons.creditcard,
                                                  size: 15,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  isSmallScreen ? 'Kartu' : 'Kartu Saya',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Shimmer(
                      child: HallmarkCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    SkeletonBox(width: 80, height: 12, borderRadius: 4),
                                    SizedBox(height: 8),
                                    SkeletonBox(width: 140, height: 18, borderRadius: 4),
                                  ],
                                ),
                                const SkeletonCircle(size: 32),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const SkeletonBox(width: 90, height: 12, borderRadius: 4),
                            const SizedBox(height: 8),
                            const SkeletonBox(width: 180, height: 36, borderRadius: 6),
                            const SizedBox(height: 20),
                            Row(
                              children: const [
                                Expanded(child: SkeletonBox(height: 48, borderRadius: 12)),
                                SizedBox(width: 10),
                                Expanded(child: SkeletonBox(height: 48, borderRadius: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        '${AppStrings.labelFailed} memuat saldo',
                        style: HallmarkTypography.bodyMain(colors.statusError),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Koleksi Spesial / Panel Iklan Section ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Koleksi Spesial',
                        style: HallmarkTypography.headingL2(colors.textPrimary),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.go('/public/menu'),
                        child: Text(
                          'Lihat Menu',
                          style: HallmarkTypography.labelButton(colors.brandPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPromoCarousel(colors),
                  const SizedBox(height: 24),

                  // ── Pesanan Aktif / Sedang Diproses Section ──
                  _buildActiveOrdersSection(context, colors),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Transaksi Terakhir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HallmarkTypography.titleL3(colors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push('/student/history'),
                        child: Text(
                          'Lihat Semua',
                          style: HallmarkTypography.labelButton(colors.brandPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Transactions List Stack
                  transactionsAsync.when(
                    skipLoadingOnRefresh: true,
                    skipLoadingOnReload: true,
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return HallmarkCard(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Belum ada transaksi hari ini',
                                style: HallmarkTypography.bodyMain(colors.textMuted),
                              ),
                            ),
                          ),
                        );
                      }
                      final int count = transactions.length > 5 ? 5 : transactions.length;
                      return Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderTactile, width: 0.8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: count,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 1.0,
                            color: colors.textMuted.withValues(alpha: 0.28),
                            indent: 14,
                            endIndent: 14,
                          ),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isTopup = tx.type == 'topup';
                            final bool isFirst = index == 0;
                            final bool isLast = index == count - 1;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  showTransactionDetailSheet(context, ref, tx);
                                },
                                borderRadius: BorderRadius.vertical(
                                  top: isFirst ? const Radius.circular(16) : Radius.zero,
                                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      _buildTransactionThumbnail(colors, tx, isTopup),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isTopup ? 'Top-Up Tunai' : (tx.canteenName ?? 'Jajan Kantin'),
                                              style: HallmarkTypography.titleSmall(colors.textPrimary),
                                            ),
                                            if (tx.createdAt != null)
                                              Text(
                                                AppDateFormatter.formatDateWithTime(tx.createdAt),
                                                style: HallmarkTypography.bodySmall(colors.textMuted),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isTopup ? '+' : '-'}${CurrencyFormatter.format(tx.totalAmount)}',
                                        style: HallmarkTypography.financialNumeral(
                                          color: isTopup ? const Color(0xFF10B981) : colors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => Shimmer(
                      child: Column(
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.borderTactile, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const SkeletonCircle(size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      SkeletonBox(width: 120, height: 14, borderRadius: 4),
                                      SizedBox(height: 6),
                                      SkeletonBox(width: 70, height: 11, borderRadius: 4),
                                    ],
                                  ),
                                ),
                                const SkeletonBox(width: 75, height: 16, borderRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    error: (err, stack) => Text(
                      'Gagal memuat riwayat transaksi',
                      style: HallmarkTypography.bodyMain(colors.statusError),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionThumbnail(
    HallmarkColorScheme colors,
    OperatorTransaction tx,
    bool isTopup,
  ) {
    final hasImage = tx.imageUrl != null && tx.imageUrl!.isNotEmpty && !isTopup;

    if (hasImage) {
      final String resolvedImg = ApiClient.resolveImageUrl(tx.imageUrl);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: resolvedImg,
            fit: BoxFit.cover,
            placeholder: (context, url) => const ShimmerRect(
              width: 40,
              height: 40,
              borderRadius: 10,
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: colors.brandPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.bag,
                color: colors.brandPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isTopup ? colors.statusSuccess : colors.brandPrimary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isTopup ? CupertinoIcons.add : CupertinoIcons.bag,
        color: isTopup ? colors.statusSuccess : colors.brandPrimary,
        size: 20,
      ),
    );
  }

  Widget _buildPromoCarousel(HallmarkColorScheme colors) {
    final productsAsync = ref.watch(publicMenuProvider(null));

    return productsAsync.when(
      data: (List<ProductWithCanteen> allProducts) {
        final availableProducts = allProducts.where((p) => p.product.isAvailable).toList();

        if (availableProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        availableProducts.sort((a, b) {
          final aDate = a.product.createdAt;
          final bDate = b.product.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        // Take top 8 featured promo products for optimal carousel UX
        final promoItems = availableProducts.take(8).toList();

        _promoCount = promoItems.length;

        if (_promoIndex >= promoItems.length) {
          _promoIndex = 0;
        }

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: Listener(
                onPointerDown: (_) => _promoTimer?.cancel(),
                onPointerUp: (_) => _startPromoTimer(),
                onPointerCancel: (_) => _startPromoTimer(),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (promoItems.isNotEmpty) {
                      setState(() => _promoIndex = index % promoItems.length);
                    }
                    _startPromoTimer();
                  },
                  itemBuilder: (context, index) {
                    if (promoItems.isEmpty) return const SizedBox.shrink();
                    final actualIndex = index % promoItems.length;
                    final item = promoItems[actualIndex];
                    return _buildPromoCard(colors, item);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(promoItems.length, (i) {
                final bool isActive = _promoIndex == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.brandPrimary
                        : colors.textMuted.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
      loading: () => Shimmer(
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderTactile, width: 0.8),
          ),
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildPromoCard(HallmarkColorScheme colors, ProductWithCanteen item) {
    final bool hasImage = item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty;

    return HallmarkCard(
      padding: EdgeInsets.zero,
      onTap: () {
        final String operatorId = item.product.operatorId.isNotEmpty ? item.product.operatorId : 'stan-utama';
        context.push('/public/stan/$operatorId?productId=${item.product.id}');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? CachedNetworkImage(
                    imageUrl: item.product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerRect(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16,
                    ),
                    errorWidget: (_, __, ___) => _buildPromoFallbackContent(colors, item),
                  )
                : _buildPromoFallbackContent(colors, item),
            Container(
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.canteenName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.product.price),
                        style: HallmarkTypography.financialNumeral(
                          color: const Color(0xFF4ADE80),
                          fontSize: 14,
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

  Widget _buildPromoFallbackContent(HallmarkColorScheme colors, ProductWithCanteen item) {
    return Container(
      color: colors.surfaceSubtle,
      child: Center(
        child: Icon(
          CupertinoIcons.flame_fill,
          size: 40,
          color: colors.brandPrimary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
