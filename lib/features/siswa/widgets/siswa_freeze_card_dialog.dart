import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/core/widgets/custom_confirm_dialog.dart';

/// Shows a confirmation dialog to freeze or activate the student card.
Future<void> showFreezeCardDialog(
  BuildContext context,
  WidgetRef ref,
  bool currentStatus,
  String studentId,
) async {
  final confirmed = await showCustomConfirmDialog(
    context: context,
    title: currentStatus ? 'Bekukan Kartu' : 'Aktifkan Kartu',
    message: currentStatus
        ? 'Apakah Anda yakin ingin membekukan kartu? Kartu tidak akan bisa digunakan jajan sementara waktu.'
        : 'Apakah Anda yakin ingin mengaktifkan kembali kartu Anda?',
    confirmLabel: currentStatus ? 'Bekukan' : 'Aktifkan',
    isDestructive: currentStatus,
    icon: currentStatus ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
  );

  if (confirmed) {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('students')
          .update({'is_active': !currentStatus})
          .eq('id', studentId);

      ref.invalidate(siswaStudentProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus
                ? 'Kartu berhasil diaktifkan kembali!'
                : 'Kartu Anda telah dibekukan sementara.'),
            backgroundColor:
                !currentStatus ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memproses status kartu'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
