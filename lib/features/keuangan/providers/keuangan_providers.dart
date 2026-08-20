import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ============================================================================
// DASHBOARD PROVIDER (Keuangan)
// ============================================================================

final keuanganDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.cacheFor(const Duration(minutes: 2));
  final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
  final apiClient = ref.watch(apiClientProvider);

  try {
    final res = await apiClient.get('/finance/dashboard');
    if (res.success && res.data != null) {
      final data = Map<String, dynamic>.from(res.data as Map);
      final rawRecent = data['recent_transactions'];
      final List<Map<String, dynamic>> parsedLogs = [];
      if (rawRecent is List) {
        for (final item in rawRecent) {
          if (item is Map) {
            parsedLogs.add(Map<String, dynamic>.from(item));
          }
        }
      }

      return {
        'profile': profile,
        'school': profile?['assigned_school']?.toString() ?? 'Sekolah Digital',
        'totalSaldo': data['total_circulating_balance'] ?? 0,
        'topupToday': data['topup_today_amount'] ?? 0,
        'topupCount': data['topup_today_count'] ?? 0,
        'recentLogs': parsedLogs,
      };
    }
  } catch (e) {
    debugPrint('keuanganDashboardProvider error: $e');
  }

  return {
    'profile': profile,
    'school': profile?['assigned_school']?.toString() ?? 'Sekolah Digital',
    'totalSaldo': 0,
    'topupToday': 0,
    'topupCount': 0,
    'recentLogs': <Map<String, dynamic>>[],
  };
});

// ============================================================================
// HISTORY PROVIDER (Keuangan)
// ============================================================================

final keuanganHistoryProvider =
    FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  ref.cacheFor(const Duration(minutes: 2));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/audit-logs', queryParams: {'limit': '100'});
    if (res.success && res.data != null) {
      final list = res.data as List<dynamic>;
      return list.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('keuanganHistoryProvider error: $e');
  }
  return <AuditLog>[];
});

// ============================================================================
// REPORT PROVIDER (Keuangan)
// ============================================================================

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

final keuanganReportProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, ReportFilterParam>(
  (ref, param) async {
    ref.cacheFor(const Duration(minutes: 3));
    final apiClient = ref.watch(apiClientProvider);
    try {
      final res = await apiClient.get('/finance/report', queryParams: {
        'start_date': param.startDate.toIso8601String(),
        'end_date': param.endDate.toIso8601String(),
      });
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        return {
          'canteens': data['canteens'] ?? [],
          'totalTopup': data['total_topup'] ?? 0,
          'totalPurchase': data['total_purchase'] ?? 0,
          'totalCorrection': data['total_correction'] ?? 0,
          'totalWithdrawal': data['total_withdrawal'] ?? 0,
          'topupCount': data['topup_count'] ?? 0,
          'purchaseCount': data['purchase_count'] ?? 0,
          'withdrawalCount': data['withdrawal_count'] ?? 0,
          'totalUnpaidMerchantEarn': data['total_unpaid_merchant_earn'] ?? 0,
          'totalCirculatingFloat': data['total_circulating_float'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('keuanganReportProvider error: $e');
    }
    return {
      'canteens': <Map<String, dynamic>>[],
      'totalTopup': 0,
      'totalPurchase': 0,
      'totalCorrection': 0,
      'topupCount': 0,
      'purchaseCount': 0,
    };
  },
);

// ============================================================================
// STUDENTS PROVIDER (Keuangan)
// ============================================================================

final keuanganStudentsProvider =
    FutureProvider<List<StudentWithProfile>>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/finance/students');
    if (res.success && res.data != null) {
      final list = res.data as List<dynamic>;
      return list.map((e) => StudentWithProfile.fromApiJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('keuanganStudentsProvider error: $e');
  }
  return <StudentWithProfile>[];
});

// ============================================================================
// STUDENT DETAIL PROVIDER
// ============================================================================

final keuanganStudentDetailProvider = FutureProvider
    .family<AdminStudentDetail, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/student/$id');
    if (res.success && res.data != null) {
      return AdminStudentDetail.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('keuanganStudentDetailProvider error: $e');
  }
  return AdminStudentDetail.fromJson({
    'profile': <String, dynamic>{},
    'student': <String, dynamic>{},
    'transactions': <dynamic>[],
  });
});

// ============================================================================
// USERS PROVIDERS (Keuangan)
// ============================================================================

final keuanganParentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/users', queryParams: {'role': 'parent'});
    if (res.success && res.data != null) {
      final list = res.data as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
  } catch (e) {
    debugPrint('keuanganParentsProvider error: $e');
  }
  return <Map<String, dynamic>>[];
});

final keuanganStaffProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/users');
    if (res.success && res.data != null) {
      final list = res.data as List<dynamic>;
      return list
          .map((e) => e as Map<String, dynamic>)
          .where((u) => u['role'] != 'student' && u['role'] != 'parent')
          .toList();
    }
  } catch (e) {
    debugPrint('keuanganStaffProvider error: $e');
  }
  return <Map<String, dynamic>>[];
});

// ============================================================================
// REALTIME DAILY TREND CHART PROVIDER
// ============================================================================

class DailyTrendPoint {
  final String dayLabel;
  final String fullDayName;
  final double amount;
  final String displayShort;
  final DateTime date;

  const DailyTrendPoint({
    required this.dayLabel,
    required this.fullDayName,
    required this.amount,
    required this.displayShort,
    required this.date,
  });
}

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
      maxAmount: 100000.0,
      totalCount: 0,
    );
  }
}

final dailyTrendChartProvider =
    FutureProvider.autoDispose<DailyTrendChartData>((ref) async {
  return DailyTrendChartData.empty();
});

// ============================================================================
// CONTINUOUS SHIFT LEDGER PROVIDERS (Keuangan)
// ============================================================================

final keuanganCurrentShiftProvider =
    FutureProvider.autoDispose<CurrentShiftSummary>((ref) async {
  ref.cacheFor(const Duration(seconds: 30));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/finance/shift/current');
    if (res.success && res.data != null) {
      return CurrentShiftSummary.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
  } catch (e) {
    debugPrint('keuanganCurrentShiftProvider error: $e');
  }
  return CurrentShiftSummary(
    officerId: '',
    officerName: 'Petugas Keuangan',
    shiftNumber: 1,
    startedAt: DateTime.now(),
    totalInflow: 0,
    totalOutflow: 0,
    expectedCash: 0,
    topupCount: 0,
    payoutCount: 0,
  );
});

final keuanganShiftHistoryProvider =
    FutureProvider.autoDispose<List<CashierShift>>((ref) async {
  ref.cacheFor(const Duration(minutes: 1));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/finance/shift/history');
    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final list = data['shifts'] as List<dynamic>? ?? [];
      return list.map((e) => CashierShift.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
  } catch (e) {
    debugPrint('keuanganShiftHistoryProvider error: $e');
  }
  return <CashierShift>[];
});

