import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

/// Step 2 of the keuangan top-up flow — amount entry.
///
/// Displays student info card, amount input field, quick-select chips,
/// and a "Lanjut → Konfirmasi" button.
class KeuanganTopupStepAmount extends StatelessWidget {
  final NumberFormat fmt;
  final String studentName;
  final String studentNisn;
  final String studentClass;
  final int studentBalance;
  final TextEditingController amountController;
  final int? selectedQuickAmount;
  final ValueChanged<int> onQuickAmountSelected;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  const KeuanganTopupStepAmount({
    super.key,
    required this.fmt,
    required this.studentName,
    required this.studentNisn,
    required this.studentClass,
    required this.studentBalance,
    required this.amountController,
    required this.selectedQuickAmount,
    required this.onQuickAmountSelected,
    required this.onChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final int amount = int.tryParse(amountController.text.trim()) ?? 0;
    final int newBalance = studentBalance + amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Info Bento Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Siswa Ditemukan',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Nama', studentName),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('NISN', studentNisn),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Kelas', 'Kelas $studentClass'),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Saldo Saat Ini', fmt.format(studentBalance)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Nominal Top-Up (Uang Tunai Diterima)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            onChanged();
          },
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.nearBlack,
            ),
            hintText: '0',
            hintStyle: GoogleFonts.inter(
              color: AppColors.mutedGray,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(color: AppColors.darkTeal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick select chips
        Text(
          '${AppStrings.buttonSelect} Cepat:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.mutedGray,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [20000, 50000, 100000, 150000, 200000, 500000].map((val) {
            final isSelected = selectedQuickAmount == val;
            return ChoiceChip(
              label: Text(
                fmt.format(val).replaceAll('Rp ', ''),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.white : AppColors.darkTeal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onQuickAmountSelected(val);
              },
              selectedColor: AppColors.darkTeal,
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.darkTeal.withValues(alpha: 0.15)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Saldo Baru (Preview): ${fmt.format(newBalance)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.darkTeal,
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: amount <= 0 || amount % 1000 != 0
                ? null
                : onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'LANJUT → KONFIRMASI',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.mutedGray,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
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
