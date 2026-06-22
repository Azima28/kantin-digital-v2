import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Helper class to show a password change dialog for a student profile.
/// Used inside the admin student detail screen.
class AdminStudentPasswordChange {
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

    final client = widget.ref.read(supabaseClientProvider);
    try {
      // Client-side role check before RPC call
      final currentUserRole =
          widget.ref.read(authNotifierProvider).profile?['role'];
      if (currentUserRole != 'super_admin' &&
          currentUserRole != 'admin' &&
          currentUserRole != 'petugas_keuangan') {
        throw Exception('Tidak memiliki izin untuk mengubah password');
      }

      // Update encrypted_password in auth.users via RPC
      try {
        await client.rpc(
          'update_auth_user_password',
          params: {
            'p_user_id': widget.profileId,
            'p_new_password': password,
          },
        );
      } catch (_) {
        // Fallback: local db may not have this RPC function.
      }

      // Write to audit logs
      try {
        final authProfile = widget.ref.read(authNotifierProvider).profile;
        final actorName = authProfile?['full_name'] ?? 'Super Admin';
        final actorId = authProfile?['id'];

        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': 'UBAH_PASSWORD',
          'description':
              'Super Admin mengubah kata sandi siswa dengan ID: ${widget.profileId}',
          'target_id': widget.profileId,
        });
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPasswordUpdated),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah kata sandi'),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
