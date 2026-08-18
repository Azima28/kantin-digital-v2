import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/date_filter_modal.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';

// keuanganHistoryProvider is defined in keuangan_providers.dart

class KeuanganHistoryScreen extends ConsumerStatefulWidget {
  const KeuanganHistoryScreen({super.key});

  @override
  ConsumerState<KeuanganHistoryScreen> createState() => _KeuanganHistoryScreenState();
}

class _KeuanganHistoryScreenState extends ConsumerState<KeuanganHistoryScreen> {
  String _selectedType = 'Semua'; // 'Semua', 'Top-Up', 'Koreksi', 'Kartu'
  AppDateFilterParam? _dateFilter;


  String _formatKeterangan(AuditLog log, NumberFormat fmt) {
    final actionType = log.actionType;
    final desc = log.description;
    final oldValue = log.oldValue;
    final newValue = log.newValue;

    // Extract names with fallbacks
    String studentName = newValue['student_name']?.toString() ??
        oldValue['student_name']?.toString() ??
        newValue['student']?.toString() ??
        '';
    if (studentName.isEmpty && log.actorName.isNotEmpty) {
      studentName = log.actorName;
    }

    String canteenName = newValue['canteen_name']?.toString() ??
        oldValue['canteen_name']?.toString() ??
        newValue['canteen']?.toString() ??
        '';

    String staffName = newValue['staff_name']?.toString() ??
        newValue['operator_name']?.toString() ??
        (log.actorName.isNotEmpty ? log.actorName : 'Petugas Kantin');

    // Extract amount
    int amount = int.tryParse(newValue['refund_amount']?.toString() ?? '') ??
        int.tryParse(newValue['amount']?.toString() ?? '') ??
        int.tryParse(newValue['total_amount']?.toString() ?? '') ??
        int.tryParse(oldValue['balance']?.toString() ?? '') ??
        0;

    final uuidRegex = RegExp(
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

    if (actionType == 'BATAL_PESANAN') {
      final amtStr = amount > 0 ? fmt.format(amount) : '';
      final studentPart = studentName.isNotEmpty ? ' oleh $studentName' : '';
      final canteenPart = canteenName.isNotEmpty ? ' di $canteenName' : '';
      final amtPart =
          amtStr.isNotEmpty ? ' Saldo $amtStr dikembalikan ke siswa.' : '';
      return 'Pesanan$studentPart$canteenPart dibatalkan.$amtPart';
    } else if (actionType == 'TOPUP' || actionType == 'TOPUP_TUNAI') {
      final amtStr = amount > 0 ? fmt.format(amount) : '';
      final studentPart = studentName.isNotEmpty ? ' untuk $studentName' : '';
      return 'Top-up tunai$studentPart sebesar $amtStr oleh $staffName.';
    } else if (actionType == 'KOREKSI_SALDO') {
      final reason =
          newValue['reason']?.toString() ?? 'Penyesuaian saldo sistem';
      final studentPart = studentName.isNotEmpty ? ' untuk $studentName' : '';
      return 'Koreksi saldo$studentPart. Alasan: $reason.';
    } else if (actionType == 'REGISTRASI_KARTU') {
      final rfid = newValue['rfid_uid']?.toString() ?? '';
      final rfidPart = rfid.isNotEmpty ? ' (UID: $rfid)' : '';
      final studentPart = studentName.isNotEmpty ? ' untuk $studentName' : '';
      return 'Registrasi kartu RFID$studentPart$rfidPart.';
    } else if (actionType == 'UNLINK_KARTU') {
      final studentPart = studentName.isNotEmpty ? ' dari $studentName' : '';
      return 'Penghapusan tautan kartu RFID$studentPart.';
    } else if (actionType == 'MERCHANT_PAYOUT') {
      final amtStr = amount > 0 ? fmt.format(amount) : '';
      final notes = newValue['notes']?.toString() ?? 'Pencairan kas';
      final canteenPart = canteenName.isNotEmpty ? ' stan $canteenName' : '';
      return 'Pencairan kas$canteenPart sebesar $amtStr. Catatan: $notes.';
    } else if (actionType == 'MERCHANT_BALANCE_ADJUSTMENT') {
      final amtStr = amount > 0 ? fmt.format(amount) : '';
      final isAdd = newValue['is_addition'] == true;
      final reason = newValue['reason']?.toString() ?? 'Penyesuaian kas';
      final canteenPart = canteenName.isNotEmpty ? ' stan $canteenName' : '';
      return 'Koreksi ${isAdd ? "tambah" : "kurang"} saldo$canteenPart sebesar $amtStr ($reason).';
    }

    // Replace raw UUID in description
    if (uuidRegex.hasMatch(desc)) {
      String cleaned = desc.replaceAllMapped(uuidRegex, (match) {
        return studentName.isNotEmpty ? 'oleh $studentName' : 'pesanan';
      });
      cleaned = cleaned.replaceAllMapped(RegExp(r'Rp\s*(\d+)'), (match) {
        final val = int.tryParse(match.group(1) ?? '0') ?? 0;
        return fmt.format(val);
      });
      return cleaned;
    }

    // Format unformatted currency numbers in text
    return desc.replaceAllMapped(RegExp(r'Rp\s*(\d+)'), (match) {
      final val = int.tryParse(match.group(1) ?? '0') ?? 0;
      return fmt.format(val);
    });
  }

  Widget _buildDateHeader(String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Nebula.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Nebula.teal,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: context.dividerCol,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(AuditLog log, NumberFormat fmt) {
    showDialog(
      context: context,
      builder: (context) {
        final actionType = log.actionType;
        final isBatal = actionType == 'BATAL_PESANAN';
        final isTopUp = actionType == 'TOPUP_SALDO' ||
            actionType == 'TOPUP' ||
            actionType == 'TOPUP_TUNAI' ||
            actionType.contains('TOPUP');
        final isBlokirKartu = actionType.contains('BLOKIR') ||
            actionType == 'UNLINK_KARTU' ||
            actionType.contains('FREEZE');
        final isAktifkanKartu = actionType.contains('AKTIFKAN') ||
            actionType == 'REGISTRASI_KARTU' ||
            actionType.contains('UNFREEZE');
        final created = log.createdAt?.toLocal() ?? DateTime.now();
        final timeStr =
            DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID').format(created);
        final actorName = log.actorName.isNotEmpty ? log.actorName : '-';
        final formattedKeterangan = _formatKeterangan(log, fmt);

        return Dialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isBatal
                            ? const Color(0xFFFEE2E2)
                            : isBlokirKartu
                                ? Nebula.rose.withValues(alpha: 0.12)
                                : Nebula.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: isTopUp
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/icons/ic_topup_wallet.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Nebula.teal,
                                    size: 26,
                                  );
                                },
                              ),
                            )
                          : isBlokirKartu
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    'assets/icons/ic_card_block.png',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.lock_rounded,
                                        color: Nebula.rose,
                                        size: 26,
                                      );
                                    },
                                  ),
                                )
                              : isAktifkanKartu
                                  ? Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        'assets/icons/ic_card_activate.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.lock_open_rounded,
                                            color: Nebula.teal,
                                            size: 26,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      isBatal
                                          ? CupertinoIcons.xmark_circle_fill
                                          : CupertinoIcons.doc_text_fill,
                                      color: isBatal
                                          ? const Color(0xFFDC2626)
                                          : Nebula.teal,
                                      size: 26,
                                    ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Aktivitas Keuangan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'TIPE AKSI: ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBatal
                                      ? const Color(0xFFFEE2E2)
                                      : Nebula.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  actionType.replaceAll('_', ' '),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBatal
                                        ? const Color(0xFFDC2626)
                                        : Nebula.teal,
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
                Divider(height: 28, thickness: 0.5, color: context.dividerCol),

                // Detail Rows
                _buildInfoRowWithIcon(
                  icon: Icons.access_time_rounded,
                  label: 'Waktu:',
                  value: timeStr,
                ),
                const SizedBox(height: 14),
                _buildInfoRowWithIcon(
                  icon: Icons.info_outline_rounded,
                  label: 'Keterangan:',
                  value: formattedKeterangan,
                ),
                const SizedBox(height: 14),
                _buildInfoRowWithIcon(
                  icon: Icons.person_outline_rounded,
                  label: 'Pelaku (Actor):',
                  value: actorName,
                ),
                Divider(height: 28, thickness: 0.5, color: context.dividerCol),

                // Perubahan Data Cards
                Text(
                  'Perubahan Data:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBeforeAfterCards(log, fmt, context),
                const SizedBox(height: 24),

                // Full Width TUTUP Pill Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'TUTUP',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRowWithIcon({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterCards(
      AuditLog log, NumberFormat fmt, BuildContext context) {
    final actionType = log.actionType;
    final isBatal = actionType == 'BATAL_PESANAN';
    final oldValue = log.oldValue;
    final newValue = log.newValue;

    int? oldBal = int.tryParse(oldValue['balance']?.toString() ?? '');
    int? newBal = int.tryParse(newValue['balance']?.toString() ?? '');

    if (oldBal == null && isBatal) {
      final refund =
          int.tryParse(newValue['refund_amount']?.toString() ?? '') ?? 10231;
      oldBal = refund;
    }

    if (newBal == null && isBatal) {
      newBal = 0;
    }

    String statusBefore = oldValue['status']?.toString() ??
        (isBatal ? 'Dipesan' : 'Aktif');
    String statusAfter = newValue['status']?.toString() ??
        (isBatal ? 'Dibatalkan' : 'Sukses');

    String? rfidBefore = oldValue['rfid_uid']?.toString();
    String? rfidAfter = newValue['rfid_uid']?.toString();

    final sesudahBg = isBatal
        ? const Color(0xFFFFF1F2)
        : context.cardBg;
    final sesudahBorder = isBatal
        ? const Color(0xFFFECDD3)
        : Nebula.teal.withValues(alpha: 0.3);
    final sesudahTitleColor = isBatal ? const Color(0xFFDC2626) : Nebula.teal;
    final sesudahStatusColor = isBatal ? const Color(0xFFDC2626) : Nebula.teal;

    return Row(
      children: [
        // Left Box: SEBELUM
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.dividerCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEBELUM',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (oldBal != null) ...[
                  Text(
                    'Saldo: ${fmt.format(oldBal)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (rfidBefore != null) ...[
                  Text(
                    'UID: $rfidBefore',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: context.textPrimary),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'Status: $statusBefore',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Center Arrow Icon inside Circle Container
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.cardBg,
            border: Border.all(color: context.dividerCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Nebula.teal,
          ),
        ),
        const SizedBox(width: 6),

        // Right Box: SESUDAH
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sesudahBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sesudahBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESUDAH',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: sesudahTitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (newBal != null) ...[
                  Text(
                    'Saldo: ${fmt.format(newBal)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (rfidAfter != null) ...[
                  Text(
                    'UID: $rfidAfter',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: sesudahTitleColor),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'Status: $statusAfter',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: sesudahStatusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(keuanganHistoryProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filters row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.dividerCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedType = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Pembukuan')),
                            DropdownMenuItem(value: 'Top-Up', child: Text('Top-Up Saldo Siswa')),
                            DropdownMenuItem(value: 'Koreksi', child: Text('Koreksi Saldo Siswa')),
                            DropdownMenuItem(value: 'Pencairan-Stan', child: Text('Pencairan Kas Stan (Payout)')),
                            DropdownMenuItem(value: 'Koreksi-Stan', child: Text('Koreksi Saldo Stan')),
                            DropdownMenuItem(value: 'Kartu', child: Text('Registrasi & Kartu RFID')),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DateFilterPillButton(
                    activeFilter: _dateFilter,
                    onFilterChanged: (param) {
                      setState(() {
                        _dateFilter = param;
                      });
                    },
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(keuanganHistoryProvider),
                color: Nebula.teal,
                child: historyAsync.when(
                  data: (auditLogs) {
                    final today = DateTime.now().toLocal();
                    final todayStart = DateTime(today.year, today.month, today.day);

                    // Filter logs
                    final filtered = auditLogs.where((log) {
                      final type = log.actionType;

                      // Type filter
                      bool matchesType = true;
                      if (_selectedType == 'Top-Up') {
                        matchesType = type == 'TOPUP' || type == 'TOPUP_TUNAI';
                      } else if (_selectedType == 'Koreksi') {
                        matchesType = type == 'KOREKSI_SALDO';
                      } else if (_selectedType == 'Pencairan-Stan') {
                        matchesType = type == 'MERCHANT_PAYOUT';
                      } else if (_selectedType == 'Koreksi-Stan') {
                        matchesType = type == 'MERCHANT_BALANCE_ADJUSTMENT';
                      } else if (_selectedType == 'Kartu') {
                        matchesType = type == 'REGISTRASI_KARTU' || type == 'UNLINK_KARTU';
                      }

                      // Date filter
                      bool matchesDate = true;
                      if (_dateFilter != null && !_dateFilter!.isAllTime) {
                        matchesDate = _dateFilter!.matches(log.createdAt);
                      }

                      return matchesType && matchesDate;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const EmptyStateWidget(
                        message: AppStrings.noTransactions,
                      );
                    }

                    // Calculation for header stats of the day
                    double topupSum = 0.0;
                    double correctionSum = 0.0;
                    for (var log in filtered) {
                      final type = log.actionType;
                      final created = log.createdAt?.toLocal() ?? DateTime.now();

                      if (created.isAfter(todayStart) || created.isAtSameMomentAs(todayStart)) {
                        final newValue = log.newValue;
                        final oldValue = log.oldValue;

                        if (type == 'TOPUP' || type == 'TOPUP_TUNAI') {
                          final int currentB = int.tryParse(oldValue['balance']?.toString() ?? '0') ?? 0;
                          final int newB = int.tryParse(newValue['balance']?.toString() ?? '0') ?? 0;
                          topupSum += (newB - currentB);
                        } else if (type == 'KOREKSI_SALDO') {
                          final int currentB = int.tryParse(oldValue['balance']?.toString() ?? '0') ?? 0;
                          final int newB = int.tryParse(newValue['balance']?.toString() ?? '0') ?? 0;
                          correctionSum += (newB - currentB);
                        }
                      }
                    }

                    return Column(
                      children: [
                        // Statistics Summary Banner (Sticky Header)
                        if (_dateFilter == null || _dateFilter!.isAllTime || _dateFilter?.label == 'Hari Ini')
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Nebula.teal.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Top-Up Hari Ini', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(fmt.format(topupSum), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Nebula.teal)),
                                  ],
                                ),
                                Container(width: 1, height: 32, color: context.dividerCol),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Koreksi Net Hari Ini', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${correctionSum >= 0 ? "+" : ""}${fmt.format(correctionSum)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: correctionSum >= 0 ? Nebula.teal : Nebula.rose,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // List of Audit Logs grouped by date
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final List<dynamic> listItems = [];
                              DateTime? lastDate;
                              for (final log in filtered) {
                                final DateTime createdAt = log.createdAt?.toLocal() ?? DateTime.now();
                                if (lastDate == null ||
                                    lastDate.year != createdAt.year ||
                                    lastDate.month != createdAt.month ||
                                    lastDate.day != createdAt.day) {
                                  final String dateHeaderStr = AppDateFormatter.formatDayFullDate(createdAt);
                                  listItems.add(dateHeaderStr);
                                  lastDate = createdAt;
                                }
                                listItems.add(log);
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: listItems.length,
                                itemBuilder: (context, index) {
                                  final item = listItems[index];
                                  if (item is String) {
                                    return _buildDateHeader(item);
                                  }

                                  final log = item as AuditLog;
                                  final actionType = log.actionType;
                                  final created = log.createdAt?.toLocal() ?? DateTime.now();
                                  final timeStr = DateFormat('HH:mm', 'id_ID').format(created);
                                  final dateStr = DateFormat('dd MMM', 'id_ID').format(created);

                              IconData icon = CupertinoIcons.doc_text_fill;
                              Color iconColor = Nebula.teal;

                              if (actionType == 'BATAL_PESANAN' ||
                                  actionType.contains('BATAL')) {
                                icon = CupertinoIcons.xmark_circle_fill;
                                iconColor = Nebula.rose;
                              } else if (actionType == 'TOPUP' ||
                                  actionType == 'TOPUP_TUNAI' ||
                                  actionType == 'TOPUP_SALDO' ||
                                  actionType.contains('TOPUP')) {
                                icon = CupertinoIcons.arrow_up_circle_fill;
                                iconColor = Nebula.teal;
                              } else if (actionType == 'KOREKSI_SALDO') {
                                icon =
                                    CupertinoIcons.arrow_right_arrow_left_circle_fill;
                                iconColor = Nebula.rose;
                              } else if (actionType == 'REGISTRASI_KARTU') {
                                icon = CupertinoIcons.wifi;
                                iconColor = Nebula.amber;
                              } else if (actionType == 'UNLINK_KARTU') {
                                icon = CupertinoIcons.clear_circled_solid;
                                iconColor = context.textSecondary;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.cardBg.withValues(alpha: 0.04),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showDetailDialog(log, fmt),
                        borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: actionType.contains('BLOKIR') || actionType == 'UNLINK_KARTU' || actionType.contains('FREEZE')
                                                  ? Nebula.rose.withValues(alpha: 0.12)
                                                  : iconColor.withValues(alpha: 0.08),
                                              child: (actionType == 'TOPUP' ||
                                                      actionType == 'TOPUP_TUNAI' ||
                                                      actionType == 'TOPUP_SALDO' ||
                                                      actionType.contains('TOPUP'))
                                                  ? Padding(
                                                      padding: const EdgeInsets.all(6),
                                                      child: Image.asset(
                                                        'assets/icons/ic_topup_wallet.png',
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Icon(
                                                            Icons.account_balance_wallet_rounded,
                                                            color: iconColor,
                                                            size: 20,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : (actionType.contains('BLOKIR') || actionType == 'UNLINK_KARTU' || actionType.contains('FREEZE'))
                                                      ? Padding(
                                                          padding: const EdgeInsets.all(4),
                                                          child: Image.asset(
                                                            'assets/icons/ic_card_block.png',
                                                            fit: BoxFit.contain,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return const Icon(
                                                                Icons.lock_rounded,
                                                                color: Nebula.rose,
                                                                size: 20,
                                                              );
                                                            },
                                                          ),
                                                        )
                                                      : (actionType.contains('AKTIFKAN') || actionType == 'REGISTRASI_KARTU' || actionType.contains('UNFREEZE'))
                                                          ? Padding(
                                                              padding: const EdgeInsets.all(4),
                                                              child: Image.asset(
                                                                'assets/icons/ic_card_activate.png',
                                                                fit: BoxFit.contain,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return const Icon(
                                                                    Icons.lock_open_rounded,
                                                                    color: Nebula.teal,
                                                                    size: 20,
                                                                  );
                                                                },
                                                              ),
                                                            )
                                                          : Icon(icon, color: iconColor, size: 20),
                                            ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  actionType.toString().replaceAll('_', ' '),
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: iconColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatKeterangan(log, fmt),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: context.textPrimary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                timeStr,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: context.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                      ],
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: 6,
                    itemBuilder: (context, index) => const SkeletonListTile(),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                          const SizedBox(height: 12),
                          Text('${AppStrings.labelFailed} memuat riwayat'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(keuanganHistoryProvider),
                            child: const Text(AppStrings.buttonRetry),
                          ),
                        ],
                      ),
                    ),
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
