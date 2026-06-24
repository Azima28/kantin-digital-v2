import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

/// Halaman publik informasi sekolah dan kantin.
class PublicSchoolInfoScreen extends StatelessWidget {
  const PublicSchoolInfoScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.darkTeal),
          onPressed: () => context.go('/public'),
        ),
        title: Text(
          'Info Sekolah & Kantin',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTeal,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Sekolah Info Card ───
            _buildSection(
              icon: CupertinoIcons.building_2_fill,
              iconColor: AppColors.darkTeal,
              title: 'Profil Sekolah',
              children: [
                _buildInfoRow(
                    CupertinoIcons.location_solid, 'Alamat Sekolah',
                    'Jl. Pendidikan No. 1, Kab. Bondowoso'),
                _buildInfoRow(
                    CupertinoIcons.phone_fill, 'Telepon Sekolah',
                    '(0332) 123456'),
                _buildInfoRow(
                    CupertinoIcons.envelope_fill, 'Email Sekolah',
                    'info@sekolah.sch.id'),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Jam Operasional ───
            _buildSection(
              icon: CupertinoIcons.clock_fill,
              iconColor: AppColors.darkOrange,
              title: 'Jam Operasional Kantin',
              children: [
                _buildScheduleRow('Senin – Kamis', '06:30 – 14:00'),
                _buildScheduleRow('Jumat', '06:30 – 11:30'),
                _buildScheduleRow('Sabtu', '06:30 – 12:00'),
                _buildScheduleRow('Minggu & Libur', 'Tutup'),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Cara Penggunaan ───
            _buildSection(
              icon: CupertinoIcons.info_circle_fill,
              iconColor: AppColors.successGreen,
              title: 'Cara Menggunakan Kantin Digital',
              children: [
                _buildStepRow('1', 'Pastikan kartu RFID kamu aktif dan memiliki saldo cukup.'),
                _buildStepRow('2', '${AppStrings.buttonSelect} menu yang ingin dibeli di kasir kantin.'),
                _buildStepRow('3', 'Tempelkan kartu RFID ke mesin kasir.'),
                _buildStepRow('4', '${AppStrings.labelTransaction} selesai! Saldo otomatis berkurang.'),
                _buildStepRow('5', 'Cek notifikasi di aplikasi untuk konfirmasi transaksi.'),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Top-Up Saldo ───
            _buildSection(
              icon: CupertinoIcons.arrow_up_circle_fill,
              iconColor: AppColors.primary,
              title: 'Cara Top-Up Saldo',
              children: [
                _buildInfoRow(CupertinoIcons.person_fill, 'Via Petugas Keuangan',
                    'Serahkan uang tunai ke petugas keuangan sekolah.'),
                _buildInfoRow(CupertinoIcons.phone_fill, 'Via Orang Tua',
                    'Login sebagai orang tua di aplikasi → pilih "Top-Up Saldo Anak".'),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Kontak Bantuan ───
            _buildSection(
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: AppColors.primary, // purple-ish
              title: 'Butuh Bantuan?',
              children: [
                _buildContactButton(
                  icon: CupertinoIcons.phone_fill,
                  label: 'Hubungi Petugas Kantin',
                  subtitle: '(0332) 123456',
                  onTap: () => _launchUrl('tel:0332123456'),
                ),
                _buildContactButton(
                  icon: CupertinoIcons.chat_bubble_text_fill,
                  label: 'WhatsApp Koperasi',
                  subtitle: '0812-3456-7890',
                  onTap: () => _launchUrl('https://wa.me/6281234567890'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Login CTA ───
            ElevatedButton.icon(
              onPressed: () => context.go('/login?from=/public/info'),
              icon: const Icon(CupertinoIcons.person, size: 16),
              label: Text(
                'Login ke Aplikasi',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkTeal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedGray),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.mutedGray,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String day, String time) {
    final bool isClosed = time == 'Tutup';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isClosed
                  ? AppColors.errorRed2
                  : AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.successGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary), // purple-ish
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
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
            const Icon(CupertinoIcons.chevron_right,
                size: 14, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }
}
