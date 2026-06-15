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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFBDC9C8).withValues(alpha: 0.3), width: 0.5),
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Tanda Terima Digital',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Success Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PEMBAYARAN ONLINE BERHASIL',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Struk Receipt Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'TANDA TERIMA DIGITAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textGray,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildReceiptRow('No. Order Midtrans', orderId),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildReceiptRow('Tanggal Bayar', '$dateStr WIB'),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildReceiptRow('Nama Pengirim', senderName),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildReceiptRow('Siswa Penerima', studentName),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildReceiptRow('Nominal Top-up', CurrencyFormatter.format(amount)),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildReceiptRow('Status Transaksi', 'SUKSES / LUNAS', isStatus: true),
                      const Divider(height: 32, thickness: 1, color: AppColors.primaryLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saldo Baru $studentName',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textGray),
                          ),
                          Text(
                            CurrencyFormatter.format(newBalance),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Bukti pembayaran PDF berhasil diunduh'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.arrow_down_to_line, color: AppColors.primary, size: 16),
                    label: const Text(
                      'DOWNLOAD BUKTI PEMBAYARAN (PDF)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to home button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.go('/parent');
                    },
                    child: const Text(
                      'KEMBALI KE HALAMAN UTAMA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isStatus
                  ? AppColors.success
                  : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
