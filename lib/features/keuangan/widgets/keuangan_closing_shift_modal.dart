import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/services/report_export_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Modal interaktif untuk Tutup Kasir / Closing Shift & Rekonsiliasi Uang Fisik di Laci
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

  int _getInflow() =>
      (widget.dashboardData['topupToday'] as num?)?.toInt() ?? 0;
  int _getOutflow() =>
      (widget.dashboardData['payoutToday'] as num?)?.toInt() ?? 0;
  int _getSystemNetCash() => _getInflow() - _getOutflow();

  int _getEnteredPhysicalCash() {
    final clean = _physicalCashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  int _getDifference() {
    final entered = _getEnteredPhysicalCash();
    final system = _getSystemNetCash();
    return entered - system;
  }

  void _onAmountChanged(String val) {
    setState(() {});
  }

  void _quickFillExpectedCash() {
    final expected = _getSystemNetCash();
    setState(() {
      _physicalCashController.text = expected > 0 ? expected.toString() : '0';
    });
  }

  Future<void> _handleDownloadPdf() async {
    final profile = ref.read(authNotifierProvider).profile;
    final acadSchool = ref.read(academicStructureProvider).valueOrNull?.schoolName;
    final officerName = profile?['full_name'] ?? 'Admin Keuangan';
    final schoolName = acadSchool?.isNotEmpty == true
        ? acadSchool!
        : (profile?['assigned_school'] ?? 'Sekolah Digital');

    final enteredPhysical = _getEnteredPhysicalCash();
    final systemCash = _getSystemNetCash();
    final difference = _getDifference();
    final notes = _notesController.text.trim();

    setState(() => _isProcessing = true);
    try {
      await ReportExportService.downloadClosingShiftPdf(
        officerName: officerName,
        schoolName: schoolName,
        authorityLevel: profile?['authority_level'] ?? 'L1',
        totalInflow: _getInflow(),
        totalOutflow: _getOutflow(),
        systemNetCash: systemCash,
        physicalCash: enteredPhysical,
        difference: difference,
        topupCount: (widget.dashboardData['topupCount'] as num?)?.toInt() ?? 0,
        payoutCount: (widget.dashboardData['payoutCount'] as num?)?.toInt() ?? 0,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berita Acara Tutup Kasir berhasil diunduh (PDF).',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat dokumen: $e', style: GoogleFonts.inter()),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareWhatsApp() async {
    final profile = ref.read(authNotifierProvider).profile;
    final acadSchool = ref.read(academicStructureProvider).valueOrNull?.schoolName;
    final officerName = profile?['full_name'] ?? 'Admin Keuangan';
    final schoolName = acadSchool?.isNotEmpty == true
        ? acadSchool!
        : (profile?['assigned_school'] ?? 'Sekolah Digital');

    final enteredPhysical = _getEnteredPhysicalCash();
    final systemCash = _getSystemNetCash();
    final difference = _getDifference();
    final notes = _notesController.text.trim();

    setState(() => _isProcessing = true);
    try {
      await ReportExportService.shareClosingShiftViaWhatsApp(
        officerName: officerName,
        schoolName: schoolName,
        authorityLevel: profile?['authority_level'] ?? 'L1',
        totalInflow: _getInflow(),
        totalOutflow: _getOutflow(),
        systemNetCash: systemCash,
        physicalCash: enteredPhysical,
        difference: difference,
        topupCount: (widget.dashboardData['topupCount'] as num?)?.toInt() ?? 0,
        payoutCount: (widget.dashboardData['payoutCount'] as num?)?.toInt() ?? 0,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context);
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
    final school = acadSchool?.isNotEmpty == true
        ? acadSchool!
        : (profile?['assigned_school'] ?? 'Sekolah Digital');

    final inflow = _getInflow();
    final outflow = _getOutflow();
    final systemNetCash = _getSystemNetCash();
    final difference = _getDifference();

    final topupCount = (widget.dashboardData['topupCount'] as num?)?.toInt() ?? 0;
    final payoutCount = (widget.dashboardData['payoutCount'] as num?)?.toInt() ?? 0;

    final isMatched = difference == 0 && _physicalCashController.text.trim().isNotEmpty;
    final isShort = difference < 0 && _physicalCashController.text.trim().isNotEmpty;

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
        child: Column(
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
                        Text(
                          'Tutup Kasir (Closing Shift)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$fullName • $school',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
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
                    // ── 1. Rekap Kas Sistem Hari Ini ──
                    Text(
                      '1. REKAP CATATAN SISTEM (HARI INI)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Nebula.teal,
                        letterSpacing: 0.5,
                      ),
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
                            sub: 'Hasil akumulasi shift',
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
                          onTap: _quickFillExpectedCash,
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
                      onChanged: _onAmountChanged,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(CupertinoIcons.money_dollar_circle_fill, color: Nebula.teal),
                        hintText: 'Contoh: 1920000',
                        labelText: 'Total Uang Kertas & Koin Fisik di Laci (Rp)',
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
                                        ? 'Fisik uang di laci kasir cocok 100% dengan catatan sistem.'
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
                        hintText: 'Contoh: Uang fisik Rp 1.920.000 diserahkan ke Super Admin dalam amplop.',
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
                      // Tombol 1: Cetak Berita Acara PDF
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _handleDownloadPdf,
                          icon: const Icon(CupertinoIcons.doc_text_fill, size: 18),
                          label: Text(
                            'Cetak Berita Acara Tutup Kasir (PDF)',
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
                          onPressed: _handleShareWhatsApp,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
