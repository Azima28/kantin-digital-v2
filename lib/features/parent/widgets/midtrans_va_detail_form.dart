import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// Virtual Account payment detail display showing VA number.
class MidtransVaDetailForm extends StatelessWidget {
  const MidtransVaDetailForm({
    super.key,
    required this.senderPhone,
  });

  final String senderPhone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerCol),
          ),
          child: Column(
            children: [
              Text(
                'Nomor Virtual Account',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '8910${senderPhone.padRight(10, '0').substring(0, 10)}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Nebula.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(CupertinoIcons.doc_on_doc,
                      color: Nebula.teal, size: 16),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Lakukan transfer total tagihan ke nomor Virtual Account di atas melalui M-Banking atau ATM.',
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
