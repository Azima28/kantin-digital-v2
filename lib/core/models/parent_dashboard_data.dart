import 'package:kantin_digital/core/models/user_profile.dart';
import 'package:kantin_digital/core/models/student.dart';
import 'package:kantin_digital/core/models/operator_transaction.dart';

/// Model gabungan untuk dashboard parent.
///
/// Berisi profile siswa, data student, dan daftar transaksi terbaru.
class ParentDashboardData {
  final UserProfile profile;
  final Student student;
  final List<OperatorTransaction> transactions;

  const ParentDashboardData({
    required this.profile,
    required this.student,
    this.transactions = const [],
  });

  /// Parse dari query parentDashboardProvider.
  factory ParentDashboardData.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile'];
    final studentData = json['student'];
    final txsData = json['transactions'] as List<dynamic>? ?? [];

    return ParentDashboardData(
      profile: profileData is Map<String, dynamic>
          ? UserProfile.fromJson(profileData)
          : const UserProfile(id: ''),
      student: studentData is Map<String, dynamic>
          ? Student.fromJson(studentData)
          : const Student(id: ''),
      transactions: txsData
          .map((e) => OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentDashboardData && profile.id == other.profile.id;

  @override
  int get hashCode => profile.id.hashCode;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'student': student.toJson(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
      };

  double get totalSpent => transactions
      .where((tx) => tx.isPurchase && tx.isSuccess)
      .fold(0.0, (sum, tx) => sum + tx.totalAmount);

  ParentDashboardData copyWith({
    UserProfile? profile,
    Student? student,
    List<OperatorTransaction>? transactions,
  }) {
    return ParentDashboardData(
      profile: profile ?? this.profile,
      student: student ?? this.student,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  String toString() =>
      'ParentDashboardData(student: ${profile.fullName}, balance: ${student.balance})';
}
