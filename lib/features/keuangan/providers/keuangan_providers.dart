import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ============================================================================
// DASHBOARD PROVIDER (Keuangan)
// ============================================================================

/// Fetch data dashboard keuangan (officer-specific).
/// Digunakan di: keuangan_dashboard_screen.dart
final keuanganDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
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
      final startOfDayUtc = '${todayStr}T00:00:00+07:00';

      // 1. Total saldo beredar semua siswa (data real dari DB)
      double totalSaldo = 0.0;
      try {
        final List<dynamic> balances =
            await client.from('students').select('balance');
        for (final row in balances) {
          totalSaldo +=
              double.tryParse(row['balance']?.toString() ?? '0') ?? 0.0;
        }
      } catch (_) {}

      // 2. Top-up hari ini
      double topupToday = 0.0;
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
              double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
        }
      } catch (_) {}

      // 3. Koreksi saldo hari ini (audit_logs KOREKSI_SALDO)
      int koreksCount = 0;
      double koreksNet = 0.0;
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
          final double oldBal =
              double.tryParse(oldVal['balance']?.toString() ?? '0') ?? 0.0;
          final double newBal =
              double.tryParse(newVal['balance']?.toString() ?? '0') ?? 0.0;
          koreksNet += (newBal - oldBal);
        }
      } catch (_) {}

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
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final client = ref.read(supabaseClientProvider);
      final profile = ref.read(authNotifierProvider).profile;
      final actorId = profile?['id'];

      // Guard: if actor ID is not available, return empty list
      if (actorId == null || actorId.toString().isEmpty) {
        return <Map<String, dynamic>>[];
      }

      final List<dynamic> res = await client
          .from('audit_logs')
          .select(
            'id, action_type, description, created_at, old_value, new_value, target_id',
          )
          .eq('actor_id', actorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    });

// ============================================================================
// REPORT PROVIDER (Keuangan)
// ============================================================================

/// Fetch data laporan keuangan (canteen operators, transaksi, koreksi).
/// Digunakan di: keuangan_report_screen.dart
final keuanganReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final client = ref.read(supabaseClientProvider);

    // Fetch canteen operators and their earned balance
    final List<dynamic> canteens = await client
        .from('canteen_operators')
        .select('canteen_name, balance_earned');

    // Fetch all transactions to compile totals
    final List<dynamic> txs = await client
        .from('transactions')
        .select('total_amount, type, status, created_at');

    double totalTopup = 0.0;
    double totalPurchase = 0.0;
    int topupCount = 0;
    int purchaseCount = 0;

    for (var tx in txs) {
      if (tx['status'] != 'success') continue;
      final amt = double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
      if (tx['type'] == 'topup') {
        totalTopup += amt;
        topupCount++;
      } else if (tx['type'] == 'purchase') {
        totalPurchase += amt;
        purchaseCount++;
      }
    }

    // Fetch audit logs to compile corrections
    final List<dynamic> logs = await client
        .from('audit_logs')
        .select('old_value, new_value')
        .eq('action_type', 'KOREKSI_SALDO');

    double totalCorrection = 0.0;
    for (var log in logs) {
      final oldVal = log['old_value'] as Map<String, dynamic>? ?? {};
      final newVal = log['new_value'] as Map<String, dynamic>? ?? {};
      final double oldBal =
          double.tryParse(oldVal['balance']?.toString() ?? '0') ?? 0.0;
      final double newBal =
          double.tryParse(newVal['balance']?.toString() ?? '0') ?? 0.0;
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
      final client = ref.read(supabaseClientProvider);

      // Fetch profiles that are students and join student details
      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid, is_active)',
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
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      // 2. Fetch student
      final student = await client
          .from('students')
          .select()
          .eq('id', id)
          .single();

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
        'profile': profile,
        'student': student,
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
      final client = ref.read(supabaseClientProvider);
      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, phone_number, is_active, created_at, parent_students!parent_id(students!parent_students_student_id_fkey(id, class, profiles:profiles!students_id_fkey(full_name, nisn)))',
          )
          .eq('role', 'parent')
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    });

/// Fetch semua petugas kantin dengan data operator.
/// Digunakan di: keuangan_users_screen.dart
final keuanganStaffProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
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
