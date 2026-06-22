import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Profile Summary Bento Card ───
        _buildProfileSummary(),
        const SizedBox(height: 16),
        // ─── Saldo & Card Info Card ───
        _buildBalanceCard(),
      ],
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          CircleAvatar(
            radius: 32,
            backgroundColor:
                AppColors.darkTeal.withValues(alpha: 0.08),
            child: Text(
              fullName.isNotEmpty
                  ? fullName[0].toUpperCase()
                  : 'S',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkTeal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.nearBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: !isAccountActive
                  ? AppColors.errorRed2.withValues(alpha: 0.08)
                  : (!hasCard
                      ? AppColors.borderGray
                      : (!isCardActive
                          ? AppColors.warningYellowLight
                          : AppColors.successGreen
                              .withValues(alpha: 0.08))),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              !isAccountActive
                  ? 'AKUN DIBLOKIR'
                  : (!hasCard
                      ? 'BELUM AKTIF'
                      : (!isCardActive ? 'KARTU DIBLOKIR' : 'AKTIF')),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: !isAccountActive
                    ? AppColors.errorRed2
                    : (!hasCard
                        ? AppColors.mutedGray
                        : (!isCardActive
                            ? AppColors.warningYellow
                            : AppColors.successGreen)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.borderGray,
          ),
          const SizedBox(height: 16),
          _buildProfileRow(CupertinoIcons.mail, 'Email', email),
          const SizedBox(height: 10),
          _buildProfileRow(
            CupertinoIcons.book,
            AppStrings.labelStudentClass,
            'Kelas $sClass',
          ),
          const SizedBox(height: 10),
          _buildProfileRow(
            CupertinoIcons.creditcard,
            'NISN',
            nisn,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Saldo & Kartu',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Aktif',
                style: GoogleFonts.inter(
                  color: AppColors.mutedGray,
                ),
              ),
              Text(
                fmt.format(balance),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: balance < 5000
                      ? AppColors.errorRed2
                      : AppColors.nearBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Kartu',
                style: GoogleFonts.inter(
                  color: AppColors.mutedGray,
                ),
              ),
              Text(
                hasCard ? 'AKTIF' : 'BELUM AKTIF',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: hasCard
                      ? AppColors.successGreen
                      : AppColors.mutedGray,
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
                  color: AppColors.mutedGray,
                ),
              ),
              Text(
                rfid ?? '-',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
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
                  color: AppColors.mutedGray,
                ),
              ),
              Text(
                lastTapStr,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedGray),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.mutedGray,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
          ),
        ),
      ],
    );
  }
}
