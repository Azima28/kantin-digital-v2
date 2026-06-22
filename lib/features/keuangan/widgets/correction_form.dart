import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Correction details form — step 2 of the correction flow.
///
/// Lets the user choose correction type (add/reduce), enter an amount,
/// and provide a mandatory reason. Calls [onSubmit] with the collected
/// data when the form is valid and the user taps "LANJUT → KONFIRMASI".
class CorrectionForm extends StatefulWidget {
  final StudentWithProfile selectedStudent;
  final NumberFormat fmt;
  final void Function(int amount, bool isAddition, String reason)
      onSubmit;

  const CorrectionForm({
    super.key,
    required this.selectedStudent,
    required this.fmt,
    required this.onSubmit,
  });

  @override
  State<CorrectionForm> createState() => _CorrectionFormState();
}

class _CorrectionFormState extends State<CorrectionForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isAddition = false; // false = reduce balance, true = add balance

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _studentBalance => widget.selectedStudent.balance;
  String get _studentName => widget.selectedStudent.fullName;
  String get _studentClass => widget.selectedStudent.class_ ?? '-';

  int _getAmount() {
    return int.tryParse(_amountController.text.trim()) ?? 0;
  }

  int _getNewBalance() {
    final int amount = _getAmount();
    if (_isAddition) {
      return _studentBalance + amount;
    } else {
      return _studentBalance - amount;
    }
  }

  bool _isBalanceValid() {
    final int amount = _getAmount();
    if (amount <= 0) return false;
    if (!_isAddition && amount > _studentBalance) {
      return false;
    }
    return true;
  }

  bool _isReasonValid() {
    return _reasonController.text.trim().length >= 10;
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
    final int newBalance = _getNewBalance();
    final bool balanceValid = _isBalanceValid();
    final bool reasonValid = _isReasonValid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Info
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
              _buildInfoRow('Nama Siswa', _studentName),
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

        // Type of correction
        Text(
          'Jenis Koreksi',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddition = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_isAddition
                        ? AppColors.errorRed2.withValues(alpha: 0.08)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isAddition
                          ? AppColors.errorRed2
                          : AppColors.borderGray,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Kurangi Saldo',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: !_isAddition
                            ? AppColors.errorRed2
                            : AppColors.mutedGray,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddition = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isAddition
                        ? AppColors.successGreen.withValues(alpha: 0.08)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isAddition
                          ? AppColors.successGreen
                          : AppColors.borderGray,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${AppStrings.buttonAdd} Saldo',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: _isAddition
                            ? AppColors.successGreen
                            : AppColors.mutedGray,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Nominal
        Text(
          'Nominal Koreksi',
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
          onChanged: (_) => setState(() {}),
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
        const SizedBox(height: 12),
        if (amount > 0 && !_isAddition && amount > _studentBalance)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '⚠️ Saldo tidak mencukupi untuk pengurangan.',
              style: GoogleFonts.inter(
                color: AppColors.errorRed2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        Text(
          'Saldo Setelah Koreksi: ${fmt.format(newBalance)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: balanceValid ? AppColors.darkTeal : AppColors.errorRed2,
          ),
        ),
        const SizedBox(height: 20),

        // Reason
        Text(
          'Alasan Koreksi (Wajib)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Masukkan alasan koreksi secara detail...',
            hintStyle: GoogleFonts.inter(
              color: AppColors.mutedGray,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(16),
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
        const SizedBox(height: 6),
        Text(
          'Minimal 10 karakter. (Saat ini: ${_reasonController.text.trim().length} karakter)',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: reasonValid ? AppColors.successGreen : AppColors.mutedGray,
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !balanceValid || !reasonValid
                ? null
                : () {
                    widget.onSubmit(
                      _getAmount(),
                      _isAddition,
                      _reasonController.text.trim(),
                    );
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
