import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';

class SiswaDashboardScreen extends ConsumerStatefulWidget {
  const SiswaDashboardScreen({super.key});

  @override
  ConsumerState<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends ConsumerState<SiswaDashboardScreen> {
  int _promoIndex = 0;

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
      floatingActionButton: _buildNfcFab(context),
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: AppColors.gray400.withValues(alpha: 0.3), width: 0.5),
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
                  ? const Icon(Icons.person, color: AppColors.teal)
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $fullName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.darkGray, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Beranda',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: Responsive.headingFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBell(color: AppColors.teal),
          SizedBox(width: 8),
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

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight, width: 1),
                          ),
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Decorative blob top-right
                              Positioned(
                                top: -30,
                                right: -30,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryLight.withValues(alpha: 0.5),
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
                                      const Text(
                                        'SALDO SAKU',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.darkGray,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppColors.teal.withValues(alpha: 0.1)
                                              : AppColors.errorRed2.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isActive ? 'Aktif' : 'Dibekukan',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isActive ? AppColors.teal : AppColors.errorRed2,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              isActive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock_fill,
                                              size: 14,
                                              color: isActive ? AppColors.teal : AppColors.errorRed2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Balance
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Text(
                                        'Rp',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        NumberFormat('#,###', 'id_ID').format(balance),
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.teal,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Action buttons inside card
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => context.push('/student/topup'),
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.teal,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(CupertinoIcons.add, color: AppColors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Isi Saldo',
                                                  style: TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.w600,
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
                                        child: GestureDetector(
                                          onTap: () => context.push('/student/cards'),
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.grayLight,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(CupertinoIcons.creditcard, color: AppColors.textDark, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Lihat Kartu',
                                                  style: TextStyle(
                                                    color: AppColors.textDark,
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
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                    error: (err, stack) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${AppStrings.labelFailed} memuat saldo', style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(siswaStudentProvider),
                          child: const Text(AppStrings.buttonRetry),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Koleksi Spesial Section ──
                  _buildSectionHeader(
                    title: 'Koleksi Spesial',
                    actionText: 'Lihat Semua',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildPromoCarousel(),
                  const SizedBox(height: 24),

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

                      return Column(
                        children: todayTxs.map((tx) {
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
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderLight, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isTopup
                                          ? AppColors.teal.withValues(alpha: 0.1)
                                          : AppColors.systemBackground,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isTopup ? CupertinoIcons.square_arrow_down : Icons.restaurant,
                                      color: isTopup ? AppColors.teal : AppColors.textDark,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isTopup ? 'Top-Up Saldo' : canteenName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 17,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$txTime WIB \u2022 ${isTopup ? "Koperasi" : "Jajan"}',
                                          style: const TextStyle(
                                            color: AppColors.darkGray,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                          color: isTopup ? AppColors.teal : AppColors.errorRed2,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        isTopup ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                        size: 12,
                                        color: isTopup ? AppColors.teal : AppColors.errorRed2,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (err, stack) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${AppStrings.labelFailed} memuat transaksi', style: TextStyle(color: AppColors.error)),
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
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView(
            onPageChanged: (i) => setState(() => _promoIndex = i),
            children: [
              _buildPromoCard(
                title: 'Promo Spesial Kantin',
                subtitle: 'Dapatkan cashback hingga 20% hari ini!',
              ),
              _buildPromoCard(
                title: 'Menu Baru Minggu Ini',
                subtitle: 'Coba berbagai menu baru yang lezat!',
              ),
              _buildPromoCard(
                title: 'Gratis Top-Up',
                subtitle: 'Minimal top-up Rp50.000, dapat bonus Rp5.000!',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final bool isActive = _promoIndex == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.grayLight,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPromoCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0.3),
            AppColors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Placeholder image icon
          Center(
            child: Icon(
              CupertinoIcons.photo,
              size: 48,
              color: AppColors.mutedGray.withValues(alpha: 0.4),
            ),
          ),
          // Gradient overlay with text at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
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

  Widget _buildEmptyTransactionBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.grayLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.photo,
              size: 32,
              color: AppColors.mutedGray,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada transaksi jajan untuk hari ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/public/menu'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Mulai Belanja',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcFab(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal,
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: const Icon(
            Icons.nfc,
            color: AppColors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
