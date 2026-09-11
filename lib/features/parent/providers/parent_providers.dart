import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';

// ============================================================================
// PARENT DASHBOARD PROVIDER
// ============================================================================

final parentDashboardProvider =
    FutureProvider.autoDispose.family<ParentDashboardData, String>(
        (ref, studentId) async {
  // Short cache to prevent thrashing, but keep balance up-to-date
  ref.cacheFor(const Duration(seconds: 10));
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/parent/dashboard/$studentId');
    if (response.success && response.data != null) {
      return ParentDashboardData.fromJson(response.data as Map<String, dynamic>);
    }
  } catch (e, st) {
    debugPrint('parentDashboardProvider error: $e\n$st');
  }

  return ParentDashboardData.fromJson({
    'profile': <String, dynamic>{'id': studentId, 'full_name': 'Siswa'},
    'student': <String, dynamic>{'id': studentId, 'balance': 0},
    'transactions': <dynamic>[],
  });
});
