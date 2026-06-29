import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// ============================================================================
// PARENT DASHBOARD PROVIDER
// ============================================================================

/// Fetch dashboard data untuk parent: profile siswa, info siswa, dan transaksi terbaru.
/// Digunakan di: parent_dashboard_screen.dart, parent_topup_screen.dart
final parentDashboardProvider =
    FutureProvider.autoDispose.family<ParentDashboardData, String>(
        (ref, studentId) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);

    // 1. Fetch profile
    final profile =
        await client.from('profiles').select().eq('id', studentId).maybeSingle();

    // 2. Fetch student
    final student =
        await client.from('students').select('*, classes:classes(name), rombels:rombels(name)').eq('id', studentId).maybeSingle();

    // 3. Fetch recent transactions (fetch up to 100 to support rich charts & analytics)
    final List<dynamic> txs = await client
        .from('transactions')
        .select(
            'id, total_amount, type, status, created_at, purchase_method, canteen_operators(canteen_name), transaction_items(quantity, unit_price, products(name, category))')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(100);

    return ParentDashboardData.fromJson({
      'profile': profile ?? <String, dynamic>{},
      'student': student ?? <String, dynamic>{},
      'transactions': List<Map<String, dynamic>>.from(txs),
    });
  } catch (e, st) {
    debugPrint('parentDashboardProvider error: $e\n$st');
    rethrow;
  }
});
