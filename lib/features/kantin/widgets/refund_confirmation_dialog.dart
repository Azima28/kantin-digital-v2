import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/operator_activities_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

Future<void> showRefundConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
  String txId,
  int amount,
  String studentName,
) async {
  final authState = ref.read(authNotifierProvider);
  final String? operatorId = authState.profile?['id'];
  if (operatorId == null) return;

  final confirmed = await showAppConfirmationDialog(
    context,
    title: 'Pengembalian Dana Transaksi',
    message: 'Apakah Anda yakin ingin membatalkan transaksi belanja senilai ${CurrencyFormatter.format(amount)} oleh $studentName? Saldo siswa akan dikembalikan.',
    confirmLabel: 'Kembalikan Saldo',
    isDestructive: true,
    icon: Icons.assignment_return_outlined,
  );

  if (!confirmed) return;

  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.post(
      '/pos/refund',
      body: {
        'transaction_id': txId,
        'reason': 'Dibatalkan oleh petugas kantin',
      },
    );

    // Refresh state
    ref.invalidate(operatorTransactionsProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(siswaStudentProvider);
    ref.invalidate(siswaTransactionsProvider);
    ref.invalidate(operatorActivitiesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.success ? 'Transaksi berhasil dibatalkan dan saldo dikembalikan.' : (response.message ?? 'Pengembalian dana diproses')),
          backgroundColor: Nebula.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.labelFailed} memproses pengembalian dana: $e'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
