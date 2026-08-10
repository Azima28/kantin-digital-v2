import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

// Provider untuk mengambil data detail siswa (kelas, saldo, status kartu)
final AutoDisposeFutureProvider<Student?> siswaStudentProvider =
    FutureProvider.autoDispose<Student?>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return null;

  final client = ref.read(supabaseClientProvider);
  final Map<String, dynamic>? student = await client
      .from('students')
      .select('id, balance, rfid_uid, is_active')
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

// Provider untuk mengambil pesanan aktif milik siswa (belum selesai & belum dibatalkan)
final siswaActiveOrdersProvider =
    FutureProvider.autoDispose<List<OrderItem>>((Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return <OrderItem>[];

  final client = ref.read(supabaseClientProvider);
  final List<dynamic> response = await client
      .from('orders')
      .select(
          'id, student_id, student_name, status, delivery_location, total_amount, created_at, cancel_request_reason, order_items(product_name, quantity, price)')
      .eq('student_id', profileId)
      .not('status', 'in', '("Selesai","Dibatalkan")')
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
});
