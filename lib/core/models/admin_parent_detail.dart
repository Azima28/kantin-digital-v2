import 'package:kantin_digital/core/models/user_profile.dart';

/// Model gabungan untuk detail orang tua di panel admin.
///
/// Berisi profile parent dan data anak-anak yang terhubung.
class AdminParentDetail {
  final UserProfile profile;
  final List<Map<String, dynamic>> children;

  const AdminParentDetail({
    required this.profile,
    this.children = const [],
  });

  /// Parse dari query admin_parent_detail_provider.
  factory AdminParentDetail.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile'];
    final childrenData = json['children'] as List<dynamic>? ?? [];

    return AdminParentDetail(
      profile: profileData is Map<String, dynamic>
          ? UserProfile.fromJson(profileData)
          : const UserProfile(id: ''),
      children: childrenData
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  int get childCount => children.length;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'children': children,
      };

  AdminParentDetail copyWith({
    UserProfile? profile,
    List<Map<String, dynamic>>? children,
  }) {
    return AdminParentDetail(
      profile: profile ?? this.profile,
      children: children ?? this.children,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminParentDetail && profile.id == other.profile.id;

  @override
  int get hashCode => profile.id.hashCode;

  @override
  String toString() =>
      'AdminParentDetail(name: ${profile.fullName}, children: $childCount)';
}
