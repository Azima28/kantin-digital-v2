/// Data model untuk master jurusan / program keahlian sekolah
class AcademicMajor {
  final String id;
  final String name;
  final String code;

  const AcademicMajor({
    required this.id,
    required this.name,
    required this.code,
  });

  factory AcademicMajor.fromJson(Map<String, dynamic> json) {
    return AcademicMajor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
      };

  AcademicMajor copyWith({
    String? id,
    String? name,
    String? code,
  }) {
    return AcademicMajor(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }
}

/// Data model untuk struktur jenjang, tingkat kelas, jurusan, dan rombel sekolah
class AcademicStructure {
  final String schoolType; // 'smk', 'sma', 'smp', 'sd', 'custom'
  final String schoolName;
  final bool hasMajors;
  final List<AcademicMajor> majors;
  final List<String> gradeLevels;
  final List<String> rombels;
  final DateTime? updatedAt;

  const AcademicStructure({
    this.schoolType = 'smk',
    this.schoolName = 'SMK Negeri 1',
    this.hasMajors = true,
    this.majors = const [
      AcademicMajor(id: 'rpl', name: 'Rekayasa Perangkat Lunak', code: 'RPL'),
      AcademicMajor(id: 'tkj', name: 'Teknik Komputer & Jaringan', code: 'TKJ'),
      AcademicMajor(id: 'dkv', name: 'Desain Komunikasi Visual', code: 'DKV'),
      AcademicMajor(id: 'akl', name: 'Akuntansi & Keuangan Lembaga', code: 'AKL'),
      AcademicMajor(id: 'otkp', name: 'Otomatisasi & Tata Kelola Perkantoran', code: 'OTKP'),
    ],
    this.gradeLevels = const ['X', 'XI', 'XII'],
    this.rombels = const [
      'X RPL 1', 'X RPL 2', 'X TKJ 1', 'X TKJ 2', 'X DKV 1', 'X AKL 1',
      'XI RPL 1', 'XI RPL 2', 'XI TKJ 1', 'XI TKJ 2', 'XI DKV 1', 'XI AKL 1',
      'XII RPL 1', 'XII RPL 2', 'XII TKJ 1', 'XII TKJ 2', 'XII DKV 1', 'XII AKL 1',
    ],
    this.updatedAt,
  });

  factory AcademicStructure.fromJson(Map<String, dynamic> json) {
    final rawMajors = json['majors'];
    List<AcademicMajor> parsedMajors = [];
    if (rawMajors is List) {
      parsedMajors = rawMajors
          .map((e) => AcademicMajor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final rawGrades = json['grade_levels'];
    List<String> parsedGrades = [];
    if (rawGrades is List) {
      parsedGrades = rawGrades.map((e) => e.toString()).toList();
    }

    final rawRombels = json['rombels'];
    List<String> parsedRombels = [];
    if (rawRombels is List) {
      parsedRombels = rawRombels.map((e) => e.toString()).toList();
    }

    return AcademicStructure(
      schoolType: json['school_type']?.toString() ?? 'smk',
      schoolName: json['school_name']?.toString() ?? 'Sekolah Digital',
      hasMajors: json['has_majors'] == true,
      majors: parsedMajors.isNotEmpty ? parsedMajors : const [],
      gradeLevels: parsedGrades.isNotEmpty ? parsedGrades : const ['X', 'XI', 'XII'],
      rombels: parsedRombels.isNotEmpty
          ? parsedRombels
          : const ['7-A', '7-B', '8-A', '8-B', '9-A', '9-B'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'school_type': schoolType,
        'school_name': schoolName,
        'has_majors': hasMajors,
        'majors': majors.map((e) => e.toJson()).toList(),
        'grade_levels': gradeLevels,
        'rombels': rombels,
      };

  AcademicStructure copyWith({
    String? schoolType,
    String? schoolName,
    bool? hasMajors,
    List<AcademicMajor>? majors,
    List<String>? gradeLevels,
    List<String>? rombels,
    DateTime? updatedAt,
  }) {
    return AcademicStructure(
      schoolType: schoolType ?? this.schoolType,
      schoolName: schoolName ?? this.schoolName,
      hasMajors: hasMajors ?? this.hasMajors,
      majors: majors ?? this.majors,
      gradeLevels: gradeLevels ?? this.gradeLevels,
      rombels: rombels ?? this.rombels,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
