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
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Jenjang & Jurusan, 1: Tingkat Kelas, 2: Master Rombel
  bool _isInitialized = false;

  // Working state
  String _schoolType = 'smk'; // 'smk', 'sma', 'smp', 'sd', 'custom'
  String _schoolName = 'SMK Negeri 1';
  bool _hasMajors = true;
  List<AcademicMajor> _majors = [];
  List<String> _gradeLevels = ['X', 'XI', 'XII'];
  List<String> _rombels = [];
  bool _autoSyncToOtherGrades = true; // Auto propagate from grade 1 to other grades
  int _selectedGradeIndex = 0;
  bool _isSaving = false;

  // Preset libraries
  static const List<AcademicMajor> _smkPresetMajors = [
    AcademicMajor(id: 'rpl', name: 'Rekayasa Perangkat Lunak', code: 'RPL'),
    AcademicMajor(id: 'tkj', name: 'Teknik Komputer & Jaringan', code: 'TKJ'),
    AcademicMajor(id: 'dkv', name: 'Desain Komunikasi Visual', code: 'DKV'),
    AcademicMajor(id: 'akl', name: 'Akuntansi & Keuangan Lembaga', code: 'AKL'),
    AcademicMajor(id: 'otkp', name: 'Otomatisasi Perkantoran', code: 'OTKP'),
    AcademicMajor(id: 'tbsm', name: 'Teknik Sepeda Motor', code: 'TBSM'),
    AcademicMajor(id: 'tkr', name: 'Teknik Kendaraan Ringan', code: 'TKR'),
    AcademicMajor(id: 'boga', name: 'Tata Boga / Kuliner', code: 'TBG'),
    AcademicMajor(id: 'hotel', name: 'Perhotelan', code: 'HTL'),
  ];

  static const List<AcademicMajor> _smaPresetMajors = [
    AcademicMajor(id: 'mipa', name: 'Matematika & IPA', code: 'MIPA'),
    AcademicMajor(id: 'ips', name: 'Ilmu Pengetahuan Sosial', code: 'IPS'),
    AcademicMajor(id: 'bahasa', name: 'Bahasa & Budaya', code: 'Bahasa'),
    AcademicMajor(id: 'merdeka_e', name: 'Kurikulum Merdeka (Fase E)', code: 'Fase-E'),
    AcademicMajor(id: 'merdeka_f', name: 'Kurikulum Merdeka (Fase F)', code: 'Fase-F'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadFromModel(AcademicStructure s) {
    if (_isInitialized) return;
    _isInitialized = true;
    _schoolType = s.schoolType;
    _schoolName = s.schoolName;
    _hasMajors = s.hasMajors;
    _majors = List.from(s.majors);
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

  void _applySchoolTypePreset(String type) {
    setState(() {
      _schoolType = type;
      _selectedGradeIndex = 0;
      switch (type) {
        case 'smk':
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          _majors = List.from(_smkPresetMajors.take(5));
          _autoGenerateRombels(countPerMajor: 2);
          break;
        case 'sma':
          _hasMajors = true;
          _gradeLevels = ['X', 'XI', 'XII'];
          _majors = List.from(_smaPresetMajors.take(3));
          _autoGenerateRombels(countPerMajor: 2);
          break;
        case 'smp':
          _hasMajors = false;
          _majors = [];
          _gradeLevels = ['VII', 'VIII', 'IX'];
          _rombels = [
            'VII-A', 'VII-B', 'VII-C', 'VII-D',
            'VIII-A', 'VIII-B', 'VIII-C', 'VIII-D',
            'IX-A', 'IX-B', 'IX-C', 'IX-D',
          ];
          break;
        case 'sd':
          _hasMajors = false;
          _majors = [];
          _gradeLevels = ['1', '2', '3', '4', '5', '6'];
          _rombels = [
            '1-A', '1-B', '2-A', '2-B', '3-A', '3-B',
            '4-A', '4-B', '5-A', '5-B', '6-A', '6-B',
          ];
          break;
        default:
          break;
      }
    });
  }

  void _autoGenerateRombels({int countPerMajor = 2}) {
    final List<String> generated = [];
    if (_hasMajors && _majors.isNotEmpty) {
      for (final grade in _gradeLevels) {
        for (final major in _majors) {
          for (int i = 1; i <= countPerMajor; i++) {
            generated.add('$grade ${major.code} $i');
          }
        }
      }
    } else {
      final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
      for (final grade in _gradeLevels) {
        for (int i = 0; i < countPerMajor && i < letters.length; i++) {
          generated.add('$grade-${letters[i]}');
        }
      }
    }
    setState(() {
      _rombels = generated;
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

  void _goToStep(int step) {
    if (step < 0 || step > 2) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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
              ? 'Master struktur akademik & rombel berhasil disimpan!'
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
            // ── Step Indicator Bar ──────────────────────────────────────────
            _buildStepIndicator(context),
            Divider(height: 1, color: context.dividerCol),

            // ── Multi-Step Wizard PageView ──────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Managed via bottom buttons
                children: [
                  _buildStep1SchoolAndMajors(context),
                  _buildStep2GradeLevels(context),
                  _buildStep3Rombels(context),
                ],
              ),
            ),

            // ── Bottom Wizard Navigation Bar ────────────────────────────────
            _buildBottomWizardBar(context),
          ],
        ),
      ),
    );
  }

  // ── Step Indicator ──────────────────────────────────────────────────────────
  Widget _buildStepIndicator(BuildContext context) {
    final steps = ['1. Jurusan', '2. Tingkat', '3. Rombel'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCurrent = _currentStep == index;
          final isPast = _currentStep > index;

          return Expanded(
            child: InkWell(
              onTap: () => _goToStep(index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: isCurrent
                              ? Nebula.teal
                              : (isPast ? Nebula.teal.withValues(alpha: 0.2) : context.dividerCol),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? Colors.white
                                  : (isPast ? Nebula.teal : context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            steps[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent ? Nebula.teal : context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Nebula.teal
                            : (isPast ? Nebula.teal.withValues(alpha: 0.4) : Colors.transparent),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Bottom Wizard Navigation Bar ────────────────────────────────────────────
  Widget _buildBottomWizardBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.dividerCol, width: 0.5)),
      ),
      child: Row(
        children: [
          // Tombol Kembali
          if (_currentStep > 0) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                side: BorderSide(color: context.dividerCol),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _goToStep(_currentStep - 1),
              child: Text(
                'Kembali',
                style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Tombol Lanjut / Simpan Akhir
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        _goToStep(_currentStep + 1);
                      } else {
                        _handleSave();
                      }
                    },
              child: Text(
                _currentStep == 0
                    ? 'Lanjut: Tingkat Kelas →'
                    : (_currentStep == 1
                        ? 'Lanjut: Master Rombel →'
                        : (_isSaving ? 'Menyimpan...' : 'Simpan Seluruh Struktur (Selesai)')),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LANGKAH 1: Jenjang & Jurusan ───────────────────────────────────────────
  Widget _buildStep1SchoolAndMajors(BuildContext context) {
    final schoolTypes = [
      {'key': 'smk', 'label': 'SMK', 'desc': 'Kejuruan (RPL, TKJ, dll)'},
      {'key': 'sma', 'label': 'SMA', 'desc': 'MIPA, IPS, Bahasa'},
      {'key': 'smp', 'label': 'SMP', 'desc': 'Kelas VII, VIII, IX'},
      {'key': 'sd', 'label': 'SD', 'desc': 'Kelas 1 sampai 6'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah 1: Jenjang & Jurusan Sekolah',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Pilih jenis sekolah untuk menerapkan struktur jurusan & tingkatan secara otomatis.',
            style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
          ),
          const SizedBox(height: 12),

          // Pilihan Jenjang 2x2 Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: schoolTypes.map((st) => _buildSchoolTypeCard(context, st)).toList(),
          ),
          const SizedBox(height: 16),

          // Toggle Punya Jurusan / Tidak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
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
                        'Sekolah Memiliki Jurusan / Peminatan',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      Text(
                        'Aktifkan jika sekolah memiliki konsentrasi keahlian (SMK/SMA)',
                        style: GoogleFonts.inter(fontSize: 10, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: _hasMajors,
                    activeTrackColor: Nebula.teal,
                    onChanged: (val) {
                      setState(() {
                        _hasMajors = val;
                        _autoGenerateRombels();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Master Jurusan List
          if (_hasMajors) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Jurusan (${_majors.length})',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          _majors = _schoolType == 'sma' ? List.from(_smaPresetMajors) : List.from(_smkPresetMajors);
                          _autoGenerateRombels();
                        });
                      },
                      child: Text(
                        'Preset ${_schoolType.toUpperCase()}',
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: Nebula.teal),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _showAddOrEditMajorDialog(),
                      child: Text('+ Tambah', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_majors.isEmpty)
              const EmptyStateWidget(message: 'Belum ada jurusan.')
            else
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.dividerCol, width: 0.6),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _majors.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: context.dividerCol, indent: 48),
                  itemBuilder: (context, index) {
                    final major = _majors[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              major.code,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              major.name,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.pencil, size: 14, color: Nebula.teal),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            onPressed: () => _showAddOrEditMajorDialog(existing: major, index: index),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.trash, size: 14, color: Nebula.rose),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            onPressed: () {
                              setState(() {
                                _majors.removeAt(index);
                                _autoGenerateRombels();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchoolTypeCard(BuildContext context, Map<String, String> st) {
    final isSelected = _schoolType == st['key'];
    return InkWell(
      onTap: () => _applySchoolTypePreset(st['key']!),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal.withValues(alpha: 0.1) : context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.4 : 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  st['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Nebula.teal : context.textPrimary,
                  ),
                ),
                Icon(
                  isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                  color: isSelected ? Nebula.teal : context.textSecondary,
                  size: 13,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              st['desc']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 9, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── LANGKAH 2: Tingkat Kelas ───────────────────────────────────────────────
  Widget _buildStep2GradeLevels(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah 2: Tingkat Kelas yang Digunakan',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Tentukan format penamaan tingkat kelas yang berlaku di sekolah.',
            style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
          ),
          const SizedBox(height: 12),

          // Pilihan Format Cepat
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  onPressed: () {
                    setState(() {
                      _gradeLevels = ['X', 'XI', 'XII'];
                      _autoGenerateRombels();
                    });
                  },
                  child: Text('Romawi (X, XI, XII)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  onPressed: () {
                    setState(() {
                      _gradeLevels = ['10', '11', '12'];
                      _autoGenerateRombels();
                    });
                  },
                  child: Text('Angka (10, 11, 12)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Tingkat Aktif (${_gradeLevels.length})',
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._gradeLevels.map((grade) {
                return Chip(
                  backgroundColor: Nebula.teal.withValues(alpha: 0.12),
                  side: BorderSide(color: Nebula.teal.withValues(alpha: 0.3)),
                  label: Text('Kelas $grade', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 11.5)),
                  deleteIcon: const Icon(CupertinoIcons.xmark, size: 11, color: Nebula.rose),
                  onDeleted: () {
                    if (_gradeLevels.length <= 1) return;
                    setState(() {
                      _gradeLevels.remove(grade);
                      _autoGenerateRombels();
                    });
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(CupertinoIcons.add, size: 12, color: Nebula.teal),
                label: Text('+ Tingkat Baru', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 11)),
                onPressed: () => _showAddGradeDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LANGKAH 3: Master Rombel (Auto-Sync dari Tingkat Pertama) ───────────────
  Widget _buildStep3Rombels(BuildContext context) {
    final firstG = _firstGrade;
    final firstGradeClasses = _rombels.where((r) => _matchesGrade(r, firstG)).toList();
    final otherGrades = _gradeLevels.skip(1).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah 3: Master Rombel (Kelas)',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Cukup isi di tingkat pertama ($firstG), tingkat selanjutnya ($otherGrades) otomatis terisi sama.',
            style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
          ),
          const SizedBox(height: 12),

          // ── KARTU MASTER TINGKAT PERTAMA ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Nebula.teal, borderRadius: BorderRadius.circular(6)),
                          child: Text('Tingkat $firstG', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                        Text('Master Kelas', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _showAddClassDialog(context, targetGrade: firstG, isMaster: true),
                      child: Text('+ Tambah Kelas', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (firstGradeClasses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Belum ada kelas. Klik "+ Tambah Kelas" di atas.',
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
                const SizedBox(height: 10),
                Divider(height: 1, color: context.dividerCol),
                const SizedBox(height: 8),

                // Switch Otomatis Terapkan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        otherGrades.isNotEmpty
                            ? 'Terapkan otomatis ke Kelas ${otherGrades.join(", ")}'
                            : 'Terapkan otomatis ke semua tingkat',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        value: _autoSyncToOtherGrades,
                        activeTrackColor: Nebula.teal,
                        onChanged: (val) => setState(() => _autoSyncToOtherGrades = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── TAB PRATINJAU SEMUA TINGKAT ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Rombel Terdaftar (${_rombels.length})',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
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

          _buildTabbedGradePreview(context),
        ],
      ),
    );
  }

  Widget _buildTabbedGradePreview(BuildContext context) {
    if (_gradeLevels.isEmpty) return const SizedBox.shrink();

    if (_selectedGradeIndex >= _gradeLevels.length) {
      _selectedGradeIndex = 0;
    }

    final activeGrade = _gradeLevels[_selectedGradeIndex];
    final activeGradeRombels = _rombels.where((r) => _matchesGrade(r, activeGrade)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      border: Border.all(color: isSelected ? Nebula.teal : context.dividerCol, width: 0.6),
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

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.dividerCol, width: 0.6),
          ),
          child: activeGradeRombels.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text('Belum ada kelas di Tingkat $activeGrade.', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
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

  // ── Dialogs ────────────────────────────────────────────────────────────────
  void _showAddOrEditMajorDialog({AcademicMajor? existing, int? index}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final isEdit = existing != null;

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
                isEdit ? 'Edit Jurusan' : 'Tambah Jurusan Baru',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 12.5, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap (Contoh: Rekayasa Perangkat Lunak)',
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
                  labelText: 'Kode Singkatan (Contoh: RPL)',
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
                          final newMajor = AcademicMajor(
                            id: isEdit ? existing.id : code.toLowerCase(),
                            name: name,
                            code: code,
                          );
                          if (isEdit && index != null) {
                            _majors[index] = newMajor;
                          } else {
                            _majors.add(newMajor);
                          }
                          _autoGenerateRombels();
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(isEdit ? 'Simpan' : 'Tambah'),
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

  void _showAddGradeDialog() {
    final gradeCtrl = TextEditingController();
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
              Text('Tambah Tingkat Kelas', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: gradeCtrl,
                style: GoogleFonts.inter(fontSize: 12.5, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Tingkat (Contoh: XIII / 10 / VII)',
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
                        final val = gradeCtrl.text.trim().toUpperCase();
                        if (val.isNotEmpty && !_gradeLevels.contains(val)) {
                          setState(() {
                            _gradeLevels.add(val);
                            _autoGenerateRombels();
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

  void _showAddClassDialog(BuildContext context, {required String targetGrade, required bool isMaster}) {
    final ctrl = TextEditingController();

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
