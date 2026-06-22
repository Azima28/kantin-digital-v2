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
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
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
