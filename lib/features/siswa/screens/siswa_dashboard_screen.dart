import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_freeze_card_dialog.dart';


class SiswaDashboardScreen extends ConsumerWidget {
  const SiswaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile != null ? UserProfile.fromJson(authState.profile!) : null;
    final String fullName = profile?.fullName ?? AppStrings.adminStudents;
    final String? profilePhotoUrl = authState.profile?['avatar_url'];
    final studentAsync = ref.watch(siswaStudentProvider);
    final transactionsAsync = ref.watch(siswaTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        backgroundColor: AppColors.systemBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: AppColors.gray400.withValues(alpha: 0.3), width: 0.5),
        ),
        title: Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $fullName!',
                  style: const TextStyle(fontSize: 13, color: AppColors.darkGray, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Beranda',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: AppColors.teal),
            onPressed: () => context.push('/student/notifications'),
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
              // Balance Card
              studentAsync.when(
                data: (student) {
                  if (student == null) return const SizedBox();
                  final int balance = student.balance;
                  final bool isActive = student.isActive;
                  final String studentId = student.id;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      ClipRRect(
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
                            clipBehavior: Clip.none,
                            children: [
                              // Decorative Background Shape
                              Positioned(
                                top: -48,
                                right: -48,
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.softTeal.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Actions Grid
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(CupertinoIcons.add, color: AppColors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Isi Saldo',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
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
                              onTap: () => showFreezeCardDialog(context, ref, isActive, studentId),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.grayLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isActive ? CupertinoIcons.lock : CupertinoIcons.lock_open,
                                      color: AppColors.textDark,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isActive ? 'Bekukan' : 'Aktifkan',
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
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
              const SizedBox(height: 28),

              // Jajan Hari Ini Title & Lihat Semua link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jajan Hari Ini',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/student/history'),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transactions List (Only show today's)
              transactionsAsync.when(
                data: (List<OperatorTransaction> txs) {
                  final now = DateTime.now();
                  final todayTxs = txs.where((tx) {
                    if (tx.createdAt == null) return false;
                    final txDate = tx.createdAt!.toLocal();
                    return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
                  }).toList();

                  if (todayTxs.isEmpty) {
                    return const EmptyStateWidget(
                      message: AppStrings.labelNoData,
                    );
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
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
