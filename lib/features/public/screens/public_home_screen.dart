/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/hallmark_card.dart';

/// Hallmark Public Landing Page Screen
class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.borderTactile,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.brandPrimary.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '🍽️  Kantin Digital v2.0',
                        style: HallmarkTypography.bodySmall(colors.brandPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kantin Modern\nBerbasis Kartu Digital',
                      style: HallmarkTypography.displayL1(colors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Jajan lebih mudah, aman, dan tanpa uang tunai. '
                      'Cukup tap kartu RFID/NFC Anda di kasir kantin.',
                      style: HallmarkTypography.bodyLarge(colors.textMuted),
                    ),
                    const SizedBox(height: 24),

                    // CTA Buttons
                    Row(
                      children: [
                        Expanded(
                          child: HallmarkButton(
                            label: 'Lihat Menu',
                            icon: CupertinoIcons.list_bullet,
                            onPressed: () => context.go('/public/menu'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HallmarkButton(
                            label: 'Masuk Aplikasi',
                            icon: CupertinoIcons.person,
                            onPressed: () => context.go('/login?from=/public'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Feature Cards Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitur Unggulan',
                      style: HallmarkTypography.headingL2(colors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      colors: colors,
                      icon: CupertinoIcons.creditcard,
                      color: colors.brandPrimary,
                      title: 'Tap & Bayar',
                      desc: 'Cukup tempelkan kartu RFID di kasir. Transaksi selesai dalam 1 detik.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      colors: colors,
                      icon: CupertinoIcons.lock_shield,
                      color: colors.statusWarning,
                      title: 'Aman & Terkontrol',
                      desc: 'Orang tua dapat memantau dan mengatur batas belanja harian anak.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      colors: colors,
                      icon: CupertinoIcons.chart_bar,
                      color: colors.brandAccent,
                      title: 'Laporan Real-time',
                      desc: 'Riwayat transaksi tersedia kapanpun dengan transparansi penuh.',
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Akses Cepat',
                      style: HallmarkTypography.headingL2(colors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildLinkTile(
                      colors: colors,
                      icon: CupertinoIcons.list_bullet,
                      label: 'Menu Kantin',
                      subtitle: 'Lihat semua menu yang tersedia',
                      onTap: () => context.go('/public/menu'),
                    ),
                    const SizedBox(height: 8),
                    _buildLinkTile(
                      colors: colors,
                      icon: CupertinoIcons.info_circle,
                      label: 'Info Sekolah',
                      subtitle: 'Jam operasional & kontak kantin',
                      onTap: () => context.go('/public/info'),
                    ),
                    const SizedBox(height: 8),
                    _buildLinkTile(
                      colors: colors,
                      icon: CupertinoIcons.person_badge_plus,
                      label: 'Login Pengguna',
                      subtitle: 'Siswa, orang tua, atau petugas kantin',
                      onTap: () => context.go('/login?from=/public'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required HallmarkColorScheme colors,
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return HallmarkCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HallmarkTypography.titleSmall(colors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: HallmarkTypography.bodySmall(colors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required HallmarkColorScheme colors,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return HallmarkCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: colors.brandPrimary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: HallmarkTypography.titleSmall(colors.textPrimary)),
                Text(subtitle, style: HallmarkTypography.bodySmall(colors.textMuted)),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, color: colors.textMuted, size: 16),
        ],
      ),
    );
  }
}
