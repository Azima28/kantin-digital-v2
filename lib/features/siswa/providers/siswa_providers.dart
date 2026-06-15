import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// Provider untuk mengambil data detail siswa (kelas, saldo, status kartu)
final AutoDisposeFutureProvider<Map<String, dynamic>?> siswaStudentProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return null;

  final client = ref.read(supabaseClientProvider);
  final Map<String, dynamic>? student = await client
      .from('students')
      .select('id, class, balance, rfid_uid, is_active')
      .eq('id', profileId)
      .maybeSingle();
  
  return student;
});

// Provider untuk mengambil daftar transaksi milik siswa
final AutoDisposeFutureProvider<List<Map<String, dynamic>>> siswaTransactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return <Map<String, dynamic>>[];

  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('transactions')
      .select('id, student_id, operator_id, total_amount, type, status, created_at, canteen_operators(canteen_name)')
      .eq('student_id', profileId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

// Provider untuk mengambil detail item suatu transaksi
final AutoDisposeFutureProviderFamily<List<Map<String, dynamic>>, String> transactionDetailsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((Ref ref, String txId) async {
  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('transaction_items')
      .select('id, product_id, quantity, unit_price, custom_notes, products(name)')
      .eq('transaction_id', txId);
  return List<Map<String, dynamic>>.from(response);
});

// Provider untuk mengambil notifikasi milik siswa
final AutoDisposeFutureProvider<List<Map<String, dynamic>>> siswaNotificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return <Map<String, dynamic>>[];

  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('notifications')
      .select('*')
      .eq('student_id', profileId)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
});
