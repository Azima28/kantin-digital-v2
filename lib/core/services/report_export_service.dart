import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Service untuk mengekspor dan mengunduh Laporan Keuangan
/// dalam format Excel (.xlsx) dan PDF.
class ReportExportService {
  ReportExportService._();

  static final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  /// Download atau Bagikan Laporan Keuangan dalam format Excel (.xlsx)
  static Future<void> downloadExcelReport({
    required String period,
    required double totalTopup,
    required double totalPurchase,
    double totalWithdrawal = 0.0,
    required int topupCount,
    required int purchaseCount,
    int withdrawalCount = 0,
    required List<Map<String, dynamic>> canteens,
    required bool includeAudit,
    required bool includeStudents,
    List<Map<String, dynamic>> auditLogs = const [],
    List<Map<String, dynamic>> students = const [],
  }) async {
    final excel = Excel.createExcel();
    final Sheet summarySheet = excel['Ringkasan Keuangan'];
    excel.setDefaultSheet('Ringkasan Keuangan');
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final double netInflow = totalTopup - totalWithdrawal;

    // Definisi Style untuk Sel Excel
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#0D9488'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final metaStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#475569'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final sectionHeaderStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#0F172A'),
      backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyleLeft = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyleRight = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final cellLeft = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final cellCenter = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellRight = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final totalStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#CCFBF1'),
      fontColorHex: ExcelColor.fromHexString('#0F766E'),
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final totalStyleCenter = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#CCFBF1'),
      fontColorHex: ExcelColor.fromHexString('#0F766E'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final totalStyleRight = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#CCFBF1'),
      fontColorHex: ExcelColor.fromHexString('#0F766E'),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Atur Lebar Kolom yang Luas & Nyaman Dibaca (Bebas Truncated)
    summarySheet.setColumnWidth(0, 44.0); // Metrik Keuangan / Nama Stan
    summarySheet.setColumnWidth(1, 24.0); // Jumlah Transaksi / No
    summarySheet.setColumnWidth(2, 32.0); // Total Nominal (IDR)

    // Row 0: Header Title
    summarySheet.appendRow([
      TextCellValue('LAPORAN KEUANGAN KANTIN DIGITAL'),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = titleStyle;

    // Row 1: Periode
    summarySheet.appendRow([
      TextCellValue('Periode Laporan: $period'),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .cellStyle = metaStyle;

    // Row 2: Tanggal Export
    summarySheet.appendRow([
      TextCellValue(
          'Tanggal Export: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}'),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .cellStyle = metaStyle;

    // Row 3: Blank
    summarySheet.appendRow([TextCellValue('')]);

    // Row 4: Section Header Metrik
    summarySheet.appendRow([
      TextCellValue('I. RINGKASAN METRIK KEUANGAN'),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .cellStyle = sectionHeaderStyle;

    // Row 5: Summary Table Header
    summarySheet.appendRow([
      TextCellValue('METRIK KEUANGAN'),
      TextCellValue('JUMLAH TRANSAKSI'),
      TextCellValue('TOTAL NOMINAL (IDR)'),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .cellStyle = headerStyleLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .cellStyle = headerStyle;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 5))
        .cellStyle = headerStyleRight;

    // Row 6: Total Top-Up
    summarySheet.appendRow([
      TextCellValue('Total Top-Up Siswa (Kas Masuk)'),
      TextCellValue('$topupCount Transaksi'),
      TextCellValue(_currencyFmt.format(totalTopup)),
    ]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).cellStyle = cellLeft;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).cellStyle = cellCenter;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6)).cellStyle = cellRight;

    // Row 7: Total Pembayaran Belanja
    summarySheet.appendRow([
      TextCellValue('Total Belanja Siswa (Omzet)'),
      TextCellValue('$purchaseCount Transaksi'),
      TextCellValue(_currencyFmt.format(totalPurchase)),
    ]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).cellStyle = cellLeft;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).cellStyle = cellCenter;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7)).cellStyle = cellRight;

    // Row 8: Total Pencairan Kas Stan (Kas Keluar)
    summarySheet.appendRow([
      TextCellValue('Pencairan Kas Stan (Kas Keluar)'),
      TextCellValue('$withdrawalCount Penarikan'),
      TextCellValue('-${_currencyFmt.format(totalWithdrawal)}'),
    ]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8)).cellStyle = cellLeft;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8)).cellStyle = cellCenter;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 8)).cellStyle = cellRight;

    // Row 9: Sisa Kas Mengendap Bersih
    summarySheet.appendRow([
      TextCellValue('Sisa Kas Mengendap Bersih'),
      TextCellValue('${topupCount + withdrawalCount} Mutasi'),
      TextCellValue(_currencyFmt.format(netInflow)),
    ]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).cellStyle = totalStyle;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9)).cellStyle = totalStyleCenter;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9)).cellStyle = totalStyleRight;

    // Row 10: Blank
    summarySheet.appendRow([TextCellValue('')]);

    // Row 11: Section Header Stan Kantin
    summarySheet.appendRow([
      TextCellValue('II. PENDAPATAN PER STAN KANTIN'),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11)).cellStyle = sectionHeaderStyle;

    // Row 12: Table Header Stan
    summarySheet.appendRow([
      TextCellValue('NAMA STAN KANTIN'),
      TextCellValue('STATUS / NO'),
      TextCellValue('PENDAPATAN EARNED (IDR)'),
    ]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12)).cellStyle = headerStyleLeft;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12)).cellStyle = headerStyle;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 12)).cellStyle = headerStyleRight;

    double totalEarnedAll = 0;
    int curRow = 13;
    if (canteens.isEmpty) {
      summarySheet.appendRow([
        TextCellValue('Belum ada data stan'),
        TextCellValue('-'),
        TextCellValue('Rp 0'),
      ]);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow)).cellStyle = cellLeft;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: curRow)).cellStyle = cellCenter;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: curRow)).cellStyle = cellRight;
      curRow++;
    } else {
      for (int i = 0; i < canteens.length; i++) {
        final c = canteens[i];
        final name = c['canteen_name']?.toString() ?? 'Stan #${i + 1}';
        final earned = (c['balance_earned'] as num?)?.toDouble() ?? 0.0;
        totalEarnedAll += earned;

        summarySheet.appendRow([
          TextCellValue(name),
          TextCellValue('Stan #${i + 1}'),
          TextCellValue(_currencyFmt.format(earned)),
        ]);
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow)).cellStyle = cellLeft;
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: curRow)).cellStyle = cellCenter;
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: curRow)).cellStyle = cellRight;
        curRow++;
      }

      // Total Row Stan Kantin
      summarySheet.appendRow([
        TextCellValue('TOTAL PENDAPATAN SELURUH STAN'),
        TextCellValue('${canteens.length} Stan Kantin'),
        TextCellValue(_currencyFmt.format(totalEarnedAll)),
      ]);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow)).cellStyle = totalStyle;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: curRow)).cellStyle = totalStyleCenter;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: curRow)).cellStyle = totalStyleRight;
    }

    // 2. Sheet Rekap Audit Log (jika dipilih)
    if (includeAudit && auditLogs.isNotEmpty) {
      final Sheet auditSheet = excel['Rekap Audit Log'];
      auditSheet.setColumnWidth(0, 10.0);
      auditSheet.setColumnWidth(1, 24.0);
      auditSheet.setColumnWidth(2, 26.0);
      auditSheet.setColumnWidth(3, 26.0);
      auditSheet.setColumnWidth(4, 55.0);

      // Title & Meta
      auditSheet.appendRow([TextCellValue('REKAP AUDIT LOG KEUANGAN')]);
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle = titleStyle;

      auditSheet.appendRow([TextCellValue('Periode Laporan: $period')]);
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .cellStyle = metaStyle;

      auditSheet.appendRow([TextCellValue('')]);

      // Header Row
      auditSheet.appendRow([
        TextCellValue('No'),
        TextCellValue('Waktu'),
        TextCellValue('Aktor'),
        TextCellValue('Tipe Aksi'),
        TextCellValue('Deskripsi'),
      ]);
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
          .cellStyle = headerStyle;
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
          .cellStyle = headerStyleLeft;
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3))
          .cellStyle = headerStyleLeft;
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3))
          .cellStyle = headerStyleLeft;
      auditSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3))
          .cellStyle = headerStyleLeft;

      for (int i = 0; i < auditLogs.length; i++) {
        final log = auditLogs[i];
        final created = log['created_at'] != null
            ? DateFormat('dd/MM/yyyy HH:mm')
                .format(DateTime.tryParse(log['created_at'].toString()) ?? DateTime.now())
            : '-';
        final rowIdx = 4 + i;
        auditSheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(created),
          TextCellValue(log['actor_name']?.toString() ?? '-'),
          TextCellValue(log['action_type']?.toString() ?? '-'),
          TextCellValue(log['description']?.toString() ?? '-'),
        ]);
        auditSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
            .cellStyle = cellCenter;
        auditSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
            .cellStyle = cellLeft;
        auditSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
            .cellStyle = cellLeft;
        auditSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx))
            .cellStyle = cellLeft;
        auditSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx))
            .cellStyle = cellLeft;
      }
    }

    // 3. Sheet Detail Per-Siswa (jika dipilih)
    if (includeStudents && students.isNotEmpty) {
      final Sheet studentSheet = excel['Detail Per-Siswa'];
      studentSheet.setColumnWidth(0, 10.0);
      studentSheet.setColumnWidth(1, 20.0);
      studentSheet.setColumnWidth(2, 30.0);
      studentSheet.setColumnWidth(3, 16.0);
      studentSheet.setColumnWidth(4, 26.0);
      studentSheet.setColumnWidth(5, 16.0);

      // Title & Meta
      studentSheet.appendRow([TextCellValue('DETAIL SALDO SISWA KANTIN DIGITAL')]);
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle = titleStyle;

      studentSheet.appendRow([TextCellValue('Periode Laporan: $period')]);
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .cellStyle = metaStyle;

      studentSheet.appendRow([TextCellValue('')]);

      // Header Row
      studentSheet.appendRow([
        TextCellValue('No'),
        TextCellValue('NISN'),
        TextCellValue('Nama Siswa'),
        TextCellValue('Kelas'),
        TextCellValue('Saldo (IDR)'),
        TextCellValue('Status'),
      ]);
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
          .cellStyle = headerStyle;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
          .cellStyle = headerStyleLeft;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3))
          .cellStyle = headerStyleLeft;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3))
          .cellStyle = headerStyleLeft;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3))
          .cellStyle = headerStyleRight;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 3))
          .cellStyle = headerStyle;

      double totalBalance = 0;
      for (int i = 0; i < students.length; i++) {
        final s = students[i];
        final bal = (s['balance'] as num?)?.toDouble() ?? 0.0;
        totalBalance += bal;
        final rowIdx = 4 + i;

        studentSheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(s['nisn']?.toString() ?? '-'),
          TextCellValue(s['full_name']?.toString() ?? '-'),
          TextCellValue(s['class_name']?.toString() ?? '-'),
          TextCellValue(_currencyFmt.format(bal)),
          TextCellValue(s['is_active'] == true ? 'Aktif' : 'Nonaktif'),
        ]);

        studentSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
            .cellStyle = cellCenter;
        studentSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
            .cellStyle = cellLeft;
        studentSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
            .cellStyle = cellLeft;
        studentSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx))
            .cellStyle = cellLeft;
        studentSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx))
            .cellStyle = cellRight;
        studentSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx))
            .cellStyle = cellCenter;
      }

      // Total Row for Students
      final totalRowIdx = 4 + students.length;
      studentSheet.appendRow([
        TextCellValue('TOTAL SALDO SISWA'),
        TextCellValue('${students.length} Siswa'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(_currencyFmt.format(totalBalance)),
        TextCellValue(''),
      ]);
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIdx))
          .cellStyle = totalStyle;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIdx))
          .cellStyle = totalStyleCenter;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRowIdx))
          .cellStyle = totalStyle;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIdx))
          .cellStyle = totalStyle;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIdx))
          .cellStyle = totalStyleRight;
      studentSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIdx))
          .cellStyle = totalStyleCenter;
    }

    // Encode file excel ke bytes
    final List<int>? fileBytes = excel.encode();
    if (fileBytes == null) return;

    final Uint8List bytes = Uint8List.fromList(fileBytes);
    final String filename = 'Laporan_Keuangan_Kantin_Digital_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    try {
      // Simpan sementara di temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      // Gunakan Printing.sharePdf / share file untuk prompt download / simpan
      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    } catch (_) {
      // Fallback
      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    }
  }

  /// Download atau Tampilkan Preview Laporan Keuangan dalam format PDF
  static Future<void> downloadPdfReport({
    required String period,
    required double totalTopup,
    required double totalPurchase,
    double totalWithdrawal = 0.0,
    required int topupCount,
    required int purchaseCount,
    int withdrawalCount = 0,
    required List<Map<String, dynamic>> canteens,
    required bool includeAudit,
    required bool includeStudents,
    List<Map<String, dynamic>> auditLogs = const [],
    List<Map<String, dynamic>> students = const [],
  }) async {
    final pdf = pw.Document();

    final ttfRegular = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    final double netInflow = totalTopup - totalWithdrawal;

    const PdfColor primaryTeal = PdfColor.fromInt(0xFF0D9488);
    const PdfColor darkText = PdfColor.fromInt(0xFF0F172A);
    const PdfColor grayText = PdfColor.fromInt(0xFF475569);
    const PdfColor subtleText = PdfColor.fromInt(0xFF64748B);
    const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);
    const PdfColor totalRowBg = PdfColor.fromInt(0xFFE6F5F2);
    const PdfColor borderCol = PdfColor.fromInt(0xFFE2E8F0);
    const PdfColor roseColor = PdfColor.fromInt(0xFFE11D48);

    final baseStyle = pw.TextStyle(font: ttfRegular, fontSize: 8.5, color: darkText);
    final boldStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkText);
    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText);
    final tableHeaderStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    final dateStr = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderCol, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Sistem Kantin Digital | Dokumen Laporan Keuangan Sah',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: subtleText),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: subtleText),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Executive Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KANTIN DIGITAL',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 16,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'LAPORAN KEUANGAN KANTIN SEKOLAH',
                        style: pw.TextStyle(
                          font: ttfRegular,
                          fontSize: 9,
                          color: const PdfColor.fromInt(0xFFCCFBF1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF0F766E),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF2DD4BF), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PERIODE: $period',
                          style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: PdfColors.white),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Dicetak: $dateStr',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: const PdfColor.fromInt(0xFFCCFBF1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Ringkasan Transaksi (2x2 KPI Grid)
            _pdfSectionTitle('RINGKASAN PERIODE', titleStyle, primaryTeal, ttfBold),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL TOP-UP SISWA (KAS MASUK)',
                    value: _currencyFmt.format(totalTopup),
                    subtext: '$topupCount transaksi berhasil',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL BELANJA SISWA (OMZET)',
                    value: _currencyFmt.format(totalPurchase),
                    subtext: '$purchaseCount transaksi belanja',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL PENCAIRAN STAN (KAS KELUAR)',
                    value: '-${_currencyFmt.format(totalWithdrawal)}',
                    subtext: '$withdrawalCount penarikan kas stan',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                    valueColor: roseColor,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'SISA KAS MENGENDAP BERSIH',
                    value: _currencyFmt.format(netInflow),
                    subtext: 'Akumulasi sisa kas mengendap',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: totalRowBg,
                    valueColor: primaryTeal,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Pendapatan Per Stan Kantin
            _pdfSectionTitle('PENDAPATAN PER STAN KANTIN', titleStyle, primaryTeal, ttfBold),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: tableHeaderStyle,
              headerDecoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
              ),
              cellStyle: baseStyle,
              headerHeight: 24,
              cellHeight: 22,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
              },
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderCol, width: 0.5),
                bottom: pw.BorderSide(color: borderCol, width: 0.8),
              ),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
              headers: ['No', 'Nama Stan Kantin', 'Pendapatan (Earned)'],
              data: canteens.isEmpty
                  ? [
                      ['1', 'Belum ada pendapatan stan', 'Rp 0']
                    ]
                  : canteens.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return [
                        '${i + 1}',
                        c['canteen_name']?.toString() ?? '-',
                        _currencyFmt.format((c['balance_earned'] as num?)?.toDouble() ?? 0.0),
                      ];
                    }).toList(),
            ),
            pw.SizedBox(height: 6),
            // Total Row Box for Canteens
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: pw.BoxDecoration(
                color: totalRowBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFF99F6E4), width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL PENDAPATAN SELURUH STAN',
                    style: boldStyle.copyWith(fontSize: 8.5, color: primaryTeal),
                  ),
                  pw.Text(
                    _currencyFmt.format(
                      canteens.fold(0.0, (sum, item) => sum + ((item['balance_earned'] as num?)?.toDouble() ?? 0.0)),
                    ),
                    style: boldStyle.copyWith(fontSize: 9.5, color: primaryTeal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Audit Logs (Opsional)
            if (includeAudit && auditLogs.isNotEmpty) ...[
              _pdfSectionTitle('REKAP RIWAYAT AUDIT LOG', titleStyle, primaryTeal, ttfBold),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: tableHeaderStyle,
                headerDecoration: pw.BoxDecoration(
                  color: primaryTeal,
                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                ),
                cellStyle: baseStyle,
                headerHeight: 24,
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(75),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(2),
                },
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: borderCol, width: 0.5),
                  bottom: pw.BorderSide(color: borderCol, width: 0.8),
                ),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
                headers: ['No', 'Waktu', 'Aktor', 'Aksi', 'Deskripsi'],
                data: auditLogs.take(25).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final log = entry.value;
                  final date = log['created_at'] != null
                      ? DateFormat('dd/MM HH:mm')
                          .format(DateTime.tryParse(log['created_at'].toString()) ?? DateTime.now())
                      : '-';
                  return [
                    '${i + 1}',
                    date,
                    log['actor_name']?.toString() ?? '-',
                    log['action_type']?.toString() ?? '-',
                    log['description']?.toString() ?? '-',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Student Detail (Opsional)
            if (includeStudents && students.isNotEmpty) ...[
              _pdfSectionTitle('DETAIL PER-SISWA (DATA SENSITIF)', titleStyle, primaryTeal, ttfBold),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: tableHeaderStyle,
                headerDecoration: pw.BoxDecoration(
                  color: primaryTeal,
                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                ),
                cellStyle: baseStyle,
                headerHeight: 24,
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(60),
                  4: const pw.FlexColumnWidth(1.2),
                },
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: borderCol, width: 0.5),
                  bottom: pw.BorderSide(color: borderCol, width: 0.8),
                ),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
                headers: ['No', 'NISN', 'Nama Siswa', 'Kelas', 'Saldo'],
                data: students.take(40).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return [
                    '${i + 1}',
                    s['nisn']?.toString() ?? '-',
                    s['full_name']?.toString() ?? '-',
                    s['class_name']?.toString() ?? '-',
                    _currencyFmt.format((s['balance'] as num?)?.toDouble() ?? 0.0),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 6),
              // Total Student Balance Row Box
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: pw.BoxDecoration(
                  color: totalRowBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFF99F6E4), width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL SALDO SISWA (${students.length} Siswa)',
                      style: boldStyle.copyWith(fontSize: 8.5, color: primaryTeal),
                    ),
                    pw.Text(
                      _currencyFmt.format(
                        students.fold(0.0, (sum, item) => sum + ((item['balance'] as num?)?.toDouble() ?? 0.0)),
                      ),
                      style: boldStyle.copyWith(fontSize: 9.5, color: primaryTeal),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(color: borderCol, width: 0.8),
                ),
                child: pw.Text(
                  'Dokumen ini ditarik secara otomatis & terverifikasi oleh Sistem Kantin Digital.',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: grayText),
                ),
              ),
            ),
          ];
        },
      ),
    );

    final String filename = 'Laporan_Keuangan_Kantin_Digital_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: filename,
    );
  }

  static pw.Widget _pdfSectionTitle(
    String title,
    pw.TextStyle style,
    PdfColor tealColor,
    pw.Font? ttfBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 4,
          height: 13,
          decoration: pw.BoxDecoration(
            color: tealColor,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: ttfBold,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF0F172A),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfKpiCard({
    required String label,
    required String value,
    required String subtext,
    required pw.TextStyle baseStyle,
    required pw.TextStyle boldStyle,
    required PdfColor grayStyle,
    required PdfColor borderCol,
    required PdfColor bgCol,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bgCol,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderCol, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: baseStyle.font, fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: grayStyle, letterSpacing: 0.3),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: boldStyle.copyWith(
              fontSize: 11,
              color: valueColor ?? const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(subtext, style: pw.TextStyle(font: baseStyle.font, fontSize: 7.5, color: grayStyle)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EKSPOR BUKU KAS PETUGAS LOKET (PDF & EXCEL & WHATSAPP)
  // ══════════════════════════════════════════════════════════════════════════

  /// Download atau Bagikan Laporan Buku Kas Petugas dalam format Excel (.xlsx)
  static Future<void> downloadOfficerLedgerExcel({
    required FinanceOfficerLedgerItem officer,
    required List<OfficerJournalEntry> journals,
    required String period,
    required int totalInflow,
    required int totalOutflow,
    required int netCash,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#0D9488'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final metaStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#475569'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final sectionHeaderStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#0F172A'),
      backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyleLeft = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyleRight = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final cellLeft = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final cellCenter = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellRight = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final totalStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#CCFBF1'),
      fontColorHex: ExcelColor.fromHexString('#0F766E'),
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final totalStyleRight = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#CCFBF1'),
      fontColorHex: ExcelColor.fromHexString('#0F766E'),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // ── 1. Sheet Ringkasan Kas Petugas ──
    final Sheet summarySheet = excel['Ringkasan Kas Petugas'];
    excel.setDefaultSheet('Ringkasan Kas Petugas');

    summarySheet.setColumnWidth(0, 36.0);
    summarySheet.setColumnWidth(1, 30.0);
    summarySheet.setColumnWidth(2, 36.0);

    summarySheet.appendRow([TextCellValue('LAPORAN BUKU KAS PETUGAS LOKET')]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

    summarySheet.appendRow([TextCellValue('Nama Petugas: ${officer.fullName} (${officer.assignedSchool})')]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = metaStyle;

    summarySheet.appendRow([TextCellValue('Periode Laporan: $period')]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = metaStyle;

    summarySheet.appendRow([TextCellValue('Tanggal Export: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}')]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = metaStyle;

    summarySheet.appendRow([TextCellValue('')]);

    summarySheet.appendRow([TextCellValue('RINGKASAN AKUNTABILITAS KAS PETUGAS')]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).cellStyle = sectionHeaderStyle;

    summarySheet.appendRow([TextCellValue('Indikator Kas'), TextCellValue('Keterangan'), TextCellValue('Nominal (IDR)')]);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).cellStyle = headerStyleLeft;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).cellStyle = headerStyleLeft;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6)).cellStyle = headerStyleRight;

    final summaryRows = [
      ['Total Uang Masuk (Inflow)', 'Setoran Top-Up Tunai Siswa', _currencyFmt.format(totalInflow)],
      ['Total Uang Keluar (Outflow)', 'Pencairan Kas Stan (Payout)', _currencyFmt.format(totalOutflow)],
      ['Kas Fisik di Tangan Petugas', 'Net Uang Tunai di Laci Kasir', _currencyFmt.format(netCash)],
      ['Total Transaksi Jurnal', 'Frekuensi Mutasi Periode Ini', '${journals.length} Transaksi'],
      ['Status Petugas', 'Otoritas ${officer.authorityLevel}', officer.isActive ? 'AKTIF' : 'NONAKTIF'],
    ];

    for (int i = 0; i < summaryRows.length; i++) {
      final r = summaryRows[i];
      final rIdx = 7 + i;
      summarySheet.appendRow([TextCellValue(r[0]), TextCellValue(r[1]), TextCellValue(r[2])]);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIdx)).cellStyle = cellLeft;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx)).cellStyle = cellLeft;
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIdx)).cellStyle = cellRight;
    }

    // ── 2. Sheet Jurnal Rincian Mutasi Kas ──
    final Sheet journalSheet = excel['Rincian Jurnal Mutasi'];
    journalSheet.setColumnWidth(0, 8.0);   // No
    journalSheet.setColumnWidth(1, 22.0);  // Waktu
    journalSheet.setColumnWidth(2, 16.0);  // Jenis
    journalSheet.setColumnWidth(3, 16.0);  // Kategori
    journalSheet.setColumnWidth(4, 28.0);  // Pihak Terkait
    journalSheet.setColumnWidth(5, 34.0);  // Catatan
    journalSheet.setColumnWidth(6, 14.0);  // Metode
    journalSheet.setColumnWidth(7, 24.0);  // Nominal

    journalSheet.appendRow([TextCellValue('JURNAL RINCIAN MUTASI KAS PETUGAS')]);
    journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

    journalSheet.appendRow([TextCellValue('Petugas: ${officer.fullName} | Periode: $period')]);
    journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = metaStyle;

    journalSheet.appendRow([TextCellValue('')]);

    journalSheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Waktu & Tanggal'),
      TextCellValue('Jenis Transaksi'),
      TextCellValue('Arah Kas'),
      TextCellValue('Pihak Terkait (Siswa/Stan)'),
      TextCellValue('Catatan / Keterangan'),
      TextCellValue('Metode'),
      TextCellValue('Nominal (IDR)'),
    ]);

    for (int col = 0; col < 8; col++) {
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3)).cellStyle =
          col == 7 ? headerStyleRight : (col == 0 ? headerStyle : headerStyleLeft);
    }

    int jRow = 4;
    for (int i = 0; i < journals.length; i++) {
      final j = journals[i];
      final dateStr = j.createdAt != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(j.createdAt!)
          : '-';
      final isInflow = j.category == 'INFLOW' || j.type == 'TOPUP';
      final sign = isInflow ? '+' : '-';

      journalSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(dateStr),
        TextCellValue(j.type),
        TextCellValue(isInflow ? 'UANG MASUK (+)' : 'UANG KELUAR (-)'),
        TextCellValue(j.targetName.isNotEmpty ? j.targetName : '-'),
        TextCellValue(j.notes.isNotEmpty ? j.notes : '-'),
        TextCellValue(j.method.isNotEmpty ? j.method.toUpperCase() : 'TUNAI'),
        TextCellValue('$sign${_currencyFmt.format(j.amount)}'),
      ]);

      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: jRow)).cellStyle = cellCenter;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: jRow)).cellStyle = cellCenter;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: jRow)).cellStyle = cellLeft;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: jRow)).cellStyle = cellLeft;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: jRow)).cellStyle = cellLeft;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: jRow)).cellStyle = cellLeft;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: jRow)).cellStyle = cellCenter;
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: jRow)).cellStyle = cellRight;
      jRow++;
    }

    // Total Row
    journalSheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue('${journals.length} Mutasi'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('KAS BERSIH DI TANGAN:'),
      TextCellValue(''),
      TextCellValue(_currencyFmt.format(netCash)),
    ]);

    for (int col = 0; col < 8; col++) {
      journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: jRow)).cellStyle =
          col == 7 ? totalStyleRight : totalStyle;
    }

    final List<int>? fileBytes = excel.encode();
    if (fileBytes == null) return;

    final Uint8List bytes = Uint8List.fromList(fileBytes);
    final safeName = officer.fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final String filename = 'Buku_Kas_${safeName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (_) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }

  /// Download atau Tampilkan Preview Laporan Buku Kas Petugas dalam format PDF Berkop Resmi
  static Future<void> downloadOfficerLedgerPdf({
    required FinanceOfficerLedgerItem officer,
    required List<OfficerJournalEntry> journals,
    required String period,
    required int totalInflow,
    required int totalOutflow,
    required int netCash,
  }) async {
    final pdf = pw.Document();

    final ttfRegular = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    const PdfColor primaryTeal = PdfColor.fromInt(0xFF0D9488);
    const PdfColor darkText = PdfColor.fromInt(0xFF0F172A);
    const PdfColor grayText = PdfColor.fromInt(0xFF475569);
    const PdfColor subtleText = PdfColor.fromInt(0xFF64748B);
    const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);
    const PdfColor totalRowBg = PdfColor.fromInt(0xFFE6F5F2);
    const PdfColor borderCol = PdfColor.fromInt(0xFFE2E8F0);
    const PdfColor roseText = PdfColor.fromInt(0xFFE11D48);

    final baseStyle = pw.TextStyle(font: ttfRegular, fontSize: 8.5, color: darkText);
    final boldStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkText);
    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText);
    final tableHeaderStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    final printDateStr = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderCol, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Sistem Kantin Digital | Buku Kas Sah Petugas Loket',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: subtleText),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: subtleText),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ── Executive Header Banner ──
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KANTIN DIGITAL',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 16,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'LAPORAN BUKU KAS PETUGAS LOKET KEUANGAN',
                        style: pw.TextStyle(
                          font: ttfRegular,
                          fontSize: 9,
                          color: const PdfColor.fromInt(0xFFCCFBF1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF0F766E),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF2DD4BF), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PERIODE: $period',
                          style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: PdfColors.white),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Dicetak: $printDateStr',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: const PdfColor.fromInt(0xFFCCFBF1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Informasi Identitas Petugas ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderCol, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NAMA PETUGAS LOKET:', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                      pw.SizedBox(height: 2),
                      pw.Text(officer.fullName, style: boldStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INSTANSI / SEKOLAH:', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                      pw.SizedBox(height: 2),
                      pw.Text(officer.assignedSchool, style: boldStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('OTORITAS / STATUS:', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                      pw.SizedBox(height: 2),
                      pw.Text('${officer.authorityLevel} | ${officer.isActive ? "AKTIF" : "NONAKTIF"}', style: boldStyle.copyWith(fontSize: 10, color: primaryTeal)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Ringkasan Kas (3 KPI Cards) ──
            _pdfSectionTitle('REKAPITULASI KAS FISIK DI TANGAN', titleStyle, primaryTeal, ttfBold),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL UANG MASUK (+)',
                    value: _currencyFmt.format(totalInflow),
                    subtext: 'Setoran Top-Up Tunai Siswa',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                    valueColor: primaryTeal,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL UANG KELUAR (-)',
                    value: _currencyFmt.format(totalOutflow),
                    subtext: 'Pencairan Kas Stan (Payout)',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                    valueColor: roseText,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'KAS FISIK DI TANGAN',
                    value: _currencyFmt.format(netCash),
                    subtext: 'Sisa uang di laci petugas',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: const PdfColor.fromInt(0xFF5EEAD4),
                    bgCol: totalRowBg,
                    valueColor: primaryTeal,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // ── Tabel Rincian Jurnal Mutasi ──
            _pdfSectionTitle('RINCIAN JURNAL MUTASI KAS (${journals.length} TRANSAKSI)', titleStyle, primaryTeal, ttfBold),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: tableHeaderStyle,
              headerDecoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
              ),
              cellStyle: baseStyle,
              headerHeight: 24,
              cellHeight: 22,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FixedColumnWidth(68),
                2: const pw.FixedColumnWidth(64),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(1.8),
                5: const pw.FixedColumnWidth(48),
                6: const pw.FlexColumnWidth(1.3),
              },
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderCol, width: 0.5),
                bottom: pw.BorderSide(color: borderCol, width: 0.8),
              ),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
              headers: ['No', 'Waktu', 'Jenis', 'Pihak Terkait', 'Keterangan', 'Metode', 'Nominal'],
              data: journals.isEmpty
                  ? [
                      ['1', '-', '-', 'Belum ada mutasi pada periode ini', '-', '-', 'Rp 0']
                    ]
                  : journals.asMap().entries.map((entry) {
                      final i = entry.key;
                      final j = entry.value;
                      final date = j.createdAt != null
                          ? DateFormat('dd/MM HH:mm').format(j.createdAt!)
                          : '-';
                      final isInflow = j.category == 'INFLOW' || j.type == 'TOPUP';
                      final sign = isInflow ? '+' : '-';
                      return [
                        '${i + 1}',
                        date,
                        j.type,
                        j.targetName.isNotEmpty ? j.targetName : '-',
                        j.notes.isNotEmpty ? j.notes : '-',
                        j.method.isNotEmpty ? j.method.toUpperCase() : 'TUNAI',
                        '$sign${_currencyFmt.format(j.amount)}',
                      ];
                    }).toList(),
            ),
            pw.SizedBox(height: 8),

            // Total Baris Bawah
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: totalRowBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFF99F6E4), width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL SISA KAS FISIK DI TANGAN PETUGAS (${journals.length} MUTASI)',
                    style: boldStyle.copyWith(fontSize: 8.5, color: primaryTeal),
                  ),
                  pw.Text(
                    _currencyFmt.format(netCash),
                    style: boldStyle.copyWith(fontSize: 10, color: primaryTeal),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── Bagian Tanda Tangan & Pengesahan Sah ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Petugas Loket Kasir,', style: baseStyle),
                    pw.SizedBox(height: 40),
                    pw.Text('( ${officer.fullName} )', style: boldStyle),
                    pw.Text('NIP / Otoritas ${officer.authorityLevel}', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Mengetahui / Mengesahkan,', style: baseStyle),
                    pw.SizedBox(height: 40),
                    pw.Text('( Super Admin Keuangan )', style: boldStyle),
                    pw.Text('Auditor & Governance Sistem', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Footer Otomatis
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(color: borderCol, width: 0.8),
                ),
                child: pw.Text(
                  'Dokumen buku kas ini ditarik secara digital & terverifikasi oleh Sistem Kantin Digital.',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: grayText),
                ),
              ),
            ),
          ];
        },
      ),
    );

    final safeName = officer.fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final String filename = 'Buku_Kas_${safeName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: filename,
    );
  }

  /// Bagikan Ringkasan Buku Kas Petugas ke WhatsApp dan Lampirkan Dokumen Laporan
  static Future<void> shareOfficerLedgerViaWhatsApp({
    required FinanceOfficerLedgerItem officer,
    required List<OfficerJournalEntry> journals,
    required String period,
    required int totalInflow,
    required int totalOutflow,
    required int netCash,
    bool asPdf = true,
  }) async {
    // 1. Susun teks pesan ringkasan WhatsApp yang sangat rapi dan informatif
    final buffer = StringBuffer();
    buffer.writeln('📋 *LAPORAN BUKU KAS PETUGAS LOKET*');
    buffer.writeln('Kantin Digital — Sistem Akuntabilitas Sah');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Petugas:* ${officer.fullName}');
    buffer.writeln('🏫 *Sekolah:* ${officer.assignedSchool}');
    buffer.writeln('🛡️ *Otoritas:* Level ${officer.authorityLevel}');
    buffer.writeln('📅 *Periode:* $period');
    buffer.writeln('⏰ *Waktu Cetak:* ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📈 *Uang Masuk (Top-Up):* ${_currencyFmt.format(totalInflow)}');
    buffer.writeln('📉 *Uang Keluar (Pencairan):* ${_currencyFmt.format(totalOutflow)}');
    buffer.writeln('💰 *SISA KAS FISIK DI TANGAN:* ${_currencyFmt.format(netCash)}');
    buffer.writeln('📊 *Total Mutasi:* ${journals.length} Transaksi');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (journals.isNotEmpty) {
      buffer.writeln('*Mutasi Terkini:*');
      final sample = journals.take(5).toList();
      for (int i = 0; i < sample.length; i++) {
        final j = sample[i];
        final dt = j.createdAt != null ? DateFormat('dd/MM HH:mm').format(j.createdAt!) : '-';
        final isInflow = j.category == 'INFLOW' || j.type == 'TOPUP';
        final sign = isInflow ? '(+)' : '(-)';
        buffer.writeln('${i + 1}. [$dt] ${j.type} $sign ${_currencyFmt.format(j.amount)} — ${j.targetName}');
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    }

    buffer.writeln('_Laporan ditarik resmi dari Sistem Kantin Digital._');

    // 2. Buka WhatsApp dengan pesan terformat
    final encodedText = Uri.encodeComponent(buffer.toString());
    final waUrl = 'https://api.whatsapp.com/send?text=$encodedText';
    final uri = Uri.parse(waUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Abaikan jika url_launcher browser belum terhubung
    }

    // 3. Picu unduhan / share file dokumen (PDF / Excel) agar pengguna dapat melampirkannya ke chat WhatsApp
    if (asPdf) {
      await downloadOfficerLedgerPdf(
        officer: officer,
        journals: journals,
        period: period,
        totalInflow: totalInflow,
        totalOutflow: totalOutflow,
        netCash: netCash,
      );
    } else {
      await downloadOfficerLedgerExcel(
        officer: officer,
        journals: journals,
        period: period,
        totalInflow: totalInflow,
        totalOutflow: totalOutflow,
        netCash: netCash,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BERITA ACARA SERAH TERIMA & TUTUP KASIR (CLOSING SHIFT PDF & WHATSAPP)
  // ══════════════════════════════════════════════════════════════════════════

  /// Download atau Tampilkan Preview Berita Acara Tutup Kasir (PDF Berkop Resmi)
  static Future<void> downloadClosingShiftPdf({
    required String officerName,
    required String schoolName,
    required String authorityLevel,
    int shiftNumber = 1,
    String? startedAtStr,
    required int totalInflow,
    required int totalOutflow,
    required int systemNetCash,
    required int physicalCash,
    required int difference,
    required int topupCount,
    required int payoutCount,
    String notes = '',
  }) async {
    final pdf = pw.Document();

    final ttfRegular = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    const PdfColor primaryTeal = PdfColor.fromInt(0xFF0D9488);
    const PdfColor darkText = PdfColor.fromInt(0xFF0F172A);
    const PdfColor grayText = PdfColor.fromInt(0xFF475569);
    const PdfColor subtleText = PdfColor.fromInt(0xFF64748B);
    const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);
    const PdfColor totalRowBg = PdfColor.fromInt(0xFFE6F5F2);
    const PdfColor borderCol = PdfColor.fromInt(0xFFE2E8F0);
    const PdfColor roseColor = PdfColor.fromInt(0xFFE11D48);

    final baseStyle = pw.TextStyle(font: ttfRegular, fontSize: 8.5, color: darkText);
    final boldStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkText);
    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText);

    final printDateStr = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());
    final dateTodayStr = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    final isMatched = difference == 0;
    final isShort = difference < 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderCol, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Sistem Kantin Digital | Berita Acara Sah Tutup Kasir (Shift #$shiftNumber)',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: subtleText),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: subtleText),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Banner Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KANTIN DIGITAL',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 16,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'BERITA ACARA SERAH TERIMA & TUTUP KASIR (SHIFT #$shiftNumber)',
                        style: pw.TextStyle(
                          font: ttfRegular,
                          fontSize: 8.5,
                          color: const PdfColor.fromInt(0xFFCCFBF1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF0F766E),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF2DD4BF), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TANGGAL: $dateTodayStr',
                          style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: PdfColors.white),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Waktu Tutup: $printDateStr',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 8, color: const PdfColor.fromInt(0xFFCCFBF1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Identitas Kasir & Loket
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderCol, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PETUGAS LOKET / KASIR:', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                      pw.SizedBox(height: 2),
                      pw.Text(officerName, style: boldStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INSTANSI / SEKOLAH:', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                      pw.SizedBox(height: 2),
                      pw.Text(schoolName, style: boldStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('WEWENANG / SHIFT:', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                      pw.SizedBox(height: 2),
                      pw.Text('Shift #$shiftNumber (Level $authorityLevel)', style: boldStyle.copyWith(fontSize: 10, color: primaryTeal)),
                      if (startedAtStr != null)
                        pw.Text('Aktif sejak: $startedAtStr', style: pw.TextStyle(font: ttfRegular, fontSize: 7, color: subtleText)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 1. REKONSILIASI KAS LACI (FISIK VS SISTEM)
            _pdfSectionTitle('1. REKONSILIASI KAS LACI FISIK', titleStyle, primaryTeal, ttfBold),
            pw.SizedBox(height: 8),

            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL UANG MASUK (+)',
                    value: _currencyFmt.format(totalInflow),
                    subtext: '$topupCount Transaksi Top-Up Tunai',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                    valueColor: primaryTeal,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'TOTAL UANG KELUAR (-)',
                    value: _currencyFmt.format(totalOutflow),
                    subtext: '$payoutCount Transaksi Pencairan Stan',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: borderCol,
                    bgCol: lightBg,
                    valueColor: roseColor,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _pdfKpiCard(
                    label: 'KAS SISTEM (WAJIB DI LACI)',
                    value: _currencyFmt.format(systemNetCash),
                    subtext: 'Saldo kas riil sistem',
                    baseStyle: baseStyle,
                    boldStyle: boldStyle,
                    grayStyle: grayText,
                    borderCol: const PdfColor.fromInt(0xFF5EEAD4),
                    bgCol: totalRowBg,
                    valueColor: primaryTeal,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Banner Hasil Perhitungan Fisik & Selisih
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: isMatched
                    ? totalRowBg
                    : (isShort
                        ? const PdfColor.fromInt(0xFFFFF1F2)
                        : const PdfColor.fromInt(0xFFFEF3C7)),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: isMatched
                      ? const PdfColor.fromInt(0xFF5EEAD4)
                      : (isShort
                          ? const PdfColor.fromInt(0xFFFDA4AF)
                          : const PdfColor.fromInt(0xFFFDE68A)),
                  width: 1,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FISIK UANG DI LACI YANG DISERAHKAN:',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _currencyFmt.format(physicalCash),
                        style: boldStyle.copyWith(fontSize: 14, color: isMatched ? primaryTeal : (isShort ? roseColor : const PdfColor.fromInt(0xFFD97706))),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'STATUS REKONSILIASI KAS:',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        isMatched
                            ? 'SEIMBANG (PAS / Rp 0 SELISIH)'
                            : (isShort
                                ? 'DEFISIT / KURANG (-${_currencyFmt.format(difference.abs())})'
                                : 'SURPLUS / LEBIH (+${_currencyFmt.format(difference.abs())})'),
                        style: boldStyle.copyWith(
                          fontSize: 10.5,
                          color: isMatched
                              ? primaryTeal
                              : (isShort ? roseColor : const PdfColor.fromInt(0xFFD97706)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 2. CATATAN & KETERANGAN SERAH TERIMA
            _pdfSectionTitle('2. KETERANGAN & CATATAN SERAH TERIMA', titleStyle, primaryTeal, ttfBold),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderCol, width: 0.6),
              ),
              child: pw.Text(
                notes.isNotEmpty
                    ? notes
                    : 'Fisik uang di laci telah dihitung bersama dan diserahkan dalam keadaan tersegel/sesuai.',
                style: baseStyle.copyWith(fontSize: 8.5),
              ),
            ),
            pw.SizedBox(height: 24),

            // Pengesahan Tanda Tangan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Yang Menyerahkan (Petugas Loket),', style: baseStyle),
                    pw.SizedBox(height: 40),
                    pw.Text('( $officerName )', style: boldStyle),
                    pw.Text('Petugas Kasir Shift', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Yang Menerima (Super Admin / Bendahara),', style: baseStyle),
                    pw.SizedBox(height: 40),
                    pw.Text('( Super Admin Keuangan )', style: boldStyle),
                    pw.Text('Auditor Kas & Governance Sekolah', style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: subtleText)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(color: borderCol, width: 0.8),
                ),
                child: pw.Text(
                  'Dokumen berita acara ini diterbitkan secara digital oleh Sistem Kantin Digital.',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 7.5, color: grayText),
                ),
              ),
            ),
          ];
        },
      ),
    );

    final safeName = officerName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final String filename = 'Berita_Acara_Tutup_Kas_${safeName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: filename,
    );
  }

  /// Bagikan Berita Acara Tutup Kasir ke WhatsApp Super Admin
  static Future<void> shareClosingShiftViaWhatsApp({
    required String officerName,
    required String schoolName,
    required String authorityLevel,
    int shiftNumber = 1,
    String? startedAtStr,
    required int totalInflow,
    required int totalOutflow,
    required int systemNetCash,
    required int physicalCash,
    required int difference,
    required int topupCount,
    required int payoutCount,
    String notes = '',
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🔒 *BERITA ACARA TUTUP KASIR (SHIFT #$shiftNumber)*');
    buffer.writeln('Kantin Digital — Sistem Akuntabilitas Sah');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Petugas Kasir:* $officerName');
    buffer.writeln('🏫 *Sekolah:* $schoolName');
    buffer.writeln('🛡️ *Sesi Shift:* Shift #$shiftNumber (Level $authorityLevel)');
    if (startedAtStr != null) {
      buffer.writeln('⏰ *Aktif Sejak:* $startedAtStr');
    }
    buffer.writeln('📅 *Tanggal Tutup:* ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())} WIB');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📈 *Uang Masuk (Top-Up Tunai):* ${_currencyFmt.format(totalInflow)} ($topupCount tx)');
    buffer.writeln('📉 *Uang Keluar (Pencairan Stan):* ${_currencyFmt.format(totalOutflow)} ($payoutCount tx)');
    buffer.writeln('📊 *Total Wajib di Laci (Sistem):* ${_currencyFmt.format(systemNetCash)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💵 *Fisik Uang Diserahkan:* ${_currencyFmt.format(physicalCash)}');

    if (difference == 0) {
      buffer.writeln('🟢 *Status:* SEIMBANG / PAS (Rp 0 Selisih)');
    } else if (difference < 0) {
      buffer.writeln('🔴 *Status:* DEFISIT / KURANG (-${_currencyFmt.format(difference.abs())})');
    } else {
      buffer.writeln('🟡 *Status:* SURPLUS / LEBIH (+${_currencyFmt.format(difference.abs())})');
    }

    if (notes.isNotEmpty) {
      buffer.writeln('📝 *Catatan:* $notes');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('_Laporan serah terima kas resmi diterbitkan dari Sistem Kantin Digital._');

    final encodedText = Uri.encodeComponent(buffer.toString());
    final waUrl = 'https://api.whatsapp.com/send?text=$encodedText';
    final uri = Uri.parse(waUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    await downloadClosingShiftPdf(
      officerName: officerName,
      schoolName: schoolName,
      authorityLevel: authorityLevel,
      totalInflow: totalInflow,
      totalOutflow: totalOutflow,
      systemNetCash: systemNetCash,
      physicalCash: physicalCash,
      difference: difference,
      topupCount: topupCount,
      payoutCount: payoutCount,
      notes: notes,
    );
  }

}


