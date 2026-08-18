import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class StudentDetailHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String nisn;
  final bool isAccountActive;
  final bool isCardActive;
  final bool hasCard;
  final String sClass;
  final int balance;
  final String? rfid;
  final String lastTapStr;
  final NumberFormat fmt;
  final VoidCallback? onToggleCardFreeze;
  final VoidCallback? onRegisterCard;

  const StudentDetailHeader({
    super.key,
    required this.fullName,
    required this.email,
    required this.nisn,
    required this.isAccountActive,
    required this.isCardActive,
    required this.hasCard,
    required this.sClass,
    required this.balance,
    required this.rfid,
    required this.lastTapStr,
    required this.fmt,
    this.onToggleCardFreeze,
    this.onRegisterCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Profile Summary Bento Card ───
        _buildProfileSummary(context),
        const SizedBox(height: 16),
        // ─── Saldo & Card Info Card ───
        _buildBalanceCard(context),
      ],
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          CircleAvatar(
            radius: 32,
            backgroundColor:
                Nebula.teal.withValues(alpha: 0.08),
            child: Text(
              fullName.isNotEmpty
                  ? fullName[0].toUpperCase()
                  : 'S',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Nebula.teal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              // Badge Status Akun Login Siswa
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAccountActive
                      ? Nebula.teal.withValues(alpha: 0.08)
                      : Nebula.rose.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAccountActive
                          ? CupertinoIcons.person_crop_circle_badge_checkmark
                          : CupertinoIcons.person_crop_circle_badge_xmark,
                      size: 11,
                      color: isAccountActive ? Nebula.teal : Nebula.rose,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAccountActive ? 'AKUN AKTIF' : 'AKUN DIBLOKIR',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAccountActive ? Nebula.teal : Nebula.rose,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge Status Kartu Fisik RFID
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: !hasCard
                      ? context.dividerCol
                      : (!isCardActive
                          ? Nebula.amberLight
                          : Nebula.teal.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      !hasCard
                          ? CupertinoIcons.creditcard
                          : (!isCardActive
                              ? CupertinoIcons.lock_fill
                              : CupertinoIcons.checkmark_seal_fill),
                      size: 11,
                      color: !hasCard
                          ? context.textSecondary
                          : (!isCardActive ? Nebula.amber : Nebula.teal),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      !hasCard
                          ? 'KARTU BELUM TERDAFTAR'
                          : (!isCardActive ? 'KARTU DIBLOKIR' : 'KARTU AKTIF'),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: !hasCard
                            ? context.textSecondary
                            : (!isCardActive ? Nebula.amber : Nebula.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 0.5,
            color: context.dividerCol,
          ),
          const SizedBox(height: 16),
          _buildProfileRow(context, CupertinoIcons.mail, 'Email', email),
          const SizedBox(height: 10),
          _buildProfileRow(
            context,
            CupertinoIcons.book,
            AppStrings.labelStudentClass,
            'Kelas $sClass',
          ),
          const SizedBox(height: 10),
          _buildProfileRow(
            context,
            CupertinoIcons.creditcard,
            'NISN',
            nisn,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Saldo & Kartu',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Aktif',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                ),
              ),
              Text(
                fmt.format(balance),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: balance < 5000
                      ? Nebula.rose
                      : context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Akun Login',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                ),
              ),
              Text(
                isAccountActive ? 'AKTIF' : 'DIBLOKIR',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isAccountActive ? Nebula.teal : Nebula.rose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Kartu Fisik',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                ),
              ),
              Text(
                !hasCard
                    ? 'BELUM TERDAFTAR'
                    : (isCardActive ? 'AKTIF' : 'DIBLOKIR'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: !hasCard
                      ? context.textSecondary
                      : (isCardActive ? Nebula.teal : Nebula.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UID Kartu',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                ),
              ),
              Text(
                rfid ?? '-',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terakhir Tap',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                ),
              ),
              Text(
                lastTapStr,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 0.5, color: context.dividerCol),
          const SizedBox(height: 14),
          if (hasCard)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onToggleCardFreeze,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isCardActive ? Nebula.rose : Nebula.teal,
                  side: BorderSide(
                    color: (isCardActive ? Nebula.rose : Nebula.teal).withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(
                  isCardActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  size: 18,
                ),
                label: Text(
                  isCardActive ? 'BEKUKAN KARTU RFID' : 'BUKA BLOKIR KARTU RFID',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRegisterCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Nebula.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(CupertinoIcons.wifi, size: 18, color: Colors.white),
                label: Text(
                  'DAFTARKAN KARTU RFID SEKARANG',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

