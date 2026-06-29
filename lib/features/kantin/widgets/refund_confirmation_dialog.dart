import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/custom_confirm_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/operator_activities_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

Future<void> showRefundConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
  String txId,
  int amount,
  String studentName,
) async {
  final authState = ref.read(authNotifierProvider);
  final String? sessionToken = authState.sessionToken;
  final String? operatorId = authState.profile?['id'];
  if (sessionToken == null || operatorId == null) return;

  final confirmed = await showCustomConfirmDialog(
    context: context,
    title: 'Refund Transaksi',
    message: 'Apakah Anda yakin ingin membatalkan transaksi belanja senilai ${CurrencyFormatter.format(amount)} oleh $studentName? Saldo siswa akan dikembalikan.',
    confirmLabel: 'Refund',
    cancelLabel: AppStrings.buttonCancel,
    isDestructive: true,
    icon: Icons.replay_circle_filled_rounded,
  );

  if (confirmed && context.mounted) {
    try {
      final client = ref.read(supabaseClientProvider);

      await client.rpc(
        'process_refund',
        params: {
          'p_transaction_id': txId,
          'p_session_token': sessionToken,
          'p_reason': 'Dibatalkan oleh petugas kantin',
        },
      );

      // Write to audit log
      try {
        final actorName =
            authState.profile?['full_name'] ?? 'Petugas Kantin';
        await client.from('audit_logs').insert({
          'actor_id': operatorId,
          'actor_name': actorName,
          'action_type': 'REFUND_TRANSAKSI',
          'description':
              'Refund transaksi $txId senilai ${CurrencyFormatter.format(amount)} untuk siswa $studentName.',
          'target_id': txId,
          'new_value': {'amount': amount, 'student_name': studentName},
        });
      } catch (_) {}

      // Refresh state
      ref.invalidate(operatorTransactionsProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(operatorActivitiesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successTransactionRefunded),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memproses refund'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
