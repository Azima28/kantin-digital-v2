import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
// Provider: semua kantin aktif + info delivery
// ─────────────────────────────────────────────────────────────

final canteensProvider =
    FutureProvider.autoDispose<List<CanteenInfo>>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  try {
    final client = ref.read(supabaseClientProvider);
    final response =
        await client.rpc('get_canteens_with_delivery') as List<dynamic>;
    return response
        .map((e) => CanteenInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('canteensProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider: menu produk per kantin
// ─────────────────────────────────────────────────────────────

final canteenMenuProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, operatorId) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('products')
        .select()
        .eq('operator_id', operatorId)
        .eq('is_available', true)
        .order('category')
        .order('name') as List<dynamic>;
    return response
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('canteenMenuProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider: pesanan AKTIF siswa (pending/accepted/preparing/ready)
// ─────────────────────────────────────────────────────────────

final siswaActiveOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  // Refresh setiap 10 detik untuk simulated realtime
  ref.cacheFor(const Duration(seconds: 10));
  try {
    final authState = ref.read(authNotifierProvider);
    final studentId = authState.profile?['id'] as String?;
    if (studentId == null) return [];

    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('orders')
        .select(
          'id, student_id, operator_id, transaction_id, status, '
          'delivery_type, delivery_location, delivery_fee, student_phone, '
          'subtotal, total_amount, note, created_at, updated_at, '
          'canteen_operators(canteen_name), '
          'order_items(id, order_id, product_id, quantity, unit_price, note, products(name))',
        )
        .eq('student_id', studentId)
        .inFilter('status', ['pending', 'accepted', 'preparing', 'ready'])
        .order('created_at', ascending: false) as List<dynamic>;

    return response
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('siswaActiveOrdersProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider: riwayat pesanan selesai/batal
// ─────────────────────────────────────────────────────────────

final siswaOrderHistoryProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  ref.cacheFor(const Duration(minutes: 2));
  try {
    final authState = ref.read(authNotifierProvider);
    final studentId = authState.profile?['id'] as String?;
    if (studentId == null) return [];

    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('orders')
        .select(
          'id, student_id, operator_id, transaction_id, status, '
          'delivery_type, delivery_location, delivery_fee, student_phone, '
          'subtotal, total_amount, note, created_at, updated_at, '
          'canteen_operators(canteen_name), '
          'order_items(id, order_id, product_id, quantity, unit_price, note, products(name))',
        )
        .eq('student_id', studentId)
        .inFilter('status', ['completed', 'cancelled'])
        .order('created_at', ascending: false)
        .limit(30) as List<dynamic>;

    return response
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('siswaOrderHistoryProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider: detail 1 order
// ─────────────────────────────────────────────────────────────

final orderDetailProvider =
    FutureProvider.autoDispose.family<Order?, String>((ref, orderId) async {
  ref.cacheFor(const Duration(seconds: 10));
  try {
    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('orders')
        .select(
          'id, student_id, operator_id, transaction_id, status, '
          'delivery_type, delivery_location, delivery_fee, student_phone, '
          'subtotal, total_amount, note, created_at, updated_at, '
          'canteen_operators(canteen_name), '
          'order_items(id, order_id, product_id, quantity, unit_price, note, products(name))',
        )
        .eq('id', orderId)
        .maybeSingle() as Map<String, dynamic>?;

    if (response == null) return null;
    return Order.fromJson(response);
  } catch (e, st) {
    debugPrint('orderDetailProvider error: $e\n$st');
    rethrow;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider: lokasi antar dari DB
// ─────────────────────────────────────────────────────────────

final deliveryLocationsProvider =
    FutureProvider.autoDispose<List<DeliveryLocation>>((ref) async {
  ref.cacheFor(const Duration(minutes: 10));
  try {
    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('delivery_locations')
        .select()
        .eq('is_active', true)
        .order('sort_order') as List<dynamic>;
    return response
        .map((e) => DeliveryLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('deliveryLocationsProvider error: $e\n$st');
    return [];
  }
});
