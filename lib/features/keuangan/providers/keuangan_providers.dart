import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// WIB timezone offset used across keuangan providers.
const _wibTimezone = Duration(hours: 7);

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
      final client = ref.read(supabaseClientProvider);

      final List<dynamic> res = await client
          .from('audit_logs')
          .select(
            'id, action_type, description, created_at, old_value, new_value, target_id, actor_id, actor_name',
          )
          .order('created_at', ascending: false)
          .limit(100);

      return res
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    });

// ============================================================================
// REPORT PROVIDER (Keuangan)
// ============================================================================

// Parameter filter tanggal laporan keuangan
class ReportFilterParam {
  final String periodLabel;
  final DateTime startDate;
  final DateTime endDate;

  const ReportFilterParam({
    required this.periodLabel,
    required this.startDate,
    required this.endDate,
  });

  String get formattedPeriodLabel {
    final fmt = DateFormat('dd/MM/yyyy');
    if (periodLabel == 'Kustom' || periodLabel == 'Custom') {
      return '${fmt.format(startDate)} - ${fmt.format(endDate)}';
    }
    return periodLabel;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilterParam &&
          periodLabel == other.periodLabel &&
          startDate.year == other.startDate.year &&
          startDate.month == other.startDate.month &&
          startDate.day == other.startDate.day &&
          endDate.year == other.endDate.year &&
          endDate.month == other.endDate.month &&
          endDate.day == other.endDate.day;

  @override
  int get hashCode => Object.hash(
        periodLabel,
        startDate.year,
        startDate.month,
        startDate.day,
        endDate.year,
        endDate.month,
        endDate.day,
      );
}

/// Fetch data laporan keuangan (canteen operators, transaksi, koreksi) berdasarkan filter tanggal.
/// Digunakan di: keuangan_report_screen.dart
final keuanganReportProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, ReportFilterParam>(
  (ref, param) async {
    final client = ref.read(supabaseClientProvider);

    final startIso = DateTime(
      param.startDate.year,
      param.startDate.month,
      param.startDate.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();

    final endIso = DateTime(
      param.endDate.year,
      param.endDate.month,
      param.endDate.day,
      23,
      59,
      59,
      999,
    ).toUtc().toIso8601String();

    // 1. Fetch daftar stan kantin
    final List<dynamic> rawCanteens = await client
        .from('canteen_operators')
        .select('id, canteen_name');

    final Map<String, Map<String, dynamic>> canteensMap = {};
    for (var c in rawCanteens) {
      final id = c['id']?.toString() ?? '';
      canteensMap[id] = {
        'id': id,
        'canteen_name': c['canteen_name']?.toString() ?? '',
        'balance_earned': 0,
      };
    }

    // 2. Fetch transaksi yang difilter rentang tanggal
    final List<dynamic> txs = await client
        .from('transactions')
        .select('total_amount, type, status, created_at, operator_id')
        .gte('created_at', startIso)
        .lte('created_at', endIso);

    int totalTopup = 0;
    int totalPurchase = 0;
    int topupCount = 0;
    int purchaseCount = 0;

    for (var tx in txs) {
      if (tx['status'] != 'success') continue;
      final amt = int.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0;
      final type = tx['type']?.toString();
      final opId = tx['operator_id']?.toString();

      if (type == 'topup') {
        totalTopup += amt;
        topupCount++;
      } else if (type == 'purchase') {
        totalPurchase += amt;
        purchaseCount++;
        if (opId != null && canteensMap.containsKey(opId)) {
          canteensMap[opId]!['balance_earned'] =
              (canteensMap[opId]!['balance_earned'] as int) + amt;
        }
      }
    }

    // 3. Fetch audit logs koreksi saldo yang difilter rentang tanggal
    final List<dynamic> logs = await client
        .from('audit_logs')
        .select('old_value, new_value, created_at')
        .eq('action_type', 'KOREKSI_SALDO')
        .gte('created_at', startIso)
        .lte('created_at', endIso);

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
      'canteens': canteensMap.values.toList(),
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
    FutureProvider<List<StudentWithProfile>>((ref) async {
      final client = ref.read(supabaseClientProvider);

      // Fetch profiles that are students and join student details
      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, nisn, is_active, students:students!students_id_fkey(balance, rfid_uid, is_active, classes:classes(name))',
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
final keuanganStudentDetailProvider = FutureProvider
    .family<AdminStudentDetail, String>((ref, id) async {
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
          .select('*, classes:classes(name)')
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
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final client = ref.read(supabaseClientProvider);
      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, email, phone_number, is_active, created_at, parent_students!parent_students_parent_id_fkey(students!parent_students_student_id_fkey(id, classes:classes(name), profiles:profiles!students_id_fkey(full_name, nisn)))',
          )
          .eq('role', 'parent')
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    });

/// Fetch semua petugas kantin dengan data operator.
/// Digunakan di: keuangan_users_screen.dart
final keuanganStaffProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
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

// ============================================================================
// REALTIME DAILY TREND CHART PROVIDER
// ============================================================================

/// Data model untuk poin grafik tren harian
class DailyTrendPoint {
  final String dayLabel; // 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'
  final String fullDayName; // 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  final double amount; // Nominal transaksi
  final String displayShort; // '1.2M', '1.5M', '1.8M', '1.4M', '2.1M', '800k'
  final DateTime date;

  const DailyTrendPoint({
    required this.dayLabel,
    required this.fullDayName,
    required this.amount,
    required this.displayShort,
    required this.date,
  });
}

/// Dynamic Data container untuk Grafik Tren Realtime
class DailyTrendChartData {
  final List<DailyTrendPoint> points;
  final double averageAmount;
  final double percentageChange;
  final double maxAmount;
  final int totalCount;

  const DailyTrendChartData({
    required this.points,
    required this.averageAmount,
    required this.percentageChange,
    required this.maxAmount,
    required this.totalCount,
  });

  factory DailyTrendChartData.empty() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final fullDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

    final emptyPoints = List.generate(6, (i) {
      final d = monday.add(Duration(days: i));
      return DailyTrendPoint(
        dayLabel: days[i],
        fullDayName: fullDays[i],
        amount: 0.0,
        displayShort: '0',
        date: d,
      );
    });

    return DailyTrendChartData(
      points: emptyPoints,
      averageAmount: 0.0,
      percentageChange: 0.0,
      maxAmount: 2500000.0,
      totalCount: 0,
    );
  }
}

String _formatShortAmount(double amount) {
  if (amount >= 1000000000) {
    final val = amount / 1000000000;
    return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}B';
  } else if (amount >= 1000000) {
    final val = amount / 1000000;
    return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
  } else if (amount >= 1000) {
    final val = amount / 1000;
    return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}k';
  } else if (amount == 0) {
    return '0';
  } else {
    return amount.toStringAsFixed(0);
  }
}

/// Fetch & Stream Realtime Grafik Tren Transaksi Harian sesuai parameter filter periode
final dailyTrendChartRealtimeProvider = StreamProvider.family
    .autoDispose<DailyTrendChartData, ReportFilterParam?>(
  (ref, filterParam) {
    final client = ref.read(supabaseClientProvider);
    final controller = StreamController<DailyTrendChartData>();

    Future<void> fetchAndEmit() async {
      try {
        DateTime startDate;
        DateTime endDate;

        if (filterParam != null) {
          startDate = DateTime(filterParam.startDate.year, filterParam.startDate.month, filterParam.startDate.day, 0, 0, 0);
          endDate = DateTime(filterParam.endDate.year, filterParam.endDate.month, filterParam.endDate.day, 23, 59, 59, 999);
        } else {
          // Default to current week (Monday to Saturday)
          final now = DateTime.now().toLocal();
          final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          startDate = monday;
          endDate = monday.add(const Duration(days: 5, hours: 23, minutes: 59, seconds: 59));
        }

        final currentStartIso = startDate.toUtc().toIso8601String();
        final currentEndIso = endDate.toUtc().toIso8601String();

        // Calculate previous period for comparison
        final duration = endDate.difference(startDate);
        final prevStartDate = startDate.subtract(duration.abs() > const Duration(days: 1) ? duration : const Duration(days: 1));
        final prevStartIso = prevStartDate.toUtc().toIso8601String();

        // Query current period transactions
        final List<dynamic> currentTxs = await client
            .from('transactions')
            .select('total_amount, created_at, status')
            .eq('status', 'success')
            .gte('created_at', currentStartIso)
            .lte('created_at', currentEndIso);

        // Query previous period transactions
        final List<dynamic> prevTxs = await client
            .from('transactions')
            .select('total_amount, created_at, status')
            .eq('status', 'success')
            .gte('created_at', prevStartIso)
            .lt('created_at', currentStartIso);

        double prevTotalAmount = 0.0;
        for (var tx in prevTxs) {
          prevTotalAmount += (double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0);
        }

        final totalDays = endDate.difference(startDate).inDays + 1;
        final List<DailyTrendPoint> points = [];
        double maxAmt = 0.0;
        double totalCurrentAmount = 0.0;

        final fullDayNamesIndo = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
        final shortDayNamesIndo = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

        if (totalDays <= 31) {
          // Daily points for <= 31 days
          final Map<String, double> dayMap = {};
          for (var tx in currentTxs) {
            final createdAtStr = tx['created_at']?.toString();
            if (createdAtStr == null) continue;
            final txDate = DateTime.parse(createdAtStr).toLocal();
            final key = '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')}';
            final amt = double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
            dayMap[key] = (dayMap[key] ?? 0.0) + amt;
            totalCurrentAmount += amt;
          }

          for (int i = 0; i < totalDays; i++) {
            final d = startDate.add(Duration(days: i));
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            final amt = dayMap[key] ?? 0.0;
            if (amt > maxAmt) maxAmt = amt;

            String dayLabel;
            if (totalDays <= 7) {
              dayLabel = shortDayNamesIndo[d.weekday % 7];
            } else {
              dayLabel = '${d.day}/${d.month}';
            }
            final String fullDayName = '${fullDayNamesIndo[d.weekday % 7]}, ${DateFormat('dd MMMM yyyy', 'id_ID').format(d)}';

            points.add(DailyTrendPoint(
              dayLabel: dayLabel,
              fullDayName: fullDayName,
              amount: amt,
              displayShort: _formatShortAmount(amt),
              date: d,
            ));
          }
        } else {
          // Group by Month for long ranges (> 31 days)
          final Map<String, double> monthMap = {};
          for (var tx in currentTxs) {
            final createdAtStr = tx['created_at']?.toString();
            if (createdAtStr == null) continue;
            final txDate = DateTime.parse(createdAtStr).toLocal();
            final key = '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';
            final amt = double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
            monthMap[key] = (monthMap[key] ?? 0.0) + amt;
            totalCurrentAmount += amt;
          }

          DateTime curr = DateTime(startDate.year, startDate.month, 1);
          final DateTime endMonth = DateTime(endDate.year, endDate.month, 1);

          while (!curr.isAfter(endMonth)) {
            final key = '${curr.year}-${curr.month.toString().padLeft(2, '0')}';
            final amt = monthMap[key] ?? 0.0;
            if (amt > maxAmt) maxAmt = amt;

            final String dayLabel = DateFormat('MMM yy', 'id_ID').format(curr);
            final String fullDayName = DateFormat('MMMM yyyy', 'id_ID').format(curr);

            points.add(DailyTrendPoint(
              dayLabel: dayLabel,
              fullDayName: fullDayName,
              amount: amt,
              displayShort: _formatShortAmount(amt),
              date: curr,
            ));

            curr = DateTime(curr.year, curr.month + 1, 1);
          }
        }

        final double avgAmt = points.isNotEmpty ? (totalCurrentAmount / points.length) : 0.0;

        double percentageChange = 0.0;
        if (prevTotalAmount > 0) {
          percentageChange = ((totalCurrentAmount - prevTotalAmount) / prevTotalAmount) * 100;
        } else if (totalCurrentAmount > 0) {
          percentageChange = 100.0;
        }

        double chartMaxY = 2500000.0;
        if (maxAmt > chartMaxY) {
          chartMaxY = maxAmt * 1.25;
        } else if (maxAmt > 0) {
          chartMaxY = math.max(maxAmt * 1.3, 50000.0);
        }

        if (!controller.isClosed) {
          controller.add(DailyTrendChartData(
            points: points,
            averageAmount: avgAmt,
            percentageChange: percentageChange,
            maxAmount: chartMaxY,
            totalCount: currentTxs.length,
          ));
        }
      } catch (e, st) {
        debugPrint('Error fetching daily trend chart: $e\n$st');
        if (!controller.isClosed) {
          controller.add(DailyTrendChartData.empty());
        }
      }
    }

    fetchAndEmit();

    final channel = client.channel('realtime:daily_trend_transactions_${filterParam?.hashCode ?? 'default'}');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'transactions',
      callback: (payload) {
        debugPrint('Realtime transaction event detected for trend chart: ${payload.eventType}');
        fetchAndEmit();
      },
    ).subscribe();

    ref.onDispose(() {
      channel.unsubscribe();
      controller.close();
    });

    return controller.stream;
  },
);


