import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

/// Modal dialog / bottom sheet adaptif untuk memproses Koreksi Saldo Siswa
/// (Penambahan atau Pengurangan) dengan row-level lock dan audit forensik.
class BalanceCorrectionDialog extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final String nisn;
  final int currentBalance;
  final bool isBottomSheet;

  const BalanceCorrectionDialog({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.nisn,
    required this.currentBalance,
    this.isBottomSheet = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String studentId,
    required String studentName,
    required String nisn,
    required int currentBalance,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 540;

    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BalanceCorrectionDialog(
          studentId: studentId,
          studentName: studentName,
          nisn: nisn,
          currentBalance: currentBalance,
          isBottomSheet: true,
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BalanceCorrectionDialog(
        studentId: studentId,
        studentName: studentName,
        nisn: nisn,
        currentBalance: currentBalance,
        isBottomSheet: false,
      ),
    );
  }

  @override
  ConsumerState<BalanceCorrectionDialog> createState() =>
      _BalanceCorrectionDialogState();
}

class _BalanceCorrectionDialogState
    extends ConsumerState<BalanceCorrectionDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // 'add' = Penambahan (+), 'deduct' = Pengurangan (-)
  String _direction = 'add';
  bool _isSubmitting = false;

  final List<int> _quickAmounts = [5000, 10000, 20000, 50000, 100000];

  final List<String> _quickReasons = [
    'Kelebihan top-up tunai',
    'Koreksi salah input kasir',
    'Penyelarasan saldo fisik',
    'Pengembalian dana manual',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    final cleanDigits =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanDigits) ?? 0;
  }

  int get _resultingBalance {
    if (_direction == 'add') {
      return widget.currentBalance + _parsedAmount;
    } else {
      return widget.currentBalance - _parsedAmount;
    }
  }

  bool get _isNegativeExceeded =>
      _direction == 'deduct' && _parsedAmount > widget.currentBalance;

  Future<void> _submitCorrection() async {
    final amount = _parsedAmount;
    final reason = _reasonController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal koreksi wajib lebih dari Rp 0'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal koreksi minimal Rp 1.000'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount > 2000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal koreksi maksimal Rp 2.000.000 per transaksi'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isNegativeExceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengurangan melebihi saldo siswa (${CurrencyFormatter.format(widget.currentBalance)}). Saldo tidak boleh negatif.',
          ),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan koreksi wajib diisi secara jelas'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await processBalanceCorrection(
        ref,
        studentId: widget.studentId,
        amount: amount,
        type: _direction,
        reason: reason,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        AppToast.showSuccess(
          context,
          title: 'Koreksi Saldo Berhasil',
          message:
              'Saldo ${widget.studentName} berhasil disesuaikan (${_direction == 'add' ? '+' : '-'}${CurrencyFormatter.format(amount)}).',
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg.isNotEmpty ? errorMsg : 'Gagal memproses koreksi saldo',
                    style: GoogleFonts.inter(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCol = _direction == 'add' ? Nebula.teal : Nebula.rose;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 380;
    final maxDialogHeight = mediaQuery.size.height * (widget.isBottomSheet ? 0.90 : 0.85);

    final content = Container(
      constraints: BoxConstraints(
        maxWidth: 500,
        maxHeight: maxDialogHeight,
      ),
      padding: EdgeInsets.only(
        top: widget.isBottomSheet ? 12 : 20,
        left: 20,
        right: 20,
        bottom: widget.isBottomSheet ? (mediaQuery.viewInsets.bottom + 16) : 20,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(24),
        border: Border.all(color: context.dividerCol, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for bottom sheet
          if (widget.isBottomSheet) ...[
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.dividerCol,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],

          // 1. PINNED HEADER (Always Visible)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeCol.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeCol.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: themeCol,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koreksi Saldo Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.xmark,
                  size: 18,
                  color: context.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.8, color: context.dividerCol),

          // 2. SCROLLABLE BODY (Form Inputs)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info Saldo Saat Ini
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.dividerCol, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saldo Aktif Saat Ini',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(widget.currentBalance),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Direction Selector (Penambahan / Pengurangan)
                  Text(
                    'JENIS KOREKSI',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PressScale(
                          onTap: _isSubmitting
                              ? null
                              : () => setState(() => _direction = 'add'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _direction == 'add'
                                  ? Nebula.teal.withValues(alpha: 0.15)
                                  : context.surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _direction == 'add'
                                    ? Nebula.teal
                                    : context.dividerCol,
                                width: _direction == 'add' ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.plus_circle_fill,
                                  size: 15,
                                  color: _direction == 'add'
                                      ? Nebula.teal
                                      : context.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    isCompact ? 'Tambah (+)' : 'Penambahan (+)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: _direction == 'add'
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: _direction == 'add'
                                          ? Nebula.teal
                                          : context.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PressScale(
                          onTap: _isSubmitting
                              ? null
                              : () => setState(() => _direction = 'deduct'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _direction == 'deduct'
                                  ? Nebula.rose.withValues(alpha: 0.15)
                                  : context.surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _direction == 'deduct'
                                    ? Nebula.rose
                                    : context.dividerCol,
                                width: _direction == 'deduct' ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.minus_circle_fill,
                                  size: 15,
                                  color: _direction == 'deduct'
                                      ? Nebula.rose
                                      : context.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    isCompact ? 'Kurang (-)' : 'Pengurangan (-)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: _direction == 'deduct'
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: _direction == 'deduct'
                                          ? Nebula.rose
                                          : context.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nominal Input
                  Text(
                    'NOMINAL KOREKSI',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeCol,
                      ),
                      hintText: '0',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: context.textSecondary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: context.surfaceBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeCol, width: 1.5),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Amount Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickAmounts.map((amt) {
                        final isSelected = _parsedAmount == amt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(CurrencyFormatter.format(amt)),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? themeCol : context.textPrimary,
                            ),
                            backgroundColor: isSelected
                                ? themeCol.withValues(alpha: 0.15)
                                : context.surfaceBg,
                            side: BorderSide(
                              color: isSelected ? themeCol : context.dividerCol,
                              width: 0.8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _amountController.text = amt.toString();
                                    });
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Calculation Result Banner
                  if (_parsedAmount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isNegativeExceeded
                            ? Nebula.rose.withValues(alpha: 0.1)
                            : themeCol.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isNegativeExceeded
                              ? Nebula.rose.withValues(alpha: 0.4)
                              : themeCol.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Estimasi Saldo Baru:',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _isNegativeExceeded
                                      ? Nebula.rose
                                      : context.textPrimary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_resultingBalance),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isNegativeExceeded
                                      ? Nebula.rose
                                      : themeCol,
                                ),
                              ),
                            ],
                          ),
                          if (_isNegativeExceeded) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Peringatan: Pengurangan melebihi saldo aktif. Sistem mencegah saldo negatif.',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Nebula.rose,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Alasan Koreksi
                  Text(
                    'ALASAN KOREKSI (WAJIB)',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    enabled: !_isSubmitting,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: context.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan penyesuaian saldo secara rinci...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: context.surfaceBg,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeCol, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Reason Chips
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: _quickReasons.map((qReason) {
                      final isChosen = _reasonController.text.trim() == qReason;
                      return ActionChip(
                        label: Text(qReason),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isChosen ? themeCol : context.textSecondary,
                          fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: isChosen
                            ? themeCol.withValues(alpha: 0.12)
                            : context.surfaceBg,
                        side: BorderSide(
                          color: isChosen ? themeCol : context.dividerCol,
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _reasonController.text = qReason;
                                });
                              },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // 3. PINNED FOOTER ACTIONS (Always Visible at Bottom)
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.8, color: context.dividerCol),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: context.dividerCol, width: 1),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeCol,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_isSubmitting || _isNegativeExceeded)
                      ? null
                      : _submitCorrection,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _direction == 'add'
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.arrow_down_circle_fill,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _direction == 'add'
                                    ? 'Tambah Saldo'
                                    : 'Kurangi Saldo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: content,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: content,
    );
  }
}
