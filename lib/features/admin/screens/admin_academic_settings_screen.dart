import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/academic_structure.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
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
  List<String> _gradeLevels = [];
  List<String> _rombels = [];
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
    _gradeLevels = List.from(s.gradeLevels);
    _rombels = List.from(s.rombels);
  }

  void _applySchoolTypePreset(String type) {
    setState(() {
      _schoolType = type;
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
            'VII-A', 'VII-B', 'VII-C',
            'VIII-A', 'VIII-B', 'VIII-C',
            'IX-A', 'IX-B', 'IX-C',
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
          content: Text('Daftar rombel tidak boleh kosong. Tambahkan minimal 1 rombel.'),
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
          'Struktur Akademik & Rombel',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 17,
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
    final steps = ['Jenjang & Jurusan', 'Tingkat Kelas', 'Master Rombel'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCurrent = _currentStep == index;
          final isPast = _currentStep > index;

          return Expanded(
            child: InkWell(
              onTap: () => _goToStep(index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: isCurrent
                              ? Nebula.teal
                              : (isPast ? Nebula.teal.withValues(alpha: 0.2) : context.dividerCol),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? Colors.white
                                  : (isPast ? Nebula.teal : context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: context.dividerCol),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _goToStep(_currentStep - 1),
              child: Text(
                'Kembali',
                style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Tombol Lanjut / Simpan Akhir
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
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
      {'key': 'smk', 'label': 'SMK / MAK', 'desc': 'Kejuruan / Banyak Jurusan'},
      {'key': 'sma', 'label': 'SMA / MA', 'desc': 'Umum / Peminatan MIPA/IPS'},
      {'key': 'smp', 'label': 'SMP / MTs', 'desc': 'Tanpa Jurusan (Kelas 7-9)'},
      {'key': 'sd', 'label': 'SD / MI', 'desc': 'Sekolah Dasar (Kelas 1-6)'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah 1: Tipe Jenjang & Master Jurusan',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Pilih jenjang sekolah Anda untuk menerapkan format standar secara otomatis.',
            style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
          ),
          const SizedBox(height: 12),

          // Pilihan Jenjang Grid 2 Kolom Ringkas
          Row(
            children: [
              Expanded(child: _buildSchoolTypeCard(context, schoolTypes[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildSchoolTypeCard(context, schoolTypes[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSchoolTypeCard(context, schoolTypes[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildSchoolTypeCard(context, schoolTypes[3])),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle Sistem Jurusan (Minimalis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        'Sistem Jurusan / Peminatan',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      Text(
                        'Aktif untuk SMK / SMA peminatan.',
                        style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
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

          // Master Jurusan List (Clean & Minimalist, No Oversized Cards)
          if (_hasMajors) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Jurusan (${_majors.length})',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
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
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal),
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
                      child: Text('+ Tambah', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
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
                  borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  major.name,
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textPrimary),
                                ),
                                Text(
                                  'Singkatan: ${major.code}',
                                  style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.pencil, size: 16, color: Nebula.teal),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => _showAddOrEditMajorDialog(existing: major, index: index),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.trash, size: 16, color: Nebula.rose),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal.withValues(alpha: 0.1) : context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.5 : 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  st['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Nebula.teal : context.textPrimary,
                  ),
                ),
                Icon(
                  isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                  color: isSelected ? Nebula.teal : context.textSecondary,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              st['desc']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 9.5, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── LANGKAH 2: Tingkat Kelas ───────────────────────────────────────────────
  Widget _buildStep2GradeLevels(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
          ),
          const SizedBox(height: 12),

          // Pilihan Format Cepat
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  onPressed: () {
                    setState(() {
                      _gradeLevels = ['X', 'XI', 'XII'];
                      _autoGenerateRombels();
                    });
                  },
                  child: Text('Romawi (X, XI, XII)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  onPressed: () {
                    setState(() {
                      _gradeLevels = ['10', '11', '12'];
                      _autoGenerateRombels();
                    });
                  },
                  child: Text('Angka (10, 11, 12)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daftar Tingkat Aktif
          Text(
            'Tingkat Aktif (${_gradeLevels.length})',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
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
                  label: Text('Kelas $grade', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 12)),
                  deleteIcon: const Icon(CupertinoIcons.xmark, size: 12, color: Nebula.rose),
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
                label: Text('+ Tingkat Baru', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 11.5)),
                onPressed: () => _showAddGradeDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LANGKAH 3: Master Rombel & Generator ───────────────────────────────────
  Widget _buildStep3Rombels(BuildContext context) {
    // Kelompokkan rombel berdasarkan tingkat kelas agar tertata rapi
    final Map<String, List<String>> grouped = {};
    for (final grade in _gradeLevels) {
      grouped[grade] = _rombels.where((r) => r.startsWith(grade)).toList();
    }
    // Sisa rombel kustom yang tidak diawali nama tingkat standar
    final customRombels = _rombels.where((r) => !_gradeLevels.any((g) => r.startsWith(g))).toList();
    if (customRombels.isNotEmpty) {
      grouped['Lainnya'] = customRombels;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah 3: Master Rombel (Kelas Paralel)',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Rombel yang terbentuk di sini otomatis digunakan di form pendaftaran siswa dan filter.',
            style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
          ),
          const SizedBox(height: 12),

          // Generator Ringkas & Bersih
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Nebula.teal.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.wand_rays, color: Nebula.teal, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Generator Otomatis',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                        ),
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
                      onPressed: () => _showAddCustomRombelDialog(),
                      child: Text('+ Kustom', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Jumlah Paralel: ', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                    const SizedBox(width: 4),
                    ...[1, 2, 3, 4].map((count) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _autoGenerateRombels(countPerMajor: count),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Nebula.teal, width: 0.8),
                            ),
                            child: Text('$count', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Organized Rombels by Grade
          Text(
            'Total Rombel Terdaftar (${_rombels.length})',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 8),

          if (_rombels.isEmpty)
            const EmptyStateWidget(message: 'Belum ada rombel. Klik generator di atas.')
          else
            ...grouped.entries.map((entry) {
              if (entry.value.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.dividerCol, width: 0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tingkat ${entry.key} (${entry.value.length})',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.value.map((rombel) {
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
                  ],
                ),
              );
            }),
        ],
      ),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ctx.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ctx.dividerCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Jurusan' : 'Tambah Jurusan Baru',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap (Contoh: Rekayasa Perangkat Lunak)',
                  labelStyle: GoogleFonts.inter(fontSize: 11.5),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kode Singkatan (Contoh: RPL)',
                  labelStyle: GoogleFonts.inter(fontSize: 11.5),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ctx.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ctx.dividerCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tambah Tingkat Kelas', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: gradeCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Tingkat (Contoh: XIII / 10 / VII)',
                  labelStyle: GoogleFonts.inter(fontSize: 11.5),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showAddCustomRombelDialog() {
    final rombelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ctx.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ctx.dividerCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tambah Rombel Kustom', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: rombelCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Rombel (Contoh: XII RPL Unggulan / X-A)',
                  labelStyle: GoogleFonts.inter(fontSize: 11.5),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                        final val = rombelCtrl.text.trim();
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
