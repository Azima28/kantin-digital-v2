import 'package:intl/intl.dart';

/// Data model untuk sesi shift kasir / closing shift berkelanjutan.
class CashierShift {
  final String id;
  final String officerId;
  final String? officerName;
  final int shiftNumber;
  final DateTime startedAt;
  final DateTime? closedAt;
  final int startingCash;
  final int totalInflow;
  final int totalOutflow;
  final int expectedCash;
  final int actualPhysicalCash;
  final int difference;
  final int topupCount;
  final int payoutCount;
  final String notes;
  final String status;
  final String? verifiedBy;
  final String? verifierName;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const CashierShift({
    required this.id,
    required this.officerId,
    this.officerName,
    required this.shiftNumber,
    required this.startedAt,
    this.closedAt,
    this.startingCash = 0,
    this.totalInflow = 0,
    this.totalOutflow = 0,
    required this.expectedCash,
    required this.actualPhysicalCash,
    required this.difference,
    this.topupCount = 0,
    this.payoutCount = 0,
    this.notes = '',
    this.status = 'closed',
    this.verifiedBy,
    this.verifierName,
    this.verifiedAt,
    required this.createdAt,
  });

  factory CashierShift.fromJson(Map<String, dynamic> json) {
    return CashierShift(
      id: json['id']?.toString() ?? '',
      officerId: json['officer_id']?.toString() ?? '',
      officerName: json['officer_name']?.toString() ?? json['full_name']?.toString(),
      shiftNumber: (json['shift_number'] as num?)?.toInt() ?? 1,
      startedAt: json['started_at'] != null
          ? (DateTime.tryParse(json['started_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'].toString())?.toLocal()
          : null,
      startingCash: (json['starting_cash'] as num?)?.toInt() ?? 0,
      totalInflow: (json['total_inflow'] as num?)?.toInt() ?? 0,
      totalOutflow: (json['total_outflow'] as num?)?.toInt() ?? 0,
      expectedCash: (json['expected_cash'] as num?)?.toInt() ?? 0,
      actualPhysicalCash: (json['actual_physical_cash'] as num?)?.toInt() ?? 0,
      difference: (json['difference'] as num?)?.toInt() ?? 0,
      topupCount: (json['topup_count'] as num?)?.toInt() ?? 0,
      payoutCount: (json['payout_count'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'closed',
      verifiedBy: json['verified_by']?.toString(),
      verifierName: json['verifier_name']?.toString(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  bool get isVerified => status == 'verified' || verifiedBy != null;
  bool get isBalanced => difference == 0;
  bool get isDeficit => difference < 0;
  bool get isSurplus => difference > 0;

  String get formattedStartedAt =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(startedAt);

  String get formattedClosedAt => closedAt != null
      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(closedAt!)
      : '-';
}

/// Ringkasan sesi shift yang sedang aktif berjalan
class CurrentShiftSummary {
  final String officerId;
  final String officerName;
  final int shiftNumber;
  final DateTime startedAt;
  final int totalInflow;
  final int totalOutflow;
  final int expectedCash;
  final int topupCount;
  final int payoutCount;
  final DateTime? lastClosedAt;

  const CurrentShiftSummary({
    required this.officerId,
    required this.officerName,
    required this.shiftNumber,
    required this.startedAt,
    required this.totalInflow,
    required this.totalOutflow,
    required this.expectedCash,
    required this.topupCount,
    required this.payoutCount,
    this.lastClosedAt,
  });

  factory CurrentShiftSummary.fromJson(Map<String, dynamic> json) {
    return CurrentShiftSummary(
      officerId: json['officer_id']?.toString() ?? '',
      officerName: json['officer_name']?.toString() ?? 'Petugas Keuangan',
      shiftNumber: (json['shift_number'] as num?)?.toInt() ?? 1,
      startedAt: json['started_at'] != null
          ? (DateTime.tryParse(json['started_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      totalInflow: (json['total_inflow'] as num?)?.toInt() ?? 0,
      totalOutflow: (json['total_outflow'] as num?)?.toInt() ?? 0,
      expectedCash: (json['expected_cash'] as num?)?.toInt() ?? 0,
      topupCount: (json['topup_count'] as num?)?.toInt() ?? 0,
      payoutCount: (json['payout_count'] as num?)?.toInt() ?? 0,
      lastClosedAt: json['last_closed_at'] != null
          ? DateTime.tryParse(json['last_closed_at'].toString())?.toLocal()
          : null,
    );
  }

  String get formattedStartedAt =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(startedAt);
}
