import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// Menampilkan Modal / Bottom Sheet "Tentang SeKantin" (About SeKantin)
/// Responsif untuk layar smartphone (bottom sheet) maupun tablet/desktop (dialog).
Future<void> showAboutSeKantinSheet(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 640;

  if (isDesktop) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: const _AboutSeKantinContent(isDialog: true),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.88,
      child: _AboutSeKantinContent(isDialog: false),
    ),
  );
}

class _AboutSeKantinContent extends StatelessWidget {
  final bool isDialog;

  const _AboutSeKantinContent({required this.isDialog});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header Bar / Drag Handle ──
          if (!isDialog)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: context.textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.info_circle_fill,
                        color: Nebula.teal,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tentang Aplikasi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 20),
                  color: context.textSecondary,
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.6, color: context.dividerCol),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Logo & App Identity
                  Image.asset(
                    isDark
                        ? 'assets/images/app_symbol_dark.png'
                        : 'assets/images/app_symbol_light.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Nebula.teal,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appName,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.appTagline,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Nebula.teal,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Nebula.teal.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'v2.0.0 (Production Release)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Nebula.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Tiga Pilar Filosofi (Smart, Efficiency, Security)
                  _buildSectionHeader(context, 'FILOSOFI & NILAI UTAMA'),
                  const SizedBox(height: 10),
                  _buildPillarCard(
                    context,
                    icon: CupertinoIcons.sparkles,
                    color: Nebula.teal,
                    title: 'Smart Ecosystem',
                    description:
                        'Integrasi transaksi nirsentuh kartu RFID/NFC, pemantauan saldo live, dan sinkronisasi status pesanan realtime via WebSocket.',
                  ),
                  const SizedBox(height: 10),
                  _buildPillarCard(
                    context,
                    icon: CupertinoIcons.bolt_horizontal_circle_fill,
                    color: Nebula.amber,
                    title: 'Maximum Efficiency',
                    description:
                        'Menghilangkan antrean jam istirahat sekolah, bebas repot uang kembalian fisik, serta rekapitulasi kas harian otomatis tanpa hitung manual.',
                  ),
                  const SizedBox(height: 10),
                  _buildPillarCard(
                    context,
                    icon: CupertinoIcons.shield_lefthalf_fill,
                    color: const Color(0xFF10B981),
                    title: 'Fintech-Grade Security',
                    description:
                        'Proteksi transaksi ACID row-level locking anti double-spend, PIN dompet terenkripsi, dan kontrol limit pengeluaran oleh orang tua.',
                  ),
                  const SizedBox(height: 22),

                  // 3. Informasi Sistem & Infrastruktur
                  _buildSectionHeader(context, 'INFORMASI SISTEM & KONEKTIVITAS'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.dividerCol, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          label: 'Gateway Server',
                          value: 'sekantin.zitech.web.id',
                          icon: CupertinoIcons.globe,
                          showDivider: true,
                        ),
                        _buildInfoRow(
                          context,
                          label: 'Enkripsi Jaringan',
                          value: 'TLS 1.3 / HTTPS / Secure WSS',
                          icon: CupertinoIcons.lock_shield_fill,
                          showDivider: true,
                        ),
                        _buildInfoRow(
                          context,
                          label: 'Standar Kartu',
                          value: 'RFID Mifare Classic 1K / NFC 13.56 MHz',
                          icon: CupertinoIcons.creditcard_fill,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 4. Pusat Bantuan & Pengaduan
                  _buildSectionHeader(context, 'BANTUAN & PENGADUAN'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.dividerCol, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kendala Kartu / Saldo?',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hubungi petugas loket keuangan sekolah atau kasir kantin untuk pelaporan kartu hilang, permintaan pembekuan akun, atau top-up saldo tunai.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Copyright & Footer
                  Text(
                    '© 2026 SeKantin • All rights reserved',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Smart Efficiency Kantin untuk Pendidikan Digital Indonesia',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildPillarCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerCol, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: context.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Nebula.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.6, color: context.dividerCol),
      ],
    );
  }
}
