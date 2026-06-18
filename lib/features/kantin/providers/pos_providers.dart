import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// Provider to fetch all active products for the logged in operator
final FutureProvider<List<Map<String, dynamic>>> posProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final operatorId = authState.profile?['id'];
  if (operatorId == null) return <Map<String, dynamic>>[];

  final client = ref.watch(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('products')
      .select()
      .eq('operator_id', operatorId)
      .eq('is_available', true)
      .order('name');

  return List<Map<String, dynamic>>.from(response);
});

// Provider to fetch and calculate today's revenue for the logged in operator
final FutureProvider<double> todayRevenueProvider =
    FutureProvider<double>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final operatorId = authState.profile?['id'];
  if (operatorId == null) return 0.0;

  final client = ref.watch(supabaseClientProvider);
  
  // Calculate today's date boundary in UTC or local day string representation
  final todayDate = DateTime.now().toLocal();
  final startOfToday = DateTime(todayDate.year, todayDate.month, todayDate.day).toUtc().toIso8601String();
  final endOfToday = DateTime(todayDate.year, todayDate.month, todayDate.day, 23, 59, 59).toUtc().toIso8601String();

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
});

// Provider to fetch all products for management (both available and unavailable)
final FutureProvider<List<Map<String, dynamic>>> manageProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final operatorId = authState.profile?['id'];
  if (operatorId == null) return <Map<String, dynamic>>[];

  final client = ref.watch(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('products')
      .select()
      .eq('operator_id', operatorId)
      .order('name');

  return List<Map<String, dynamic>>.from(response);
});

// Provider to fetch transaction history for the logged in operator
final FutureProvider<List<Map<String, dynamic>>> operatorTransactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final operatorId = authState.profile?['id'];
  if (operatorId == null) return <Map<String, dynamic>>[];

  final client = ref.watch(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('transactions')
      .select('id, total_amount, type, status, created_at, student_id, students(profiles:profiles!students_id_fkey(full_name))')
      .eq('operator_id', operatorId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});
