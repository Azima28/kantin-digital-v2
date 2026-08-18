import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/features/keuangan/widgets/student_detail_header.dart';
import 'package:kantin_digital/features/keuangan/widgets/student_detail_password_change.dart';
import 'package:kantin_digital/features/keuangan/widgets/student_detail_status_toggle.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// keuanganStudentDetailProvider is defined in keuangan_providers.dart

class KeuanganStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const KeuanganStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<KeuanganStudentDetailScreen> createState() =>
      _KeuanganStudentDetailScreenState();
}

class _KeuanganStudentDetailScreenState
    extends ConsumerState<KeuanganStudentDetailScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    StudentDetailPasswordChange.dispose();
    super.dispose();
  }

  Future<void> _toggleCardFreeze(bool currentCardStatus) async {
    final bool newStatus = !currentCardStatus;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: newStatus ? 'Aktifkan Kartu RFID' : 'Bekukan Kartu RFID',
      message: newStatus
          ? 'Apakah Anda yakin ingin mengaktifkan kembali kartu RFID ini? Kartu dapat digunakan jajan.'
          : 'Apakah Anda yakin ingin membekukan kartu RFID ini? Siswa tidak dapat melakukan pembayaran atau topup dengan kartu ini untuk sementara.',
      confirmLabel: newStatus ? 'Aktifkan Kartu' : 'Bekukan Kartu',
      isDestructive: !newStatus,
      icon: newStatus ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
    );

    if (!confirmed) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/student/card-status', body: {
        'student_id': widget.studentId,
        'is_active': newStatus,
      });

      ref.invalidate(keuanganStudentDetailProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Kartu RFID berhasil diaktifkan.' : 'Kartu RFID berhasil dibekukan.'),
            backgroundColor: newStatus ? Nebula.teal : Nebula.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah status kartu: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openAllTransactionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: widget.studentId,
          primaryColor: Nebula.teal,
          accentColor: Nebula.amber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      keuanganStudentDetailProvider(widget.studentId),
    );
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Siswa',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: detailAsync.when(
          data: (data) {
            final profile = data.profile;
            final student = data.student;
            final txs = data.recentTransactions;

            final fullName = profile.fullName ?? AppStrings.adminStudents;
            final email = profile.email ?? '-';
            final nisn = profile.nisn ?? '-';
            final isAccountActive = profile.isActive == true;
            final isCardActive = student.isActive == true;

            final sClass = student.class_ ?? 'Belum Diisi';
            final int balance = student.balance;
            final String? rfid = student.rfidUid;
            final hasCard = rfid != null && rfid.isNotEmpty;

            final String lastTapStr =
                txs.isNotEmpty && txs.first.createdAt != null
                ? DateFormat(
                    'dd MMM yyyy, HH:mm', 'id_ID',
                  ).format(txs.first.createdAt!.toLocal())
                : '-';

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                keuanganStudentDetailProvider(widget.studentId),
              ),
              color: Nebula.teal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentDetailHeader(
                      fullName: fullName,
                      email: email,
                      nisn: nisn,
                      isAccountActive: isAccountActive,
                      isCardActive: isCardActive,
                      hasCard: hasCard,
                      sClass: sClass,
                      balance: balance,
                      rfid: rfid,
                      lastTapStr: lastTapStr,
                      fmt: fmt,
                      onToggleCardFreeze: hasCard ? () => _toggleCardFreeze(isCardActive) : null,
                      onRegisterCard: () => context.push('/finance/students/${widget.studentId}/card'),
                    ),
                    const SizedBox(height: 16),

                    // ─── Aksi Admin Card ───
                    NebulaCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              top: 16,
                              right: 20,
                              bottom: 8,
                            ),
                            child: Text(
                              'Aksi Admin',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.arrow_up_circle,
                            iconColor: Nebula.teal,
                            title: 'Top-Up Saldo Tunai',
                            isEnabled: hasCard && isCardActive,
                            subtitle: !hasCard
                                ? 'Daftarkan kartu RFID terlebih dahulu'
                                : (!isCardActive
                                    ? 'Kartu RFID sedang diblokir'
                                    : null),
                            disabledTooltip: !hasCard
                                ? 'Siswa belum memiliki kartu RFID. Silakan daftarkan kartu terlebih dahulu.'
                                : 'Kartu RFID sedang diblokir. Buka blokir kartu terlebih dahulu.',
                            onTap: () {
                              final studentProfile = StudentWithProfile(
                                id: widget.studentId,
                                fullName: fullName,
                                email: email,
                                nisn: nisn,
                                isActive: isAccountActive,
                                class_: sClass,
                                balance: balance,
                                rfidUid: rfid,
                                cardIsActive: isCardActive,
                              );
                              context.push(
                                '/finance/topup',
                                extra: studentProfile,
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: context.dividerCol,
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.arrow_right_arrow_left_circle,
                            iconColor: Nebula.rose,
                            title: AppStrings.keuanganKoreksiSaldo,
                            isEnabled: hasCard && isCardActive,
                            subtitle: !hasCard
                                ? 'Daftarkan kartu RFID terlebih dahulu'
                                : (!isCardActive
                                    ? 'Kartu RFID sedang diblokir'
                                    : null),
                            disabledTooltip: !hasCard
                                ? 'Siswa belum memiliki kartu RFID. Silakan daftarkan kartu terlebih dahulu.'
                                : 'Kartu RFID sedang diblokir. Buka blokir kartu terlebih dahulu.',
                            onTap: () {
                              final studentProfile = StudentWithProfile(
                                id: widget.studentId,
                                fullName: fullName,
                                email: email,
                                nisn: nisn,
                                isActive: isAccountActive,
                                class_: sClass,
                                balance: balance,
                                rfidUid: rfid,
                                cardIsActive: isCardActive,
                              );
                              context.push(
                                '/finance/correction',
                                extra: studentProfile,
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: context.dividerCol,
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.wifi,
                            iconColor: Nebula.teal,
                            title: hasCard ? 'Ganti Kartu RFID / NFC' : 'Registrasi Kartu RFID Baru',
                            subtitle: hasCard ? 'UID: $rfid' : 'Belum memiliki kartu fisik',
                            isEnabled: true,
                            onTap: () {
                              context.push(
                                '/finance/students/${widget.studentId}/card',
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: context.dividerCol,
                          ),
                          _buildActionTile(
                            icon: Icons.key,
                            iconColor: Nebula.amber,
                            title: AppStrings.adminChangePassword,
                            isEnabled: true,
                            onTap: () => StudentDetailPasswordChange.show(
                              context, ref, profile.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientLine(height: 1, margin: EdgeInsets.zero),

                    // ─── Riwayat Transaksi Card ───
                    NebulaCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Riwayat Transaksi (10 Terakhir)',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              PressScale(
                                onTap: _openAllTransactionsScreen,
                                child: TextButton(
                                  onPressed: null,
                                  child: Text(
                                    'Lihat Semua',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (txs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  AppStrings.noTransactions,
                                  style: GoogleFonts.inter(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: txs.take(10).map((tx) {
                                final isTopup = tx.isTopup;
                                final isSuccess = tx.isSuccess;
                                final int amount = tx.totalAmount;
                                final timestamp =
                                    tx.createdAt?.toLocal() ?? DateTime.now();
                                final timeStr = DateFormat(
                                  'dd MMM, HH:mm', 'id_ID',
                                ).format(timestamp);
                                final canteenName = tx.canteenName ?? 'Top-up';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: isTopup
                                                  ? Nebula.teal.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Nebula.amber.withValues(
                                                      alpha: 0.08,
                                                    ),
                                              child: Icon(
                                                isTopup
                                                    ? CupertinoIcons.arrow_up
                                                    : CupertinoIcons.cart,
                                                size: 14,
                                                color: isTopup
                                                    ? Nebula.teal
                                                    : Nebula.amber,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isTopup
                                                        ? 'Top-Up Saldo'
                                                        : canteenName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: context.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    timeStr,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: context.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${isTopup ? "+" : "-"}${fmt.format(amount)}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isTopup
                                                  ? Nebula.teal
                                                  : context.textPrimary,
                                            ),
                                          ),
                                          if (!isSuccess)
                                            Text(
                                              tx.status
                                                  .toString()
                                                  .toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Nebula.rose,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientLine(height: 1, margin: EdgeInsets.zero),

                    // ─── Block Account Button ───
                    StudentDetailStatusToggle(
                      studentId: widget.studentId,
                      isAccountActive: isAccountActive,
                    ),
                    const SizedBox(height: 24),
                  ],
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
                      borderRadius: BorderRadius.circular(24),
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
                        3,
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
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                  const SizedBox(height: 12),
                  Text('${AppStrings.labelFailed} memuat profil'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(keuanganStudentDetailProvider(widget.studentId)),
                    child: const Text(AppStrings.buttonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isEnabled = true,
    String? subtitle,
    String? disabledTooltip,
  }) {
    final effectiveColor = isEnabled ? iconColor : context.textSecondary.withValues(alpha: 0.5);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: PressScale(
        onTap: () {
          if (isEnabled) {
            onTap();
          } else if (disabledTooltip != null && mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(disabledTooltip),
                backgroundColor: Nebula.rose,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: effectiveColor.withValues(alpha: 0.08),
            child: Icon(icon, color: effectiveColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isEnabled ? context.textPrimary : context.textSecondary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isEnabled ? context.textSecondary : Nebula.rose,
                    fontWeight: isEnabled ? FontWeight.normal : FontWeight.w500,
                  ),
                )
              : null,
          trailing: Icon(
            isEnabled ? CupertinoIcons.chevron_forward : Icons.lock_outline_rounded,
            size: 16,
            color: isEnabled ? context.textSecondary : Nebula.rose.withValues(alpha: 0.6),
          ),
          onTap: null,
        ),
      ),
    );
  }
}