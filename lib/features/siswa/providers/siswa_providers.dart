import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// Provider untuk mengambil data detail siswa (kelas, saldo, status kartu)
final AutoDisposeFutureProvider<Student?> siswaStudentProvider =
    FutureProvider.autoDispose<Student?>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final authState = ref.watch(authNotifierProvider);
  final String? profileId = authState.profile?['id'];
  if (profileId == null) return null;

  final client = ref.read(supabaseClientProvider);
  final Map<String, dynamic>? student = await client
      .from('students')
      .select('id, class_id, rombel_id, balance, rfid_uid, is_active, classes:classes(name), rombels:rombels(name)')
      .eq('id', profileId)
      .maybeSingle();

  if (student == null) return null;
  return Student.fromJson(student);
});

// Provider untuk mengambil daftar transaksi milik siswa
final AutoDisposeFutureProvider<List<OperatorTransaction>>
    siswaTransactionsProvider =
    FutureProvider.autoDispose<List<OperatorTransaction>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
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
  ref.cacheFor(const Duration(minutes: 5));
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
  ref.cacheFor(const Duration(minutes: 5));
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
  ref.cacheFor(const Duration(minutes: 5));
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

class PaginatedNotificationsNotifier
    extends StateNotifier<PaginatedState<AppNotification>> {
  final SupabaseClient _client;
  final String _userId;
  int _currentPage = 0;
  static const int _pageSize = 15;

  PaginatedNotificationsNotifier(this._client, this._userId)
      : super(const PaginatedState(items: [])) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    _currentPage = 0;
    try {
      final data = await _fetchPage(0);
      state = PaginatedState(
        items: data,
        isLoading: false,
        isLoadingMore: false,
        hasReachedMax: data.length < _pageSize,
      );
    } catch (e, st) {
      debugPrint('PaginatedNotificationsNotifier loadFirstPage error: $e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedMax) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = _currentPage + 1;
      final data = await _fetchPage(nextPage);
      _currentPage = nextPage;
      state = state.copyWith(
        items: [...state.items, ...data],
        isLoadingMore: false,
        hasReachedMax: data.length < _pageSize,
      );
    } catch (e, st) {
      debugPrint('PaginatedNotificationsNotifier loadNextPage error: $e\n$st');
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<List<AppNotification>> _fetchPage(int page) async {
    final start = page * _pageSize;
    final end = start + _pageSize - 1;

    final List<dynamic> response = await _client
        .from('notifications')
        .select('*')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .range(start, end);

    return response
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final paginatedNotificationsProvider = StateNotifierProvider.family.autoDispose<
    PaginatedNotificationsNotifier,
    PaginatedState<AppNotification>,
    String>((ref, userId) {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.watch(supabaseClientProvider);
  return PaginatedNotificationsNotifier(client, userId);
});
