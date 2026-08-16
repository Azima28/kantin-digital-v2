import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_password_change.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_rfid_section.dart';
import 'package:kantin_digital/features/admin/widgets/admin_student_status_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_student_sheet.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';

class AdminStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<AdminStudentDetailScreen> createState() =>
      _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState
    extends ConsumerState<AdminStudentDetailScreen> {

  @override
  void dispose() {
    AdminStudentPasswordChange.dispose();
    super.dispose();
  }

  void _openAllTransactionsScreen({
    required String studentId,
    required Color primaryColor,
    required Color accentColor,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: studentId,
          primaryColor: Nebula.teal,
          accentColor: Nebula.amber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(
      adminStudentDetailProvider(widget.studentId),
    );

    return Scaffold(
      backgroundColor: context.surfaceBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${AppStrings.titleDetail} Siswa',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
          ),
        ),
        actions: [
          studentAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(CupertinoIcons.pencil, color: Nebula.teal),
              tooltip: 'Edit Profil Siswa',
              onPressed: () => showEditStudentSheet(
                context,
                ref,
                data.profile,
                data.student,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (data) {
          final profile = data.profile;
          final student = data.student;
          final List<OperatorTransaction> txs = data.recentTransactions;

          final String fullName = profile.fullName ?? '';
          final String email = profile.email ?? '';
          final String username = profile.username ?? '';
          final String nisn = profile.nisn ?? '';
          final String className = student.class_ ?? 'Belum Diisi';
          final int balance = student.balance;
          final double? dailyLimit = student.dailyLimit;
          final String rfidUid = student.rfidUid ?? 'Belum Terdaftar';
          final bool isCardActive = student.isActive;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Main White Card Container
                    Container(
                      margin: const EdgeInsets.only(top: 34),
                      padding: const EdgeInsets.only(
                        top: 48,
                        left: 32,
                        right: 32,
                        bottom: 32,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: context.dividerCol.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Name & Class / NISN Subtitle
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  fullName,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Nebula.teal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Kelas $className • NISN: ${nisn.isNotEmpty ? nisn : "-"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. Student Info List Card
                          AdminStudentStatusCard(
                            isCardActive: isCardActive,
                            rfidUid: rfidUid,
                            username: username,
                            email: email,
                            balance: balance,
                            dailyLimit: dailyLimit,
                          ),
                          const SizedBox(height: 20),

                          // 3. Action Buttons Row (Ubah Kata Sandi & Bekukan/Aktifkan Kartu RFID)
                          Row(
                            children: [
                              // Ubah Kata Sandi Button
                              Expanded(
                                child: PressScale(
                                  onTap: () => AdminStudentPasswordChange.show(
                                    context,
                                    ref,
                                    profile.id,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Nebula.teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Nebula.teal.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.key,
                                          color: Nebula.teal,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Ubah\nKata Sandi',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Nebula.teal,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Bekukan / Aktifkan Kartu RFID Button
                              Expanded(
                                child: AdminStudentRfidSection(
                                  studentId: widget.studentId,
                                  isCardActive: isCardActive,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // 4. Riwayat Transaksi Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Riwayat Transaksi',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _openAllTransactionsScreen(
                                  studentId: widget.studentId,
                                  primaryColor: Nebula.teal,
                                  accentColor: Nebula.amber,
                                ),
                                child: Text(
                                  'Lihat Semua',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Nebula.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 5. Transaction History List / Empty State
                          if (txs.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  AppStrings.noTransactions,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: txs.map((tx) {
                                final int amount = tx.totalAmount;
                                final bool isTopup = tx.isTopup;
                                final String canteen =
                                    tx.canteenName ?? 'Stan Kantin';
                                final date =
                                    tx.createdAt?.toLocal() ?? DateTime.now();

                                return NebulaCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isTopup
                                            ? Nebula.amber
                                            : Nebula.teal.withValues(alpha: 0.1),
                                        child: Icon(
                                          isTopup
                                              ? CupertinoIcons.creditcard
                                              : Icons.shopping_bag,
                                          color: isTopup
                                              ? Nebula.amber
                                              : Nebula.teal,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isTopup
                                                  ? 'Top-up Saldo'
                                                  : canteen,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'dd MMM yyyy, HH:mm',
                                                'id_ID',
                                              ).format(date),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: context.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isTopup
                                              ? Nebula.teal
                                              : Nebula.rose,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    // Prominent Edit Profil Button on Top-Right Corner of White Card
                    Positioned(
                      top: 48,
                      right: 20,
                      child: PressScale(
                        onTap: () => showEditStudentSheet(
                          context,
                          ref,
                          profile,
                          student,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Nebula.teal.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.pencil,
                                color: Nebula.teal,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Edit Profil',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Nebula.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Floating Avatar Badge at Top Center
                    Positioned(
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                          child: const Icon(
                            CupertinoIcons.person,
                            color: Nebula.teal,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => Shimmer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                  child: Column(
                    children: List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            SkeletonBox(width: 80, height: 14, borderRadius: 4),
                            Spacer(),
                            SkeletonBox(width: 120, height: 14, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SkeletonBox(width: 140, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                ...List.generate(3, (i) => const SkeletonListTile()),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  adminStudentDetailProvider(widget.studentId),
                ),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
