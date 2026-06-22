/// Data model untuk tabel `parent_students`.
///
/// Tabel penghubung relasi many-to-many antara orang tua (parent) dan siswa.
/// Primary key komposit: (parent_id, student_id).
class ParentStudent {
  final String parentId;
  final String studentId;
  final DateTime? createdAt;

  const ParentStudent({
    required this.parentId,
    required this.studentId,
    this.createdAt,
  });

  factory ParentStudent.fromJson(Map<String, dynamic> json) {
    return ParentStudent(
      parentId: json['parent_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        'student_id': studentId,
        'created_at': createdAt?.toIso8601String(),
      };

  ParentStudent copyWith({
    String? parentId,
    String? studentId,
    DateTime? createdAt,
  }) {
    return ParentStudent(
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ParentStudent(parent: $parentId, student: $studentId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentStudent &&
          parentId == other.parentId &&
          studentId == other.studentId;

  @override
  int get hashCode => Object.hash(parentId, studentId);
}
