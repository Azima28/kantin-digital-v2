import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Formatter untuk input nominal dengan pemisah ribuan titik (.) khas Indonesia
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;

    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Step 2 of the keuangan top-up flow — amount entry.
///
/// Displays student info card, amount input field, quick-select chips,
/// and a "Lanjut → Konfirmasi" button.
class KeuanganTopupStepAmount extends StatelessWidget {
  final NumberFormat fmt;
  final StudentWithProfile? student;
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
    this.student,
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
    final clean = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final int amount = int.tryParse(clean) ?? 0;
    final int newBalance = studentBalance + amount;

    final isAccountBlocked = student?.isAccountBlocked ?? false;
    final isCardBlocked = student?.isCardBlocked ?? false;
    final hasRfid = student?.hasRfid ?? false;

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
            border: Border.all(
              color: isAccountBlocked
                  ? Nebula.rose.withValues(alpha: 0.5)
                  : (isCardBlocked
                      ? Nebula.amber.withValues(alpha: 0.4)
                      : context.dividerCol),
              width: isAccountBlocked || isCardBlocked ? 1.2 : 0.8,
            ),
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
                  Icon(
                    isAccountBlocked
                        ? CupertinoIcons.xmark_octagon_fill
                        : (isCardBlocked
                            ? CupertinoIcons.exclamationmark_triangle_fill
                            : (!hasRfid
                                ? CupertinoIcons.info_circle_fill
                                : CupertinoIcons.checkmark_circle_fill)),
                    color: isAccountBlocked
                        ? Nebula.rose
                        : (isCardBlocked
                            ? Nebula.amber
                            : (!hasRfid ? Colors.blueGrey : Nebula.teal)),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isAccountBlocked
                          ? 'Akun Siswa Dinonaktifkan / Diblokir'
                          : (isCardBlocked
                              ? 'Kartu RFID Sedang Dibekukan'
                              : (!hasRfid
                                  ? 'Siswa Belum Memiliki Kartu RFID'
                                  : 'Siswa Ditemukan & Kartu Aktif')),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isAccountBlocked
                            ? Nebula.rose
                            : (isCardBlocked
                                ? Nebula.amber
                                : (!hasRfid ? Colors.blueGrey : Nebula.teal)),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Nama', studentName),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'NISN', studentNisn),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Kelas', 'Kelas $studentClass'),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(
                context,
                'Status Akun',
                isAccountBlocked ? 'Diblokir (Nonaktif)' : 'Aktif',
                customColor: isAccountBlocked ? Nebula.rose : Nebula.teal,
              ),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(
                context,
                'Status Kartu RFID',
                isCardBlocked
                    ? 'Dibekukan / Hilang'
                    : (!hasRfid
                        ? 'Belum Terdaftar'
                        : 'Terdaftar (${student?.rfidUid})'),
                customColor: isCardBlocked
                    ? Nebula.amber
                    : (!hasRfid ? Colors.blueGrey : Nebula.teal),
              ),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Saldo Saat Ini', fmt.format(studentBalance)),
            ],
          ),
        ),

        // Warning Alert Banner
        if (isAccountBlocked) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Nebula.rose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Nebula.rose.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.xmark_octagon_fill, color: Nebula.rose, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Akun siswa ini sedang dinonaktifkan oleh admin. Top-up saldo dan transaksi tidak dapat diproses demi keamanan.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Nebula.rose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isCardBlocked) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Nebula.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Nebula.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Nebula.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Perhatian: Kartu RFID siswa sedang dibekukan / diblokir. Siswa tidak dapat bertransaksi di kasir kantin sebelum kartu diaktifkan kembali.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Nebula.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (!hasRfid) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.info_circle_fill, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Siswa belum memiliki kartu RFID aktif. Saldo akan tersimpan di akun, namun daftarkan kartu di menu "Registrasi Kartu" agar dapat digunakan di kasir.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

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
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorInputFormatter(),
          ],
          onChanged: (val) {
            onChanged();
          },
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Nebula.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rp',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Nebula.teal,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0',
            hintStyle: GoogleFonts.inter(
              color: context.textSecondary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: context.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerCol),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerCol),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Nebula.teal, width: 1.5),
            ),
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
            final isSelected = selectedQuickAmount == val;
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
                if (selected) onQuickAmountSelected(val);
              },
              selectedColor: Nebula.teal,
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Nebula.teal.withValues(alpha: 0.15)),
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
            onPressed: (isAccountBlocked || amount <= 0 || amount % 1000 != 0)
                ? null
                : onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccountBlocked ? Nebula.rose : Nebula.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              isAccountBlocked
                  ? 'TIDAK DAPAT TOP-UP (AKUN DIBLOKIR)'
                  : 'LANJUT → KONFIRMASI',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? customColor}) {
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
              fontWeight: FontWeight.w600,
              color: customColor ?? context.textPrimary,
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
