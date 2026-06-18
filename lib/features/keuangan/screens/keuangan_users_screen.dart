import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final keuanganParentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final List<dynamic> res = await client
      .from('profiles')
      .select(
          'id, full_name, email, phone_number, is_active, created_at, children_profiles:profiles!parent_student_links_parent_id_fkey(full_name, nisn, students(class))')
      .eq('role', 'parent')
      .order('full_name', ascending: true);
  return List<Map<String, dynamic>>.from(res);
});

final keuanganStaffProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final List<dynamic> res = await client
      .from('profiles')
      .select(
          'id, full_name, username, phone_number, is_active, last_sign_in_at, canteen_operators(canteen_name, balance_earned, transaction_count)')
      .eq('role', 'petugas_kantin')
      .order('full_name', ascending: true);
  return List<Map<String, dynamic>>.from(res);
});

// ── Main Screen ─────────────────────────────────────────────────────────────

class KeuanganUsersScreen extends ConsumerStatefulWidget {
  const KeuanganUsersScreen({super.key});

  @override
  ConsumerState<KeuanganUsersScreen> createState() =>
      _KeuanganUsersScreenState();
}

class _KeuanganUsersScreenState extends ConsumerState<KeuanganUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);
  static const Color warningAmber = Color(0xFF7A5000);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Manajemen Pengguna',
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
            tooltip: _tabController.index == 0
                ? 'Tambah Orang Tua'
                : 'Tambah Petugas',
            onPressed: () => _showAddBottomSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryTeal,
              unselectedLabelColor: const Color(0xFF6F7978),
              indicatorColor: primaryTeal,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Orang Tua'),
                Tab(text: 'Petugas Kantin'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: _tabController.index == 0
                    ? 'Cari nama atau email...'
                    : 'Cari nama atau username...',
                hintStyle: GoogleFonts.beVietnamPro(
                    color: const Color(0xFF6F7978), fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search,
                    color: Color(0xFF6F7978)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid,
                            color: Color(0xFF6F7978), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
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
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ParentsTab(searchQuery: _searchQuery),
                _StaffTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    if (_tabController.index == 0) {
      _showAddParentSheet(context);
    } else {
      _showAddStaffSheet(context);
    }
  }

  void _showAddParentSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'ortu${_randomSuffix()}');
    final childNisnCtrl = TextEditingController();
    String relation = 'Ayah';
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
                  'Tambah Orang Tua',
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
                _buildDropdownRow(
                  label: 'Hubungan *',
                  value: relation,
                  items: ['Ayah', 'Ibu', 'Wali'],
                  onChanged: (v) => setLocal(() => relation = v ?? relation),
                ),
                const SizedBox(height: 12),
                _buildFormField(phoneCtrl, 'Nomor HP / WhatsApp *',
                    inputType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildFormField(emailCtrl, 'Email *',
                    inputType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _sectionLabel('AKUN SISTEM'),
                const SizedBox(height: 8),
                _buildFormField(passCtrl, 'Password Awal *',
                    suffix: IconButton(
                      icon: const Icon(CupertinoIcons.refresh,
                          size: 18, color: primaryTeal),
                      onPressed: () => setLocal(() =>
                          passCtrl.text = 'ortu${_randomSuffix()}'),
                    )),
                const SizedBox(height: 20),
                _sectionLabel('HUBUNGKAN KE SISWA (NISN)'),
                const SizedBox(height: 8),
                _buildFormField(childNisnCtrl, 'NISN Anak (opsional)',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                emailCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Nama dan email wajib diisi')),
                              );
                              return;
                            }
                            setLocal(() => isSaving = true);
                            try {
                              final client = ref.read(supabaseClientProvider);
                              // Insert new parent profile
                              await client.from('profiles').insert({
                                'full_name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'phone_number': phoneCtrl.text.trim(),
                                'role': 'parent',
                                'is_active': true,
                                'relation': relation,
                              });
                              ref.invalidate(keuanganParentsProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${nameCtrl.text.trim()} berhasil didaftarkan sebagai orang tua'),
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
                                      backgroundColor: dangerRed),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CupertinoActivityIndicator(
                            color: Colors.white)
                        : Text('SIMPAN & DAFTARKAN ORTU',
                            style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStaffSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl =
        TextEditingController(text: 'kantin${_randomSuffix()}');
    String? selectedCanteen;
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
                  'Tambah Petugas Kantin',
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
                _buildFormField(phoneCtrl, 'Nomor HP *',
                    inputType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildFormField(emailCtrl, 'Email (Opsional)',
                    inputType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _sectionLabel('AKUN SISTEM'),
                const SizedBox(height: 8),
                _buildFormField(usernameCtrl, 'Username *'),
                const SizedBox(height: 12),
                _buildFormField(passCtrl, 'Password Awal *',
                    suffix: IconButton(
                      icon: const Icon(CupertinoIcons.refresh,
                          size: 18, color: primaryTeal),
                      onPressed: () => setLocal(() =>
                          passCtrl.text = 'kantin${_randomSuffix()}'),
                    )),
                const SizedBox(height: 20),
                _sectionLabel('PENUGASAN STAN KANTIN'),
                const SizedBox(height: 8),
                _buildDropdownRow(
                  label: 'Stan Kantin',
                  value: selectedCanteen ?? 'Belum Dipilih',
                  items: [
                    'Belum Dipilih',
                    'Warung Bude Sari',
                    'Koperasi Minuman',
                    'Stan Bakso Pak Harto',
                    'Stan Nasi Goreng',
                  ],
                  onChanged: (v) => setLocal(() => selectedCanteen = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                usernameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Nama dan username wajib diisi')),
                              );
                              return;
                            }
                            setLocal(() => isSaving = true);
                            try {
                              final client = ref.read(supabaseClientProvider);
                              await client.from('profiles').insert({
                                'full_name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim().isEmpty
                                    ? null
                                    : emailCtrl.text.trim(),
                                'phone_number': phoneCtrl.text.trim(),
                                'username': usernameCtrl.text.trim(),
                                'role': 'petugas_kantin',
                                'is_active': true,
                              });
                              ref.invalidate(keuanganStaffProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${nameCtrl.text.trim()} berhasil ditambahkan'),
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
                                      backgroundColor: dangerRed),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CupertinoActivityIndicator(
                            color: Colors.white)
                        : Text('SIMPAN & AKTIFKAN PETUGAS',
                            style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
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
          hintStyle: GoogleFonts.beVietnamPro(
              color: const Color(0xFF6F7978), fontSize: 14),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFFBF9F8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            Text('$label: ',
                style: GoogleFonts.beVietnamPro(
                    fontSize: 13, color: const Color(0xFF6F7978))),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  style: GoogleFonts.beVietnamPro(
                      color: const Color(0xFF1B1C1B), fontSize: 14),
                  onChanged: onChanged,
                  items: items
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Parents Tab ─────────────────────────────────────────────────────────────

class _ParentsTab extends ConsumerWidget {
  final String searchQuery;
  const _ParentsTab({required this.searchQuery});

  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);
  static const Color warningAmber = Color(0xFF7A5000);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(keuanganParentsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganParentsProvider),
      color: primaryTeal,
      child: parentsAsync.when(
        data: (list) {
          final pending =
              list.where((p) => p['is_active'] != true).toList();
          final active = list.where((p) => p['is_active'] == true).toList();

          final filtered = list.where((p) {
            final name =
                (p['full_name'] ?? '').toString().toLowerCase();
            final email =
                (p['email'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) ||
                email.contains(searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState('Tidak ada orang tua yang terdaftar.',
                'Tambahkan orang tua dengan tombol [+] di atas.');
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Pending verification section
              if (pending.isNotEmpty && searchQuery.isEmpty) ...[
                _sectionHeader('⚠️  PERLU VERIFIKASI (${pending.length})'),
                const SizedBox(height: 8),
                ...pending.map((p) => _buildParentCard(context, ref, p,
                    isPending: true)),
                const SizedBox(height: 20),
              ],
              // All active parents
              _sectionHeader('SEMUA ORANG TUA (${filtered.length})'),
              const SizedBox(height: 8),
              ...filtered.map((p) => _buildParentCard(context, ref, p,
                  isPending: false)),
            ],
          );
        },
        loading: () => const Center(
            child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.xmark_circle,
                    size: 48, color: dangerRed),
                const SizedBox(height: 12),
                Text('Gagal memuat data: $e',
                    style: GoogleFonts.beVietnamPro(color: dangerRed),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: () => ref.invalidate(keuanganParentsProvider),
                    child: const Text('Coba Lagi')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6F7978),
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _buildParentCard(
      BuildContext context, WidgetRef ref, Map<String, dynamic> parent,
      {required bool isPending}) {
    final name = parent['full_name'] ?? 'Orang Tua';
    final email = parent['email'] ?? '-';
    final phone = parent['phone_number'] ?? '-';
    final isActive = parent['is_active'] == true;
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPending
            ? Border.all(color: warningAmber.withValues(alpha: 0.4), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isPending
                      ? warningAmber.withValues(alpha: 0.1)
                      : primaryTeal.withValues(alpha: 0.08),
                  child: Text(initials,
                      style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isPending ? warningAmber : primaryTeal)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF1B1C1B))),
                      Text(email,
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFF6F7978))),
                    ],
                  ),
                ),
                if (isPending)
                  _statusBadge('PENDING', warningAmber)
                else if (isActive)
                  _statusBadge('AKTIF', successGreen)
                else
                  _statusBadge('DIBLOKIR', dangerRed),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dangerRed,
                        side: const BorderSide(color: dangerRed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () =>
                          _rejectParent(context, ref, parent['id'], name),
                      child: Text('TOLAK',
                          style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () =>
                          _verifyParent(context, ref, parent['id'], name),
                      child: Text('VERIFIKASI',
                          style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.beVietnamPro(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _buildEmptyState(String title, String subtitle) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 30),
            child: Center(
              child: Column(
                children: [
                  const Icon(CupertinoIcons.person_2,
                      size: 64, color: Color(0xFF6F7978)),
                  const SizedBox(height: 16),
                  Text(title,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1B)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 13, color: const Color(0xFF6F7978)),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _verifyParent(BuildContext context, WidgetRef ref,
      String parentId, String name) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client.from('profiles').update({'is_active': true}).eq(
          'id', parentId);
      ref.invalidate(keuanganParentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$name berhasil diverifikasi'),
              backgroundColor: successGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'), backgroundColor: dangerRed),
        );
      }
    }
  }

  Future<void> _rejectParent(BuildContext context, WidgetRef ref,
      String parentId, String name) async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tolak Pendaftaran'),
        content: Text('Tolak pendaftaran orang tua "$name"?'),
        actions: [
          CupertinoDialogAction(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              final client = ref.read(supabaseClientProvider);
              try {
                await client
                    .from('profiles')
                    .update({'is_active': false}).eq('id', parentId);
                ref.invalidate(keuanganParentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Pendaftaran $name ditolak'),
                        backgroundColor: dangerRed),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: dangerRed),
                  );
                }
              }
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

// ── Staff Tab ────────────────────────────────────────────────────────────────

class _StaffTab extends ConsumerWidget {
  final String searchQuery;
  const _StaffTab({required this.searchQuery});

  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(keuanganStaffProvider);
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(keuanganStaffProvider),
      color: primaryTeal,
      child: staffAsync.when(
        data: (list) {
          final filtered = list.where((s) {
            final name = (s['full_name'] ?? '').toString().toLowerCase();
            final uname =
                (s['username'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) ||
                uname.contains(searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _sectionHeader('PETUGAS AKTIF (${filtered.length})'),
              const SizedBox(height: 8),
              ...filtered.map((s) => _buildStaffCard(context, ref, s, fmt)),
            ],
          );
        },
        loading: () => const Center(
            child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Gagal memuat: $e',
                style: GoogleFonts.beVietnamPro(color: dangerRed)),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6F7978),
                letterSpacing: 1.1)),
      );

  Widget _buildEmptyState() => ListView(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 30),
          child: Center(
            child: Column(
              children: [
                const Icon(CupertinoIcons.person_badge_plus_fill,
                    size: 64, color: Color(0xFF6F7978)),
                const SizedBox(height: 16),
                Text('Belum ada petugas kantin.',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1B))),
                const SizedBox(height: 6),
                Text('Tambahkan petugas dengan tombol [+] di atas.',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13, color: const Color(0xFF6F7978)),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ]);

  Widget _buildStaffCard(BuildContext context, WidgetRef ref,
      Map<String, dynamic> staff, NumberFormat fmt) {
    final name = staff['full_name'] ?? 'Petugas';
    final username = staff['username'] ?? '-';
    final isActive = staff['is_active'] == true;
    final lastLogin = staff['last_sign_in_at'];
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name[0].toUpperCase();

    // Check if logged in today
    bool loggedInToday = false;
    if (lastLogin != null) {
      final last = DateTime.tryParse(lastLogin)?.toLocal();
      final now = DateTime.now();
      loggedInToday = last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;
    }

    final canteenData =
        staff['canteen_operators'] as Map<String, dynamic>?;
    final canteenName = canteenData?['canteen_name'] ?? 'Belum Ada Stan';
    final omzet = double.tryParse(
            canteenData?['balance_earned']?.toString() ?? '0') ??
        0;
    final txCount = canteenData?['transaction_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryTeal.withValues(alpha: 0.08),
                  child: Text(initials,
                      style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryTeal)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: loggedInToday ? successGreen : const Color(0xFFE4E2E1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1B1C1B))),
                  Text(canteenName,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: const Color(0xFF6F7978))),
                  const SizedBox(height: 4),
                  Text(
                    'Omzet: ${fmt.format(omzet)} · $txCount Transaksi',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 11, color: const Color(0xFF6F7978)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: loggedInToday
                        ? successGreen.withValues(alpha: 0.1)
                        : const Color(0xFFE4E2E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loggedInToday ? 'LOGIN' : 'OFF',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: loggedInToday
                            ? successGreen
                            : const Color(0xFF6F7978)),
                  ),
                ),
                const SizedBox(height: 6),
                if (!isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dangerRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('NONAKTIF',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: dangerRed)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
