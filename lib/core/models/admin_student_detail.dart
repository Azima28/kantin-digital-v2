import 'package:kantin_digital/core/models/user_profile.dart';
import 'package:kantin_digital/core/models/student.dart';
import 'package:kantin_digital/core/models/operator_transaction.dart';

/// Model gabungan untuk detail siswa di panel admin super admin.
///
/// Berisi profile, data student, dan transaksi terbaru siswa.
class AdminStudentDetail {
  final UserProfile profile;
  final Student student;
  final List<OperatorTransaction> recentTransactions;

  const AdminStudentDetail({
    required this.profile,
    required this.student,
    this.recentTransactions = const [],
  });

  /// Parse dari query admin_student_detail_provider.
  factory AdminStudentDetail.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile'];
    final studentData = json['student'];
    final txsData = json['transactions'] as List<dynamic>? ?? [];

    return AdminStudentDetail(
      profile: profileData is Map<String, dynamic>
          ? UserProfile.fromJson(profileData)
          : const UserProfile(id: ''),
      student: studentData is Map<String, dynamic>
          ? Student.fromJson(studentData)
          : const Student(id: ''),
      recentTransactions: txsData
          .map((e) => OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminStudentDetail && profile.id == other.profile.id;

  @override
  int get hashCode => profile.id.hashCode;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'student': student.toJson(),
        'transactions': recentTransactions.map((e) => e.toJson()).toList(),
      };

  AdminStudentDetail copyWith({
    UserProfile? profile,
    Student? student,
    List<OperatorTransaction>? recentTransactions,
  }) {
    return AdminStudentDetail(
      profile: profile ?? this.profile,
      student: student ?? this.student,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }

  @override
  String toString() =>
      'AdminStudentDetail(name: ${profile.fullName}, balance: ${student.balance})';
}
