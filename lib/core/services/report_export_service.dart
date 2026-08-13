import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    required double totalCorrection,
    required int topupCount,
    required int purchaseCount,
    required List<Map<String, dynamic>> canteens,
    required bool includeAudit,
    required bool includeStudents,
    List<Map<String, dynamic>> auditLogs = const [],
    List<Map<String, dynamic>> students = const [],
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Hapus sheet default Sheet1

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

    // 1. Sheet Ringkasan Keuangan
    final Sheet summarySheet = excel['Ringkasan Keuangan'];
    excel.setDefaultSheet('Ringkasan Keuangan');

    // Atur Lebar Kolom yang Luas & Nyaman Dibaca
    summarySheet.setColumnWidth(0, 36.0); // Metrik / Nama Stan
    summarySheet.setColumnWidth(1, 26.0); // Jumlah Transaksi / No
    summarySheet.setColumnWidth(2, 36.0); // Total Nominal (IDR) / Pendapatan

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
      TextCellValue('Total Top-Up Tunai'),
      IntCellValue(topupCount),
      TextCellValue(_currencyFmt.format(totalTopup)),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .cellStyle = cellLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .cellStyle = cellCenter;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6))
        .cellStyle = cellRight;

    // Row 7: Total Pembayaran
    summarySheet.appendRow([
      TextCellValue('Total Pembayaran Belanja'),
      IntCellValue(purchaseCount),
      TextCellValue(_currencyFmt.format(totalPurchase)),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .cellStyle = cellLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .cellStyle = cellCenter;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7))
        .cellStyle = cellRight;

    // Row 8: Total Koreksi
    summarySheet.appendRow([
      TextCellValue('Total Koreksi Saldo'),
      TextCellValue('-'),
      TextCellValue(
          '${totalCorrection >= 0 ? "+" : ""}${_currencyFmt.format(totalCorrection)}'),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .cellStyle = cellLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .cellStyle = cellCenter;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 8))
        .cellStyle = cellRight;

    // Row 9: Total Row - Net Aliran
    summarySheet.appendRow([
      TextCellValue('Net Aliran Masuk'),
      TextCellValue('-'),
      TextCellValue(_currencyFmt.format(totalTopup + totalCorrection)),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .cellStyle = totalStyle;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .cellStyle = totalStyleCenter;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9))
        .cellStyle = totalStyleRight;

    // Row 10: Blank
    summarySheet.appendRow([TextCellValue('')]);

    // Row 11: Section Header Stan Kantin
    summarySheet.appendRow([
      TextCellValue('II. PENDAPATAN PER STAN KANTIN'),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11))
        .cellStyle = sectionHeaderStyle;

    // Row 12: Table Header Stan
    summarySheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Nama Stan Kantin'),
      TextCellValue('Pendapatan Earned (IDR)'),
    ]);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12))
        .cellStyle = headerStyle;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12))
        .cellStyle = headerStyleLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 12))
        .cellStyle = headerStyleRight;

    double totalEarnedAll = 0;
    int curRow = 13;
    if (canteens.isEmpty) {
      summarySheet.appendRow([
        TextCellValue('-'),
        TextCellValue('Belum ada data stan'),
        TextCellValue('Rp 0'),
      ]);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow))
          .cellStyle = cellCenter;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: curRow))
          .cellStyle = cellLeft;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: curRow))
          .cellStyle = cellRight;
      curRow++;
    } else {
      for (int i = 0; i < canteens.length; i++) {
        final c = canteens[i];
        final name = c['canteen_name']?.toString() ?? 'Stan #${i + 1}';
        final earned = (c['balance_earned'] as num?)?.toDouble() ?? 0.0;
        totalEarnedAll += earned;

        summarySheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(name),
          TextCellValue(_currencyFmt.format(earned)),
        ]);
        summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow))
            .cellStyle = cellCenter;
        summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: curRow))
            .cellStyle = cellLeft;
        summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: curRow))
            .cellStyle = cellRight;
        curRow++;
      }

      // Total Row Stan Kantin
      summarySheet.appendRow([
        TextCellValue('TOTAL PENDAPATAN STAN'),
        TextCellValue('${canteens.length} Stan Kantin'),
        TextCellValue(_currencyFmt.format(totalEarnedAll)),
      ]);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow))
          .cellStyle = totalStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: curRow))
          .cellStyle = totalStyleCenter;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: curRow))
          .cellStyle = totalStyleRight;
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
    required double totalCorrection,
    required int topupCount,
    required int purchaseCount,
    required List<Map<String, dynamic>> canteens,
    required bool includeAudit,
    required bool includeStudents,
    List<Map<String, dynamic>> auditLogs = const [],
    List<Map<String, dynamic>> students = const [],
  }) async {
    final pdf = pw.Document();

    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      ttfRegular = pw.Font.ttf(regularData);
      ttfBold = pw.Font.ttf(boldData);
    } catch (_) {
      // Fallback ke standard font
    }

    const PdfColor primaryTeal = PdfColor.fromInt(0xFF0D9488);
    const PdfColor darkText = PdfColor.fromInt(0xFF0F172A);
    const PdfColor grayText = PdfColor.fromInt(0xFF475569);
    const PdfColor subtleText = PdfColor.fromInt(0xFF64748B);
    const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);
    const PdfColor totalRowBg = PdfColor.fromInt(0xFFE6F5F2);
    const PdfColor borderCol = PdfColor.fromInt(0xFFE2E8F0);

    final baseStyle = pw.TextStyle(font: ttfRegular, fontSize: 8.5, color: darkText);
    final boldStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkText);
    final titleStyle = pw.TextStyle(font: ttfBold, fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText);
    final tableHeaderStyle = pw.TextStyle(font: ttfBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    final netInflow = totalTopup + totalCorrection;
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
                  'Sistem Kantin Digital • Dokumen Laporan Keuangan Sah',
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
                    label: 'TOTAL TOP-UP TUNAI',
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
                    label: 'TOTAL PEMBAYARAN BELANJA',
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
                    label: 'TOTAL KOREKSI SALDO',
                    value: '${totalCorrection >= 0 ? "+" : ""}${_currencyFmt.format(totalCorrection)}',
                    subtext: 'Penyesuaian & audit system',
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
                    label: 'NET ALIRAN MASUK',
                    value: _currencyFmt.format(netInflow),
                    subtext: 'Total saldo masuk bersih',
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

}
