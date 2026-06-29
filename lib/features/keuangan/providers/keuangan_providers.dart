import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

/// WIB timezone offset used across keuangan providers.
const _wibTimezone = Duration(hours: 7);

// ============================================================================
// DASHBOARD PROVIDER (Keuangan)
// ============================================================================

/// Fetch data dashboard keuangan (officer-specific).
/// Digunakan di: keuangan_dashboard_screen.dart
final keuanganDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);
      final profile = ref.read(authNotifierProvider).profile;
      final officerId = profile?['id'];
      final school = profile?['assigned_school'] ?? '';

      // Guard: if officer ID is not available, return empty data
      if (officerId == null || officerId.toString().isEmpty) {
        return {
          'profile': profile,
          'school': school,
          'totalSaldo': 0.0,
          'topupToday': 0.0,
          'topupCount': 0,
          'koreksCount': 0,
          'koreksNet': 0.0,
          'recentLogs': <Map<String, dynamic>>[],
        };
      }

      // Awal hari ini (UTC)
      final now = DateTime.now().toLocal();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final startOfDayUtc = '${todayStr}T00:00:00${_wibTimezone.isNegative ? '-' : '+'}${_wibTimezone.inHours.toString().padLeft(2, '0')}:00';

      // 1. Total saldo beredar semua siswa (data real dari DB)
      int totalSaldo = 0;
      try {
        final List<dynamic> balances =
            await client.from('students').select('balance');
        for (final row in balances) {
          totalSaldo +=
              (row['balance'] as num?)?.toInt() ?? 0;
        }
      } catch (e, st) {
        debugPrint('keuanganDashboard saldo error: $e\n$st');
      }

      // 2. Top-up hari ini
      int topupToday = 0;
      int topupCount = 0;
      try {
        final List<dynamic> topups = await client
            .from('transactions')
            .select('total_amount')
            .eq('type', 'topup')
            .eq('status', 'success')
            .gte('created_at', startOfDayUtc);
        topupCount = topups.length;
        for (final tx in topups) {
          topupToday +=
              int.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0;
        }
      } catch (e, st) {
        debugPrint('keuanganDashboard topup error: $e\n$st');
      }

      // 3. Koreksi saldo hari ini (audit_logs KOREKSI_SALDO)
      int koreksCount = 0;
      int koreksNet = 0;
      try {
        final List<dynamic> koreksi = await client
            .from('audit_logs')
            .select('old_value, new_value')
            .eq('action_type', 'KOREKSI_SALDO')
            .eq('actor_id', officerId)
            .gte('created_at', startOfDayUtc);
        koreksCount = koreksi.length;
        for (final log in koreksi) {
          final oldVal = log['old_value'] as Map<String, dynamic>? ?? {};
          final newVal = log['new_value'] as Map<String, dynamic>? ?? {};
          final int oldBal =
              int.tryParse(oldVal['balance']?.toString() ?? '0') ?? 0;
          final int newBal =
              int.tryParse(newVal['balance']?.toString() ?? '0') ?? 0;
          koreksNet += (newBal - oldBal);
        }
      } catch (e, st) {
        debugPrint('keuanganDashboard koreksi error: $e\n$st');
      }

      // 4. Recent audit logs by this officer
      final List<dynamic> logs = await client
          .from('audit_logs')
          .select('actor_name, action_type, description, created_at')
          .eq('actor_id', officerId)
          .order('created_at', ascending: false)
          .limit(5);

      return {
        'profile': profile,
        'school': school,
        'totalSaldo': totalSaldo,
        'topupToday': topupToday,
        'topupCount': topupCount,
        'koreksCount': koreksCount,
        'koreksNet': koreksNet,
        'recentLogs': List<Map<String, dynamic>>.from(logs),
      };
    });

// ============================================================================
// HISTORY PROVIDER (Keuangan)
// ============================================================================

/// Fetch riwayat audit logs milik officer keuangan.
/// Digunakan di: keuangan_history_screen.dart
final keuanganHistoryProvider =
    FutureProvider.autoDispose<List<AuditLog>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);
      final profile = ref.read(authNotifierProvider).profile;
      final actorId = profile?['id'];

      // Guard: if actor ID is not available, return empty list
      if (actorId == null || actorId.toString().isEmpty) {
        return <AuditLog>[];
      }

      final List<dynamic> res = await client
          .from('audit_logs')
          .select(
            'id, action_type, description, created_at, old_value, new_value, target_id',
          )
          .eq('actor_id', actorId)
          .order('created_at', ascending: false)
          .limit(50);

      return res
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    });

// ============================================================================
// STATE PROVIDERS (Keuangan Search & Filters)
// ============================================================================
// State providers for search query have been deprecated.
// Filtering is now performed completely client-side in the list tabs.

// ============================================================================
// REPORT PROVIDER (Keuangan)
// ============================================================================

/// Fetch data laporan keuangan (canteen operators, transaksi, koreksi).
/// Digunakan di: keuangan_report_screen.dart
final keuanganReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, period) async {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.read(supabaseClientProvider);

    final now = DateTime.now().toLocal();
    DateTime startDate;
    if (period == 'Hari Ini') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (period == 'Minggu Ini') {
      final daysToSubtract = now.weekday - 1; // Monday is 1
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    } else {
      // Bulan Ini (default)
      startDate = DateTime(now.year, now.month, 1);
    }
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}T00:00:00+07:00';

    // Fetch canteen operators and their earned balance
    final List<dynamic> canteens = await client
        .from('canteen_operators')
        .select('id, canteen_name, balance_earned');

    // Fetch transactions for this period only to compile totals
    final List<dynamic> txs = await client
        .from('transactions')
        .select('total_amount, type, status, created_at')
        .gte('created_at', startStr);

    int totalTopup = 0;
    int totalPurchase = 0;
    int topupCount = 0;
    int purchaseCount = 0;

    for (var tx in txs) {
      if (tx['status'] != 'success') continue;
      final amt = int.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0;
      if (tx['type'] == 'topup') {
        totalTopup += amt;
        topupCount++;
      } else if (tx['type'] == 'purchase') {
        totalPurchase += amt;
        purchaseCount++;
      }
    }

    // Fetch audit logs for this period only to compile corrections
    final List<dynamic> logs = await client
        .from('audit_logs')
        .select('old_value, new_value')
        .eq('action_type', 'KOREKSI_SALDO')
        .gte('created_at', startStr);

    int totalCorrection = 0;
    for (var log in logs) {
      final oldVal = log['old_value'] as Map<String, dynamic>? ?? {};
      final newVal = log['new_value'] as Map<String, dynamic>? ?? {};
      final int oldBal =
          int.tryParse(oldVal['balance']?.toString() ?? '0') ?? 0;
      final int newBal =
          int.tryParse(newVal['balance']?.toString() ?? '0') ?? 0;
      totalCorrection += (newBal - oldBal);
    }

    return {
      'canteens': List<Map<String, dynamic>>.from(canteens),
      'totalTopup': totalTopup,
      'totalPurchase': totalPurchase,
      'totalCorrection': totalCorrection,
      'topupCount': topupCount,
      'purchaseCount': purchaseCount,
    };
  },
);

// ============================================================================
// STUDENTS PROVIDER (Keuangan)
// ============================================================================

/// Fetch semua siswa dengan data profile + student (join).
/// Digunakan di: keuangan_students_screen.dart
final keuanganStudentsProvider =
    FutureProvider.autoDispose<List<StudentWithProfile>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);

      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes(name), rombels:rombels(name))',
          )
          .eq('role', 'student')
          .order('full_name', ascending: true);

      return res
          .map(
            (e) => StudentWithProfile.fromJoinedJson(e as Map<String, dynamic>),
          )
          .toList();
    });

/// Fetch semua siswa untuk Manajemen User (CRUD).
/// Digunakan di: keuangan_users_screen.dart (tab Siswa)
final keuanganUsersStudentsProvider =
    FutureProvider.autoDispose<List<StudentWithProfile>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);

      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes(name), rombels:rombels(name))',
          )
          .eq('role', 'student')
          .order('full_name', ascending: true);

      return res
          .map(
            (e) => StudentWithProfile.fromJoinedJson(e as Map<String, dynamic>),
          )
          .toList();
    });

// ============================================================================
// STUDENT DETAIL PROVIDER
// ============================================================================

/// Fetch detail siswa lengkap dengan riwayat transaksi.
/// Digunakan di: keuangan_student_detail_screen.dart
final keuanganStudentDetailProvider = FutureProvider.autoDispose
    .family<AdminStudentDetail, String>((ref, id) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      // 2. Fetch student
      final student = await client
          .from('students')
          .select('*, classes:classes(name), rombels:rombels(name)')
          .eq('id', id)
          .maybeSingle();

      // 3. Fetch recent transactions
      final List<dynamic> txs = await client
          .from('transactions')
          .select(
            'id, total_amount, type, status, created_at, canteen_operators(canteen_name)',
          )
          .eq('student_id', id)
          .order('created_at', ascending: false)
          .limit(10);

      return AdminStudentDetail.fromJson({
        'profile': profile ?? <String, dynamic>{},
        'student': student ?? <String, dynamic>{},
        'transactions': txs,
      });
    });

// ============================================================================
// USERS PROVIDERS (Keuangan)
// ============================================================================

/// Fetch semua parent/ortu dengan data children.
/// Digunakan di: keuangan_users_screen.dart
final keuanganParentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);

      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, phone_number, is_active, created_at, parent_students!parent_id(students!parent_students_student_id_fkey(id, class_id, rombel_id, classes:classes(name), rombels:rombels(name), profiles:profiles!students_id_fkey(full_name, nisn)))',
          )
          .eq('role', 'parent')
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(res);
    });

/// Fetch semua petugas kantin dengan data operator.
/// Digunakan di: keuangan_users_screen.dart
final keuanganStaffProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5));
      final client = ref.read(supabaseClientProvider);

      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, username, phone_number, is_active, canteen_operators(canteen_name, balance_earned)',
          )
          .eq('role', 'petugas_kantin')
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(res);
    });

class PaginatedStudentsFilter {
  final String? classFilter;
  final String? statusFilter;
  final String? searchQuery;

  const PaginatedStudentsFilter({
    this.classFilter,
    this.statusFilter,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedStudentsFilter &&
          runtimeType == other.runtimeType &&
          classFilter == other.classFilter &&
          statusFilter == other.statusFilter &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      classFilter.hashCode ^ statusFilter.hashCode ^ searchQuery.hashCode;
}

class PaginatedStudentsNotifier
    extends StateNotifier<PaginatedState<StudentWithProfile>> {
  final SupabaseClient _client;
  final PaginatedStudentsFilter _filter;
  int _currentPage = 0;
  static const int _pageSize = 15;

  PaginatedStudentsNotifier(this._client, this._filter)
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
      debugPrint('PaginatedStudentsNotifier loadFirstPage error: $e\n$st');
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
      debugPrint('PaginatedStudentsNotifier loadNextPage error: $e\n$st');
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<List<StudentWithProfile>> _fetchPage(int page) async {
    final start = page * _pageSize;
    final end = start + _pageSize - 1;

    final hasClass = _filter.classFilter != null && _filter.classFilter != 'Semua';
    final hasStatus = _filter.statusFilter != null && _filter.statusFilter != 'Semua' && _filter.statusFilter != 'Akun Diblokir';
    final innerJoinStudent = hasClass || hasStatus;

    String selectStr;
    if (innerJoinStudent) {
      final parts = _filter.classFilter?.split('-') ?? [];
      if (parts.length == 2) {
        selectStr =
            'id, full_name, email, nisn, is_active, students:students!inner(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes!inner(name), rombels:rombels!inner(name))';
      } else if (parts.length == 1 && parts[0] != 'Semua' && parts[0].isNotEmpty) {
        selectStr =
            'id, full_name, email, nisn, is_active, students:students!inner(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes!inner(name), rombels:rombels(name))';
      } else {
        selectStr =
            'id, full_name, email, nisn, is_active, students:students!inner(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes(name), rombels:rombels(name))';
      }
    } else {
      selectStr =
          'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes(name), rombels:rombels(name))';
    }

    var query = _client.from('profiles').select(selectStr).eq('role', 'student');

    if (hasClass) {
      final parts = _filter.classFilter!.split('-');
      if (parts.length == 2) {
        query = query
            .eq('students.classes.name', parts[0])
            .eq('students.rombels.name', parts[1]);
      } else {
        query = query.eq('students.classes.name', parts[0]);
      }
    }

    if (_filter.statusFilter != null && _filter.statusFilter != 'Semua') {
      if (_filter.statusFilter == 'Aktif') {
        query = query
            .eq('is_active', true)
            .eq('students.is_active', true)
            .not('students.rfid_uid', 'is', null)
            .neq('students.rfid_uid', '');
      } else if (_filter.statusFilter == 'Akun Diblokir') {
        query = query.eq('is_active', false);
      } else if (_filter.statusFilter == 'Kartu Diblokir') {
        query = query
            .eq('is_active', true)
            .eq('students.is_active', false)
            .not('students.rfid_uid', 'is', null)
            .neq('students.rfid_uid', '');
      } else if (_filter.statusFilter == 'Belum Aktif') {
        query = query.or('rfid_uid.is.null,rfid_uid.eq.', referencedTable: 'students');
      } else if (_filter.statusFilter == 'Saldo Rendah') {
        query = query.lt('students.balance', 5000);
      }
    }

    if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
      final queryStr = '%${_filter.searchQuery}%';
      query = query.or('full_name.ilike.$queryStr,email.ilike.$queryStr,nisn.ilike.$queryStr');
    }

    final List<dynamic> response = await query
        .order('full_name', ascending: true)
        .range(start, end);

    return response
        .map((e) => StudentWithProfile.fromJoinedJson(e as Map<String, dynamic>))
        .toList();
  }
}

final paginatedStudentsProvider = StateNotifierProvider.family.autoDispose<
    PaginatedStudentsNotifier,
    PaginatedState<StudentWithProfile>,
    PaginatedStudentsFilter>((ref, filter) {
  ref.cacheFor(const Duration(minutes: 5));
  final client = ref.watch(supabaseClientProvider);
  return PaginatedStudentsNotifier(client, filter);
});
