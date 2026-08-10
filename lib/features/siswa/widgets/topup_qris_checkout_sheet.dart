import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class TopupQrisCheckoutSheet extends ConsumerWidget {
  final double amount;
  final bool isLoading;
  final Future<void> Function(double amount) onConfirmPayment;

  const TopupQrisCheckoutSheet({
    super.key,
    required this.amount,
    required this.isLoading,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // iOS grab handle
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Simulasi QRIS Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(amount),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Nebula.teal,
                ),
              ),
              const SizedBox(height: 20),

              // Simulated QR Code Graphic Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderLight, width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      color: context.surfaceBg,
                      child: Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 130,
                          color: context.textPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'KANTIN DIGITAL COOPERATIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pindai QRIS di atas menggunakan e-wallet atau Mobile Banking Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setSheetState(() {});
                          await onConfirmPayment(amount);
                        },
                  child: isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Simulasikan Pembayaran Berhasil',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(color: Nebula.rose, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}