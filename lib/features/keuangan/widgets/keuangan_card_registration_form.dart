import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

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
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.radiowaves_right,
                    color: Nebula.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SIAP MEMINDAI',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Nebula.teal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tempelkan kartu siswa ke sensor NFC perangkat ini atau gunakan tombol simulasi di bawah.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecondary,
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
                    color: Nebula.teal.withValues(alpha: 0.05),
                    border: Border.all(
                        color: Nebula.teal.withValues(alpha: 0.15),
                        width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.antenna_radiowaves_left_right,
                      color: Nebula.teal,
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
                    TextButton.styleFrom(foregroundColor: Nebula.teal),
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
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: uidController,
          decoration: InputDecoration(
            hintText: 'Contoh: 04:F8:A1:22',
            hintStyle:
                GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
            filled: true,
            fillColor: context.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerCol),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerCol),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide:
                  BorderSide(color: Nebula.teal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (oldRfid != null && oldRfid!.isNotEmpty)
          Row(
            children: [
              Icon(CupertinoIcons.info_circle, size: 14, color: context.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'UID Sebelumnya: $oldRfid',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        SizedBox(height: 32),

        // ─── Action Buttons ───
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLinkCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isLoading
                ? CupertinoActivityIndicator(color: context.cardBg)
                : Text(
                    'HUBUNGKAN KARTU',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.cardBg,
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
                side: const BorderSide(color: Nebula.rose),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Hapus Tautan Kartu',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Nebula.rose,
                ),
              ),
            ),
          ),
      ],
    );
  }
}