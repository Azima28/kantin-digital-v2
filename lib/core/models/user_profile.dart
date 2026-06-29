/// Data model untuk tabel `profiles`.
///
/// Merepresentasikan semua pengguna sistem (siswa, admin keuangan, kantin).
class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  final String? username;
  final String? phoneNumber;
  final String? nisn;
  final String? password;
  final String? avatarUrl;
  final String? relation;
  final String? role;
  final bool? isActive;
  final DateTime? createdAt;

  /// Joined fields from canteen_operators table.
  final String? canteenName;
  final int? balanceEarned;

  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.username,
    this.phoneNumber,
    this.nisn,
    this.password,
    this.avatarUrl,
    this.relation,
    this.role,
    this.isActive,
    this.createdAt,
    this.canteenName,
    this.balanceEarned,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final canteenData = json['canteen_operators'];
    Map<String, dynamic>? canteenMap;
    if (canteenData is Map<String, dynamic>) {
      canteenMap = canteenData;
    } else if (canteenData is List && canteenData.isNotEmpty) {
      canteenMap = canteenData.first as Map<String, dynamic>;
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      phoneNumber: json['phone_number'] as String?,
      nisn: json['nisn'] as String?,
      password: json['password'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      relation: json['relation'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool?,
      canteenName: canteenMap?['canteen_name'] as String?,
      balanceEarned: (canteenMap?['balance_earned'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'username': username,
        'phone_number': phoneNumber,
        'nisn': nisn,
        // 'password': password, // REMOVED: never send password back to DB
        'avatar_url': avatarUrl,
        'relation': relation,
        'role': role,
        'is_active': isActive,
        'canteen_name': canteenName,
        'balance_earned': balanceEarned,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Membuat salinan dengan field yang diubah.
  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? nisn,
    String? password,
    String? avatarUrl,
    String? relation,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    String? canteenName,
    int? balanceEarned,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nisn: nisn ?? this.nisn,
      password: password ?? this.password,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      relation: relation ?? this.relation,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      canteenName: canteenName ?? this.canteenName,
      balanceEarned: balanceEarned ?? this.balanceEarned,
    );
  }

  bool get isStudent => role == 'student';
  bool get isKeuangan => role == 'keuangan';
  bool get isCanteen => role == 'canteen';

  @override
  String toString() => 'UserProfile(id: $id, name: $fullName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserProfile && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
