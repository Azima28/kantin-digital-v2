import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service untuk generate dan share struk transaksi dalam format PDF.
/// Menggunakan package `pdf` dan `printing`.
class PdfService {
  // Warna tema aplikasi
  static const PdfColor _primaryTeal = PdfColor.fromInt(0xFF006767);
  static const PdfColor _lightBg = PdfColor.fromInt(0xFFF2F2F7);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1A1C1F);
  static const PdfColor _textGray = PdfColor.fromInt(0xFF6F7978);
  static const PdfColor _successGreen = PdfColor.fromInt(0xFF006A35);
  static const PdfColor _white = PdfColors.white;

  static final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  /// Generate dan tampilkan preview PDF struk transaksi.
  ///
  /// [transactionId] — ID transaksi pendek (diambil 10 karakter pertama)
  /// [type] — 'purchase' atau 'topup'
  /// [amount] — total nominal transaksi
  /// [studentName] — nama siswa
  /// [canteenOrLocation] — nama kantin atau 'QRIS / Koperasi'
  /// [dateTime] — waktu transaksi
  /// [items] — list detail item (opsional, untuk tipe 'purchase')
  static Future<void> showReceiptPreview({
    required String transactionId,
    required String type,
    required double amount,
    required String studentName,
    required String canteenOrLocation,
    required DateTime dateTime,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final pdf = await _buildReceiptPdf(
      transactionId: transactionId,
      type: type,
      amount: amount,
      studentName: studentName,
      canteenOrLocation: canteenOrLocation,
      dateTime: dateTime,
      items: items,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Struk_${transactionId.substring(0, 8).toUpperCase()}.pdf',
    );
  }

  /// Share PDF struk langsung (tanpa preview).
  static Future<void> shareReceipt({
    required String transactionId,
    required String type,
    required double amount,
    required String studentName,
    required String canteenOrLocation,
    required DateTime dateTime,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final pdf = await _buildReceiptPdf(
      transactionId: transactionId,
      type: type,
      amount: amount,
      studentName: studentName,
      canteenOrLocation: canteenOrLocation,
      dateTime: dateTime,
      items: items,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Struk_${transactionId.substring(0, 8).toUpperCase()}.pdf',
    );
  }

  static Future<pw.Document> _buildReceiptPdf({
    required String transactionId,
    required String type,
    required double amount,
    required String studentName,
    required String canteenOrLocation,
    required DateTime dateTime,
    required List<Map<String, dynamic>> items,
  }) async {
    final pdf = pw.Document();

    // Load font dari asset (fallback ke Helvetica jika tidak ada)
    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      ttfRegular = pw.Font.ttf(regularData);
      ttfBold = pw.Font.ttf(boldData);
    } catch (_) {
      // Gunakan font bawaan jika custom font tidak tersedia
    }

    final pw.TextStyle baseStyle =
        pw.TextStyle(font: ttfRegular, fontSize: 10, color: _textDark);
    final pw.TextStyle boldStyle = pw.TextStyle(
        font: ttfBold,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _textDark);

    final bool isPurchase = type == 'purchase';
    final String dateStr =
        DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime.toLocal());
    final String timeStr = DateFormat('HH:mm').format(dateTime.toLocal());
    final String shortId = transactionId.length >= 10
        ? transactionId.substring(0, 10).toUpperCase()
        : transactionId.toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _primaryTeal,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'KANTIN DIGITAL',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 18,
                        color: _white,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      isPurchase ? 'STRUK PEMBELIAN' : 'STRUK TOP-UP SALDO',
                      style: pw.TextStyle(
                          font: ttfRegular, fontSize: 10, color: _white),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ─── Status Badge ───
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: isPurchase
                        ? _successGreen
                        : const PdfColor.fromInt(0xFF0066CC),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    isPurchase ? '✓  Pembayaran Berhasil' : '✓  Top-Up Berhasil',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 11,
                      color: _white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // ─── Jumlah Transaksi ───
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Jumlah',
                      style: pw.TextStyle(
                          font: ttfRegular, fontSize: 11, color: _textGray),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _currencyFmt.format(amount),
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: _lightBg, thickness: 1.5),
              pw.SizedBox(height: 12),

              // ─── Detail Info ───
              _buildInfoRow('Nama Siswa', studentName, baseStyle, boldStyle),
              pw.SizedBox(height: 8),
              _buildInfoRow(
                  isPurchase ? 'Kantin' : 'Metode',
                  canteenOrLocation,
                  baseStyle,
                  boldStyle),
              pw.SizedBox(height: 8),
              _buildInfoRow('Tanggal', dateStr, baseStyle, boldStyle),
              pw.SizedBox(height: 8),
              _buildInfoRow('Waktu', '$timeStr WIB', baseStyle, boldStyle),
              pw.SizedBox(height: 8),
              _buildInfoRow('ID Transaksi', shortId, baseStyle, boldStyle),

              // ─── Items (hanya untuk purchase) ───
              if (isPurchase && items.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Divider(color: _lightBg, thickness: 1),
                pw.SizedBox(height: 8),
                pw.Text('Rincian Pembelian', style: boldStyle),
                pw.SizedBox(height: 8),
                ...items.map((item) {
                  final String name =
                      item['product_name']?.toString() ?? item['name']?.toString() ?? '-';
                  final int qty = item['quantity'] as int? ?? 1;
                  final double price = double.tryParse(
                          item['unit_price']?.toString() ?? '0') ??
                      0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('$qty× $name', style: baseStyle),
                        ),
                        pw.Text(
                          _currencyFmt.format(price * qty),
                          style: baseStyle,
                        ),
                      ],
                    ),
                  );
                }),
                pw.Divider(color: _lightBg, thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total', style: boldStyle),
                    pw.Text(_currencyFmt.format(amount),
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryTeal,
                        )),
                  ],
                ),
              ],

              pw.SizedBox(height: 20),
              pw.Divider(color: _lightBg, thickness: 1),
              pw.SizedBox(height: 12),

              // ─── Footer ───
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Terima kasih telah menggunakan Kantin Digital!',
                      style: pw.TextStyle(
                          font: ttfRegular, fontSize: 9, color: _textGray),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Simpan struk ini sebagai bukti transaksi.',
                      style: pw.TextStyle(
                          font: ttfRegular, fontSize: 9, color: _textGray),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: baseStyle.copyWith(color: _textGray, fontSize: 10)),
        pw.Text(value, style: boldStyle.copyWith(fontSize: 10)),
      ],
    );
  }
}
