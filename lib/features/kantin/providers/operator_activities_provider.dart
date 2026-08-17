import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final operatorActivitiesProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null || profile['role']?.toString() != 'petugas_kantin') {
      return <AuditLog>[];
    }

    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/pos/activities', queryParams: {'limit': '50'});
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <AuditLog>[];
  } catch (e, st) {
    debugPrint('operatorActivitiesProvider error: $e\n$st');
    return <AuditLog>[];
  }
});
