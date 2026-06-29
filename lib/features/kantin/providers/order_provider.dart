import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
// Provider: semua pesanan masuk ke kantin ini (active)
// ─────────────────────────────────────────────────────────────

final kantinOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  // Poll setiap 8 detik
  ref.cacheFor(const Duration(seconds: 8));
  try {
    final authState = ref.read(authNotifierProvider);
    final operatorId = authState.profile?['id'] as String?;
    if (operatorId == null) return [];

    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('orders')
        .select(
          'id, student_id, operator_id, status, delivery_type, '
          'delivery_location, delivery_fee, student_phone, '
          'subtotal, total_amount, note, created_at, updated_at, '
          'students(profiles:profiles!students_id_fkey(full_name)), '
          'order_items(id, order_id, product_id, quantity, unit_price, note, products(name))',
        )
        .eq('operator_id', operatorId)
        .inFilter('status', ['pending', 'accepted', 'preparing', 'ready'])
        .order('created_at', ascending: true) as List<dynamic>;

    return response
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('kantinOrdersProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider: jumlah pesanan baru (pending) → untuk badge
// ─────────────────────────────────────────────────────────────

final newOrderCountProvider = Provider.autoDispose<int>((ref) {
  final ordersAsync = ref.watch(kantinOrdersProvider);
  return ordersAsync.when(
    data: (orders) => orders.where((o) => o.isPending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ─────────────────────────────────────────────────────────────
// Provider: riwayat pesanan selesai/batal per kantin
// ─────────────────────────────────────────────────────────────

final kantinOrderHistoryProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  ref.cacheFor(const Duration(minutes: 2));
  try {
    final authState = ref.read(authNotifierProvider);
    final operatorId = authState.profile?['id'] as String?;
    if (operatorId == null) return [];

    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('orders')
        .select(
          'id, student_id, operator_id, status, delivery_type, '
          'delivery_location, delivery_fee, student_phone, '
          'subtotal, total_amount, note, created_at, updated_at, '
          'students(profiles:profiles!students_id_fkey(full_name)), '
          'order_items(id, order_id, product_id, quantity, unit_price, note, products(name))',
        )
        .eq('operator_id', operatorId)
        .inFilter('status', ['completed', 'cancelled'])
        .order('created_at', ascending: false)
        .limit(50) as List<dynamic>;

    return response
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('kantinOrderHistoryProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Action: update status order (state machine via RPC)
// ─────────────────────────────────────────────────────────────

Future<void> updateOrderStatus({
  required WidgetRef ref,
  required String orderId,
  required String newStatus,
}) async {
  final authState = ref.read(authNotifierProvider);
  final operatorId = authState.profile?['id'] as String?;
  if (operatorId == null) throw Exception('Not authenticated');

  final client = ref.read(supabaseClientProvider);
  await client.rpc('update_order_status', params: {
    'p_order_id': orderId,
    'p_operator_id': operatorId,
    'p_new_status': newStatus,
  });

  // Invalidate cache
  ref.invalidate(kantinOrdersProvider);
  ref.invalidate(kantinOrderHistoryProvider);
}

// ─────────────────────────────────────────────────────────────
// Action: complete order (RPC — selesai + credit saldo kantin)
// ─────────────────────────────────────────────────────────────

Future<void> completeOrder({
  required WidgetRef ref,
  required String orderId,
}) async {
  final authState = ref.read(authNotifierProvider);
  final operatorId = authState.profile?['id'] as String?;
  if (operatorId == null) throw Exception('Not authenticated');

  final client = ref.read(supabaseClientProvider);
  await client.rpc('complete_order', params: {
    'p_order_id': orderId,
    'p_operator_id': operatorId,
  });

  ref.invalidate(kantinOrdersProvider);
  ref.invalidate(kantinOrderHistoryProvider);
}

// ─────────────────────────────────────────────────────────────
// Action: cancel order dari sisi kantin (tolak pesanan)
// ─────────────────────────────────────────────────────────────

Future<void> cancelOrderByOperator({
  required WidgetRef ref,
  required String orderId,
}) async {
  final authState = ref.read(authNotifierProvider);
  final operatorId = authState.profile?['id'] as String?;
  if (operatorId == null) throw Exception('Not authenticated');

  final client = ref.read(supabaseClientProvider);
  await client.rpc('update_order_status', params: {
    'p_order_id': orderId,
    'p_operator_id': operatorId,
    'p_new_status': 'cancelled',
  });

  ref.invalidate(kantinOrdersProvider);
}

// ─────────────────────────────────────────────────────────────
// Provider: settings (delivery_enabled, delivery_fee) untuk kantin ini
// ─────────────────────────────────────────────────────────────

final kantinOperatorSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.read(authNotifierProvider);
  final operatorId = authState.profile?['id'] as String?;
  if (operatorId == null) return null;

  final client = ref.read(supabaseClientProvider);
  final response = await client
      .from('canteen_operators')
      .select('delivery_enabled, delivery_fee')
      .eq('id', operatorId)
      .maybeSingle() as Map<String, dynamic>?;
  return response;
});

// Action: update delivery settings
Future<void> updateKantinDeliverySettings({
  required WidgetRef ref,
  required bool enabled,
  required int fee,
}) async {
  final authState = ref.read(authNotifierProvider);
  final operatorId = authState.profile?['id'] as String?;
  if (operatorId == null) throw Exception('Not authenticated');

  final client = ref.read(supabaseClientProvider);
  await client.from('canteen_operators').update({
    'delivery_enabled': enabled,
    'delivery_fee': fee,
  }).eq('id', operatorId);

  ref.invalidate(kantinOperatorSettingsProvider);
}
