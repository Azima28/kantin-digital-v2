import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

// Provider to fetch all active products for the logged in operator
final posProductsProvider =
    FutureProvider<List<Product>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <Product>[];

    final client = ref.watch(supabaseClientProvider);
    final List<dynamic> response = await client
        .from('products')
        .select()
        .eq('operator_id', operatorId)
        .eq('is_available', true)
        .order('name');

    return response
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('posProductsProvider error: $e\n$st');
    rethrow;
  }
});

// Provider to fetch and calculate today's revenue for the logged in operator
final todayRevenueProvider =
    FutureProvider.autoDispose<double>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return 0.0;

    final client = ref.watch(supabaseClientProvider);

    // Calculate today's date boundary in UTC or local day string representation
    final todayDate = DateTime.now().toLocal();
    final startOfToday =
        DateTime(todayDate.year, todayDate.month, todayDate.day)
            .toUtc()
            .toIso8601String();
    final endOfToday =
        DateTime(todayDate.year, todayDate.month, todayDate.day, 23, 59, 59)
            .toUtc()
            .toIso8601String();

    final List<dynamic> response = await client
        .from('transactions')
        .select('total_amount')
        .eq('operator_id', operatorId)
        .eq('status', 'success')
        .gte('created_at', startOfToday)
        .lte('created_at', endOfToday);

    double sum = 0.0;
    for (var tx in response) {
      final amt = tx['total_amount'];
      if (amt != null) {
        sum += double.tryParse(amt.toString()) ?? 0.0;
      }
    }
    return sum;
  } catch (e, st) {
    debugPrint('todayRevenueProvider error: $e\n$st');
    rethrow;
  }
});

// Provider to fetch all products for management (both available and unavailable)
final manageProductsProvider =
    FutureProvider<List<Product>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <Product>[];

    final client = ref.watch(supabaseClientProvider);
    final List<dynamic> response = await client
        .from('products')
        .select()
        .eq('operator_id', operatorId)
        .order('name');

    return response
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('manageProductsProvider error: $e\n$st');
    rethrow;
  }
});

// Provider to fetch transaction history for the logged in operator
final operatorTransactionsProvider =
    FutureProvider.autoDispose<List<OperatorTransaction>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <OperatorTransaction>[];

    final client = ref.watch(supabaseClientProvider);
    final List<dynamic> response = await client
        .from('transactions')
        .select(
            'id, total_amount, type, status, created_at, student_id, students(profiles:profiles!students_id_fkey(full_name))')
        .eq('operator_id', operatorId)
        .order('created_at', ascending: false)
        .limit(50);

    return response
        .map(
            (e) => OperatorTransaction.fromOperatorJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('operatorTransactionsProvider error: $e\n$st');
    rethrow;
  }
});

final canteenOrdersProvider = FutureProvider.autoDispose<List<OrderItem>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <OrderItem>[];

    final client = ref.watch(supabaseClientProvider);
    
    final List<dynamic> response = await client
        .from('orders')
        .select('id, student_id, student_name, status, delivery_location, total_amount, created_at, cancel_request_reason, order_items(product_name, quantity, price)')
        .eq('operator_id', operatorId)
        .order('created_at', ascending: false);

    return response.map((e) {
      final map = e as Map<String, dynamic>;
      final List<dynamic> rawItems = map['order_items'] ?? [];
      final List<OrderSubItem> subItems = rawItems.map((item) {
        final itemMap = item as Map<String, dynamic>;
        return OrderSubItem(
          name: itemMap['product_name'] ?? '',
          qty: (itemMap['quantity'] as num).toInt(),
          price: (itemMap['price'] as num).toInt(),
        );
      }).toList();

      final createdAtStr = map['created_at'] != null 
          ? '${DateFormat('HH:mm').format(DateTime.parse(map['created_at']).toLocal())} WIB'
          : '';

      return OrderItem(
        id: map['id'] ?? '',
        studentId: map['student_id'] ?? '',
        studentName: map['student_name'] ?? 'Siswa',
        time: createdAtStr,
        status: map['status'] ?? 'Baru',
        deliveryLocation: map['delivery_location'],
        items: subItems,
        totalAmount: (map['total_amount'] as num).toInt(),
        cancelRequestReason: map['cancel_request_reason'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']).toLocal() : null,
      );
    }).toList();
  } catch (e, st) {
    debugPrint('canteenOrdersProvider error: $e\n$st');
    rethrow;
  }
});

