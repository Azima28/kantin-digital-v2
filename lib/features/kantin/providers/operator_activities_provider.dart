import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

final operatorActivitiesProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.read(supabaseClientProvider);
  final profile = ref.read(authNotifierProvider).profile;
  final operatorId = profile?['id'];

  if (operatorId == null) return [];

  final List<dynamic> res = await client
      .from('audit_logs')
      .select('id, action_type, description, created_at, old_value, new_value')
      .eq('actor_id', operatorId)
      .order('created_at', ascending: false)
      .limit(100);

  return res
      .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
      .toList();
});
