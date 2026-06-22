import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Registration form for NFC card linking.
///
/// Displays the NFC scan card, UID manual input field, old UID info,
/// and action buttons (link card / unlink card).
class KeuanganCardRegistrationForm extends StatelessWidget {
  final TextEditingController uidController;
  final String? oldRfid;
  final bool isLoading;
  final VoidCallback onSimulateNfcScan;
  final VoidCallback onLinkCard;
  final VoidCallback onUnlinkCard;

  const KeuanganCardRegistrationForm({
    super.key,
    required this.uidController,
    this.oldRfid,
    required this.isLoading,
    required this.onSimulateNfcScan,
    required this.onLinkCard,
    required this.onUnlinkCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Scan NFC Bento Card ───
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '📶 SIAP MEMINDAI',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.darkTeal,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tempelkan kartu siswa ke sensor NFC perangkat ini atau gunakan tombol simulasi di bawah.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.mutedGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Animated ripple design
              GestureDetector(
                onTap: onSimulateNfcScan,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkTeal.withValues(alpha: 0.05),
                    border: Border.all(
                        color: AppColors.darkTeal.withValues(alpha: 0.15),
                        width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.antenna_radiowaves_left_right,
                      color: AppColors.darkTeal,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onSimulateNfcScan,
                icon: const Icon(CupertinoIcons.play_circle_fill, size: 18),
                label: Text(
                  'Simulasikan Tap Kartu',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.darkTeal),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ─── Input UID Manual ───
        Text(
          'UID Kartu (Manual Fallback)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.nearBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: uidController,
          decoration: InputDecoration(
            hintText: 'Contoh: 04:F8:A1:22',
            hintStyle:
                GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 14),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.darkTeal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (oldRfid != null && oldRfid!.isNotEmpty)
          Text(
            'ℹ UID Lama: $oldRfid (aktif)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.mutedGray,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 32),

        // ─── Action Buttons ───
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLinkCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isLoading
                ? const CupertinoActivityIndicator(color: AppColors.white)
                : Text(
                    'HUBUNGKAN KARTU',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (oldRfid != null && oldRfid!.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : onUnlinkCard,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorRed2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Hapus Tautan Kartu',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.errorRed2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
