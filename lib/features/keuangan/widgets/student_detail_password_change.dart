import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/custom_password_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Helper class to show a password change dialog for a student profile.
/// Used inside the keuangan student detail screen.
class StudentDetailPasswordChange {
  static void show(BuildContext context, WidgetRef ref, String profileId) {
    showCustomPasswordDialog(
      context: context,
      title: AppStrings.adminChangePassword,
      description: 'Masukkan kata sandi baru untuk akun siswa ini.',
      placeholder: 'Kata sandi baru',
      onSave: (password) async {
        final client = ref.read(supabaseClientProvider);
        
        // Client-side role check before RPC call
        final currentUserRole = ref.read(authNotifierProvider).profile?['role'];
        if (currentUserRole != 'super_admin' &&
            currentUserRole != 'admin' &&
            currentUserRole != 'petugas_keuangan') {
          throw Exception('Tidak memiliki izin untuk mengubah password');
        }

        final currentUserId = ref.read(authNotifierProvider).profile?['id'];
        final response = await client.rpc(
          'update_auth_user_password',
          params: {
            'p_user_id': profileId,
            'p_new_password': password,
            'p_caller_id': currentUserId,
          },
        );
        if (response is Map && response['success'] == false) {
          throw Exception(response['error'] ?? 'Gagal mengubah kata sandi');
        }

        // Write to audit logs
        try {
          final authProfile = ref.read(authNotifierProvider).profile;
          final actorName = authProfile?['full_name'] ?? 'Admin Keuangan';
          final actorId = authProfile?['id'];

          await client.from('audit_logs').insert({
            'actor_id': actorId,
            'actor_name': actorName,
            'action_type': 'UBAH_PASSWORD',
            'description': 'Mengubah kata sandi siswa dengan ID: $profileId',
            'target_id': profileId,
          });
        } catch (_) {}

        // Show snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kata sandi berhasil diperbarui!'),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
