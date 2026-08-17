import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

/// Helper class to show a password change dialog for a student profile.
/// Used inside the keuangan student detail screen.
class StudentDetailPasswordChange {
  static final _passwordController = TextEditingController();

  static void dispose() {
    _passwordController.dispose();
  }

  static void show(BuildContext context, WidgetRef ref, String profileId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => _PasswordChangeDialog(
        profileId: profileId,
        passwordController: _passwordController,
        ref: ref,
      ),
    );
  }
}

class _PasswordChangeDialog extends ConsumerStatefulWidget {
  final String profileId;
  final TextEditingController passwordController;
  final WidgetRef ref;

  const _PasswordChangeDialog({
    required this.profileId,
    required this.passwordController,
    required this.ref,
  });

  @override
  ConsumerState<_PasswordChangeDialog> createState() =>
      _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends ConsumerState<_PasswordChangeDialog> {
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(AppStrings.adminChangePassword),
      content: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: CupertinoTextField(
          controller: widget.passwordController,
          placeholder: 'Masukkan sandi baru',
          obscureText: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text(AppStrings.buttonCancel),
          onPressed: () {
            widget.passwordController.clear();
            Navigator.pop(context);
          },
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => _changePassword(),
          child: const Text(AppStrings.buttonSave),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final String password = widget.passwordController.text.trim();
    if (password.isEmpty) return;

    try {
      final apiClient = widget.ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/users/password',
        body: {
          'user_id': widget.profileId,
          'new_password': password,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal mengubah kata sandi');
      }

      if (mounted) {
        Navigator.pop(context);
        widget.passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diperbarui!'),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah kata sandi: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
