import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Halaman landing publik yang bisa diakses tanpa login.
/// Menampilkan info singkat sistem kantin, CTA ke menu, dan tombol login.
class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Hero Section ───
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkTeal, AppColors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🍽️  Kantin Digital',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Kantin Modern\nBerbasis Kartu Digital',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Jajan lebih mudah, aman, dan tanpa uang tunai. '
                      'Cukup tap kartu RFID di kasir kantin.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CTA Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/public/menu'),
                            icon: const Icon(CupertinoIcons.list_bullet,
                                size: 16),
                            label: Text(
                              'Lihat Menu',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.darkTeal,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/login?from=/public'),
                            icon: const Icon(CupertinoIcons.person,
                                size: 16, color: AppColors.white),
                            label: Text(
                              'Masuk',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.white, width: 1.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Feature Cards ───
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitur Unggulan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: CupertinoIcons.creditcard,
                      color: AppColors.teal,
                      title: 'Tap & Bayar',
                      desc:
                          'Cukup tempelkan kartu RFID di kasir. Transaksi selesai dalam 1 detik.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: CupertinoIcons.lock_shield,
                      color: AppColors.darkOrange,
                      title: 'Aman & Terkontrol',
                      desc:
                          'Orang tua dapat memantau dan mengatur batas belanja harian anak.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: CupertinoIcons.chart_bar,
                      color: AppColors.successGreen,
                      title: 'Laporan Real-time',
                      desc:
                          'Riwayat transaksi tersedia kapanpun. Tidak ada lagi uang hilang.',
                    ),
                    const SizedBox(height: 24),

                    // Quick links
                    Text(
                      'Akses Cepat',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLinkTile(
                      context,
                      icon: CupertinoIcons.list_bullet,
                      label: 'Menu Kantin',
                      subtitle: 'Lihat semua menu yang tersedia',
                      onTap: () => context.go('/public/menu'),
                    ),
                    _buildLinkTile(
                      context,
                      icon: CupertinoIcons.info_circle,
                      label: 'Info Sekolah',
                      subtitle: 'Jam operasional & kontak kantin',
                      onTap: () => context.go('/public/info'),
                    ),
                    _buildLinkTile(
                      context,
                      icon: CupertinoIcons.person_badge_plus,
                      label: 'Login Pengguna',
                      subtitle: 'Siswa, orang tua, atau petugas',
                      onTap: () => context.go('/login?from=/public'),
                      isHighlighted: true,
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
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.teal.withValues(alpha: 0.07)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isHighlighted
                    ? AppColors.teal
                    : AppColors.mutedGray),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isHighlighted
                          ? AppColors.teal
                          : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.mutedGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: isHighlighted
                  ? AppColors.teal
                  : AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }
}
