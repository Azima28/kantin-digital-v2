import re, os, sys

# Mapping of hex colors to AppColors constants
COLOR_MAP = {
    '0xFF0E8A8A': 'AppColors.primary',
    '0xFF003434': 'AppColors.darkTeal',
    '0xFF006767': 'AppColors.teal',
    '0xFF008282': 'AppColors.primary',
    '0xFFB2DFDF': 'AppColors.softTeal',
    '0xFFE6F2F2': 'AppColors.primaryLight',
    '0xFF72D6D6': 'AppColors.softTeal',
    '0xFF006A35': 'AppColors.successGreen',
    '0xFFE8F5E9': 'AppColors.successGreenLight',
    '0xFF34C759': 'AppColors.success',
    '0xFFBA1A1A': 'AppColors.errorRed2',
    '0xFFFF3B30': 'AppColors.errorRed',
    '0xFFFFEBEE': 'AppColors.errorRedLight',
    '0xFF93000A': 'AppColors.errorDark',
    '0xFFFF9500': 'AppColors.accentOrange',
    '0xFFFFF2E0': 'AppColors.accentOrangeLight',
    '0xFFFCA558': 'AppColors.accentOrange2',
    '0xFFFFF3E8': 'AppColors.softOrange',
    '0xFFFFF3E0': 'AppColors.softOrange',
    '0xFF904D00': 'AppColors.darkOrange',
    '0xFF1A1C1F': 'AppColors.textDark',
    '0xFF1A1D1E': 'AppColors.textPrimary',
    '0xFF6F7978': 'AppColors.mutedGray',
    '0xFF8E8E93': 'AppColors.textGray',
    '0xFF1B1C1B': 'AppColors.nearBlack',
    '0xFF1C1C1E': 'AppColors.textDark',
    '0xFF3D4949': 'AppColors.darkGray',
    '0xFF3F4848': 'AppColors.darkGray',
    '0xFF49454F': 'AppColors.onSurfaceVariant',
    '0xFFF2F2F7': 'AppColors.systemBackground',
    '0xFFF5F5F5': 'AppColors.scaffoldBackground',
    '0xFFF8F9FA': 'AppColors.surfaceContainer',
    '0xFFF0F0F0': 'AppColors.surfaceContainerLow',
    '0xFFFBF9F8': 'AppColors.offWhite',
    '0xFFF5F3F2': 'AppColors.offWhite2',
    '0xFFF6F3F2': 'AppColors.offWhite2',
    '0xFFF0EDED': 'AppColors.offWhite2',
    '0xFFF9F9FE': 'AppColors.systemBackground',
    '0xFF9E9E9E': 'AppColors.gray',
    '0xFFE0E0E0': 'AppColors.grayLight',
    '0xFFBFC8C8': 'AppColors.gray400',
    '0xFFE5E5EA': 'AppColors.borderLight',
    '0xFFE4E2E1': 'AppColors.borderGray',
    '0xFFE8E8E8': 'AppColors.borderLight',
    '0xFFD1D1D6': 'AppColors.borderLight',
    '0xFFC7C7CC': 'AppColors.textGray',
    '0xFFCAC4D0': 'AppColors.outlineVariant',
    '0xFF7A7A7A': 'AppColors.textGray',
    '0xFFBDC9C8': 'AppColors.gray400',
    '0xFFE9E9EB': 'AppColors.grayLight',
    '0xFFE2E2E7': 'AppColors.grayLight',
    '0xFFEAEAEA': 'AppColors.grayLight',
    '0xFFFFFFFF': 'AppColors.white',
    '0xFF000000': 'AppColors.black',
    '0xFFFFB300': 'AppColors.accentOrange',
    '0xFFFEF5E7': 'AppColors.softOrange',
    '0xFFD35400': 'AppColors.darkOrange',
    '0xFF2ECC71': 'AppColors.success',
    '0xFFEBFDF2': 'AppColors.successLight',
    '0xFF15803D': 'AppColors.successDark',
    '0xFF3498DB': 'AppColors.primary',
    '0xFFEFF6FF': 'AppColors.primaryLight',
    '0xFF1D4ED8': 'AppColors.primary',
    '0xFF4A4A4A': 'AppColors.textDark',
    '0xFF3A3A3C': 'AppColors.textDark',
    '0xFF1B1C1C': 'AppColors.nearBlack',
    '0xFF8FF3F2': 'AppColors.softTeal',
    '0xFF7EFBA4': 'AppColors.success',
    '0xFFFFDCC3': 'AppColors.softOrange',
}

FILES = [
    'lib/features/siswa/screens/siswa_dashboard_screen.dart',
    'lib/features/siswa/screens/siswa_history_screen.dart',
    'lib/features/siswa/screens/siswa_cards_screen.dart',
    'lib/features/siswa/screens/siswa_topup_screen.dart',
    'lib/features/siswa/screens/siswa_notifications_screen.dart',
    'lib/features/siswa/screens/siswa_profile_screen.dart',
    'lib/features/siswa/screens/student_welcome_screen.dart',
    'lib/features/parent/screens/parent_dashboard_screen.dart',
    'lib/features/parent/screens/parent_topup_screen.dart',
    'lib/features/parent/screens/parent_portal_screen.dart',
    'lib/features/parent/screens/parent_receipt_screen.dart',
    'lib/features/kantin/screens/pos_home_screen.dart',
    'lib/features/kantin/screens/check_card_screen.dart',
    'lib/features/kantin/screens/order_list_screen.dart',
    'lib/features/public/screens/public_home_screen.dart',
    'lib/features/public/screens/public_menu_screen.dart',
    'lib/features/public/screens/public_school_info_screen.dart',
    'lib/features/shared/screens/officer_activities_screen.dart',
    'lib/features/shared/screens/student_transactions_screen.dart',
]

total_replaced = 0

for filepath in FILES:
    if not os.path.exists(filepath):
        print(f"MISSING: {filepath}")
        continue

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Remove local static const Color definitions that duplicate AppColors
    content = re.sub(
        r'^[ \t]*static const Color \w+ = Color\(0x[0-9A-Fa-f]{8}\);[ \t]*\n',
        '',
        content,
        flags=re.MULTILINE
    )

    # Remove local non-static const Color definitions inside methods
    content = re.sub(
        r'^[ \t]*const Color \w+ = Color\(0x[0-9A-Fa-f]{8}\);[ \t]*\n',
        '',
        content,
        flags=re.MULTILINE
    )

    # Replace Color(0xFF...) with AppColors.*
    def replace_color(match):
        color_val = match.group(1)
        if color_val in COLOR_MAP:
            return COLOR_MAP[color_val]
        return match.group(0)

    # Match: Color(0xFF......) optionally preceded by 'const '
    # But not inside strings
    content = re.sub(
        r'(?:const )?Color\((0x[0-9A-Fa-f]{8})\)',
        replace_color,
        content
    )

    # Also replace .withValues patterns where the color was already replaced
    content = re.sub(
        r'AppColors\.(\w+)\.withValues',
        r'AppColors.\1.withValues',
        content
    )

    if content != original:
        old_count = len(re.findall(r'0x[0-9A-Fa-f]{8}', original))
        new_count = len(re.findall(r'0x[0-9A-Fa-f]{8}', content))
        replaced = old_count - new_count
        total_replaced += replaced
        app_refs = content.count('AppColors.')
        print(f"{filepath}: replaced ~{replaced} colors, {app_refs} AppColors references")

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
    else:
        print(f"{filepath}: no changes needed")

print(f"\nTotal replacements across files: ~{total_replaced}")
