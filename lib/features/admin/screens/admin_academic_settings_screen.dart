import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/academic_structure.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

class AdminAcademicSettingsScreen extends ConsumerStatefulWidget {
  const AdminAcademicSettingsScreen({super.key});

  @override
  ConsumerState<AdminAcademicSettingsScreen> createState() => _AdminAcademicSettingsScreenState();
}

class _AdminAcademicSettingsScreenState extends ConsumerState<AdminAcademicSettingsScreen> {
  bool _isInitialized = false;

  // Working state
  String _schoolType = 'smk'; // 'smk', 'sma', 'smp', 'sd', 'custom'
  String _schoolName = 'SMK Negeri 1';
  bool _hasMajors = true;
  List<AcademicMajor> _majors = [];
  List<String> _gradeLevels = [];
  List<String> _rombels = [];
  final Map<String, int> _majorCounts = {}; // Major Code -> Count per grade
  int _nonMajorParallelCount = 3; // For SMP/SD (A, B, C)
  int _selectedGradeIndex = 0;
  bool _isSaving = false;

  // Preset libraries
  static const List<AcademicMajor> _smkPresetMajors = [
    AcademicMajor(id: 'rpl', name: 'Rekayasa Perangkat Lunak', code: 'RPL'),
    AcademicMajor(id: 'tkj', name: 'Teknik Komputer & Jaringan', code: 'TKJ'),
    AcademicMajor(id: 'dkv', name: 'Desain Komunikasi Visual', code: 'DKV'),
    AcademicMajor(id: 'akl', name: 'Akuntansi & Keuangan Lembaga', code: 'AKL'),
    AcademicMajor(id: 'otkp', name: 'Otomatisasi & Tata Kelola Perkantoran', code: 'OTKP'),
    AcademicMajor(id: 'tbsm', name: 'Teknik Sepeda Motor', code: 'TBSM'),
    AcademicMajor(id: 'tkr', name: 'Teknik Kendaraan Ringan', code: 'TKR'),
    AcademicMajor(id: 'boga', name: 'Tata Boga / Kuliner', code: 'TBG'),
    AcademicMajor(id: 'hotel', name: 'Perhotelan', code: 'HTL'),
  ];

  static const List<AcademicMajor> _smaPresetMajors = [
    AcademicMajor(id: 'mipa', name: 'Matematika & Ilmu Alam', code: 'MIPA'),
    AcademicMajor(id: 'ips', name: 'Ilmu Pengetahuan Sosial', code: 'IPS'),
    AcademicMajor(id: 'bahasa', name: 'Bahasa & Budaya', code: 'Bahasa'),
    AcademicMajor(id: 'merdeka_e', name: 'Kurikulum Merdeka (Fase E)', code: 'Fase-E'),
    AcademicMajor(id: 'merdeka_f', name: 'Kurikulum Merdeka (Fase F)', code: 'Fase-F'),
  ];

  void _loadFromModel(AcademicStructure s) {
    if (_isInitialized) return;
    _isInitialized = true;
    _schoolType = s.schoolType;
    _schoolName = s.schoolName;
    _hasMajors = s.hasMajors;
    _majors = List.from(s.majors);
    _gradeLevels = List.from(s.gradeLevels);
    _rombels = List.from(s.rombels);

    // Hitung jumlah kelas per jurusan dari rombel yang ada
    for (final major in _majors) {
      int maxFound = 0;
      for (final r in _rombels) {
        if (r.contains(' ${major.code} ')) {
          final parts = r.split(' ');
          final lastNum = int.tryParse(parts.last);
          if (lastNum != null && lastNum > maxFound) {
            maxFound = lastNum;
          }
        }
      }
      _majorCounts[major.code] = maxFound > 0 ? maxFound : 2;
    }

    if (!_hasMajors && _rombels.isNotEmpty) {
      // Perkirakan paralel untuk SMP/SD
      int maxLetterIdx = 0;
      const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
      for (final r in _rombels) {
        for (int i = 0; i < letters.length; i++) {
          if (r.endsWith('-${letters[i]}') && i > maxLetterIdx) {
            maxLetterIdx = i;
          }
        }
      }
      _nonMajorParallelCount = maxLetterIdx + 1;
    }
  }

  void _applySchoolTypePreset(String type) {
    setState(() {
      _schoolType = type;
      _selectedGradeIndex = 0;
      switch (type) {
        case 'smk':
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          _majors = List.from(_smkPresetMajors.take(5));
          for (final m in _majors) {
            _majorCounts[m.code] = 2;
          }
          _regenerateAllRombels();
          break;
        case 'sma':
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          _majors = List.from(_smaPresetMajors.take(3));
          for (final m in _majors) {
            _majorCounts[m.code] = 2;
          }
          _regenerateAllRombels();
          break;
        case 'smp':
          _hasMajors = false;
          _majors = [];
          _gradeLevels = ['VII', 'VIII', 'IX'];
          _nonMajorParallelCount = 3;
          _regenerateAllRombels();
          break;
        case 'sd':
          _hasMajors = false;
          _majors = [];
          _gradeLevels = ['1', '2', '3', '4', '5', '6'];
          _nonMajorParallelCount = 2;
          _regenerateAllRombels();
          break;
        default:
          break;
      }
    });
  }

  void _regenerateAllRombels() {
    final List<String> generated = [];
    if (_hasMajors && _majors.isNotEmpty) {
      for (final grade in _gradeLevels) {
        for (final major in _majors) {
          final count = _majorCounts[major.code] ?? 2;
          for (int i = 1; i <= count; i++) {
            generated.add('$grade ${major.code} $i');
          }
        }
      }
    } else {
      const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
      for (final grade in _gradeLevels) {
        for (int i = 0; i < _nonMajorParallelCount && i < letters.length; i++) {
          generated.add('$grade-${letters[i]}');
        }
      }
    }
    _rombels = generated;
  }

  void _updateMajorClassCount(AcademicMajor major, int delta) {
    final current = _majorCounts[major.code] ?? 2;
    final next = current + delta;
    if (next < 1 || next > 8) return;

    setState(() {
      _majorCounts[major.code] = next;

      // Update rombel untuk jurusan ini di seluruh tingkatan
      for (final grade in _gradeLevels) {
        if (delta > 0) {
          // Tambahkan rombel baru (misal X RPL 3)
          final newName = '$grade ${major.code} $next';
          if (!_rombels.contains(newName)) {
            _rombels.add(newName);
          }
        } else {
          // Hapus rombel nomor tertinggi (misal X RPL 3)
          final removeName = '$grade ${major.code} $current';
          _rombels.remove(removeName);
        }
      }
    });
  }

  void _updateNonMajorCount(int delta) {
    final next = _nonMajorParallelCount + delta;
    if (next < 1 || next > 6) return;

    setState(() {
      _nonMajorParallelCount = next;
      _regenerateAllRombels();
    });
  }

  void _removeMajor(AcademicMajor major) {
    setState(() {
      _majors.removeWhere((m) => m.code == major.code);
      _majorCounts.remove(major.code);
      // Hapus seluruh rombel yang berhubungan dengan jurusan ini
      _rombels.removeWhere((r) => r.contains(' ${major.code} '));
    });
  }

  bool _matchesGrade(String rombel, String grade) {
    final trimmed = rombel.trim();
    if (trimmed == grade) return true;
    if (trimmed.startsWith('$grade ') || trimmed.startsWith('$grade-') || trimmed.startsWith('$grade.')) {
      return true;
    }
    return false;
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
      majors: _majors,
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
          'Kelola Rombel & Kelas',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. JENJANG SEKOLAH (1-Tap Fast Selection) ────────────
                    _buildSectionHeader(context, 'JENJANG & MODEL SEKOLAH'),
                    const SizedBox(height: 8),
                    _buildSchoolTypeSelector(context),
                    const SizedBox(height: 20),

                    // ── 2. JURUSAN & JUMLAH KELAS (Interactive Steppers) ─────
                    if (_hasMajors) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(context, 'JURUSAN & JUMLAH KELAS (${_majors.length})'),
                          PressScale(
                            onTap: () => _showAddMajorDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.plus, size: 12, color: Nebula.teal),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tambah Jurusan',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMajorsListWithSteppers(context),
                    ] else ...[
                      // Mode SMP / SD (Non-Jurusan)
                      _buildSectionHeader(context, 'PENGATURAN KELAS PARALEL'),
                      const SizedBox(height: 8),
                      _buildNonMajorParallelSetting(context),
                    ],
                    const SizedBox(height: 22),

                    // ── 3. PRATINJAU ROMBEL PER TINGKAT (Clean Tabs) ─────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(context, 'DAFTAR KELAS AKTIF (${_rombels.length})'),
                        PressScale(
                          onTap: () => _showAddCustomClassDialog(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.plus, size: 12, color: Nebula.teal),
                                const SizedBox(width: 4),
                                Text(
                                  'Tambah Kelas Khusus',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildRombelsPreviewSection(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Save Bar ─────────────────────────────────────────
            _buildBottomSaveBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }

  // ── 1. School Type 4-Button Grid ───────────────────────────────────────────
  Widget _buildSchoolTypeSelector(BuildContext context) {
    final types = [
      {'key': 'smk', 'label': 'SMK', 'sub': 'Kejuruan (RPL, TKJ, dll)', 'icon': CupertinoIcons.hammer},
      {'key': 'sma', 'label': 'SMA', 'sub': 'MIPA, IPS, Bahasa', 'icon': CupertinoIcons.book},
      {'key': 'smp', 'label': 'SMP', 'sub': 'Kelas VII, VIII, IX', 'icon': CupertinoIcons.building_2_fill},
      {'key': 'sd', 'label': 'SD', 'sub': 'Kelas 1 sampai 6', 'icon': CupertinoIcons.person_2_fill},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.35,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: types.map((t) {
        final isSelected = _schoolType == t['key'];
        return InkWell(
          onTap: () => _applySchoolTypePreset(t['key'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Nebula.teal.withValues(alpha: 0.12) : context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Nebula.teal : context.dividerCol,
                width: isSelected ? 1.5 : 0.6,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isSelected ? Nebula.teal : context.surfaceBg,
                  child: Icon(
                    t['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : context.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Nebula.teal : context.textPrimary,
                        ),
                      ),
                      Text(
                        t['sub'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
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

  // ── 2. Majors List with Steppers ───────────────────────────────────────────
  Widget _buildMajorsListWithSteppers(BuildContext context) {
    if (_majors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerCol, width: 0.6),
        ),
        child: Center(
          child: Column(
            children: [
              Text('Belum ada jurusan aktif.', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => _applySchoolTypePreset(_schoolType),
                child: Text('Muat Ulang Preset ${_schoolType.toUpperCase()}', style: GoogleFonts.inter(fontSize: 11.5, color: Nebula.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol, width: 0.6),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _majors.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: context.dividerCol, indent: 56),
        itemBuilder: (context, index) {
          final major = _majors[index];
          final count = _majorCounts[major.code] ?? 2;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Major Code Badge
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    major.code,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: Nebula.teal,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Major Full Name
                Expanded(
                  child: Text(
                    major.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),

                // Class Count Stepper ([- 2 +])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.surfaceBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.dividerCol, width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: count > 1 ? () => _updateMajorClassCount(major, -1) : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            CupertinoIcons.minus,
                            size: 13,
                            color: count > 1 ? context.textPrimary : context.textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$count kls',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: count < 8 ? () => _updateMajorClassCount(major, 1) : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 13,
                            color: count < 8 ? context.textPrimary : context.textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Delete Major Button
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, size: 14, color: Nebula.rose),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Hapus Jurusan',
                  onPressed: () => _removeMajor(major),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Non-Major Setting (SMP / SD) ───────────────────────────────────────────
  Widget _buildNonMajorParallelSetting(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol, width: 0.6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah Kelas per Tingkat',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                Text(
                  'Format: $_gradeLevels.first-A, $_gradeLevels.first-B, dst.',
                  style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.dividerCol, width: 0.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _nonMajorParallelCount > 1 ? () => _updateNonMajorCount(-1) : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.minus,
                      size: 14,
                      color: _nonMajorParallelCount > 1 ? context.textPrimary : context.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_nonMajorParallelCount Kelas',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Nebula.teal,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _nonMajorParallelCount < 6 ? () => _updateNonMajorCount(1) : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.plus,
                      size: 14,
                      color: _nonMajorParallelCount < 6 ? context.textPrimary : context.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Rombels Preview with Grade Tabs ─────────────────────────────────────
  Widget _buildRombelsPreviewSection(BuildContext context) {
    if (_gradeLevels.isEmpty) {
      return const EmptyStateWidget(message: 'Tingkat kelas belum diatur.');
    }

    if (_selectedGradeIndex >= _gradeLevels.length) {
      _selectedGradeIndex = 0;
    }

    final activeGrade = _gradeLevels[_selectedGradeIndex];
    final activeGradeRombels = _rombels.where((r) => _matchesGrade(r, activeGrade)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grade Tabs Selector
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
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Nebula.teal : context.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Nebula.teal : context.dividerCol,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Kelas $grade',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : context.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
        const SizedBox(height: 10),

        // Rombels Chip Container for Active Grade
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerCol, width: 0.6),
          ),
          child: activeGradeRombels.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Belum ada kelas untuk Tingkat $activeGrade.\nKlik tombol "+" di atas untuk menambahkan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 11.5),
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
                  '${_rombels.length} Kelas Terdaftar',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                Text(
                  _hasMajors ? '${_majors.length} Jurusan • ${_gradeLevels.length} Tingkat' : '${_gradeLevels.length} Tingkat',
                  style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _handleSave,
            child: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Master Kelas',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Tambah Jurusan Baru ───────────────────────────────────────────
  void _showAddMajorDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    // Preset yang belum ditambahkan
    final availablePresets = (_schoolType == 'sma' ? _smaPresetMajors : _smkPresetMajors)
        .where((p) => !_majors.any((m) => m.code.toUpperCase() == p.code.toUpperCase()))
        .toList();

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
                'Tambah Jurusan',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              ),
              const SizedBox(height: 10),

              // Pilihan Preset Cepat jika ada
              if (availablePresets.isNotEmpty) ...[
                Text(
                  'Pilih dari Preset Cepat:',
                  style: GoogleFonts.inter(fontSize: 11, color: ctx.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: availablePresets.take(6).map((p) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _majors.add(p);
                          _majorCounts[p.code] = 2;
                          // Tambahkan rombel default
                          for (final grade in _gradeLevels) {
                            _rombels.add('$grade ${p.code} 1');
                            _rombels.add('$grade ${p.code} 2');
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 0.8),
                        ),
                        child: Text(
                          '+ ${p.code} (${p.name.split(" ").first})',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: ctx.dividerCol),
                const SizedBox(height: 12),
              ],

              Text(
                'Atau Masukkan Manual:',
                style: GoogleFonts.inter(fontSize: 11, color: ctx.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 12.5, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Jurusan',
                  hintText: 'Contoh: Desain Komunikasi Visual',
                  labelStyle: GoogleFonts.inter(fontSize: 11),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                style: GoogleFonts.inter(fontSize: 12.5, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kode Singkatan',
                  hintText: 'Contoh: DKV',
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
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim().toUpperCase();
                        if (name.isEmpty || code.isEmpty) return;

                        setState(() {
                          final newMajor = AcademicMajor(id: code.toLowerCase(), name: name, code: code);
                          _majors.add(newMajor);
                          _majorCounts[code] = 2;
                          for (final grade in _gradeLevels) {
                            _rombels.add('$grade $code 1');
                            _rombels.add('$grade $code 2');
                          }
                        });
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

  // ── Dialog: Tambah Kelas Khusus ───────────────────────────────────────────
  void _showAddCustomClassDialog() {
    final classCtrl = TextEditingController();
    final activeGrade = _gradeLevels.isNotEmpty ? _gradeLevels[_selectedGradeIndex] : 'X';

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
                'Tambah Kelas Khusus',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Akan ditambahkan ke daftar Tingkat $activeGrade.',
                style: GoogleFonts.inter(fontSize: 11.5, color: ctx.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: classCtrl,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Kelas',
                  hintText: 'Contoh: $activeGrade RPL Khusus / $activeGrade Tahfidz',
                  labelStyle: GoogleFonts.inter(fontSize: 11.5),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        final val = classCtrl.text.trim();
                        if (val.isNotEmpty && !_rombels.contains(val)) {
                          setState(() {
                            _rombels.add(val);
                          });
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
