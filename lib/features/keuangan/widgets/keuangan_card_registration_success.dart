import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

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
      backgroundColor: AppColors.offWhite,
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successLight,
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: AppColors.successGreen,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kartu Berhasil Diaktifkan!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTeal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kartu NFC berhasil ditautkan dan akun siswa aktif.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.mutedGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Column(
                  children: [
                    _buildSuccessRow('Nama Siswa', fullName),
                    const Divider(
                        height: 16,
                        thickness: 0.5,
                        color: AppColors.borderGray),
                    _buildSuccessRow(
                        'Kelas', 'Kelas $studentClass'),
                    const Divider(
                        height: 16,
                        thickness: 0.5,
                        color: AppColors.borderGray),
                    _buildSuccessRow('UID Kartu', savedUid),
                    const Divider(
                        height: 16,
                        thickness: 0.5,
                        color: AppColors.borderGray),
                    _buildSuccessRow('Waktu Tautan', successTime),
                  ],
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
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
                      color: AppColors.white,
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

  Widget _buildSuccessRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              color: AppColors.mutedGray, fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.nearBlack,
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
