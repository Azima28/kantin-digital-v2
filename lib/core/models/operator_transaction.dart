import 'transaction_item.dart';

/// Model gabungan untuk transaksi operator/kasir (join dengan data terkait).
///
/// Digunakan di:
/// - `siswa_providers` (daftar transaksi siswa dengan nama kantin)
/// - `pos_providers` (riwayat transaksi operator dengan nama siswa)
class OperatorTransaction {
  final String id;
  final int totalAmount;
  final String? type;
  final String? status;
  final DateTime? createdAt;
  final String? studentId;
  final String? operatorId;

  /// Nested data dari join Supabase (opsional).
  final String? canteenName;
  final String? studentName;
  final String? studentNisn;
  final List<TransactionItem>? transactionItems;

  const OperatorTransaction({
    required this.id,
    this.totalAmount = 0,
    this.type,
    this.status,
    this.createdAt,
    this.studentId,
    this.operatorId,
    this.canteenName,
    this.studentName,
    this.studentNisn,
    this.transactionItems,
  });

  /// Parse dari query transaksi siswa:
  /// `transactions.select('id, student_id, operator_id, total_amount, type, status, created_at, canteen_operators(canteen_name)')`
  factory OperatorTransaction.fromSiswaJson(Map<String, dynamic> json) {
    final canteenData = json['canteen_operators'];
    String? canteenName;
    if (canteenData is Map<String, dynamic>) {
      canteenName = canteenData['canteen_name'] as String?;
    } else if (canteenData is List && canteenData.isNotEmpty) {
      canteenName = (canteenData.first as Map<String, dynamic>)['canteen_name'] as String?;
    }

    final txsItemsData = json['transaction_items'];
    List<TransactionItem>? transactionItems;
    if (txsItemsData is List) {
      transactionItems = txsItemsData
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return OperatorTransaction(
      id: json['id']?.toString() ?? '',
      totalAmount: int.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      type: json['type'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      studentId: json['student_id'] as String?,
      operatorId: json['operator_id'] as String?,
      canteenName: canteenName,
      transactionItems: transactionItems,
    );
  }

  /// Parse dari query transaksi operator POS:
  /// `transactions.select('id, total_amount, type, status, created_at, student_id, students(profiles:profiles!students_id_fkey(full_name))')`
  factory OperatorTransaction.fromOperatorJson(Map<String, dynamic> json) {
    String? studentName;
    String? studentNisn;
    final studentData = json['students'];
    if (studentData is Map<String, dynamic>) {
      final profilesData = studentData['profiles'];
      if (profilesData is Map<String, dynamic>) {
        studentName = profilesData['full_name'] as String?;
        studentNisn = profilesData['nisn'] as String?;
      }
    } else if (studentData is List && studentData.isNotEmpty) {
      final firstStudent = studentData.first as Map<String, dynamic>;
      final profilesData = firstStudent['profiles'];
      if (profilesData is Map<String, dynamic>) {
        studentName = profilesData['full_name'] as String?;
        studentNisn = profilesData['nisn'] as String?;
      } else if (profilesData is List && profilesData.isNotEmpty) {
        final firstProfile = profilesData.first as Map<String, dynamic>;
        studentName = firstProfile['full_name'] as String?;
        studentNisn = firstProfile['nisn'] as String?;
      }
    }

    return OperatorTransaction(
      id: json['id']?.toString() ?? '',
      totalAmount: int.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      type: json['type'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      studentId: json['student_id'] as String?,
      studentName: studentName,
      studentNisn: studentNisn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'total_amount': totalAmount,
        'type': type,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'student_id': studentId,
        'operator_id': operatorId,
      };

  bool get isPurchase => type == 'purchase';
  bool get isTopup => type == 'topup';
  bool get isSuccess => status == 'success';

  OperatorTransaction copyWith({
    String? id,
    int? totalAmount,
    String? type,
    String? status,
    DateTime? createdAt,
    String? studentId,
    String? operatorId,
    String? canteenName,
    String? studentName,
    String? studentNisn,
    List<TransactionItem>? transactionItems,
  }) {
    return OperatorTransaction(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      studentId: studentId ?? this.studentId,
      operatorId: operatorId ?? this.operatorId,
      canteenName: canteenName ?? this.canteenName,
      studentName: studentName ?? this.studentName,
      studentNisn: studentNisn ?? this.studentNisn,
      transactionItems: transactionItems ?? this.transactionItems,
    );
  }

  @override
  String toString() =>
      'OperatorTransaction(id: $id, amount: $totalAmount, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OperatorTransaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
