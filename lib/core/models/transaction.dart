/// Data model untuk tabel `transactions`.
///
/// Mencatat semua transaksi keuangan kantin (purchase / topup).
class Transaction {
  final String id;
  final String studentId;
  final String operatorId;
  final String status;
  final int totalAmount;
  final String type; // 'purchase' or 'topup'
  final DateTime createdAt;

  /// Nested objects dari join Supabase (opsional).
  final Map<String, dynamic>? operator;
  final Map<String, dynamic>? student;

  const Transaction({
    required this.id,
    required this.studentId,
    required this.operatorId,
    required this.status,
    required this.totalAmount,
    required this.type,
    required this.createdAt,
    this.operator,
    this.student,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      operatorId: json['operator_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: int.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      type: json['type'] as String,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      operator: json['operator'] as Map<String, dynamic>?,
      student: json['student'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'operator_id': operatorId,
        'status': status,
        'total_amount': totalAmount,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  Transaction copyWith({
    String? id,
    String? studentId,
    String? operatorId,
    String? status,
    int? totalAmount,
    String? type,
    DateTime? createdAt,
    Map<String, dynamic>? operator,
    Map<String, dynamic>? student,
  }) {
    return Transaction(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      operatorId: operatorId ?? this.operatorId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      operator: operator ?? this.operator,
      student: student ?? this.student,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get isPurchase => type == 'purchase';
  bool get isTopup => type == 'topup';
  bool get isSuccess => status == 'success';

  // ---------------------------------------------------------------------------
  // Operator / student display helpers (when joined data is available)
  // ---------------------------------------------------------------------------

  /// Nama operator dari join data.
  String get operatorName {
    if (operator != null) {
      return operator!['name'] as String? ?? '-';
    }
    return '-';
  }

  /// Nama siswa dari join data.
  String get studentName {
    if (student != null) {
      return student!['full_name'] as String? ?? '-';
    }
    return '-';
  }

  // ---------------------------------------------------------------------------
  // Equality & debugging
  // ---------------------------------------------------------------------------

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, status: $status, totalAmount: $totalAmount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Transaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
