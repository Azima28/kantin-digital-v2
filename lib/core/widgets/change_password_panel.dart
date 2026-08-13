import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';

/// A reusable floating panel for changing account passwords across all roles.
class ChangePasswordPanel extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const ChangePasswordPanel({super.key, required this.parentContext});

  @override
  ConsumerState<ChangePasswordPanel> createState() => _ChangePasswordPanelState();
}

class _ChangePasswordPanelState extends ConsumerState<ChangePasswordPanel> {
  final _formKey = GlobalKey<FormState>();
  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

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
    _oldFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final String oldPwd = _oldPwdController.text;
    final String newPwd = _newPwdController.text;

    final authState = ref.read(authNotifierProvider);
    final profileId = authState.profile?['id'];
    if (profileId == null) {
      setState(() => _isSaving = false);
      return;
    }

    final profileEmail = authState.profile?['email'];
    final profileNisn = authState.profile?['nisn'];
    final profileUsername = authState.profile?['username'];
    final String identifier = profileEmail ?? profileNisn ?? profileUsername ?? '';

    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final nav = Navigator.of(context);

    try {
      final client = ref.read(supabaseClientProvider);

      // Verify old password using verify_password RPC
      final verifyRes = await client.rpc('verify_password', params: {
        'p_email': identifier,
        'p_password': oldPwd,
      });

      final bool isValid = verifyRes is Map && verifyRes['password_valid'] == true;
      if (!isValid) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Sandi lama yang dimasukkan salah.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Update password via update_auth_user_password RPC
      final response = await client.rpc('update_auth_user_password', params: {
        'p_user_id': profileId,
        'p_new_password': newPwd,
        'p_caller_id': profileId,
      });

      if (response is Map && response['success'] == false) {
        throw Exception(response['error'] ?? 'Gagal mengubah kata sandi');
      }

      if (!mounted) return;
      nav.pop(); // close dialog
      AppToast.showSuccess(
        context,
        title: 'Berhasil Disimpan',
        message: 'Kata sandi Anda telah aman diperbarui.',
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.labelFailed} mengubah kata sandi: $e'),
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
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.02),
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
                // Close button + Centered Lock Shield Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Title & Subtitle
                Text(
                  'Ubah Sandi Akun',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gunakan kata sandi yang kuat untuk menjaga keamanan akun Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Old Password
                _buildPasswordField(
                  controller: _oldPwdController,
                  focusNode: _oldFocus,
                  label: 'Kata Sandi Lama',
                  hintText: 'Kata Sandi Lama',
                  obscure: _obscureOld,
                  onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Kata sandi lama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // New Password
                _buildPasswordField(
                  controller: _newPwdController,
                  focusNode: _newFocus,
                  label: 'Kata Sandi Baru',
                  hintText: '••••••••',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Kata sandi baru wajib diisi';
                    if (val.length < 6) return 'Minimal terdiri dari 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm New Password
                _buildPasswordField(
                  controller: _confirmPwdController,
                  focusNode: _confirmFocus,
                  label: 'Konfirmasi Kata Sandi Baru',
                  hintText: '••••••••',
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                    if (val != _newPwdController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.darkGray,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          AppStrings.buttonCancel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Save Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isSaving
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: context.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.cardBg,
                                  ),
                                )
                              : Text(
                                  AppStrings.buttonSave,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    final bool isFocused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isFocused ? AppColors.primary : AppColors.textDark.withValues(alpha: 0.85),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isFocused
                ? AppColors.primary.withValues(alpha: 0.08)
                : (context.isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              CupertinoIcons.lock_fill,
              size: 18,
              color: isFocused ? AppColors.primary : AppColors.textGray,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                size: 18,
                color: context.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.borderLight, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.borderLight.withValues(alpha: 0.8), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}