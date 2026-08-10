import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// Success screen after a card has been successfully linked.
class KeuanganCardRegistrationSuccess extends StatelessWidget {
  final String fullName;
  final String studentClass;
  final String savedUid;
  final String successTime;

  const KeuanganCardRegistrationSuccess({
    super.key,
    required this.fullName,
    required this.studentClass,
    required this.savedUid,
    required this.successTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Nebula.teal.withValues(alpha: 0.1),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: Nebula.teal,
                    size: 56,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Kartu Berhasil Diaktifkan!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Nebula.teal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kartu NFC berhasil ditautkan dan akun siswa aktif.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.dividerCol),
                ),
                child: Column(
                  children: [
                    _buildSuccessRow(context, 'Nama Siswa', fullName),
                    Divider(
                        height: 16,
                        thickness: 0.5,
                        color: context.dividerCol),
                    _buildSuccessRow(
                        context, 'Kelas', 'Kelas $studentClass'),
                    Divider(
                        height: 16,
                        thickness: 0.5,
                        color: context.dividerCol),
                    _buildSuccessRow(context, 'UID Kartu', savedUid),
                    Divider(
                        height: 16,
                        thickness: 0.5,
                        color: context.dividerCol),
                    _buildSuccessRow(context, 'Waktu Tautan', successTime),
                  ],
                ),
              ),

              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'KEMBALI KE PROFIL SISWA',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              color: context.textSecondary, fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
