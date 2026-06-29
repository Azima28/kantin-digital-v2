import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ============================================================================
// CACHE EXTENSION
// ============================================================================

extension CacheForExtension on Ref<Object?> {
  /// Keep the provider alive for [duration] after the last listener is removed.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;

    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, () {
        link.close();
      });
    });

    onResume(() {
      timer?.cancel();
    });

    onDispose(() {
      timer?.cancel();
    });
  }
}

// ============================================================================
// SUPABASE CLIENT
// ============================================================================

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ============================================================================
// TRANSACTION TYPES - Cached, shared across all features
// ============================================================================

/// Cache transaksi types agar tidak berulang kali query.
/// Digunakan di banyak screen (top-up, adjustment, dll).
final transactionTypesProvider =
    FutureProvider.autoDispose<List<TransactionType>>((ref) async {
  ref.cacheFor(const Duration(minutes: 15));
  // Hardcoded — DB only uses string types ('purchase', 'topup')
  return [
    TransactionType(id: 'purchase', name: 'Pembelian'),
    TransactionType(id: 'topup', name: 'Top-Up'),
    TransactionType(id: 'refund', name: 'Refund'),
  ];
});

/// Map transaction type id -> TransactionType untuk lookup cepat.
final transactionTypeMapProvider =
    FutureProvider.autoDispose<Map<String, TransactionType>>((ref) async {
  ref.cacheFor(const Duration(minutes: 15));
  final types = await ref.watch(transactionTypesProvider.future);
  return {for (var t in types) t.id: t};
});

// ============================================================================
// CURRENT USER PROFILE
// ============================================================================

/// Fetch profile user yang sedang login.
final currentUserProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);
    final authState = ref.watch(authNotifierProvider);
    final String? userId = authState.profile?['id']?.toString() ?? client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  } catch (e, st) {
    debugPrint('currentUserProfileProvider error: $e\n$st');
    rethrow;
  }
});

// ============================================================================
// STUDENT LOOKUP PROVIDERS
// ============================================================================

/// Fetch single student by ID (dengan profile join).
final studentByIdProvider =
    FutureProvider.autoDispose.family<StudentWithProfile?, String>(
        (ref, id) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('profiles')
        .select(
            'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class_id, rombel_id, balance, rfid_uid, classes:classes(name), rombels:rombels(name))')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return StudentWithProfile.fromJoinedJson(data);
  } catch (e, st) {
    debugPrint('studentByIdProvider error: $e\n$st');
    rethrow;
  }
});

// ============================================================================
// RFID PROVIDERS (via students.rfid_uid — no separate rfid_cards table)
// ============================================================================

/// Ambil semua siswa yang punya RFID terdaftar.
final rfidCardsProvider =
    FutureProvider.autoDispose<List<Student>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('students')
        .select('*, profiles!inner(*)')
        .not('rfid_uid', 'is', null)
        .order('rfid_uid');
    return data
        .map((e) => Student.fromJson(e))
        .toList();
  } catch (e, st) {
    debugPrint('rfidCardsProvider error: $e\n$st');
    rethrow;
  }
});

/// Cek apakah RFID UID sudah terdaftar ke siswa.
/// Returns Student jika ditemukan, null jika belum terdaftar.
final rfidByUidProvider =
    FutureProvider.autoDispose.family<Student?, String>((ref, uid) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('students')
        .select('*, profiles!inner(*)')
        .eq('rfid_uid', uid)
        .maybeSingle();
    if (data == null) return null;
    return Student.fromJson(data);
  } catch (e, st) {
    debugPrint('rfidByUidProvider error: $e\n$st');
    rethrow;
  }
});

// ============================================================================
// GLOBAL NOTIFICATIONS PROVIDERS (Multi-Role)
// ============================================================================

/// Fetch all notifications for currently logged in user (Siswa, Kantin, Keuangan, Admin)
final userNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final client = ref.read(supabaseClientProvider);
    final authState = ref.watch(authNotifierProvider);
    final String? userId = authState.profile?['id']?.toString() ?? client.auth.currentUser?.id;
    if (userId == null) return <AppNotification>[];

    final List<dynamic> response = await client
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return response
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('userNotificationsProvider error: $e\n$st');
    return <AppNotification>[];
  }
});

/// Count of unread notifications for currently logged in user
final unreadNotificationsCountProvider =
    Provider.autoDispose<int>((ref) {
  final notifsAsync = ref.watch(userNotificationsProvider);
  return notifsAsync.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ============================================================================
// MASTER CLASSES PROVIDER
// ============================================================================

/// Fetch semua data master kelas dari tabel classes.
final classesProvider = FutureProvider.autoDispose<List<SchoolClass>>((ref) async {
  ref.cacheFor(const Duration(minutes: 15));
  try {
    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('classes')
        .select('*')
        .order('level', ascending: true)
        .order('name', ascending: true);
    
    return (response as List)
        .map((e) => SchoolClass.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('classesProvider error: $e\n$st');
    return <SchoolClass>[];
  }
});

/// Fetch semua data master rombel dari tabel rombels.
final rombelsProvider = FutureProvider.autoDispose<List<SchoolRombel>>((ref) async {
  ref.cacheFor(const Duration(minutes: 15));
  try {
    final client = ref.read(supabaseClientProvider);
    final response = await client
        .from('rombels')
        .select('*')
        .order('name', ascending: true);
    
    return (response as List)
        .map((e) => SchoolRombel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('rombelsProvider error: $e\n$st');
    return <SchoolRombel>[];
  }
});

// ============================================================================
// GENERIC PAGINATED STATE
// ============================================================================

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final String? error;

  const PaginatedState({
    required this.items,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? error,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
    );
  }
}

// ============================================================================
// PAGINATED TRANSACTIONS PROVIDER
// ============================================================================

class PaginatedTransactionsFilter {
  final String? studentId;
  final String? operatorId;
  final String? type;
  final String? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const PaginatedTransactionsFilter({
    this.studentId,
    this.operatorId,
    this.type,
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedTransactionsFilter &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          operatorId == other.operatorId &&
          type == other.type &&
          status == other.status &&
          searchQuery == other.searchQuery &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      studentId.hashCode ^
      operatorId.hashCode ^
      type.hashCode ^
      status.hashCode ^
      searchQuery.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

class PaginatedTransactionsNotifier
    extends StateNotifier<PaginatedState<OperatorTransaction>> {
  final SupabaseClient _client;
  final PaginatedTransactionsFilter _filter;
  int _currentPage = 0;
  static const int _pageSize = 15;

  PaginatedTransactionsNotifier(this._client, this._filter)
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
      debugPrint('PaginatedTransactionsNotifier loadFirstPage error: $e\n$st');
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
      debugPrint('PaginatedTransactionsNotifier loadNextPage error: $e\n$st');
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<List<OperatorTransaction>> _fetchPage(int page) async {
    final start = page * _pageSize;
    final end = start + _pageSize - 1;

    var query = _client.from('transactions').select(
        'id, total_amount, type, status, created_at, student_id, operator_id, purchase_method, canteen_operators(canteen_name), students(profiles:profiles!students_id_fkey(full_name, nisn))');

    if (_filter.studentId != null) {
      query = query.eq('student_id', _filter.studentId!);
    }
    if (_filter.operatorId != null) {
      query = query.eq('operator_id', _filter.operatorId!);
    }
    if (_filter.type != null) {
      query = query.eq('type', _filter.type!);
    }
    if (_filter.status != null) {
      query = query.eq('status', _filter.status!);
    }
    if (_filter.startDate != null) {
      query = query.gte('created_at', _filter.startDate!.toUtc().toIso8601String());
    }
    if (_filter.endDate != null) {
      query = query.lte('created_at', _filter.endDate!.toUtc().toIso8601String());
    }

    final List<dynamic> response = await query
        .order('created_at', ascending: false)
        .range(start, end);

    return response.map((e) {
      if (_filter.operatorId != null) {
        return OperatorTransaction.fromOperatorJson(e as Map<String, dynamic>);
      } else {
        return OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>);
      }
    }).toList();
  }
}

final paginatedTransactionsProvider = StateNotifierProvider.family.autoDispose<
    PaginatedTransactionsNotifier,
    PaginatedState<OperatorTransaction>,
    PaginatedTransactionsFilter>((ref, filter) {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.watch(supabaseClientProvider);
  return PaginatedTransactionsNotifier(client, filter);
});

// ============================================================================
// PAGINATED AUDIT LOGS PROVIDER
// ============================================================================

class PaginatedAuditLogsFilter {
  final String? actorId;
  final String? actorName;
  final String? actionType;
  final String? searchQuery;
  final String? dateFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const PaginatedAuditLogsFilter({
    this.actorId,
    this.actorName,
    this.actionType,
    this.searchQuery,
    this.dateFilter,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedAuditLogsFilter &&
          runtimeType == other.runtimeType &&
          actorId == other.actorId &&
          actorName == other.actorName &&
          actionType == other.actionType &&
          searchQuery == other.searchQuery &&
          dateFilter == other.dateFilter &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      actorId.hashCode ^
      actorName.hashCode ^
      actionType.hashCode ^
      searchQuery.hashCode ^
      dateFilter.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

class PaginatedAuditLogsNotifier
    extends StateNotifier<PaginatedState<AuditLog>> {
  final SupabaseClient _client;
  final PaginatedAuditLogsFilter _filter;
  int _currentPage = 0;
  static const int _pageSize = 15;

  PaginatedAuditLogsNotifier(this._client, this._filter)
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
      debugPrint('PaginatedAuditLogsNotifier loadFirstPage error: $e\n$st');
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
      debugPrint('PaginatedAuditLogsNotifier loadNextPage error: $e\n$st');
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<List<AuditLog>> _fetchPage(int page) async {
    final start = page * _pageSize;
    final end = start + _pageSize - 1;

    var query = _client.from('audit_logs').select(
        'id, actor_id, actor_name, action_type, description, target_id, old_value, new_value, ip_address, user_agent, created_at');

    if (_filter.actorId != null && _filter.actorName != null) {
      query = query.or('actor_id.eq.${_filter.actorId},actor_name.eq.${_filter.actorName}');
    } else if (_filter.actorId != null) {
      query = query.eq('actor_id', _filter.actorId!);
    } else if (_filter.actorName != null) {
      query = query.eq('actor_name', _filter.actorName!);
    }

    if (_filter.actionType != null && _filter.actionType != 'Semua') {
      if (_filter.actionType == 'KARTU') {
        query = query.inFilter('action_type', ['REGISTRASI_KARTU', 'UNLINK_KARTU']);
      } else {
        query = query.eq('action_type', _filter.actionType!);
      }
    }

    if (_filter.dateFilter != null && _filter.dateFilter != 'Semua') {
      final now = DateTime.now().toLocal();
      DateTime startDate;
      if (_filter.dateFilter == 'Hari Ini') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_filter.dateFilter == 'Minggu Ini') {
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      } else {
        // Bulan Ini
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      }
      final startStr = startDate.toUtc().toIso8601String();
      query = query.gte('created_at', startStr);
    }

    if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
      query = query.ilike('description', '%${_filter.searchQuery}%');
    }
    if (_filter.startDate != null) {
      query = query.gte('created_at', _filter.startDate!.toUtc().toIso8601String());
    }
    if (_filter.endDate != null) {
      query = query.lte('created_at', _filter.endDate!.toUtc().toIso8601String());
    }

    final List<dynamic> response = await query
        .order('created_at', ascending: false)
        .range(start, end);

    return response.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final paginatedAuditLogsProvider = StateNotifierProvider.family.autoDispose<
    PaginatedAuditLogsNotifier,
    PaginatedState<AuditLog>,
    PaginatedAuditLogsFilter>((ref, filter) {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.watch(supabaseClientProvider);
  return PaginatedAuditLogsNotifier(client, filter);
});

// ============================================================================
// PAGINATED PROFILES PROVIDER (Staff / Parents)
// ============================================================================

class PaginatedProfilesFilter {
  final String? role;
  final String? searchQuery;

  const PaginatedProfilesFilter({
    this.role,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedProfilesFilter &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => role.hashCode ^ searchQuery.hashCode;
}

class PaginatedProfilesNotifier
    extends StateNotifier<PaginatedState<UserProfile>> {
  final SupabaseClient _client;
  final PaginatedProfilesFilter _filter;
  int _currentPage = 0;
  static const int _pageSize = 15;

  PaginatedProfilesNotifier(this._client, this._filter)
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
      debugPrint('PaginatedProfilesNotifier loadFirstPage error: $e\n$st');
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
      debugPrint('PaginatedProfilesNotifier loadNextPage error: $e\n$st');
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<List<UserProfile>> _fetchPage(int page) async {
    final start = page * _pageSize;
    final end = start + _pageSize - 1;

    // Choose select based on role: staff needs canteen_operators join
    final selectStr = (_filter.role == 'petugas_kantin')
        ? 'id, full_name, username, phone_number, is_active, canteen_operators(canteen_name, balance_earned)'
        : 'id, full_name, email, phone_number, is_active, created_at';

    var query = _client.from('profiles').select(selectStr);

    if (_filter.role != null) {
      query = query.eq('role', _filter.role!);
    }

    if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
      final q = '%${_filter.searchQuery}%';
      query = query.or('full_name.ilike.$q,email.ilike.$q');
    }

    final List<dynamic> response = await query
        .order('full_name', ascending: true)
        .range(start, end);

    return response
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final paginatedProfilesProvider = StateNotifierProvider.family.autoDispose<
    PaginatedProfilesNotifier,
    PaginatedState<UserProfile>,
    PaginatedProfilesFilter>((ref, filter) {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.watch(supabaseClientProvider);
  return PaginatedProfilesNotifier(client, filter);
});
