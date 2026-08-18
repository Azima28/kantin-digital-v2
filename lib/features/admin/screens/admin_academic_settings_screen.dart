import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/academic_structure.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

class AdminAcademicSettingsScreen extends ConsumerStatefulWidget {
  const AdminAcademicSettingsScreen({super.key});

  @override
  ConsumerState<AdminAcademicSettingsScreen> createState() => _AdminAcademicSettingsScreenState();
}

class _AdminAcademicSettingsScreenState extends ConsumerState<AdminAcademicSettingsScreen> {
  bool _isInitialized = false;

  // State
  String _schoolType = 'smk'; // 'smk', 'sma', 'smp', 'sd', 'custom'
  String _schoolName = 'SMK Negeri 1';
  bool _hasMajors = true;
  List<String> _gradeLevels = ['X', 'XI', 'XII'];
  List<String> _rombels = [];
  bool _autoSyncToOtherGrades = true; // Auto propagate from grade 1 to other grades
  int _selectedGradeIndex = 0;
  bool _isSaving = false;

  // Preset templates untuk tingkat pertama
  static const List<String> _smkDefaultFirstGradeClasses = [
    'X RPL 1', 'X RPL 2', 'X TKJ 1', 'X TKJ 2', 'X DKV 1', 'X AKL 1', 'X OTKP 1'
  ];

  static const List<String> _smaDefaultFirstGradeClasses = [
    'X MIPA 1', 'X MIPA 2', 'X IPS 1', 'X IPS 2', 'X Bahasa 1'
  ];

  static const List<String> _smpDefaultFirstGradeClasses = [
    'VII-A', 'VII-B', 'VII-C', 'VII-D'
  ];

  static const List<String> _sdDefaultFirstGradeClasses = [
    '1-A', '1-B'
  ];

  void _loadFromModel(AcademicStructure s) {
    if (_isInitialized) return;
    _isInitialized = true;
    _schoolType = s.schoolType;
    _schoolName = s.schoolName;
    _hasMajors = s.hasMajors;
    _gradeLevels = s.gradeLevels.isNotEmpty ? List.from(s.gradeLevels) : ['X', 'XI', 'XII'];
    _rombels = s.rombels.isNotEmpty ? List.from(s.rombels) : [];

    if (_rombels.isEmpty) {
      _applySchoolTypePreset(_schoolType);
    }
  }

  String get _firstGrade => _gradeLevels.isNotEmpty ? _gradeLevels.first : 'X';

  /// Helper untuk mengubah format nama kelas dari satu tingkat ke tingkat lainnya.
  /// Contoh: 'X RPL 1' (source X, target XI) -> 'XI RPL 1'
  /// Contoh: 'VII-A' (source VII, target VIII) -> 'VIII-A'
  String _projectClassToGrade(String className, String sourceGrade, String targetGrade) {
    final trimmed = className.trim();
    if (trimmed.startsWith('$sourceGrade ')) {
      return '$targetGrade ${trimmed.substring(sourceGrade.length + 1)}';
    } else if (trimmed.startsWith('$sourceGrade-')) {
      return '$targetGrade-${trimmed.substring(sourceGrade.length + 1)}';
    } else if (trimmed.startsWith('$sourceGrade.')) {
      return '$targetGrade.${trimmed.substring(sourceGrade.length + 1)}';
    } else if (trimmed.startsWith(sourceGrade)) {
      return '$targetGrade${trimmed.substring(sourceGrade.length)}';
    } else {
      // Jika user mengetik tanpa prefix tingkat (misal 'RPL 1' atau 'A')
      if (trimmed.startsWith('-')) {
        return '$targetGrade$trimmed';
      }
      return '$targetGrade $trimmed';
    }
  }

  /// Memeriksa apakah suatu nama rombel merupakan milik tingkat tertentu.
  /// Mencegah substring collision (contoh: 'X' tidak akan mencocokkan 'XI' atau 'XII').
  bool _matchesGrade(String rombel, String grade) {
    final trimmed = rombel.trim();
    if (trimmed == grade) return true;
    if (trimmed.startsWith('$grade ') ||
        trimmed.startsWith('$grade-') ||
        trimmed.startsWith('$grade.') ||
        trimmed.startsWith('$grade/')) {
      return true;
    }
    return false;
  }

  /// Terapkan Preset Sekolah
  void _applySchoolTypePreset(String type) {
    setState(() {
      _schoolType = type;
      _selectedGradeIndex = 0;
      List<String> firstGradeClasses = [];

      switch (type) {
        case 'smk':
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          firstGradeClasses = List.from(_smkDefaultFirstGradeClasses);
          break;
        case 'sma':
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          firstGradeClasses = List.from(_smaDefaultFirstGradeClasses);
          break;
        case 'smp':
          _hasMajors = false;
          _gradeLevels = ['VII', 'VIII', 'IX'];
          firstGradeClasses = List.from(_smpDefaultFirstGradeClasses);
          break;
        case 'sd':
          _hasMajors = false;
          _gradeLevels = ['1', '2', '3', '4', '5', '6'];
          firstGradeClasses = List.from(_sdDefaultFirstGradeClasses);
          break;
        default:
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          firstGradeClasses = ['X 1', 'X 2'];
          break;
      }

      // Generate rombels untuk seluruh tingkat berdasarkan tingkat pertama
      final List<String> allRombels = [];
      final firstG = _gradeLevels.first;
      for (final g in _gradeLevels) {
        for (final baseClass in firstGradeClasses) {
          allRombels.add(_projectClassToGrade(baseClass, firstG, g));
        }
      }
      _rombels = allRombels;
    });
  }

  /// Tambah kelas ke tingkat pertama (otomatis duplikasi ke tingkat berikutnya jika autoSync ON)
  void _addClassToFirstGrade(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return;

    final firstG = _firstGrade;
    final formattedFirstGradeName = _projectClassToGrade(trimmed, firstG, firstG);

    setState(() {
      if (!_rombels.contains(formattedFirstGradeName)) {
        _rombels.add(formattedFirstGradeName);
      }

      // Auto-propagate ke tingkat berikutnya (XI, XII, dst.)
      if (_autoSyncToOtherGrades) {
        for (int i = 1; i < _gradeLevels.length; i++) {
          final targetGrade = _gradeLevels[i];
          final projected = _projectClassToGrade(trimmed, firstG, targetGrade);
          if (!_rombels.contains(projected)) {
            _rombels.add(projected);
          }
        }
      }
    });
  }

  /// Hapus kelas dari tingkat pertama (otomatis hapus dari tingkat berikutnya jika autoSync ON)
  void _removeClassFromFirstGrade(String className) {
    final firstG = _firstGrade;
    setState(() {
      _rombels.remove(className);

      if (_autoSyncToOtherGrades) {
        for (int i = 1; i < _gradeLevels.length; i++) {
          final targetGrade = _gradeLevels[i];
          final projected = _projectClassToGrade(className, firstG, targetGrade);
          _rombels.remove(projected);
        }
      }
    });
  }

  /// Tambah kelas khusus di tingkat tertentu saja
  void _addCustomClassToGrade(String grade, String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return;

    final formatted = _projectClassToGrade(trimmed, grade, grade);
    setState(() {
      if (!_rombels.contains(formatted)) {
        _rombels.add(formatted);
      }
    });
  }

  /// Ekstrak master jurusan dari rombels
  List<AcademicMajor> _extractMajors() {
    final Set<String> foundCodes = {};
    for (final r in _rombels) {
      final parts = r.split(' ');
      if (parts.length >= 3) {
        foundCodes.add(parts[1].toUpperCase());
      }
    }
    return foundCodes.map((code) => AcademicMajor(id: code.toLowerCase(), name: code, code: code)).toList();
  }

  Future<void> _handleSave() async {
    if (_rombels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar kelas tidak boleh kosong. Tambahkan minimal 1 kelas.'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final struct = AcademicStructure(
      schoolType: _schoolType,
      schoolName: _schoolName.trim().isNotEmpty ? _schoolName.trim() : 'Sekolah Digital',
      hasMajors: _hasMajors,
      majors: _extractMajors(),
      gradeLevels: _gradeLevels,
      rombels: _rombels,
    );

    final saveFn = ref.read(saveAcademicStructureProvider);
    final ok = await saveFn(struct);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Master kelas (${_rombels.length} rombel) berhasil disimpan!'
              : 'Gagal menyimpan struktur akademik'),
          backgroundColor: ok ? Nebula.teal : Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(academicStructureProvider);
    asyncData.whenData((s) => _loadFromModel(s));

    final firstG = _firstGrade;
    final firstGradeClasses = _rombels.where((r) => _matchesGrade(r, firstG)).toList();
    final otherGrades = _gradeLevels.skip(1).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Kelola Kelas & Rombel',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 16.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. PILIH JENJANG SEKOLAH (Cukup 1 Klik) ─────────────
                    Text(
                      'JENJANG SEKOLAH',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildSchoolTypePresetGrid(context),
                    const SizedBox(height: 18),

                    // ── 2. PENGISIAN TINGKAT PERTAMA (Otomatis ke Tingkat Berikutnya)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Nebula.teal.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Bar Pengisian Tingkat Pertama
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Nebula.teal,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Tingkat $firstG',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Master Kelas Utama',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Cukup atur kelas di sini. Tingkat lain otomatis mengikuti.',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Nebula.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showAddClassDialog(context, targetGrade: firstG, isMaster: true),
                                child: Text('+ Kelas', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Daftar Kelas Tingkat Pertama
                          if (firstGradeClasses.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Belum ada kelas. Klik "+ Kelas" di atas untuk menambahkan.',
                                style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: firstGradeClasses.map((className) {
                                return Chip(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                                  side: BorderSide(color: Nebula.teal.withValues(alpha: 0.3), width: 0.8),
                                  label: Text(
                                    className,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 11.5),
                                  ),
                                  deleteIcon: const Icon(CupertinoIcons.xmark, size: 11, color: Nebula.rose),
                                  onDeleted: () => _removeClassFromFirstGrade(className),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: context.dividerCol),
                          const SizedBox(height: 8),

                          // Auto Sync Switch Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  otherGrades.isNotEmpty
                                      ? 'Terapkan otomatis ke Kelas ${otherGrades.join(", ")}'
                                      : 'Terapkan ke seluruh tingkat',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimary),
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: _autoSyncToOtherGrades,
                                  activeTrackColor: Nebula.teal,
                                  onChanged: (val) {
                                    setState(() => _autoSyncToOtherGrades = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 3. PRATINJAU & KELAS PER TINGKAT (Clean Tabs) ────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HASIL SEMUA TINGKAT (${_rombels.length} KELAS)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (_selectedGradeIndex > 0)
                          PressScale(
                            onTap: () => _showAddClassDialog(
                              context,
                              targetGrade: _gradeLevels[_selectedGradeIndex],
                              isMaster: false,
                            ),
                            child: Text(
                              '+ Tambah Khusus',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildAllGradesTabbedPreview(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── STICKY BOTTOM SAVE BAR ──────────────────────────────────────
            _buildBottomSaveBar(context),
          ],
        ),
      ),
    );
  }

  // ── 1. School Type 4-Preset Grid ──────────────────────────────────────────
  Widget _buildSchoolTypePresetGrid(BuildContext context) {
    final types = [
      {'key': 'smk', 'label': 'SMK', 'sub': 'RPL, TKJ, AKL, dll', 'icon': CupertinoIcons.hammer},
      {'key': 'sma', 'label': 'SMA', 'sub': 'MIPA, IPS, Bahasa', 'icon': CupertinoIcons.book},
      {'key': 'smp', 'label': 'SMP', 'sub': 'Kelas VII, VIII, IX', 'icon': CupertinoIcons.building_2_fill},
      {'key': 'sd', 'label': 'SD', 'sub': 'Kelas 1 sampai 6', 'icon': CupertinoIcons.person_2_fill},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: types.map((t) {
        final isSelected = _schoolType == t['key'];
        return InkWell(
          onTap: () => _applySchoolTypePreset(t['key'] as String),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Nebula.teal.withValues(alpha: 0.12) : context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Nebula.teal : context.dividerCol,
                width: isSelected ? 1.4 : 0.6,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? Nebula.teal : context.surfaceBg,
                  child: Icon(
                    t['icon'] as IconData,
                    size: 13,
                    color: isSelected ? Colors.white : context.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Nebula.teal : context.textPrimary,
                        ),
                      ),
                      Text(
                        t['sub'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: isSelected ? Nebula.teal.withValues(alpha: 0.8) : context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 3. All Grades Tabbed Preview ──────────────────────────────────────────
  Widget _buildAllGradesTabbedPreview(BuildContext context) {
    if (_gradeLevels.isEmpty) return const SizedBox.shrink();

    if (_selectedGradeIndex >= _gradeLevels.length) {
      _selectedGradeIndex = 0;
    }

    final activeGrade = _gradeLevels[_selectedGradeIndex];
    final activeGradeRombels = _rombels.where((r) => _matchesGrade(r, activeGrade)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_gradeLevels.length, (idx) {
              final grade = _gradeLevels[idx];
              final count = _rombels.where((r) => _matchesGrade(r, grade)).length;
              final isSelected = _selectedGradeIndex == idx;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedGradeIndex = idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Nebula.teal : context.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Nebula.teal : context.dividerCol,
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Kelas $grade',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : context.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Nebula.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // List Rombels Container
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerCol, width: 0.6),
          ),
          child: activeGradeRombels.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Belum ada kelas di Tingkat $activeGrade.',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: activeGradeRombels.map((rombel) {
                    return Chip(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: context.surfaceBg,
                      side: BorderSide(color: context.dividerCol, width: 0.6),
                      label: Text(
                        rombel,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 11),
                      ),
                      deleteIcon: const Icon(CupertinoIcons.xmark, size: 11, color: Nebula.rose),
                      onDeleted: () {
                        setState(() {
                          _rombels.remove(rombel);
                        });
                      },
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Bottom Sticky Save Bar ────────────────────────────────────────────────
  Widget _buildBottomSaveBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.dividerCol, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_rombels.length} Kelas Siap Disimpan',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                Text(
                  '${_gradeLevels.length} Tingkat Kelas Aktif',
                  style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _handleSave,
            child: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Master Kelas',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog Tambah Kelas ───────────────────────────────────────────────────
  void _showAddClassDialog(BuildContext context, {required String targetGrade, required bool isMaster}) {
    final ctrl = TextEditingController();

    // Quick suggestions based on school type
    final List<String> suggestions = _schoolType == 'smk'
        ? ['RPL 1', 'RPL 2', 'TKJ 1', 'TKJ 2', 'DKV 1', 'AKL 1', 'OTKP 1', 'TBG 1']
        : (_schoolType == 'sma'
            ? ['MIPA 1', 'MIPA 2', 'IPS 1', 'IPS 2', 'Bahasa 1']
            : ['A', 'B', 'C', 'D', 'E']);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ctx.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ctx.dividerCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isMaster ? 'Tambah Kelas Master (Tingkat $targetGrade)' : 'Tambah Kelas Khusus (Tingkat $targetGrade)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isMaster && _autoSyncToOtherGrades
                    ? 'Otomatis dibuatkan untuk seluruh tingkat (${_gradeLevels.join(", ")}).'
                    : 'Hanya ditambahkan untuk Tingkat $targetGrade.',
                style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
              ),
              const SizedBox(height: 10),

              // Suggestions
              Text(
                'Saran Cepat:',
                style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: suggestions.map((s) {
                  return InkWell(
                    onTap: () {
                      if (isMaster) {
                        _addClassToFirstGrade(s);
                      } else {
                        _addCustomClassToGrade(targetGrade, s);
                      }
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 0.6),
                      ),
                      child: Text(
                        '+ $s',
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: Nebula.teal),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Manual Input
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 12.5, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Ketik Nama Kelas Manual',
                  hintText: 'Contoh: RPL 1 atau 7-A atau Tahfidz',
                  labelStyle: GoogleFonts.inter(fontSize: 11),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Nebula.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        final val = ctrl.text.trim();
                        if (val.isNotEmpty) {
                          if (isMaster) {
                            _addClassToFirstGrade(val);
                          } else {
                            _addCustomClassToGrade(targetGrade, val);
                          }
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Tambah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
