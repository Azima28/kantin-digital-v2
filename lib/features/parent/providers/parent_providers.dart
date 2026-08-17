import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// ============================================================================
// PARENT DASHBOARD PROVIDER
// ============================================================================

final parentDashboardProvider =
    FutureProvider.autoDispose.family<ParentDashboardData, String>(
        (ref, studentId) async {
  ref.keepAlive();
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/student/transactions');
    final List<dynamic> txs = response.success && response.data != null ? response.data as List<dynamic> : [];

    return ParentDashboardData.fromJson({
      'profile': <String, dynamic>{'id': studentId},
      'student': <String, dynamic>{'id': studentId},
      'transactions': txs,
    });
  } catch (e, st) {
    debugPrint('parentDashboardProvider error: $e\n$st');
    return ParentDashboardData.fromJson({
      'profile': <String, dynamic>{'id': studentId},
      'student': <String, dynamic>{'id': studentId},
      'transactions': <dynamic>[],
    });
  }
});
