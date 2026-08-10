import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';

/// Settings section for parent dashboard â€” daily limit, card freeze, WA alerts.
class ParentSettingsSection extends StatefulWidget {
  final bool dailyLimitActive;
  final TextEditingController limitController;
  final bool cardFrozen;
  final bool waAlertsActive;
  final TextEditingController phoneController;
  final bool isSaving;
  final ValueChanged<bool> onDailyLimitChanged;
  final ValueChanged<bool> onCardFrozenChanged;
  final ValueChanged<bool> onWaAlertsChanged;
  final VoidCallback onSave;

  const ParentSettingsSection({
    super.key,
    required this.dailyLimitActive,
    required this.limitController,
    required this.cardFrozen,
    required this.waAlertsActive,
    required this.phoneController,
    required this.isSaving,
    required this.onDailyLimitChanged,
    required this.onCardFrozenChanged,
    required this.onWaAlertsChanged,
    required this.onSave,
  });

  @override
  State<ParentSettingsSection> createState() => _ParentSettingsSectionState();
}

class _ParentSettingsSectionState extends State<ParentSettingsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dark Mode Toggle Card
        Consumer(
          builder: (context, ref, child) {
            final isDark = ref.watch(themeProvider) == ThemeMode.dark;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.dividerCol, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Gelap',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aktifkan mode malam untuk tampilan yang nyaman bagi mata.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: isDark,
                    activeTrackColor: Nebula.teal,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Daily limit toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batasi Jajan Harian',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Batasi pengeluaran saku maksimal anak per hari.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: widget.dailyLimitActive,
                    activeTrackColor: Nebula.teal,
                    onChanged: widget.onDailyLimitChanged,
                  ),
                ],
              ),
              if (widget.dailyLimitActive) ...[
                const SizedBox(height: 16),
                Divider(color: context.dividerCol, height: 1),
                const SizedBox(height: 16),
                Text(
                  'Batas Maksimal Per Hari (Rupiah)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.dividerCol, width: 1),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.limitController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nominal limit...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Freeze Card toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bekukan Kartu RFID Anak',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nonaktifkan seketika jika kartu anak hilang/terjatuh.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: widget.cardFrozen,
                activeTrackColor: Nebula.rose,
                onChanged: widget.onCardFrozenChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // WA Alert toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifikasi WhatsApp Wali',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kirim WhatsApp peringatan setiap anak tap jajan di kantin.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: widget.waAlertsActive,
                    activeTrackColor: Nebula.teal,
                    onChanged: widget.onWaAlertsChanged,
                  ),
                ],
              ),
              if (widget.waAlertsActive) ...[
                const SizedBox(height: 16),
                Divider(color: context.dividerCol, height: 1),
                const SizedBox(height: 16),
                Text(
                  'Nomor WhatsApp Penerima Notifikasi',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.dividerCol, width: 1),
                  ),
                  child: TextField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Save Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Nebula.teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: widget.isSaving ? null : widget.onSave,
          child: widget.isSaving
              ? CupertinoActivityIndicator(color: context.cardBg)
              : Text(
                  'SIMPAN PENGATURAN SAKU',
                  style: GoogleFonts.inter(
                    color: context.cardBg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }
}