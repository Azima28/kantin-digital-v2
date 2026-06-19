/// Data model untuk tabel `students`.
///
/// Berisi data akademik dan saldo kantin siswa.
/// Selalu ter-asosiasi dengan [UserProfile] melalui field [id].
class Student {
  final String id;
  final String? class_;
  final double balance;
  final String? rfidUid;
  final double? dailyLimit;
  final bool isActive;
  final DateTime? lastTopupAt;
  final DateTime? createdAt;
  final bool waNotificationsEnabled;
  final String? parentPhone;

  const Student({
    required this.id,
    this.class_,
    this.balance = 0.0,
    this.rfidUid,
    this.dailyLimit,
    this.isActive = true,
    this.lastTopupAt,
    this.createdAt,
    this.waNotificationsEnabled = true,
    this.parentPhone,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      class_: json['class'] as String?,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      rfidUid: json['rfid_uid'] as String?,
      dailyLimit: json['daily_limit'] != null
          ? double.tryParse(json['daily_limit'].toString())
          : null,
      isActive: json['is_active'] == true,
      lastTopupAt: json['last_topup_at'] != null
          ? DateTime.tryParse(json['last_topup_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      waNotificationsEnabled: json['wa_notifications_enabled'] == true,
      parentPhone: json['parent_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class': class_,
        'balance': balance,
        'rfid_uid': rfidUid,
        'daily_limit': dailyLimit,
        'is_active': isActive,
        'last_topup_at': lastTopupAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'wa_notifications_enabled': waNotificationsEnabled,
        'parent_phone': parentPhone,
      };

  Student copyWith({
    String? id,
    String? class_,
    double? balance,
    String? rfidUid,
    double? dailyLimit,
    bool? isActive,
    DateTime? lastTopupAt,
    DateTime? createdAt,
    bool? waNotificationsEnabled,
    String? parentPhone,
  }) {
    return Student(
      id: id ?? this.id,
      class_: class_ ?? this.class_,
      balance: balance ?? this.balance,
      rfidUid: rfidUid ?? this.rfidUid,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      isActive: isActive ?? this.isActive,
      lastTopupAt: lastTopupAt ?? this.lastTopupAt,
      createdAt: createdAt ?? this.createdAt,
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
  final String? class_;
  final double balance;
  final String? rfidUid;
  final bool cardIsActive;

  const StudentWithProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.nisn,
    this.isActive = true,
    this.class_,
    this.balance = 0.0,
    this.rfidUid,
    this.cardIsActive = true,
  });

  /// Parse dari query Supabase:
  /// `profiles.select('id, full_name, email, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid, is_active)')`
  factory StudentWithProfile.fromJoinedJson(Map<String, dynamic> json) {
    final studentData = json['students'] is List
        ? (json['students'] as List).firstOrNull as Map<String, dynamic>?
        : json['students'] as Map<String, dynamic>?;

    return StudentWithProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] ?? 'Siswa') as String,
      email: json['email'] as String?,
      nisn: json['nisn'] as String?,
      isActive: json['is_active'] == true,
      class_: studentData?['class'] as String?,
      balance:
          double.tryParse(studentData?['balance']?.toString() ?? '0') ?? 0.0,
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
