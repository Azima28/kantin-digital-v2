/// Data model untuk tabel `finance_officers`.
///
/// Merepresentasikan data petugas keuangan yang ditugaskan di sekolah.
class FinanceOfficer {
  final String id;
  final String assignedSchool;
  final String authorityLevel;
  final List<String> features;
  final DateTime? createdAt;

  const FinanceOfficer({
    required this.id,
    required this.assignedSchool,
    required this.authorityLevel,
    this.features = const [],
    this.createdAt,
  });

  factory FinanceOfficer.fromJson(Map<String, dynamic> json) {
    return FinanceOfficer(
      id: json['id'] as String,
      assignedSchool: json['assigned_school']?.toString() ?? '',
      authorityLevel: json['authority_level']?.toString() ?? '',
      features: json['features'] is List
          ? List<String>.from(json['features'].map((e) => e.toString()))
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assigned_school': assignedSchool,
        'authority_level': authorityLevel,
        'features': features,
        'created_at': createdAt?.toIso8601String(),
      };

  FinanceOfficer copyWith({
    String? id,
    String? assignedSchool,
    String? authorityLevel,
    List<String>? features,
    DateTime? createdAt,
  }) {
    return FinanceOfficer(
      id: id ?? this.id,
      assignedSchool: assignedSchool ?? this.assignedSchool,
      authorityLevel: authorityLevel ?? this.authorityLevel,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isL1 => authorityLevel == 'L1';
  bool get isL2 => authorityLevel == 'L2';
  bool get isL3 => authorityLevel == 'L3';

  @override
  String toString() =>
      'FinanceOfficer(id: $id, school: $assignedSchool, level: $authorityLevel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FinanceOfficer && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
