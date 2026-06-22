import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Top-up form widget — step 2 of the top-up flow.
///
/// Shows the selected student info, lets the user enter an amount
/// manually or pick from quick-select chips, then calls [onSubmit]
/// when they tap "LANJUT → KONFIRMASI".
class TopupForm extends StatefulWidget {
  final StudentWithProfile selectedStudent;
  final NumberFormat fmt;
  final void Function(int amount) onSubmit;

  const TopupForm({
    super.key,
    required this.selectedStudent,
    required this.fmt,
    required this.onSubmit,
  });

  @override
  State<TopupForm> createState() => _TopupFormState();
}

class _TopupFormState extends State<TopupForm> {
  final TextEditingController _amountController = TextEditingController();
  int? _selectedQuickAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _studentName => widget.selectedStudent.fullName;
  String get _studentNisn => widget.selectedStudent.nisn ?? '-';
  String get _studentClass => widget.selectedStudent.class_ ?? '-';
  int get _studentBalance => widget.selectedStudent.balance;

  int _getAmount() {
    return int.tryParse(_amountController.text.trim()) ?? 0;
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
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
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.nearBlack,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.fmt;
    final int amount = _getAmount();
    final int newBalance = _studentBalance + amount;

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
              _buildInfoRow('Nama', _studentName),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('NISN', _studentNisn),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow(AppStrings.labelStudentClass, 'Kelas $_studentClass'),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Saldo Saat Ini', fmt.format(_studentBalance)),
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
          controller: _amountController,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() {
              _selectedQuickAmount = null;
            });
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
              borderSide:
                  const BorderSide(color: AppColors.darkTeal, width: 1.5),
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
            final isSelected = _selectedQuickAmount == val;
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
                if (selected) _onQuickAmountSelected(val);
              },
              selectedColor: AppColors.darkTeal,
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: AppColors.darkTeal.withValues(alpha: 0.15)),
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
                : () {
                    widget.onSubmit(_getAmount());
                  },
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
}
