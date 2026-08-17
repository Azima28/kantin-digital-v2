import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ============================================================================
// DASHBOARD PROVIDER (Keuangan)
// ============================================================================

final keuanganDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      ref.keepAlive();
      final profile = ref.read(authNotifierProvider).profile;
      final officerId = profile?['id'];
      final school = profile?['assigned_school'] ?? '';

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

      return {
        'profile': profile,
        'school': school,
        'totalSaldo': 0,
        'topupToday': 0,
        'topupCount': 0,
        'koreksCount': 0,
        'koreksNet': 0,
        'recentLogs': <Map<String, dynamic>>[],
      };
    });

// ============================================================================
// HISTORY PROVIDER (Keuangan)
// ============================================================================

final keuanganHistoryProvider =
    FutureProvider.autoDispose<List<AuditLog>>((ref) async {
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
      ref.keepAlive();
      return <StudentWithProfile>[];
    });

// ============================================================================
// STUDENT DETAIL PROVIDER
// ============================================================================

final keuanganStudentDetailProvider = FutureProvider
    .family<AdminStudentDetail, String>((ref, id) async {
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
      ref.keepAlive();
      return <Map<String, dynamic>>[];
    });

final keuanganStaffProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      ref.keepAlive();
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
