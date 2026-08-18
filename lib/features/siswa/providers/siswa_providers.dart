import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

// Provider untuk mengambil data detail siswa (kelas, saldo, status kartu) - Cache 5 Menit
final AutoDisposeFutureProvider<Student?> siswaStudentProvider =
    FutureProvider.autoDispose<Student?>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
  if (profile == null || profile['id'] == null) return null;
  if (profile['is_active'] == false) {
    // If digital account is blocked, provide local student data without hitting backend
    final cachedStudent = profile['student'] is Map<String, dynamic> ? profile['student'] as Map<String, dynamic> : null;
    if (cachedStudent != null) {
      return Student.fromJson(cachedStudent);
    }
    return Student(
      id: profile['id'].toString(),
      class_: profile['class']?.toString(),
      balance: (profile['balance'] as num?)?.toInt() ?? 0,
      rfidUid: profile['rfid_uid']?.toString(),
      isActive: profile['is_card_active'] == true || profile['card_is_active'] == true,
    );
  }

  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/student/me');
  if (response.success && response.data != null) {
    return Student.fromJson(response.data as Map<String, dynamic>);
  }
  return null;
});

// State untuk pagination & lazy loading riwayat transaksi siswa
class SiswaTransactionsState {
  final List<OperatorTransaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final DateTime? lastFetched;
  final int totalCount;

  const SiswaTransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.lastFetched,
    this.totalCount = 0,
  });

  SiswaTransactionsState copyWith({
    List<OperatorTransaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    DateTime? lastFetched,
    int? totalCount,
  }) {
    return SiswaTransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// StateNotifier untuk lazy loading & memory caching transaksi siswa
class SiswaTransactionsNotifier extends StateNotifier<SiswaTransactionsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  SiswaTransactionsNotifier(this._apiClient, this._ref)
      : super(const SiswaTransactionsState()) {
    loadInitial();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    final profile = _ref.read(authNotifierProvider).profile;
    if (profile == null || profile['is_active'] == false) {
      state = state.copyWith(isLoading: false, transactions: const []);
      return;
    }

    if (!forceRefresh &&
        state.transactions.isNotEmpty &&
        state.lastFetched != null &&
        DateTime.now().difference(state.lastFetched!).inMinutes < 3) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get('/student/transactions', queryParams: {
        'page': 1,
        'limit': 15,
      });

      if (response.success && response.data != null) {
        List<dynamic> itemsList = [];
        int total = 0;
        bool hasMore = false;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          itemsList = dataMap['items'] as List<dynamic>? ?? [];
          total = (dataMap['total'] as num?)?.toInt() ?? itemsList.length;
          hasMore = dataMap['has_more'] as bool? ?? (itemsList.length >= 15);
        } else if (response.data is List<dynamic>) {
          itemsList = response.data as List<dynamic>;
          total = itemsList.length;
          hasMore = itemsList.length >= 15;
        }

        final parsed = itemsList
            .map((e) => OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          transactions: parsed,
          isLoading: false,
          hasMore: hasMore,
          page: 1,
          lastFetched: DateTime.now(),
          totalCount: total,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Gagal memuat riwayat transaksi',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final response = await _apiClient.get('/student/transactions', queryParams: {
        'page': nextPage,
        'limit': 15,
      });

      if (response.success && response.data != null) {
        List<dynamic> itemsList = [];
        bool hasMore = false;
        int total = state.totalCount;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          itemsList = dataMap['items'] as List<dynamic>? ?? [];
          total = (dataMap['total'] as num?)?.toInt() ?? total;
          hasMore = dataMap['has_more'] as bool? ?? (itemsList.length >= 15);
        } else if (response.data is List<dynamic>) {
          itemsList = response.data as List<dynamic>;
          hasMore = itemsList.length >= 15;
        }

        final parsed = itemsList
            .map((e) => OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>))
            .toList();

        final existingIds = state.transactions.map((t) => t.id).toSet();
        final newItems = parsed.where((t) => !existingIds.contains(t.id)).toList();

        state = state.copyWith(
          transactions: [...state.transactions, ...newItems],
          isLoadingMore: false,
          hasMore: hasMore && newItems.isNotEmpty,
          page: nextPage,
          totalCount: total,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadInitial(forceRefresh: true);
  }
}

final siswaTransactionsNotifierProvider =
    StateNotifierProvider.autoDispose<SiswaTransactionsNotifier, SiswaTransactionsState>((ref) {
  ref.keepAlive();
  final apiClient = ref.read(apiClientProvider);
  return SiswaTransactionsNotifier(apiClient, ref);
});

// Provider untuk mengambil daftar transaksi milik siswa (dengan auto cache & lazy load)
final AutoDisposeFutureProvider<List<OperatorTransaction>>
    siswaTransactionsProvider =
    FutureProvider.autoDispose<List<OperatorTransaction>>((Ref ref) async {
  final txState = ref.watch(siswaTransactionsNotifierProvider);
  return txState.transactions;
});

// Provider untuk mengambil detail item suatu transaksi
final AutoDisposeFutureProviderFamily<List<TransactionItem>, String>
    transactionDetailsProvider =
    FutureProvider.autoDispose.family<List<TransactionItem>, String>(
        (Ref ref, String txId) async {
  return <TransactionItem>[];
});

// Provider untuk mengambil notifikasi milik siswa (Cache 2 Menit)
final AutoDisposeFutureProvider<List<AppNotification>>
    siswaNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 2));
  final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
  if (profile == null || profile['id'] == null || profile['is_active'] == false) return <AppNotification>[];

  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/student/notifications');
  if (response.success && response.data != null) {
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return <AppNotification>[];
});

// Provider untuk mengambil data kontak orang tua
final AutoDisposeFutureProvider<Map<String, String>?> siswaParentContactProvider =
    FutureProvider.autoDispose<Map<String, String>?>((Ref ref) async {
  return null;
});

// Provider untuk mengambil pesanan aktif milik siswa (Cache 3 Menit)
final siswaActiveOrdersProvider =
    FutureProvider.autoDispose<List<OrderItem>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
  if (profile == null || profile['role']?.toString() != 'student' || profile['is_active'] == false) return <OrderItem>[];
  final profileId = profile['id'] as String?;
  if (profileId == null) return <OrderItem>[];

  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/orders/student');
  if (response.success && response.data != null) {
    final list = response.data as List<dynamic>;
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final List<dynamic> rawItems = map['items'] ?? map['order_items'] ?? [];
      final List<OrderSubItem> subItems = rawItems.map((item) {
        final itemMap = item as Map<String, dynamic>;
        final name = itemMap['product_name'] ?? itemMap['name'] ?? '';
        return OrderSubItem(
          name: name,
          qty: (itemMap['quantity'] as num?)?.toInt() ?? 1,
          price: (itemMap['price'] as num?)?.toInt() ?? (itemMap['unit_price'] as num?)?.toInt() ?? 0,
          imageUrl: itemMap['image_url'],
        );
      }).toList();

      final createdAtStr = map['created_at'] != null
          ? '${DateFormat('HH:mm').format(DateTime.parse(map['created_at']).toLocal())} WIB'
          : '';

      return OrderItem(
        id: map['id']?.toString() ?? '',
        studentId: map['student_id']?.toString() ?? '',
        studentName: map['student_name']?.toString() ?? 'Siswa',
        time: createdAtStr,
        status: map['status']?.toString() ?? 'Baru',
        deliveryLocation: map['delivery_location']?.toString(),
        items: subItems,
        totalAmount: (map['total_amount'] as num?)?.toInt() ?? 0,
        cancelRequestReason: map['cancel_request_reason']?.toString(),
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString())?.toLocal() : null,
      );
    }).toList();
  }
  return <OrderItem>[];
});

// Provider untuk menghitung jumlah pesanan aktif siswa
final siswaActiveOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final ordersAsync = ref.watch(siswaActiveOrdersProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders.where((o) {
      final s = o.status.trim().toLowerCase();
      return s != 'selesai' && s != 'dibatalkan' && s != 'cancelled' && s != 'refunded';
    }).length,
    orElse: () => 0,
  );
});

