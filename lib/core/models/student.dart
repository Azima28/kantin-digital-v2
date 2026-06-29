/// Data model untuk tabel `students`.
///
/// Berisi data akademik dan saldo kantin siswa.
/// Selalu ter-asosiasi dengan [UserProfile] melalui field [id].
class Student {
  final String id;
  final String? classId;
  final String? rombelId;
  final String? class_;
  final int balance;
  final String? rfidUid;
  final double? dailyLimit;
  final bool isActive;
  final bool waNotificationsEnabled;
  final String? parentPhone;

  const Student({
    required this.id,
    this.classId,
    this.rombelId,
    this.class_,
    this.balance = 0,
    this.rfidUid,
    this.dailyLimit,
    this.isActive = true,
    this.waNotificationsEnabled = true,
    this.parentPhone,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final classesData = json['classes'];
    final rombelsData = json['rombels'];
    
    String? className = json['class'] as String?;
    if (className == null && classesData is Map) {
      className = classesData['name'] as String?;
    } else if (className == null && classesData is List && classesData.isNotEmpty) {
      className = classesData.first['name'] as String?;
    }

    String? rombelName;
    if (rombelsData is Map) {
      rombelName = rombelsData['name'] as String?;
    } else if (rombelsData is List && rombelsData.isNotEmpty) {
      rombelName = rombelsData.first['name'] as String?;
    }

    String? classStr = className;
    if (className != null && rombelName != null && rombelName != '-') {
      classStr = '$className-$rombelName';
    }

    return Student(
      id: json['id'] as String,
      classId: json['class_id'] as String?,
      rombelId: json['rombel_id'] as String?,
      class_: classStr,
      balance: (double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0).toInt(),
      rfidUid: json['rfid_uid'] as String?,
      dailyLimit: json['daily_limit'] != null
          ? double.tryParse(json['daily_limit'].toString())
          : null,
      isActive: json['is_active'] == true,
      waNotificationsEnabled: json['wa_notifications_enabled'] == true,
      parentPhone: json['parent_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'rombel_id': rombelId,
        'class': class_,
        'balance': balance,
        'rfid_uid': rfidUid,
        'daily_limit': dailyLimit,
        'is_active': isActive,
        'wa_notifications_enabled': waNotificationsEnabled,
        'parent_phone': parentPhone,
      };

  Student copyWith({
    String? id,
    String? classId,
    String? rombelId,
    String? class_,
    int? balance,
    String? rfidUid,
    double? dailyLimit,
    bool? isActive,
    bool? waNotificationsEnabled,
    String? parentPhone,
  }) {
    return Student(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      rombelId: rombelId ?? this.rombelId,
      class_: class_ ?? this.class_,
      balance: balance ?? this.balance,
      rfidUid: rfidUid ?? this.rfidUid,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      isActive: isActive ?? this.isActive,
      waNotificationsEnabled: waNotificationsEnabled ?? this.waNotificationsEnabled,
      parentPhone: parentPhone ?? this.parentPhone,
    );
  }

  bool get hasRfid => rfidUid != null && rfidUid!.isNotEmpty;
  bool get isLowBalance => balance < 5000;

  @override
  String toString() => 'Student(id: $id, class: $class_, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Student && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model gabungan untuk query student + profile (join).
class StudentWithProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? nisn;
  final bool isActive;
  final String? classId;
  final String? rombelId;
  final String? class_;
  final int balance;
  final String? rfidUid;
  final bool cardIsActive;

  const StudentWithProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.nisn,
    this.isActive = true,
    this.classId,
    this.rombelId,
    this.class_,
    this.balance = 0,
    this.rfidUid,
    this.cardIsActive = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentWithProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          balance == other.balance;

  @override
  int get hashCode => Object.hash(id, fullName, balance);

  StudentWithProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? nisn,
    bool? isActive,
    String? classId,
    String? rombelId,
    String? class_,
    int? balance,
    String? rfidUid,
    bool? cardIsActive,
  }) {
    return StudentWithProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      nisn: nisn ?? this.nisn,
      isActive: isActive ?? this.isActive,
      classId: classId ?? this.classId,
      rombelId: rombelId ?? this.rombelId,
      class_: class_ ?? this.class_,
      balance: balance ?? this.balance,
      rfidUid: rfidUid ?? this.rfidUid,
      cardIsActive: cardIsActive ?? this.cardIsActive,
    );
  }

  /// Parse dari query Supabase:
  /// `profiles.select('id, full_name, email, nisn, is_active, students:students!students_id_fkey(class_id, rombel_id, balance, rfid_uid, is_active, classes:classes(name), rombels:rombels(name))')`
  factory StudentWithProfile.fromJoinedJson(Map<String, dynamic> json) {
    final studentData = json['students'] is List
        ? (json['students'] as List).firstOrNull as Map<String, dynamic>?
        : json['students'] as Map<String, dynamic>?;

    final classesData = studentData?['classes'];
    final rombelsData = studentData?['rombels'];
    
    String? className = studentData?['class'] as String?;
    if (className == null && classesData is Map) {
      className = classesData['name'] as String?;
    } else if (className == null && classesData is List && classesData.isNotEmpty) {
      className = classesData.first['name'] as String?;
    }

    String? rombelName;
    if (rombelsData is Map) {
      rombelName = rombelsData['name'] as String?;
    } else if (rombelsData is List && rombelsData.isNotEmpty) {
      rombelName = rombelsData.first['name'] as String?;
    }

    String? fullClass = className;
    if (className != null && rombelName != null && rombelName != '-') {
      fullClass = '$className-$rombelName';
    }

    return StudentWithProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] ?? 'Siswa') as String,
      email: json['email'] as String?,
      nisn: json['nisn'] as String?,
      isActive: json['is_active'] == true,
      classId: studentData?['class_id'] as String?,
      rombelId: studentData?['rombel_id'] as String?,
      class_: fullClass,
      balance:
          (double.tryParse(studentData?['balance']?.toString() ?? '0') ?? 0.0).toInt(),
      rfidUid: studentData?['rfid_uid'] as String?,
      cardIsActive: studentData?['is_active'] == true,
    );
  }

  bool get hasRfid => rfidUid != null && rfidUid!.isNotEmpty;
  bool get isLowBalance => balance < 5000;

  @override
  String toString() =>
      'StudentWithProfile(id: $id, name: $fullName, class: $class_)';
}
