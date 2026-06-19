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
      .select('id, full_name, email, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid, is_active)')
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
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid,
                color: primaryTeal, size: 26),
            tooltip: 'Tambah Siswa',
            onPressed: () => _showAddStudentSheet(context),
          ),
        ],
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
                                    DropdownMenuItem(value: 'Akun Diblokir', child: Text('Akun Diblokir')),
                                    DropdownMenuItem(value: 'Kartu Diblokir', child: Text('Kartu Diblokir')),
                                    DropdownMenuItem(value: 'Belum Aktif', child: Text('Belum Aktif')),
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
                        matchesStatus = isAc && rfid != null && rfid.isNotEmpty && (studentData?['is_active'] == true);
                      } else if (_selectedStatus == 'Akun Diblokir') {
                        matchesStatus = !isAc && rfid != null && rfid.isNotEmpty;
                      } else if (_selectedStatus == 'Kartu Diblokir') {
                        matchesStatus = isAc && (studentData?['is_active'] == false) && rfid != null && rfid.isNotEmpty;
                      } else if (_selectedStatus == 'Belum Aktif') {
                        matchesStatus = rfid == null || rfid.isEmpty;
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
                                              if (!isActive)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: dangerRed.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(CupertinoIcons.clear_circled_solid, size: 10, color: dangerRed),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'AKUN DIBLOKIR',
                                                        style: GoogleFonts.beVietnamPro(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: dangerRed,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else if (!hasCard)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE4E2E1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(CupertinoIcons.info_circle_fill, size: 10, color: Color(0xFF6F7978)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'BELUM AKTIF',
                                                        style: GoogleFonts.beVietnamPro(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFF6F7978),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else if (studentData?['is_active'] != true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFF9E6),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(CupertinoIcons.exclamationmark_circle_fill, size: 10, color: Color(0xFF8F6B00)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'KARTU DIBLOKIR',
                                                        style: GoogleFonts.beVietnamPro(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFF8F6B00),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: successGreen.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(CupertinoIcons.checkmark_circle_fill, size: 10, color: successGreen),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'AKTIF',
                                                        style: GoogleFonts.beVietnamPro(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: successGreen,
                                                        ),
                                                      ),
                                                    ],
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

  void _showAddStudentSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nisnCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final parentPhoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'siswa${_randomSuffix()}');
    final rfidCtrl = TextEditingController();
    String selectedClass = '7-A';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E2E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tambah Siswa Baru',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1C1B),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('INFORMASI PRIBADI'),
                const SizedBox(height: 8),
                _buildFormField(nameCtrl, 'Nama Lengkap *'),
                const SizedBox(height: 12),
                _buildFormField(nisnCtrl, 'NISN *', inputType: TextInputType.number),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Kelas *',
                  value: selectedClass,
                  items: ['7-A', '7-B', '7-C', '8-A', '8-B', '8-C', '9-A', '9-B', '9-C'],
                  onChanged: (v) => setLocal(() => selectedClass = v ?? selectedClass),
                ),
                const SizedBox(height: 12),
                _buildFormField(parentPhoneCtrl, 'Nomor HP Orang Tua (WhatsApp)', inputType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildFormField(emailCtrl, 'Email (Opsional, otomatis jika kosong)', inputType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _sectionLabel('AKUN SISTEM'),
                const SizedBox(height: 8),
                _buildFormField(usernameCtrl, 'Username (Opsional, otomatis jika kosong)'),
                const SizedBox(height: 12),
                _buildFormField(passCtrl, 'Password Awal *',
                    suffix: IconButton(
                      icon: const Icon(CupertinoIcons.refresh, size: 18, color: primaryTeal),
                      onPressed: () => setLocal(() => passCtrl.text = 'siswa${_randomSuffix()}'),
                    )),
                const SizedBox(height: 20),
                _sectionLabel('KARTU RFID / NFC'),
                const SizedBox(height: 8),
                _buildFormField(rfidCtrl, 'RFID UID / Nomor Kartu *'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final nisn = nisnCtrl.text.trim();
                            final password = passCtrl.text.trim();
                            final rfid = rfidCtrl.text.trim();
                            if (name.isEmpty || nisn.isEmpty || password.isEmpty || rfid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama, NISN, password, dan nomor kartu RFID wajib diisi')),
                              );
                              return;
                            }
                            setLocal(() => isSaving = true);
                            try {
                              final client = ref.read(supabaseClientProvider);
                              
                              final email = emailCtrl.text.trim().isNotEmpty
                                  ? emailCtrl.text.trim()
                                  : '$nisn@sekolah.sch.id';
                              final username = usernameCtrl.text.trim().isNotEmpty
                                  ? usernameCtrl.text.trim()
                                  : 'student_$nisn';
                              final parentPhone = parentPhoneCtrl.text.trim().isNotEmpty
                                  ? parentPhoneCtrl.text.trim()
                                  : null;
                              final rfid = rfidCtrl.text.trim().isNotEmpty
                                  ? rfidCtrl.text.trim()
                                  : null;

                              // 1. Call RPC function to create the user account
                              final newProfile = await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': password,
                                'p_full_name': name,
                                'p_role': 'student',
                                'p_phone_number': parentPhone,
                                'p_username': username,
                                'p_nisn': nisn,
                                'p_class': selectedClass,
                                'p_is_active': true,
                                'p_rfid_uid': rfid,
                                'p_parent_phone': parentPhone,
                              });

                              final String studentId = newProfile['id'];

                              // 3. Write to audit logs
                              try {
                                final authProfile = ref.read(authNotifierProvider).profile;
                                final actorName = authProfile?['full_name'] ?? 'Admin Keuangan';
                                final actorId = authProfile?['id'];

                                await client.from('audit_logs').insert({
                                  'actor_id': actorId,
                                  'actor_name': actorName,
                                  'action_type': 'TAMBAH_PENGGUNA',
                                  'description': 'Menambahkan siswa baru secara manual: $name (NISN: $nisn)',
                                  'target_id': studentId,
                                  'new_value': {
                                    'full_name': name,
                                    'email': email,
                                    'nisn': nisn,
                                    'class': selectedClass,
                                    'rfid_uid': rfid,
                                    'is_active': true,
                                  },
                                });
                              } catch (_) {}

                              ref.invalidate(keuanganStudentsProvider);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Siswa $name berhasil didaftarkan'),
                                    backgroundColor: successGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocal(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                    backgroundColor: dangerRed,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            'SIMPAN & DAFTARKAN SISWA',
                            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _randomSuffix() {
    final now = DateTime.now();
    return '${now.second}${now.millisecond % 100}';
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6F7978),
          letterSpacing: 1.2,
        ),
      );

  Widget _buildFormField(
    TextEditingController ctrl,
    String hint, {
    TextInputType inputType = TextInputType.text,
    Widget? suffix,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: GoogleFonts.beVietnamPro(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 14),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFFBF9F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
        ),
      );

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF9F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E2E1)),
        ),
        child: Row(
          children: [
            Text('$label: ', style: GoogleFonts.beVietnamPro(fontSize: 13, color: const Color(0xFF6F7978))),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  style: GoogleFonts.beVietnamPro(color: const Color(0xFF1B1C1B), fontSize: 14),
                  onChanged: onChanged,
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
              ),
            ),
          ],
        ),
      );
}
