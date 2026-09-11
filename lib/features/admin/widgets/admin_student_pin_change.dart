import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Helper class to show a PIN change dialog for a student profile.
/// Used inside the admin student detail screen.
class AdminStudentPinChange {
  static void show(BuildContext context, WidgetRef ref, String profileId) {
    showDialog(
      context: context,
      builder: (context) => _PinChangeDialog(
        profileId: profileId,
        ref: ref,
      ),
    );
  }
}

class _PinChangeDialog extends ConsumerStatefulWidget {
  final String profileId;
  final WidgetRef ref;

  const _PinChangeDialog({
    required this.profileId,
    required this.ref,
  });

  @override
  ConsumerState<_PinChangeDialog> createState() => _PinChangeDialogState();
}

class _PinChangeDialogState extends ConsumerState<_PinChangeDialog> {
  late final TextEditingController _pinController;
  late final TextEditingController _confirmPinController;
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _confirmPinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.dividerCol, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: Nebula.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah PIN Transaksi Siswa',
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atur ulang PIN belanja 6-digit siswa',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Field 1: PIN Baru
              Text(
                'PIN Transaksi Baru (6 Digit)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _pinController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: _obscure ? 4.0 : 2.0,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: 123456',
                  hintStyle: GoogleFonts.inter(
                    color: context.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                  filled: true,
                  fillColor: context.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: Icon(
                    CupertinoIcons.lock_fill,
                    size: 18,
                    color: context.textSecondary.withValues(alpha: 0.6),
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
                    borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 19),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Field 2: Konfirmasi PIN Baru
              Text(
                'Konfirmasi PIN Baru',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPinController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: _obscure ? 4.0 : 2.0,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ketik ulang 6 digit PIN baru',
                  hintStyle: GoogleFonts.inter(
                    color: context.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                  filled: true,
                  fillColor: context.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: Icon(
                    CupertinoIcons.lock_fill,
                    size: 18,
                    color: context.textSecondary.withValues(alpha: 0.6),
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
                    borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 19),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pinController.clear();
                        _confirmPinController.clear();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: context.dividerCol),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppStrings.buttonCancel,
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _changePin(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                              AppStrings.buttonSave,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
    );
  }

  Future<void> _changePin() async {
    final String pin = _pinController.text.trim();
    final String confirmPin = _confirmPinController.text.trim();

    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN baru wajib diisi'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN harus terdiri dari 6 digit angka'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi PIN tidak cocok dengan PIN baru'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final apiClient = widget.ref.read(apiClientProvider);
      final authState = widget.ref.read(authNotifierProvider);
      final callerRole = authState.profile?['role']?.toString();
      final prefix = (callerRole == 'petugas_keuangan') ? '/finance' : '/admin';

      final response = await apiClient.post(
        '$prefix/users/pin',
        body: {
          'user_id': widget.profileId,
          'pin': pin,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal mengubah PIN transaksi siswa');
      }

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN transaksi siswa berhasil diperbarui.'),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah PIN: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
