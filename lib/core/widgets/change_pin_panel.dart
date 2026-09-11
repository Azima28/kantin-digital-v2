import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';

/// A reusable floating panel for changing the 6-digit transaction PIN for students.
class ChangePinPanel extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const ChangePinPanel({super.key, required this.parentContext});

  @override
  ConsumerState<ChangePinPanel> createState() => _ChangePinPanelState();
}

class _ChangePinPanelState extends ConsumerState<ChangePinPanel> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _oldFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _newFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _confirmFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final String oldPin = _oldPinController.text.trim();
    final String newPin = _newPinController.text.trim();

    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final nav = Navigator.of(context);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/student/change-pin', body: {
        'old_pin': oldPin,
        'new_pin': newPin,
      });

      if (!mounted) return;

      if (!response.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Gagal mengubah PIN transaksi.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      nav.pop(); // close dialog
      AppToast.showSuccess(
        context,
        title: 'PIN Berhasil Disimpan',
        message: 'PIN transaksi dompet siswa Anda telah aman diperbarui.',
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.labelFailed} mengubah PIN: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Nebula.teal.withValues(alpha: 0.04),
              blurRadius: 64,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button + Centered Shield Lock Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: Nebula.teal,
                          size: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.textSecondary,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  'Ubah PIN Transaksi',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'PIN 6-digit digunakan untuk mengonfirmasi transaksi dan belanja di kantin.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Info banner default PIN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.2), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.info_circle_fill, size: 16, color: Nebula.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catatan: PIN awal bawaan sistem adalah 123456.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Nebula.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 1. PIN LAMA ──
                _buildPinField(
                  controller: _oldPinController,
                  focusNode: _oldFocus,
                  label: 'PIN Transaksi Saat Ini',
                  hint: 'Masukkan 6 digit PIN lama',
                  obscure: _obscureOld,
                  onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'PIN saat ini wajib diisi';
                    }
                    if (val.trim().length != 6) {
                      return 'PIN harus terdiri dari 6 digit angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── 2. PIN BARU ──
                _buildPinField(
                  controller: _newPinController,
                  focusNode: _newFocus,
                  label: 'PIN Baru (6 Digit)',
                  hint: 'Contoh: 889900',
                  obscure: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'PIN baru wajib diisi';
                    }
                    if (val.trim().length != 6) {
                      return 'PIN baru harus tepat 6 digit angka';
                    }
                    if (val.trim() == _oldPinController.text.trim()) {
                      return 'PIN baru tidak boleh sama dengan PIN lama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── 3. KONFIRMASI PIN BARU ──
                _buildPinField(
                  controller: _confirmPinController,
                  focusNode: _confirmFocus,
                  label: 'Konfirmasi PIN Baru',
                  hint: 'Ketik ulang 6 digit PIN baru',
                  obscure: _obscureConfirm,
                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Konfirmasi PIN wajib diisi';
                    }
                    if (val.trim() != _newPinController.text.trim()) {
                      return 'Konfirmasi PIN tidak cocok dengan PIN baru';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: context.dividerCol),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          AppStrings.buttonCancel,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan PIN',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    final hasFocus = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: obscure ? 4.0 : 2.0,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              letterSpacing: 0,
              color: context.textSecondary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: context.surfaceBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
            ),
            prefixIcon: Icon(
              CupertinoIcons.lock_fill,
              size: 18,
              color: hasFocus ? Nebula.teal : context.textSecondary.withValues(alpha: 0.6),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 19,
                color: context.textSecondary,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
