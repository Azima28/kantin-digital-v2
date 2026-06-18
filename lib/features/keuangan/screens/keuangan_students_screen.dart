import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final keuanganStudentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  
  // Fetch profiles that are students and join student details
  final List<dynamic> res = await client
      .from('profiles')
      .select('id, full_name, email, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid)')
      .eq('role', 'student')
      .order('full_name', ascending: true);
      
  return List<Map<String, dynamic>>.from(res);
});

class KeuanganStudentsScreen extends ConsumerStatefulWidget {
  const KeuanganStudentsScreen({super.key});

  @override
  ConsumerState<KeuanganStudentsScreen> createState() => _KeuanganStudentsScreenState();
}

class _KeuanganStudentsScreenState extends ConsumerState<KeuanganStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClass = 'Semua';
  String _selectedStatus = 'Semua';

  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(keuanganStudentsProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Manajemen Siswa',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filters Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NISN, atau kelas...',
                      hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 14),
                      prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF6F7978)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Filters
                  studentsAsync.when(
                    data: (list) {
                      // Get unique classes
                      final classes = {'Semua'};
                      for (var item in list) {
                        final studentData = item['students'];
                        if (studentData != null && studentData['class'] != null) {
                          classes.add(studentData['class'].toString());
                        }
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE4E2E1)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedClass,
                                  isExpanded: true,
                                  style: GoogleFonts.beVietnamPro(color: const Color(0xFF1B1C1B), fontSize: 13),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedClass = val;
                                      });
                                    }
                                  },
                                  items: classes.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(c == 'Semua' ? 'Semua Kelas' : 'Kelas $c'),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE4E2E1)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  style: GoogleFonts.beVietnamPro(color: const Color(0xFF1B1C1B), fontSize: 13),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedStatus = val;
                                      });
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
                                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                                    DropdownMenuItem(value: 'Diblokir', child: Text('Diblokir')),
                                    DropdownMenuItem(value: 'Terhubung', child: Text('Kartu Terhubung')),
                                    DropdownMenuItem(value: 'Belum Terhubung', child: Text('Belum Ada Kartu')),
                                    DropdownMenuItem(value: 'Saldo Rendah', child: Text('Saldo Rendah (<5k)')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),

            // Students List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(keuanganStudentsProvider),
                color: primaryTeal,
                child: studentsAsync.when(
                  data: (list) {
                    // Filter the list
                    final filtered = list.where((item) {
                      final fullName = (item['full_name'] ?? '').toString().toLowerCase();
                      final email = (item['email'] ?? '').toString().toLowerCase();
                      final nisn = (item['nisn'] ?? '').toString().toLowerCase();
                      final isAc = item['is_active'] == true;

                      final studentData = item['students'] as Map<String, dynamic>?;
                      final sClass = (studentData?['class'] ?? '').toString().toLowerCase();
                      final double sBalance = double.tryParse(studentData?['balance']?.toString() ?? '0') ?? 0.0;
                      final rfid = studentData?['rfid_uid'];

                      // Search query matching
                      final matchesSearch = fullName.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          nisn.contains(_searchQuery) ||
                          sClass.contains(_searchQuery);

                      // Class filter matching
                      final matchesClass = _selectedClass == 'Semua' || studentData?['class'] == _selectedClass;

                      // Status filter matching
                      bool matchesStatus = true;
                      if (_selectedStatus == 'Aktif') {
                        matchesStatus = isAc;
                      } else if (_selectedStatus == 'Diblokir') {
                        matchesStatus = !isAc;
                      } else if (_selectedStatus == 'Terhubung') {
                        matchesStatus = rfid != null;
                      } else if (_selectedStatus == 'Belum Terhubung') {
                        matchesStatus = rfid == null;
                      } else if (_selectedStatus == 'Saldo Rendah') {
                        matchesStatus = sBalance < 5000;
                      }

                      return matchesSearch && matchesClass && matchesStatus;
                    }).toList();

                    if (filtered.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 64, color: Color(0xFF6F7978)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Siswa tidak ditemukan',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Coba sesuaikan kata kunci pencarian Anda.',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      color: const Color(0xFF6F7978),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final studentId = item['id'];
                        final fullName = item['full_name'] ?? 'Siswa';
                        final nisn = item['nisn'] ?? '-';
                        final isActive = item['is_active'] == true;

                        final studentData = item['students'] as Map<String, dynamic>?;
                        final sClass = studentData?['class'] ?? 'Belum Diisi';
                        final double balance = double.tryParse(studentData?['balance']?.toString() ?? '0') ?? 0.0;
                        final String? rfid = studentData?['rfid_uid'];
                        final hasCard = rfid != null && rfid.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push('/finance/students/$studentId'),
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: primaryTeal.withValues(alpha: 0.08),
                                      child: Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Student info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: GoogleFonts.beVietnamPro(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: const Color(0xFF1B1C1B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'NISN: $nisn · Kelas $sClass',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 12,
                                              color: const Color(0xFF6F7978),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              // Card status pill
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: hasCard ? successGreen.withValues(alpha: 0.08) : const Color(0xFFE4E2E1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      hasCard ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clear_circled_solid,
                                                      size: 10,
                                                      color: hasCard ? successGreen : const Color(0xFF6F7978),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      hasCard ? 'TERHUBUNG' : 'BELUM LINK',
                                                      style: GoogleFonts.beVietnamPro(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: hasCard ? successGreen : const Color(0xFF6F7978),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Account status block
                                              if (!isActive)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: dangerRed.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'DIBLOKIR',
                                                    style: GoogleFonts.beVietnamPro(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: dangerRed,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Saldo
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Saldo',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 11,
                                            color: const Color(0xFF6F7978),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          fmt.format(balance),
                                          style: GoogleFonts.beVietnamPro(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: balance < 5000 ? dangerRed : const Color(0xFF1B1C1B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CupertinoActivityIndicator(color: primaryTeal),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Gagal memuat data: $e',
                        style: GoogleFonts.beVietnamPro(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
