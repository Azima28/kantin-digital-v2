/// Tool: Replace hardcoded Color(0xFF...) with AppColors.* references
/// Usage: dart tooling/replace_colors.dart --all
///        dart tooling/replace_colors.dart --admin
///        dart tooling/replace_colors.dart --parent
///        dart tooling/replace_colors.dart --remaining
///        dart tooling/replace_colors.dart --fix
library;

import 'dart:io';

List<String> findDartFiles(String dir) {
  final files = <String>[];
  final root = Directory(dir);
  if (!root.existsSync()) return files;
  void walk(Directory d) {
    for (final entity in d.listSync()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity.path);
      } else if (entity is Directory) {
        walk(entity);
      }
    }
  }
  walk(root);
  return files;
}

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help')) {
    print('Usage: dart tooling/replace_colors.dart [--admin|--parent|--remaining|--all|--fix]');
    return;
  }

  // Special fix mode
  if (args.contains('--fix')) {
    fixBadPatterns();
    return;
  }

  List<String> files = [];
  if (args.contains('--all')) {
    files = findDartFiles('lib');
  } else if (args.contains('--admin')) files = findDartFiles('lib/features/admin');
  else if (args.contains('--parent')) files = findDartFiles('lib/features/parent');
  else if (args.contains('--remaining')) {
    files.addAll(findDartFiles('lib/features/kantin'));
    files.addAll(findDartFiles('lib/features/siswa'));
    files.addAll(findDartFiles('lib/features/public'));
    files.addAll(findDartFiles('lib/features/shared'));
    files.addAll(findDartFiles('lib/features/auth'));
  } else {
    files = args.where((a) => a.endsWith('.dart')).toList();
  }

  files = files.where((f) =>
    !f.contains('.g.dart') && !f.contains('.freezed.dart') && !f.contains('app_colors.dart')
  ).toList();
  files.sort();

  print('Processing ${files.length} files...');

  // Hex replacement map: full "Color(0xFF...)" -> replacement
  // Order matters: more specific first
  final hexReplacements = <String, String>{
    // Primary
    'Color(0xFF0E8A8A)': 'AppColors.primary',
    'Color(0xFF003434)': 'AppColors.darkTeal',
    'Color(0xFF004D4D)': 'AppColors.darkTeal2',
    'Color(0xFF006767)': 'AppColors.teal',
    'Color(0xFF005A5A)': 'AppColors.teal',
    'Color(0xFF005E5E)': 'AppColors.teal',
    'Color(0xFF008282)': 'AppColors.primary',
    'Color(0xFF0A5E5E)': 'AppColors.primaryDark',
    'Color(0xFFE6F2F2)': 'AppColors.primaryLight',
    'Color(0xFFD6F0F0)': 'AppColors.primaryLight',
    // Accent
    'Color(0xFFFF9500)': 'AppColors.accentOrange',
    'Color(0xFF904D00)': 'AppColors.darkOrange',
    'Color(0xFFFCA558)': 'AppColors.accentOrange2',
    'Color(0xFFFFF2E0)': 'AppColors.accentOrangeLight',
    'Color(0xFFFFF3E0)': 'AppColors.softOrange',
    'Color(0xFFFFF3E8)': 'AppColors.softOrange',
    // State
    'Color(0xFF006A35)': 'AppColors.successGreen',
    'Color(0xFFBA1A1A)': 'AppColors.errorRed2',
    'Color(0xFFFF3B30)': 'AppColors.errorRed',
    'Color(0xFF34C759)': 'AppColors.success',
    'Color(0xFFEAF9EE)': 'AppColors.successLight',
    'Color(0xFFFEECEB)': 'AppColors.errorLight',
    'Color(0xFFFFDAD6)': 'AppColors.errorLightColor',
    'Color(0xFF93000A)': 'AppColors.errorDark',
    'Color(0xFF003718)': 'AppColors.darkGreen',
    'Color(0xFF005026)': 'AppColors.successDark',
    'Color(0xFFE8F5E9)': 'AppColors.successGreenLight',
    'Color(0xFFFFEBEE)': 'Color(0xFFFFEBEE)', // No equivalent
    //'Color(0xFFFFEBEE)': 'AppColors.errorRedLight',
    'Color(0xFFFFF8E1)': 'AppColors.warningYellowLight',
    'Color(0xFFFFA000)': 'AppColors.warningYellow',
    // Neutral
    'Color(0xFF6F7978)': 'AppColors.mutedGray',
    'Color(0xFF1B1C1B)': 'AppColors.nearBlack',
    'Color(0xFF1B1C1C)': 'AppColors.nearBlack',
    'Color(0xFFE4E2E1)': 'AppColors.borderGray',
    'Color(0xFFF5F3F2)': 'AppColors.offWhite2',
    'Color(0xFFBFC8C8)': 'AppColors.gray400',
    'Color(0xFF3F4848)': 'AppColors.darkGray',
    'Color(0xFF3D4949)': 'AppColors.darkGray',
    'Color(0xFFEFEDEC)': 'AppColors.lightGray',
    'Color(0xFFE5E5EA)': 'AppColors.borderLight',
    'Color(0xFFF2F2F7)': 'AppColors.systemBackground',
    'Color(0xFFFBF9F8)': 'AppColors.offWhite',
    'Color(0xFF1C1C1E)': 'AppColors.textDark',
    'Color(0xFF8E8E93)': 'AppColors.textGray',
    'Color(0xFFFFFFFF)': 'AppColors.white',
    'Color(0xFFF5F5F5)': 'AppColors.scaffoldBackground',
    'Color(0xFFF8F9FA)': 'AppColors.surfaceContainer',
    'Color(0xFFF0F0F0)': 'AppColors.surfaceContainerLow',
    'Color(0xFF49454F)': 'AppColors.onSurfaceVariant',
    'Color(0xFFCAC4D0)': 'AppColors.outlineVariant',
    'Color(0xFFB2DFDF)': 'AppColors.softTeal',
    'Color(0xFF9E9E9E)': 'AppColors.gray',
    'Color(0xFFE0E0E0)': 'AppColors.grayLight',
    'Color(0xFFFF9800)': 'AppColors.secondary',
    'Color(0xFF1A1D1E)': 'AppColors.textPrimary',
    'Color(0xFFE8E8E8)': 'AppColors.borderLight',
    'Color(0xFFE2E2E7)': 'AppColors.borderLight',
    'Color(0xFF1A1C1F)': 'AppColors.nearBlack',
    'Color(0xFF1A1C1C)': 'AppColors.nearBlack',
  };

  int totalReplacements = 0;
  int fileCount = 0;

  for (final filePath in files) {
    String content;
    try {
      content = File(filePath).readAsStringSync();
    } catch (e) {
      print('  ERROR reading $filePath: $e');
      continue;
    }

    if (!content.contains('Color(0x') && !content.contains('Colors.white') && !content.contains('Colors.black')) {
      continue;
    }

    String newContent = content;
    int perFileReplacements = 0;

    // Pass 1: Safe Colors.white/black replacements (exact match, not substring)
    // Colors.white70 etc should stay as-is
    newContent = newContent.replaceAllMapped(
      RegExp(r'\bColors\.white\b(?!\w)'),
      (_) => 'AppColors.white',
    );
    newContent = newContent.replaceAllMapped(
      RegExp(r'\bColors\.black\b(?!\w)'),
      (_) => 'AppColors.black',
    );
    // Count changes approximately
    int whiteCount = 'Colors.white'.allMatches(newContent).length;
    int blackCount = 'Colors.black'.allMatches(newContent).length;

    // Pass 2: Replace Color(0xFF...) with AppColors.*
    for (final entry in hexReplacements.entries) {
      final search = entry.key;
      final replace = entry.value;
      if (search == replace) continue; // Skip no-op
      
      // Check both "const Color(0x..." and "Color(0x..."
      for (final prefix in ['const ', '']) {
        final fullSearch = '$prefix$search';
        if (newContent.contains(fullSearch)) {
          newContent = newContent.replaceAll(fullSearch, replace);
          perFileReplacements++;
        }
      }
    }

    // Pass 3: Remove `const Color xxx = AppColors.xxx;` patterns
    // These were const Color declarations whose hex value was replaced
    var lines = newContent.split('\n');
    var filtered = <String>[];
    int removed = 0;
    for (final line in lines) {
      // Match: static const Color xxx = AppColors.xxx;
      // Match: const Color xxx = AppColors.xxx; (inside method)
      if (RegExp(r'^\s*(static\s+)?const\s+Color\s+\w+\s*=\s*AppColors\.\w+\s*;\s*$').hasMatch(line)) {
        removed++;
        continue;
      }
      filtered.add(line);
    }
    newContent = filtered.join('\n');

    // Pass 4: Add AppColors import if we use AppColors.*
    if (newContent.contains('AppColors.') && !newContent.contains("import 'package:kantin_digital/core/constants/app_colors.dart'")) {
      final importRegex = RegExp(r"^import '.+';\s*$", multiLine: true);
      final matches = importRegex.allMatches(newContent).toList();
      if (matches.isNotEmpty) {
        final pos = matches.last.end;
        newContent = '${newContent.substring(0, pos)}\nimport \'package:kantin_digital/core/constants/app_colors.dart\';\n${newContent.substring(pos)}';
      }
    }

    if (newContent != content) {
      File(filePath).writeAsStringSync(newContent);
      fileCount++;
      totalReplacements += perFileReplacements;
      print('  UPDATED: $filePath ($perFileReplacements hex replacements, $removed local defs removed)');
    }
  }

  print('\nDone! Processed $fileCount files with $totalReplacements hex replacements.');
}

void fixBadPatterns() {
  print('Fixing bad patterns across all files...');
  for (final f in findDartFiles('lib')) {
    if (f.contains('.g.dart') || f.contains('.freezed.dart') || f.contains('app_colors.dart')) continue;
    
    String c = File(f).readAsStringSync();
    int changes = 0;
    
    // Fix: const AppColors.xxx -> AppColors.xxx
    int n1 = 'const AppColors.'.allMatches(c).length;
    if (n1 > 0) { c = c.replaceAll('const AppColors.', 'AppColors.'); changes += n1; }
    
    // Fix: AppColors.AppColors.xxx -> AppColors.xxx
    int n2 = 'AppColors.AppColors.'.allMatches(c).length;
    if (n2 > 0) { c = c.replaceAll('AppColors.AppColors.', 'AppColors.'); changes += n2; }
    
    // Fix: const Color AppColors.xxx = AppColors.xxx;
    // These were already handled by the main script but be safe
    int n3 = 'const Color AppColors.'.allMatches(c).length;
    if (n3 > 0) {
      c = c.replaceAll(RegExp(r'^\s*(static\s+)?const\s+Color\s+AppColors\.\w+\s*=\s*AppColors\.\w+\s*;\s*$', multiLine: true), '');
      changes += n3;
    }
    
    // Fix: final Color AppColors.xxx; 
    int n4 = 'final Color AppColors.'.allMatches(c).length;
    if (n4 > 0) {
      c = c.replaceAll(RegExp(r'^\s*final\s+Color\s+AppColors\.\w+\s*;\s*$', multiLine: true), '');
      changes += n4;
    }
    
    // Fix: Color AppColors.xxx as parameter type (Color is the type, not AppColors)
    int n5 = RegExp(r'Color\s+AppColors\.\w+').allMatches(c).length;
    if (n5 > 0) {
      // This needs manual fixing - we can't auto-fix parameter types
      print('  WARNING: Possible parameter type issue in $f ($n5 occurrences)');
    }
    
    if (changes > 0) {
      File(f).writeAsStringSync(c);
      print('  Fixed $changes bad patterns in $f');
    }
  }
  print('Done fixing.');
}
