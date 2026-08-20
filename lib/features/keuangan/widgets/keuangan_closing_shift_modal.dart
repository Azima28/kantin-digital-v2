import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/services/report_export_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

/// Formatter untuk input nominal dengan pemisah ribuan titik (.) khas Indonesia
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;

    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Modal interaktif untuk Tutup Kasir / Closing Shift Berkelanjutan (Rolling Shift Ledger)
class KeuanganClosingShiftModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> dashboardData;

  const KeuanganClosingShiftModal({
    super.key,
    required this.dashboardData,
  });

  @override
  ConsumerState<KeuanganClosingShiftModal> createState() =>
      _KeuanganClosingShiftModalState();
}

class _KeuanganClosingShiftModalState
    extends ConsumerState<KeuanganClosingShiftModal> {
  final TextEditingController _physicalCashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _getEnteredPhysicalCash() {
    final clean = _physicalCashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  void _onAmountChanged(String val) {
    setState(() {});
  }

  void _quickFillExpectedCash(int expected) {
    final fmt = NumberFormat('#,###', 'id_ID');
    setState(() {
      _physicalCashController.text = expected > 0 ? fmt.format(expected) : '0';
    });
  }

  Future<void> _handleCloseShiftAndDownloadPdf({
    required CurrentShiftSummary shiftSummary,
    required String officerName,
    required String schoolName,
    required String authorityLevel,
  }) async {
    final enteredPhysical = _getEnteredPhysicalCash();
    final notes = _notesController.text.trim();
    final difference = enteredPhysical - shiftSummary.expectedCash;

    setState(() => _isProcessing = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Eksekusi API Tutup Kasir (Close Shift)
      final res = await apiClient.post('/finance/shift/close', body: {
        'actual_physical_cash': enteredPhysical,
        'notes': notes,
      });

      if (!res.success) {
        throw Exception(res.message ?? 'Gagal menutup sesi shift kasir');
      }

      // 2. Download / Share Berita Acara PDF Resmi
      try {
        await ReportExportService.downloadClosingShiftPdf(
          officerName: officerName,
          schoolName: schoolName,
          authorityLevel: authorityLevel,
          shiftNumber: shiftSummary.shiftNumber,
          startedAtStr: shiftSummary.formattedStartedAt,
          totalInflow: shiftSummary.totalInflow,
          totalOutflow: shiftSummary.totalOutflow,
          systemNetCash: shiftSummary.expectedCash,
          physicalCash: enteredPhysical,
          difference: difference,
          topupCount: shiftSummary.topupCount,
          payoutCount: shiftSummary.payoutCount,
          notes: notes,
        );
      } catch (pdfErr) {
        debugPrint('[PDF Generate Error]: $pdfErr');
      }

      // 3. Invalidate Providers untuk Reset Dashboard & Sesi
      ref.invalidate(keuanganCurrentShiftProvider);
      ref.invalidate(keuanganShiftHistoryProvider);
      ref.invalidate(keuanganDashboardProvider);
      ref.invalidate(adminFinanceOfficersLedgerProvider);
      ref.invalidate(adminAllShiftsProvider(null));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesi Shift #${shiftSummary.shiftNumber} berhasil ditutup & disetor. Laci kasir telah di-reset untuk sesi baru.',
                    style: GoogleFonts.inter(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText.isNotEmpty ? errText : 'Gagal memproses tutup kasir', style: GoogleFonts.inter()),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareWhatsApp({
    required CurrentShiftSummary shiftSummary,
    required String officerName,
    required String schoolName,
    required String authorityLevel,
  }) async {
    final enteredPhysical = _getEnteredPhysicalCash();
    final notes = _notesController.text.trim();
    final difference = enteredPhysical - shiftSummary.expectedCash;

    setState(() => _isProcessing = true);
    try {
      await ReportExportService.shareClosingShiftViaWhatsApp(
        officerName: officerName,
        schoolName: schoolName,
        authorityLevel: authorityLevel,
        shiftNumber: shiftSummary.shiftNumber,
        startedAtStr: shiftSummary.formattedStartedAt,
        totalInflow: shiftSummary.totalInflow,
        totalOutflow: shiftSummary.totalOutflow,
        systemNetCash: shiftSummary.expectedCash,
        physicalCash: enteredPhysical,
        difference: difference,
        topupCount: shiftSummary.topupCount,
        payoutCount: shiftSummary.payoutCount,
        notes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Membuka WhatsApp untuk mengirim laporan serah terima kas ke Super Admin.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan ke WhatsApp: $e', style: GoogleFonts.inter()),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).profile;
    final acadSchool = ref.watch(academicStructureProvider).valueOrNull?.schoolName;
    final fullName = profile?['full_name'] ?? 'Admin Keuangan';
    final authorityLevel = profile?['authority_level'] ?? 'L1';
    final school = acadSchool?.isNotEmpty == true
        ? acadSchool!
        : (profile?['assigned_school'] ?? 'Sekolah Digital');

    final shiftAsync = ref.watch(keuanganCurrentShiftProvider);

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        16;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.dividerCol, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: shiftAsync.when(
          data: (shiftSummary) {
            final inflow = shiftSummary.totalInflow;
            final outflow = shiftSummary.totalOutflow;
            final systemNetCash = shiftSummary.expectedCash;
            final enteredPhysical = _getEnteredPhysicalCash();
            final difference = enteredPhysical - systemNetCash;

            final topupCount = shiftSummary.topupCount;
            final payoutCount = shiftSummary.payoutCount;

            final isMatched = difference == 0 && _physicalCashController.text.trim().isNotEmpty;
            final isShort = difference < 0 && _physicalCashController.text.trim().isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Grab Handle ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Modal Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: Nebula.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Tutup Kasir (Shift #${shiftSummary.shiftNumber})',
                                    style: GoogleFonts.inter(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$fullName • Sesi sejak ${shiftSummary.formattedStartedAt}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                        color: context.textSecondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                // ── Scrollable Body ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Rekap Sesi Berjalan (Sejak Tutup Kasir Terakhir) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1. REKAP SESI BERJALAN',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Shift #${shiftSummary.shiftNumber}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Nebula.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.surfaceBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.dividerCol, width: 0.8),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                label: 'Uang Masuk (Top-Up Tunai):',
                                value: '+${_fmt.format(inflow)}',
                                sub: '$topupCount transaksi',
                                color: Nebula.teal,
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                label: 'Uang Keluar (Pencairan Stan):',
                                value: '-${_fmt.format(outflow)}',
                                sub: '$payoutCount transaksi',
                                color: Nebula.rose,
                              ),
                              const Divider(height: 16, thickness: 0.5),
                              _buildSummaryRow(
                                label: 'Wajib Ada di Laci Kasir:',
                                value: _fmt.format(systemNetCash),
                                sub: 'Akumulasi sesi berjalan',
                                color: context.textPrimary,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── 2. Input Uang Fisik Hasil Hitung Laci ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '2. FISIK UANG DI LACI KASIR',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            InkWell(
                              onTap: () => _quickFillExpectedCash(systemNetCash),
                              child: Text(
                                'Isi Sesuai Sistem',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Nebula.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: _physicalCashController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandsSeparatorInputFormatter(),
                          ],
                          onChanged: _onAmountChanged,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Rp',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Nebula.teal,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintText: '0',
                            labelText: 'Total Uang Kertas & Koin Fisik di Laci',
                            labelStyle: GoogleFonts.inter(fontSize: 12),
                            filled: true,
                            fillColor: context.surfaceBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.dividerCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.dividerCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Nebula.teal, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── 3. Status Rekonsiliasi Realtime ──
                        if (_physicalCashController.text.trim().isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMatched
                                  ? Nebula.teal.withValues(alpha: 0.1)
                                  : (isShort
                                      ? Nebula.rose.withValues(alpha: 0.1)
                                      : Nebula.amber.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMatched
                                    ? Nebula.teal.withValues(alpha: 0.4)
                                    : (isShort
                                        ? Nebula.rose.withValues(alpha: 0.4)
                                        : Nebula.amber.withValues(alpha: 0.4)),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isMatched
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : (isShort
                                          ? CupertinoIcons.exclamationmark_circle_fill
                                          : CupertinoIcons.info_circle_fill),
                                  color: isMatched
                                      ? Nebula.teal
                                      : (isShort ? Nebula.rose : Nebula.amber),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMatched
                                            ? 'KAS SEIMBANG (PAS / Rp 0 SELISIH)'
                                            : (isShort
                                                ? 'KAS KURANG / DEFISIT (-${_fmt.format(difference.abs())})'
                                                : 'KAS LEBIH / SURPLUS (+${_fmt.format(difference.abs())})'),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isMatched
                                              ? Nebula.teal
                                              : (isShort ? Nebula.rose : Nebula.amber),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isMatched
                                            ? 'Fisik uang di laci cocok 100% dengan catatan sistem.'
                                            : (isShort
                                                ? 'Fisik uang di laci lebih sedikit dari catatan sistem.'
                                                : 'Fisik uang di laci lebih banyak dari catatan sistem.'),
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── 4. Catatan Serah Terima (Opsional) ──
                        Text(
                          '3. CATATAN / KETERANGAN SERAH TERIMA',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: GoogleFonts.inter(fontSize: 12.5, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Uang fisik diserahkan ke Super Admin dalam amplop.',
                            hintStyle: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                            filled: true,
                            fillColor: context.surfaceBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.dividerCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.dividerCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Nebula.teal, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── 5. Tombol Aksi Cetak & Share WhatsApp ──
                        if (_isProcessing)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(color: Nebula.teal),
                            ),
                          )
                        else ...[
                          // Tombol 1: Tutup Kasir & Kunci Shift
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _physicalCashController.text.trim().isEmpty
                                  ? null
                                  : () => _handleCloseShiftAndDownloadPdf(
                                        shiftSummary: shiftSummary,
                                        officerName: fullName,
                                        schoolName: school,
                                        authorityLevel: authorityLevel,
                                      ),
                              icon: const Icon(CupertinoIcons.lock_shield_fill, size: 18),
                              label: Text(
                                'Tutup Kasir & Setor Sesi Shift #${shiftSummary.shiftNumber}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Nebula.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tombol 2: Kirim ke WhatsApp Super Admin
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () => _handleShareWhatsApp(
                                shiftSummary: shiftSummary,
                                officerName: fullName,
                                schoolName: school,
                                authorityLevel: authorityLevel,
                              ),
                              icon: const Icon(CupertinoIcons.share, size: 18),
                              label: Text(
                                'Kirim Serah Terima ke WA Super Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: Nebula.teal),
            ),
          ),
          error: (err, stack) => SizedBox(
            height: 250,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle, color: Nebula.rose, size: 36),
                    const SizedBox(height: 10),
                    Text('Gagal memuat sesi shift: $err', style: GoogleFonts.inter(color: Nebula.rose)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(keuanganCurrentShiftProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required String sub,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 13.5 : 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
