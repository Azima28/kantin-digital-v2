/// Data model untuk tabel `students`.
///
/// Berisi data akademik dan saldo kantin siswa.
/// Selalu ter-asosiasi dengan [UserProfile] melalui field [id].
class Student {
  final String id;
  final String? class_;
  final int balance;
  final String? rfidUid;
  final double? dailyLimit;
  final bool isActive;
  final bool waNotificationsEnabled;
  final String? parentPhone;

  const Student({
    required this.id,
    this.class_,
    this.balance = 0,
    this.rfidUid,
    this.dailyLimit,
    this.isActive = true,
    this.waNotificationsEnabled = true,
    this.parentPhone,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      class_: json['class']?.toString() ??
          (json['classes'] is Map ? (json['classes'] as Map)['name']?.toString() : null),
      balance: _parseBalance(json['balance']),
      rfidUid: json['rfid_uid']?.toString(),
      dailyLimit: json['daily_limit'] != null
          ? double.tryParse(json['daily_limit'].toString())
          : null,
      isActive: json['is_active'] == true,
      waNotificationsEnabled: json['wa_notifications_enabled'] == true,
      parentPhone: json['parent_phone']?.toString(),
    );
  }

  static int _parseBalance(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return (double.tryParse(value?.toString() ?? '0') ?? 0.0).toInt();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
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
      class_: class_ ?? this.class_,
      balance: balance ?? this.balance,
      rfidUid: rfidUid ?? this.rfidUid,
      cardIsActive: cardIsActive ?? this.cardIsActive,
    );
  }

  /// Parse dari response REST API /finance/students atau /student/lookup:
  factory StudentWithProfile.fromApiJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;
    final bool isAccountActive = (profile['is_active'] ?? json['is_active']) == true;
    final bool isCardActive = json.containsKey('is_active')
        ? json['is_active'] == true
        : (profile['is_active'] == true);

    return StudentWithProfile(
      id: (json['id'] ?? profile['id'])?.toString() ?? '',
      fullName: (profile['full_name'] ?? json['full_name'] ?? 'Siswa').toString(),
      email: (profile['email'] ?? json['email'])?.toString(),
      nisn: (profile['nisn'] ?? json['nisn'])?.toString(),
      isActive: isAccountActive,
      class_: (json['class'] ?? profile['class'] ?? json['rombel'])?.toString(),
      balance: Student._parseBalance(json['balance'] ?? profile['balance']),
      rfidUid: (json['rfid_uid'] ?? profile['rfid_uid'])?.toString(),
      cardIsActive: isCardActive,
    );
  }

  /// Parse dari response data join student + profile:
  factory StudentWithProfile.fromJoinedJson(Map<String, dynamic> json) {
    if (json.containsKey('profile') || json.containsKey('balance')) {
      return StudentWithProfile.fromApiJson(json);
    }
    final studentData = json['students'] is List
        ? (json['students'] as List).firstOrNull as Map<String, dynamic>?
        : json['students'] as Map<String, dynamic>?;

    return StudentWithProfile(
      id: json['id']?.toString() ?? '',
      fullName: (json['full_name'] ?? 'Siswa').toString(),
      email: json['email']?.toString(),
      nisn: json['nisn']?.toString(),
      isActive: json['is_active'] == true,
      class_: (studentData?['class'] ??
          (studentData?['classes'] is Map
              ? (studentData?['classes'] as Map)['name']
              : null))?.toString(),
      balance:
          (double.tryParse(studentData?['balance']?.toString() ?? '0') ?? 0.0).toInt(),
      rfidUid: studentData?['rfid_uid']?.toString(),
      cardIsActive: studentData?['is_active'] == true,
    );
  }

  bool get hasRfid => rfidUid != null && rfidUid!.trim().isNotEmpty;
  bool get isCardBlocked => hasRfid && !cardIsActive;
  bool get isAccountBlocked => !isActive;
  bool get isLowBalance => balance < 5000;

  @override
  String toString() =>
      'StudentWithProfile(id: $id, name: $fullName, class: $class_)';
}
