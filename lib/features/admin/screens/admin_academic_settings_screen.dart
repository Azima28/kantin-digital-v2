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

class _AdminAcademicSettingsScreenState extends ConsumerState<AdminAcademicSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    AcademicMajor(id: 'otkp', name: 'Otomatisasi & Tata Kelola Perkantoran', code: 'OTKP'),
    AcademicMajor(id: 'tbsm', name: 'Teknik Bisnis Sepeda Motor', code: 'TBSM'),
    AcademicMajor(id: 'tkr', name: 'Teknik Kendaraan Ringan', code: 'TKR'),
    AcademicMajor(id: 'boga', name: 'Kuliner / Tata Boga', code: 'TBG'),
    AcademicMajor(id: 'hotel', name: 'Perhotelan', code: 'HTL'),
  ];

  static const List<AcademicMajor> _smaPresetMajors = [
    AcademicMajor(id: 'mipa', name: 'Matematika & Ilmu Pengetahuan Alam', code: 'MIPA'),
    AcademicMajor(id: 'ips', name: 'Ilmu Pengetahuan Sosial', code: 'IPS'),
    AcademicMajor(id: 'bahasa', name: 'Bahasa & Budaya', code: 'Bahasa'),
    AcademicMajor(id: 'merdeka_e', name: 'Kurikulum Merdeka (Fase E Umum)', code: 'Fase-E'),
    AcademicMajor(id: 'merdeka_f', name: 'Kurikulum Merdeka (Fase F Peminatan)', code: 'Fase-F'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Simpan Master',
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Nebula.teal, strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.checkmark_seal_fill, color: Nebula.teal, size: 24),
            onPressed: _isSaving ? null : _handleSave,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.dividerCol, width: 0.8),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Nebula.teal,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: Nebula.teal,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                const Tab(text: '1. Jenjang & Jurusan'),
                const Tab(text: '2. Tingkat Kelas'),
                Tab(text: '3. Master Rombel (${_rombels.length})'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabSchoolAndMajors(context),
            _buildTabGradeLevels(context),
            _buildTabRombels(context),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border(top: BorderSide(color: context.dividerCol, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(CupertinoIcons.checkmark_circle, size: 18, color: Colors.white),
            label: Text(
              _isSaving ? 'Menyimpan Master...' : 'Simpan Master Struktur (${_rombels.length} Rombel)',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            onPressed: _isSaving ? null : _handleSave,
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Jenjang & Jurusan ────────────────────────────────────────────────
  Widget _buildTabSchoolAndMajors(BuildContext context) {
    final schoolTypes = [
      {'key': 'smk', 'label': 'SMK / MAK', 'desc': 'Kejuruan (Banyak Jurusan)'},
      {'key': 'sma', 'label': 'SMA / MA', 'desc': 'Umum / Peminatan MIPA, IPS'},
      {'key': 'smp', 'label': 'SMP / MTs', 'desc': 'Menengah Pertama (Tanpa Jurusan)'},
      {'key': 'sd', 'label': 'SD / MI', 'desc': 'Sekolah Dasar (Tanpa Jurusan)'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipe & Jenjang Sekolah',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih jenjang sekolah untuk memuat preset jurusan dan penamaan rombel secara otomatis.',
            style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
          ),
          const SizedBox(height: 14),

          // School type selector cards
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: schoolTypes.map((st) {
              final isSelected = _schoolType == st['key'];
              return InkWell(
                onTap: () => _applySchoolTypePreset(st['key']!),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 50) / 2,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Nebula.teal.withValues(alpha: 0.1) : context.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Nebula.teal : context.dividerCol,
                      width: isSelected ? 1.5 : 0.8,
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Nebula.teal : context.textPrimary,
                            ),
                          ),
                          Icon(
                            isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                            color: isSelected ? Nebula.teal : context.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        st['desc']!,
                        style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Toggle sistem jurusan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.dividerCol, width: 0.8),
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
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aktifkan jika sekolah memiliki program keahlian/jurusan seperti di SMK/SMA.',
                        style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _hasMajors,
                  activeTrackColor: Nebula.teal,
                  onChanged: (val) {
                    setState(() {
                      _hasMajors = val;
                      if (!val) {
                        _autoGenerateRombels();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Daftar Jurusan
          if (_hasMajors) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Master Jurusan (${_majors.length})',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(CupertinoIcons.sparkles, size: 14, color: Nebula.teal),
                      label: Text('Preset ${_schoolType.toUpperCase()}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal)),
                      onPressed: () {
                        setState(() {
                          _majors = _schoolType == 'sma' ? List.from(_smaPresetMajors) : List.from(_smkPresetMajors);
                          _autoGenerateRombels();
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(CupertinoIcons.add, size: 14, color: Colors.white),
                      label: Text('Tambah', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddOrEditMajorDialog(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_majors.isEmpty)
              const EmptyStateWidget(message: 'Belum ada jurusan yang ditambahkan.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _majors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final major = _majors[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.dividerCol, width: 0.6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            major.code,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                major.name,
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              Text(
                                'Kode Singkatan: ${major.code}',
                                style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.pencil, size: 18, color: Nebula.teal),
                          onPressed: () => _showAddOrEditMajorDialog(existing: major, index: index),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.trash, size: 18, color: Nebula.rose),
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
          ],
        ],
      ),
    );
  }

  // ── Tab 2: Tingkat Kelas ────────────────────────────────────────────────────
  Widget _buildTabGradeLevels(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tingkat Kelas yang Aktif',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola tingkatan kelas yang digunakan di sekolah (misal: X, XI, XII atau 7, 8, 9).',
            style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
          ),
          const SizedBox(height: 16),

          // Pilihan Format Cepat
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  onPressed: () {
                    setState(() {
                      _gradeLevels = ['X', 'XI', 'XII'];
                      _autoGenerateRombels();
                    });
                  },
                  child: Text('Romawi (X, XI, XII)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Nebula.teal)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  onPressed: () {
                    setState(() {
                      _gradeLevels = ['10', '11', '12'];
                      _autoGenerateRombels();
                    });
                  },
                  child: Text('Angka (10, 11, 12)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Nebula.teal)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chip List Tingkat
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._gradeLevels.map((grade) {
                return Chip(
                  backgroundColor: Nebula.teal.withValues(alpha: 0.12),
                  side: BorderSide(color: Nebula.teal.withValues(alpha: 0.3)),
                  label: Text('Kelas $grade', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 13)),
                  deleteIcon: const Icon(CupertinoIcons.xmark, size: 14, color: Nebula.rose),
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
                avatar: const Icon(CupertinoIcons.add, size: 14, color: Nebula.teal),
                label: Text('Tambah Tingkat', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 12)),
                onPressed: () => _showAddGradeDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Master Rombel ────────────────────────────────────────────────────
  Widget _buildTabRombels(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smart Batch Generator Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Nebula.teal.withValues(alpha: 0.15), Nebula.tealDark.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Nebula.teal.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.wand_rays, color: Nebula.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Smart Batch Rombel Generator',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Buat seluruh rombel otomatis berdasarkan kombinasi tingkat (${_gradeLevels.join(', ')}) dan jurusan aktif (${_majors.map((m) => m.code).join(', ')}).',
                  style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Nebula.teal),
                        ),
                        onPressed: () => _autoGenerateRombels(countPerMajor: 2),
                        child: Text('2 Rombel / Jurusan', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Nebula.teal),
                        ),
                        onPressed: () => _autoGenerateRombels(countPerMajor: 3),
                        child: Text('3 Rombel / Jurusan', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Nebula.teal),
                        ),
                        onPressed: () => _autoGenerateRombels(countPerMajor: 4),
                        child: Text('4 Rombel / Jurusan', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Nebula.teal)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header Rombel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Rombel Aktif (${_rombels.length})',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Nebula.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(CupertinoIcons.add, size: 14, color: Colors.white),
                label: Text('Tambah Manual', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddCustomRombelDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rombel Grid
          if (_rombels.isEmpty)
            const EmptyStateWidget(message: 'Belum ada rombel. Gunakan generator atau tambah manual.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rombels.map((rombel) {
                return Chip(
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.dividerCol, width: 0.8),
                  label: Text(
                    rombel,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 12),
                  ),
                  deleteIcon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: Nebula.rose),
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
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Jurusan (Contoh: Rekayasa Perangkat Lunak)',
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kode / Singkatan (Contoh: RPL)',
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
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
              Text('Tambah Tingkat Kelas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: gradeCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Tingkat (Contoh: XIII / 10 / VII)',
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal'))),
                  const SizedBox(width: 10),
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
              Text('Tambah Rombel Kustom', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: rombelCtrl,
                style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Rombel (Contoh: XII RPL Unggulan / X-A)',
                  labelStyle: GoogleFonts.inter(fontSize: 12),
                  filled: true,
                  fillColor: ctx.surfaceBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal'))),
                  const SizedBox(width: 10),
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
