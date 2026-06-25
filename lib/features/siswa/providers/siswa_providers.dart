import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';

// Provider untuk mengambil data detail siswa (kelas, saldo, status kartu)
final AutoDisposeFutureProvider<Student?> siswaStudentProvider =
    FutureProvider.autoDispose<Student?>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return null;

  final client = ref.read(supabaseClientProvider);
  final Map<String, dynamic>? student = await client
      .from('students')
      .select('id, class, balance, rfid_uid, is_active')
      .eq('id', profileId)
      .maybeSingle();

  if (student == null) return null;
  return Student.fromJson(student);
});

// Provider untuk mengambil daftar transaksi milik siswa
final AutoDisposeFutureProvider<List<OperatorTransaction>>
    siswaTransactionsProvider =
    FutureProvider.autoDispose<List<OperatorTransaction>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return <OperatorTransaction>[];

  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('transactions')
      .select(
          'id, student_id, operator_id, total_amount, type, status, created_at, purchase_method, canteen_operators(canteen_name)')
      .eq('student_id', profileId)
      .order('created_at', ascending: false)
      .limit(50);

  return response
      .map((e) => OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>))
      .toList();
});

// Provider untuk mengambil detail item suatu transaksi
final AutoDisposeFutureProviderFamily<List<TransactionItem>, String>
    transactionDetailsProvider =
    FutureProvider.autoDispose.family<List<TransactionItem>, String>(
        (Ref ref, String txId) async {
  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('transaction_items')
      .select(
          'id, transaction_id, product_id, quantity, unit_price, custom_notes, products(name)')
      .eq('transaction_id', txId);

  return response
      .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Provider untuk mengambil notifikasi milik siswa
final AutoDisposeFutureProvider<List<AppNotification>>
    siswaNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return <AppNotification>[];

  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('notifications')
      .select('*')
      .eq('student_id', profileId)
      .order('created_at', ascending: false)
      .limit(50);

  return response
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Provider untuk mengambil data kontak orang tua
final AutoDisposeFutureProvider<Map<String, String>?> siswaParentContactProvider =
    FutureProvider.autoDispose<Map<String, String>?>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return null;

  final client = ref.read(supabaseClientProvider);
  try {
    final parentRel = await client
        .from('parent_students')
        .select('parent_id')
        .eq('student_id', profileId)
        .maybeSingle();

    if (parentRel != null && parentRel['parent_id'] != null) {
      final String parentId = parentRel['parent_id'];
      final parentProfile = await client
          .from('profiles')
          .select('email, phone_number')
          .eq('id', parentId)
          .maybeSingle();

      if (parentProfile != null) {
        return {
          'email': parentProfile['email']?.toString() ?? '',
          'phone': parentProfile['phone_number']?.toString() ?? '',
        };
      }
    }
  } catch (_) {
    // Database query failed
  }

  return null;
});
