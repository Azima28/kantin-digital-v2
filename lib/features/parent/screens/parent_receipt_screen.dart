import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

class ParentReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  
  const ParentReceiptScreen({super.key, required this.receiptData});

  @override
  Widget build(BuildContext context) {
    final String orderId = receiptData['orderId'] ?? '-';
    final String dateStr = receiptData['date'] != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(receiptData['date']).toLocal())
        : '-';
    final String senderName = receiptData['senderName'] ?? '-';
    final String studentName = receiptData['studentName'] ?? '-';
    final double amount = receiptData['amount'] ?? 0.0;
    final double newBalance = receiptData['newBalance'] ?? 0.0;

    const Color primaryTeal = Color(0xFF006767);
    const Color successGreen = Color(0xFF006A35);
    const Color bgWarm = Color(0xFFFBF9F8);
    const Color borderOutline = Color(0xFFE4E2E1);

    Widget buildReceiptRow(String label, String value, {bool isPrimary = false, bool isStatus = false}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: AppColors.textGray,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatus
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7EFBA4).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: successGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                        color: isPrimary ? primaryTeal : AppColors.textDark,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 480;

    return Scaffold(
      backgroundColor: bgWarm,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pop-in animated success icon badge
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7EFBA4), // Light green container circle background
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.checkmark_alt_circle_fill,
                        color: successGreen,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Success Title
                Text(
                  'PEMBAYARAN ONLINE BERHASIL',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Ticket Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderOutline, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Card Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 16 : 24, isMobile ? 16 : 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detail Transaksi',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Icon(CupertinoIcons.doc_text, color: primaryTeal, size: 20),
                          ],
                        ),
                      ),
                      const Divider(color: borderOutline, height: 1),
                      
                      // Details Body
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                        child: Column(
                          children: [
                            buildReceiptRow('Order ID', orderId),
                            const SizedBox(height: 16),
                            buildReceiptRow('Tanggal', '$dateStr WIB'),
                            const SizedBox(height: 16),
                            buildReceiptRow('Pengirim', senderName),
                            const SizedBox(height: 16),
                            buildReceiptRow('Penerima', studentName),
                            const SizedBox(height: 16),
                            buildReceiptRow('Nominal', CurrencyFormatter.format(amount), isPrimary: true),
                            const SizedBox(height: 16),
                            buildReceiptRow('Status', 'SUKSES / LUNAS', isStatus: true),
                            
                            const SizedBox(height: 24),
                            // Child Balance box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F3F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Saldo Baru $studentName',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(newBalance),
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF904D00), // Orange Accent
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // PDF Download action
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryTeal, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bukti pembayaran PDF berhasil diunduh ke perangkat Anda.',
                            style: GoogleFonts.beVietnamPro(),
                          ),
                          backgroundColor: successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.arrow_down_to_line, color: primaryTeal, size: 16),
                    label: Text(
                      'DOWNLOAD BUKTI PEMBAYARAN (PDF)',
                      style: GoogleFonts.beVietnamPro(
                        color: primaryTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main back action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.go('/parent');
                    },
                    child: Text(
                      'KEMBALI KE HALAMAN UTAMA',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
