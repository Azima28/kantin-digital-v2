import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/services/api_client.dart';

/// Universal Avatar Widget for Kantin Digital v2.0
///
/// Automatically displays high-quality role & gender-appropriate illustrated
/// avatar characters when no custom uploaded image is provided.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? role;
  final String? name;
  final String? gender;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.photoUrl,
    this.role,
    this.name,
    this.gender,
    this.radius = 20,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0.5,
    this.backgroundColor,
  });

  /// Inferred gender based on name or explicit gender string
  static bool isFemale({String? gender, String? name}) {
    if (gender != null && gender.trim().isNotEmpty) {
      final g = gender.trim().toLowerCase();
      if (g == 'p' || g == 'female' || g == 'perempuan' || g == 'f') return true;
      if (g == 'l' || g == 'male' || g == 'laki-laki' || g == 'm') return false;
    }

    if (name != null && name.trim().isNotEmpty) {
      final n = name.toLowerCase();
      final femaleKeywords = [
        'siti',
        'ani',
        'aminah',
        'putri',
        'nur',
        'dewi',
        'azima',
        'rina',
        'sarah',
        'ayu',
        'tri',
        'ibu',
        'mama',
        'bunda',
        'wati',
        'lestari',
        'rahayu',
        'safitri',
        'zahra',
        'aulia',
        'kartika',
        'maya',
        'dian',
        'fitri',
        'indah',
        'tiara',
      ];
      for (final kw in femaleKeywords) {
        if (n.contains(kw)) return true;
      }
    }
    return false;
  }

  /// Get the default illustrated asset path based on role and gender
  static String getIllustratedAssetPath({
    String? role,
    String? name,
    String? gender,
  }) {
    final cleanRole = (role ?? '').trim().toLowerCase();
    final bool female = isFemale(gender: gender, name: name);

    switch (cleanRole) {
      case 'petugas_kantin':
      case 'canteen':
      case 'operator':
      case 'merchant':
        return 'assets/images/avatars/avatar_canteen_male.png';

      case 'petugas_keuangan':
      case 'keuangan':
      case 'finance':
        return 'assets/images/avatars/avatar_finance.png';

      case 'super_admin':
      case 'admin':
        return 'assets/images/avatars/avatar_admin.png';

      case 'parent':
      case 'orang_tua':
      case 'orangtua':
        return female
            ? 'assets/images/avatars/avatar_parent_female.png'
            : 'assets/images/avatars/avatar_parent_male.png';

      case 'student':
      case 'siswa':
      default:
        return female
            ? 'assets/images/avatars/avatar_student_girl.png'
            : 'assets/images/avatars/avatar_student_boy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String resolvedAsset = getIllustratedAssetPath(
      role: role,
      name: name,
      gender: gender,
    );

    final String? validPhotoUrl = (photoUrl != null && photoUrl!.trim().isNotEmpty)
        ? ApiClient.resolveImageUrl(photoUrl)
        : null;

    final diameter = radius * 2;

    Widget avatarContent;

    if (validPhotoUrl != null && validPhotoUrl.isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: validPhotoUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          resolvedAsset,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          resolvedAsset,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
        ),
      );
    } else {
      avatarContent = Image.asset(
        resolvedAsset,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      );
    }

    Widget avatarWidget = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? const Color(0xFFF1F5F9),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
