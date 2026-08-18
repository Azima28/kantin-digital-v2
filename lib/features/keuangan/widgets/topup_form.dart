import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
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
            color: context.textSecondary,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? context.textPrimary,
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
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Nebula.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Siswa Ditemukan',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Nebula.teal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Nama', _studentName),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow('NISN', _studentNisn),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(AppStrings.labelStudentClass, 'Kelas $_studentClass'),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
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
            color: context.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dividerCol),
          ),
          child: Row(
            children: [
              Text(
                'Rp',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedQuickAmount = null;
                    });
                  },
                ),
              ),
              if (_amountController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_rounded, color: context.textSecondary, size: 20),
                  onPressed: () {
                    setState(() {
                      _amountController.clear();
                      _selectedQuickAmount = null;
                    });
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Quick select chips
        Text(
          '${AppStrings.buttonSelect} Cepat:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.textSecondary,
          ),
        ),
        SizedBox(height: 8),
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
                  color: isSelected ? Colors.white : Nebula.teal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onQuickAmountSelected(val);
              },
              selectedColor: Nebula.teal,
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: Nebula.teal.withValues(alpha: 0.15)),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
        Text(
          'Saldo Baru (Preview): ${fmt.format(newBalance)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Nebula.teal,
          ),
        ),
        SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: amount <= 0 || amount % 1000 != 0
                ? null
                : () {
                    widget.onSubmit(_getAmount());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
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
                color: context.cardBg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
