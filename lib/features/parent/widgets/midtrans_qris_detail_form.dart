import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// QRIS payment instruction display with placeholder QR code.
class MidtransQrisDetailForm extends StatelessWidget {
  const MidtransQrisDetailForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.dividerCol),
              borderRadius: BorderRadius.circular(16),
              color: context.cardBg,
            ),
            child: Icon(
              CupertinoIcons.qrcode,
              size: 160,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Silakan scan QR code di atas menggunakan Gopay, ShopeePay, OVO, Dana atau aplikasi pembayaran QRIS lainnya.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}