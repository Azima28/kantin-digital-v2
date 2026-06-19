import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'Semua'; // 'Semua', 'Keuangan', 'Kantin', 'Siswa', 'Orang Tua'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper map client role string to UI label
  String _getRoleLabel(String dbRole) {
    switch (dbRole) {
      case 'student':
        return 'Siswa';
      case 'petugas_kantin':
        return 'Kantin';
      case 'parent':
        return 'Orang Tua';
      case 'petugas_keuangan':
        return 'Keuangan';
      case 'super_admin':
      case 'admin':
        return 'Admin';
      default:
        return dbRole;
    }
  }

  // Mapping role filter to db role key
  String? _getDbRoleKey(String filter) {
    switch (filter) {
      case 'Siswa':
        return 'student';
      case 'Kantin':
        return 'petugas_kantin';
      case 'Orang Tua':
        return 'parent';
      case 'Keuangan':
        return 'petugas_keuangan';
      default:
        return null;
    }
  }

  Future<void> _toggleUserStatus(String profileId, String role, bool currentStatus) async {
    final client = ref.read(supabaseClientProvider);
    final bool newStatus = !currentStatus;

    try {
      // 1. Update profiles table
      await client.from('profiles').update({'is_active': newStatus}).eq('id', profileId);

      // 2. If student, update students table as well
      if (role == 'student') {
        await client.from('students').update({'is_active': newStatus}).eq('id', profileId);
      }

      // Write to audit logs
      try {
        final authProfile = ref.read(authNotifierProvider).profile;
        final actorName = authProfile?['full_name'] ?? 'Super Admin';
        final actorId = authProfile?['id'];

        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': newStatus ? 'AKTIFKAN_AKUN' : 'BLOKIR_AKUN',
          'description': 'Super Admin ${newStatus ? "mengaktifkan" : "memblokir"} akun dengan ID: $profileId (Role: $role)',
          'target_id': profileId,
          'old_value': {'is_active': currentStatus},
          'new_value': {'is_active': newStatus},
        });
      } catch (_) {}

      // Refresh list
      ref.invalidate(adminUsersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status akun berhasil ${newStatus ? "diaktifkan" : "dinonaktifkan"}.'),
            backgroundColor: const Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status akun: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToDetail(String profileId, String dbRole) {
    switch (dbRole) {
      case 'student':
        context.push('/admin/users/student/$profileId');
        break;
      case 'petugas_kantin':
        context.push('/admin/users/merchant/$profileId');
        break;
      case 'petugas_keuangan':
        context.push('/admin/users/finance/$profileId');
        break;
      case 'parent':
        context.push('/admin/users/parent/$profileId');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detail untuk peran Admin dikelola langsung dari database.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    const Color primaryTeal = Color(0xFF003434);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kelola Akun Pengguna',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        actions: [
          if (_selectedRoleFilter != 'Semua' &&
              _selectedRoleFilter != 'Admin' &&
              _selectedRoleFilter != 'Orang Tua')
            IconButton(
              icon: const Icon(CupertinoIcons.square_arrow_down, color: primaryTeal),
              tooltip: 'Import $_selectedRoleFilter (CSV)',
              onPressed: () => _showImportUsersDialog(context, _selectedRoleFilter),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                // Search input field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEDEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase().trim();
                      });
                    },
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama, email, NISN, usn...',
                      hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                      prefixIcon: Icon(CupertinoIcons.search, color: Color(0xFF6F7978)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cupertino Segmented Control Filter Peran
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CupertinoSegmentedControl<String>(
                      groupValue: _selectedRoleFilter,
                      selectedColor: primaryTeal,
                      unselectedColor: Colors.white,
                      borderColor: const Color(0xFFE4E2E1),
                      pressedColor: primaryTeal.withValues(alpha: 0.1),
                      children: {
                        'Semua': _buildRoleFilterSegment('Semua'),
                        'Keuangan': _buildRoleFilterSegment('Keuangan'),
                        'Kantin': _buildRoleFilterSegment('Kantin'),
                        'Siswa': _buildRoleFilterSegment('Siswa'),
                        'Orang Tua': _buildRoleFilterSegment('Orang Tua'),
                      },
                      onValueChanged: (val) {
                        setState(() {
                          _selectedRoleFilter = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // Filter by role
                final dbRoleFilter = _getDbRoleKey(_selectedRoleFilter);
                var filtered = users;
                if (dbRoleFilter != null) {
                  filtered = filtered.where((u) => u.role == dbRoleFilter).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((u) {
                    final fullName = (u.fullName ?? '').toLowerCase();
                    final email = (u.email ?? '').toLowerCase();
                    final username = (u.username ?? '').toLowerCase();
                    final nisn = (u.nisn ?? '').toLowerCase();
                    return fullName.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        username.contains(_searchQuery) ||
                        nisn.contains(_searchQuery);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada pengguna ditemukan.',
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.textGray,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminUsersProvider);
                  },
                  color: primaryTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final String id = user.id;
                      final String fullName = user.fullName ?? 'User Baru';
                      final String role = user.role ?? 'student';
                      final String email = user.email ?? '';
                      final String username = user.username ?? '';
                      final String nisn = user.nisn ?? '';
                      final bool isActive = user.isActive ?? true;

                      // Build descriptive subtitle
                      String subText = '';
                      if (role == 'student') {
                        subText = 'NISN: ${nisn.isNotEmpty ? nisn : "-"} • USN: $username';
                      } else if (role == 'petugas_kantin') {
                        subText = 'USN: $username';
                      } else if (role == 'petugas_keuangan') {
                        subText = 'TU • USN: $username';
                      } else if (role == 'parent') {
                        subText = 'Email: $email';
                      } else {
                        subText = 'Email: $email';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24), // Wide radii
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                // Avatar profile picture
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: primaryTeal.withValues(alpha: 0.1),
                                  child: Icon(
                                    role == 'student'
                                        ? CupertinoIcons.person
                                        : (role == 'petugas_kantin'
                                            ? Icons.shopping_bag
                                            : CupertinoIcons.person_solid),
                                    color: primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // User info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1B1C1B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Role badge chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primaryTeal.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                            child: Text(
                                              _getRoleLabel(role),
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: primaryTeal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subText,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE4E2E1)),
                            const SizedBox(height: 12),
                            
                            // Cupertino Switch & Action button
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final statusControl = Row(
                                  children: [
                                    Text(
                                      'Status: ',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        color: const Color(0xFF3F4848),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        isActive ? 'AKTIF' : 'DIBLOKIR',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? const Color(0xFF006A35) : const Color(0xFFBA1A1A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 44,
                                      height: 28,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: CupertinoSwitch(
                                          value: isActive,
                                          activeTrackColor: primaryTeal,
                                          onChanged: (val) => _toggleUserStatus(id, role, isActive),
                                        ),
                                      ),
                                    ),
                                  ],
                                );

                                final detailLink = InkWell(
                                  onTap: () => _navigateToDetail(id, role),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Detail & Riwayat',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: primaryTeal,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 14,
                                          color: primaryTeal,
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (constraints.maxWidth < 330) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      statusControl,
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: detailLink,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: statusControl),
                                    const SizedBox(width: 12),
                                    detailLink,
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator(color: primaryTeal)),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: (_selectedRoleFilter != 'Semua' &&
              _selectedRoleFilter != 'Orang Tua')
          ? FloatingActionButton.small(
              backgroundColor: primaryTeal,
              shape: const CircleBorder(),
              child: const Icon(CupertinoIcons.add, color: Colors.white),
              onPressed: () => _showAddUserSheet(context, _selectedRoleFilter),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showImportUsersDialog(BuildContext context, String roleFilter) {
    final TextEditingController csvCtrl = TextEditingController();
    bool isProcessing = false;

    String formatGuidance = '';
    String hintText = '';
    String templateText = '';

    if (roleFilter == 'Siswa') {
      formatGuidance = 'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, NISN, Kelas, Password';
      hintText = 'Ahmad Fauzi, ahmad@sekolah.sch.id, 20260001, 7-A, password123\nSiti Aminah, siti@sekolah.sch.id, 20260002, 7-B, password123';
      templateText = 'Ahmad Fauzi, ahmad@sekolah.sch.id, 20260001, 7-A, password123\n'
          'Siti Aminah, siti@sekolah.sch.id, 20260002, 7-B, password123\n'
          'Budi Santoso, budi@sekolah.sch.id, 20260003, 8-A, password123';
    } else if (roleFilter == 'Orang Tua') {
      formatGuidance = 'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, No Telepon, NISN Anak, Hubungan, Password';
      hintText = 'Salim Subarjo, salim@example.com, +62812345678, 20260001, Ayah, password123';
      templateText = 'Salim Subarjo, salim@example.com, +62812345678, 20260001, Ayah, password123\n'
          'Rina Aminah, rina@example.com, +62898765432, 20260002, Ibu, password123';
    } else if (roleFilter == 'Kantin') {
      formatGuidance = 'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, Nama Stan, Username, Password';
      hintText = 'Stan Bakso, bakso@canteen.com, Stan Bakso Enak, bakso_stan, password123';
      templateText = 'Stan Bakso, bakso@canteen.com, Stan Bakso Enak, bakso_stan, password123\n'
          'Stan Nasi Goreng, nasgor@canteen.com, Stan Nasgor, nasgor_stan, password123';
    } else if (roleFilter == 'Keuangan') {
      formatGuidance = 'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, Sekolah, Tingkat Wewenang (L1/L2/L3), Password';
      hintText = 'Budi Finance, budi.fin@sekolah.sch.id, SMP Terpadu, L1, password123';
      templateText = 'Budi Finance, budi.fin@sekolah.sch.id, SMP Terpadu, L1, password123\n'
          'Siti Finance, siti.fin@sekolah.sch.id, SMP Terpadu, L2, password123';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(
              'Import $roleFilter Baru (CSV)',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatGuidance,
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6F7978)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: csvCtrl,
                    maxLines: 8,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isProcessing ? null : () {
                          csvCtrl.text = templateText;
                        },
                        child: Text('Gunakan Template', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003434),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        final text = csvCtrl.text.trim();
                        if (text.isEmpty) return;

                        setLocal(() {
                          isProcessing = true;
                        });

                        final client = ref.read(supabaseClientProvider);
                        final lines = text.split('\n');
                        int successCount = 0;
                        int failCount = 0;
                        List<String> errors = [];

                        for (var line in lines) {
                          final trimmed = line.trim();
                          if (trimmed.isEmpty) continue;
                          
                          if (trimmed.toLowerCase().startsWith('nama,') ||
                              trimmed.toLowerCase().startsWith('name,') ||
                              trimmed.toLowerCase().startsWith('email,')) {
                            continue;
                          }

                          final parts = trimmed.split(',');

                          if (roleFilter == 'Siswa') {
                            if (parts.length < 5) {
                              failCount++;
                              errors.add('Format salah (baris: "$trimmed")');
                              continue;
                            }
                            final name = parts[0].trim();
                            final email = parts[1].trim();
                            final nisn = parts[2].trim();
                            final sClass = parts[3].trim();
                            final password = parts[4].trim();

                            if (name.isEmpty || email.isEmpty || nisn.isEmpty || sClass.isEmpty || password.isEmpty) {
                              failCount++;
                              errors.add('Data kolom kosong (baris: "$trimmed")');
                              continue;
                            }

                            try {
                              final username = 'student_$nisn';
                              await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': password,
                                'p_full_name': name,
                                'p_role': 'student',
                                'p_username': username,
                                'p_nisn': nisn,
                                'p_class': sClass,
                                'p_is_active': false,
                              });
                              successCount++;
                            } catch (e) {
                              failCount++;
                              errors.add('Error $name: $e');
                            }
                          } else if (roleFilter == 'Orang Tua') {
                            if (parts.length < 6) {
                              failCount++;
                              errors.add('Format salah (baris: "$trimmed")');
                              continue;
                            }
                            final name = parts[0].trim();
                            final email = parts[1].trim();
                            final phone = parts[2].trim();
                            final childNisn = parts[3].trim();
                            final relation = parts[4].trim();
                            final password = parts[5].trim();

                            if (name.isEmpty || email.isEmpty || phone.isEmpty || childNisn.isEmpty || relation.isEmpty || password.isEmpty) {
                              failCount++;
                              errors.add('Data kolom kosong (baris: "$trimmed")');
                              continue;
                            }

                            try {
                              final newProfile = await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': password,
                                'p_full_name': name,
                                'p_role': 'parent',
                                'p_phone_number': phone,
                                'p_relation': relation,
                                'p_is_active': true,
                              });

                              final parentId = newProfile['id'];
                              final student = await client
                                  .from('profiles')
                                  .select('id')
                                  .eq('nisn', childNisn)
                                  .eq('role', 'student')
                                  .maybeSingle();

                              if (student != null) {
                                final studentId = student['id'];
                                await client.from('parent_students').insert({
                                  'parent_id': parentId,
                                  'student_id': studentId,
                                });
                              }

                              successCount++;
                            } catch (e) {
                              failCount++;
                              errors.add('Error $name: $e');
                            }
                          } else if (roleFilter == 'Kantin') {
                            if (parts.length < 5) {
                              failCount++;
                              errors.add('Format salah (baris: "$trimmed")');
                              continue;
                            }
                            final name = parts[0].trim();
                            final email = parts[1].trim();
                            final canteenName = parts[2].trim();
                            final username = parts[3].trim();
                            final password = parts[4].trim();

                            if (name.isEmpty || email.isEmpty || canteenName.isEmpty || username.isEmpty || password.isEmpty) {
                              failCount++;
                              errors.add('Data kolom kosong (baris: "$trimmed")');
                              continue;
                            }

                            try {
                              await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': password,
                                'p_full_name': name,
                                'p_role': 'petugas_kantin',
                                'p_phone_number': null,
                                'p_username': username,
                                'p_canteen_name': canteenName,
                                'p_is_active': true,
                              });
                              successCount++;
                            } catch (e) {
                              failCount++;
                              errors.add('Error $name: $e');
                            }
                          } else if (roleFilter == 'Keuangan') {
                            if (parts.length < 5) {
                              failCount++;
                              errors.add('Format salah (baris: "$trimmed")');
                              continue;
                            }
                            final name = parts[0].trim();
                            final email = parts[1].trim();
                            final school = parts[2].trim();
                            final authLevel = parts[3].trim();
                            final password = parts[4].trim();

                            if (name.isEmpty || email.isEmpty || school.isEmpty || authLevel.isEmpty || password.isEmpty) {
                              failCount++;
                              errors.add('Data kolom kosong (baris: "$trimmed")');
                              continue;
                            }

                            try {
                              final newProfile = await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': password,
                                'p_full_name': name,
                                'p_role': 'petugas_keuangan',
                                'p_is_active': true,
                              });

                              final officerId = newProfile['id'];
                              await client.from('finance_officers').update({
                                'assigned_school': school,
                                'authority_level': authLevel,
                              }).eq('id', officerId);

                              successCount++;
                            } catch (e) {
                              failCount++;
                              errors.add('Error $name: $e');
                            }
                          }
                        }

                        // Write to Audit Log if successCount > 0
                        if (successCount > 0) {
                          try {
                            final authProfile = ref.read(authNotifierProvider).profile;
                            final actorName = authProfile?['full_name'] ?? 'Super Admin';
                            final actorId = authProfile?['id'];

                            final String actionType = roleFilter == 'Siswa'
                                ? 'IMPORT_SISWA'
                                : roleFilter == 'Orang Tua'
                                    ? 'IMPORT_WALI'
                                    : roleFilter == 'Kantin'
                                        ? 'IMPORT_KANTIN'
                                        : 'IMPORT_KEUANGAN';

                            await client.from('audit_logs').insert({
                              'actor_id': actorId,
                              'actor_name': actorName,
                              'action_type': actionType,
                              'description': 'Berhasil mengimport $successCount $roleFilter secara massal dari CSV.',
                              'new_value': {'imported_count': successCount},
                            });
                          } catch (_) {}
                        }

                        // Refresh list
                        ref.invalidate(adminUsersProvider);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          // Show results
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text('Hasil Import', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sukses: $successCount $roleFilter', style: GoogleFonts.beVietnamPro(color: Colors.green, fontWeight: FontWeight.bold)),
                                    Text('Gagal: $failCount $roleFilter', style: GoogleFonts.beVietnamPro(color: Colors.red, fontWeight: FontWeight.bold)),
                                    if (errors.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text('Detail Error:', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      ...errors.map((err) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text('- $err', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.red)),
                                          )),
                                    ]
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text('Tutup', style: GoogleFonts.beVietnamPro()),
                                )
                              ],
                            ),
                          );
                        }
                      },
                child: isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator(color: Colors.white))
                    : Text('Proses Import', style: GoogleFonts.beVietnamPro()),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleFilterSegment(String label) {
    return SizedBox(
      width: label == 'Orang Tua' ? 104 : 92,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddUserSheet(BuildContext context, String roleFilter) {
    if (roleFilter == 'Siswa') {
      _showAddStudentSheet(context);
    } else if (roleFilter == 'Kantin') {
      _showAddCanteenSheet(context);
    } else if (roleFilter == 'Keuangan') {
      _showAddFinanceSheet(context);
    }
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
                      icon: const Icon(CupertinoIcons.refresh, size: 18, color: Color(0xFF003434)),
                      onPressed: () => setLocal(() => passCtrl.text = 'siswa${_randomSuffix()}'),
                    )),
                const SizedBox(height: 20),
                _sectionLabel('KARTU RFID / NFC'),
                const SizedBox(height: 8),
                _buildFormField(rfidCtrl, 'RFID UID / Nomor Kartu (Opsional)'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003434),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final nisn = nisnCtrl.text.trim();
                            final password = passCtrl.text.trim();
                            final rfid = rfidCtrl.text.trim();
                            if (name.isEmpty || nisn.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama, NISN, dan password wajib diisi')),
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
                              final rfidVal = rfid.isNotEmpty ? rfid : null;

                              // Call RPC function to create the user account
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
                                'p_rfid_uid': rfidVal,
                                'p_parent_phone': parentPhone,
                              });

                              final String studentId = newProfile['id'];

                              // Write to audit logs
                              try {
                                final authProfile = ref.read(authNotifierProvider).profile;
                                final actorName = authProfile?['full_name'] ?? 'Super Admin';
                                final actorId = authProfile?['id'];

                                await client.from('audit_logs').insert({
                                  'actor_id': actorId,
                                  'actor_name': actorName,
                                  'action_type': 'TAMBAH_PENGGUNA',
                                  'description': 'Super Admin menambahkan siswa baru secara manual: $name (NISN: $nisn)',
                                  'target_id': studentId,
                                  'new_value': {
                                    'full_name': name,
                                    'email': email,
                                    'nisn': nisn,
                                    'class': selectedClass,
                                    'rfid_uid': rfidVal,
                                  },
                                });
                              } catch (_) {}

                              ref.invalidate(adminUsersProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name berhasil didaftarkan sebagai siswa'),
                                    backgroundColor: const Color(0xFF006A35),
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocal(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                    backgroundColor: const Color(0xFFBA1A1A),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            'SIMPAN & DAFTARKAN SISWA',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  void _showAddCanteenSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'kantin${_randomSuffix()}');
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
            right: 20,
          ),
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
                  'Tambah Petugas Kantin Baru',
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
                _buildFormField(
                  phoneCtrl,
                  'Nomor HP *',
                  inputType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  emailCtrl,
                  'Email (Opsional)',
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _sectionLabel('AKUN SISTEM'),
                const SizedBox(height: 8),
                _buildFormField(usernameCtrl, 'Username *'),
                const SizedBox(height: 12),
                _buildFormField(
                  passCtrl,
                  'Password Awal *',
                  suffix: IconButton(
                    icon: const Icon(
                      CupertinoIcons.refresh,
                      size: 18,
                      color: Color(0xFF003434),
                    ),
                    onPressed: () => setLocal(
                      () => passCtrl.text = 'kantin${_randomSuffix()}',
                    ),
                  ),
                ),
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
                      backgroundColor: const Color(0xFF003434),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                usernameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nama dan username wajib diisi',
                                  ),
                                ),
                              );
                              return;
                            }
                            setLocal(() => isSaving = true);
                            try {
                              final client = ref.read(supabaseClientProvider);
                              final email = emailCtrl.text.trim().isEmpty
                                  ? '${usernameCtrl.text.trim()}@sekolah.sch.id'
                                  : emailCtrl.text.trim();

                              final newProfile = await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': passCtrl.text.trim(),
                                'p_full_name': nameCtrl.text.trim(),
                                'p_role': 'petugas_kantin',
                                'p_phone_number': phoneCtrl.text.trim(),
                                'p_username': usernameCtrl.text.trim(),
                                'p_canteen_name': selectedCanteen != 'Belum Dipilih' ? selectedCanteen : 'Stan Kantin',
                                'p_is_active': true,
                              });

                              // Write to audit logs
                              try {
                                final staffId = newProfile['id'];
                                final authProfile = ref.read(authNotifierProvider).profile;
                                final actorName = authProfile?['full_name'] ?? 'Super Admin';
                                final actorId = authProfile?['id'];

                                await client.from('audit_logs').insert({
                                  'actor_id': actorId,
                                  'actor_name': actorName,
                                  'action_type': 'TAMBAH_PENGGUNA',
                                  'description': 'Super Admin menambahkan petugas kantin baru secara manual: ${nameCtrl.text.trim()}',
                                  'target_id': staffId,
                                  'new_value': {
                                    'full_name': nameCtrl.text.trim(),
                                    'username': usernameCtrl.text.trim(),
                                    'role': 'petugas_kantin',
                                  },
                                });
                              } catch (_) {}

                              ref.invalidate(adminUsersProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${nameCtrl.text.trim()} berhasil ditambahkan',
                                    ),
                                    backgroundColor: const Color(0xFF006A35),
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocal(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                    backgroundColor: const Color(0xFFBA1A1A),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            'SIMPAN & AKTIFKAN PETUGAS',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  void _showAddFinanceSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'keu${_randomSuffix()}');
    String school = 'SMP Terpadu';
    String authLevel = 'L1';
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
            right: 20,
          ),
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
                  'Tambah Admin Keuangan Baru',
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
                _buildFormField(
                  emailCtrl,
                  'Email (Opsional)',
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _sectionLabel('AKUN SISTEM'),
                const SizedBox(height: 8),
                _buildFormField(usernameCtrl, 'Username *'),
                const SizedBox(height: 12),
                _buildFormField(
                  passCtrl,
                  'Password Awal *',
                  suffix: IconButton(
                    icon: const Icon(
                      CupertinoIcons.refresh,
                      size: 18,
                      color: Color(0xFF003434),
                    ),
                    onPressed: () => setLocal(
                      () => passCtrl.text = 'keu${_randomSuffix()}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('PENUGASAN SEKOLAH & WEWENANG'),
                const SizedBox(height: 8),
                _buildDropdownRow(
                  label: 'Sekolah',
                  value: school,
                  items: ['SMP Terpadu'],
                  onChanged: (v) => setLocal(() => school = v ?? school),
                ),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Tingkat Wewenang',
                  value: authLevel,
                  items: ['L1', 'L2', 'L3'],
                  onChanged: (v) => setLocal(() => authLevel = v ?? authLevel),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003434),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                usernameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nama dan username wajib diisi',
                                  ),
                                ),
                              );
                              return;
                            }
                            setLocal(() => isSaving = true);
                            try {
                              final client = ref.read(supabaseClientProvider);
                              final email = emailCtrl.text.trim().isEmpty
                                  ? '${usernameCtrl.text.trim()}@sekolah.sch.id'
                                  : emailCtrl.text.trim();

                              final newProfile = await client.rpc('create_user_account', params: {
                                'p_email': email,
                                'p_password': passCtrl.text.trim(),
                                'p_full_name': nameCtrl.text.trim(),
                                'p_role': 'petugas_keuangan',
                                'p_username': usernameCtrl.text.trim(),
                                'p_is_active': true,
                              });

                              final officerId = newProfile['id'];
                              await client.from('finance_officers').update({
                                'assigned_school': school,
                                'authority_level': authLevel,
                              }).eq('id', officerId);

                              // Write to audit logs
                              try {
                                final authProfile = ref.read(authNotifierProvider).profile;
                                final actorName = authProfile?['full_name'] ?? 'Super Admin';
                                final actorId = authProfile?['id'];

                                await client.from('audit_logs').insert({
                                  'actor_id': actorId,
                                  'actor_name': actorName,
                                  'action_type': 'TAMBAH_PENGGUNA',
                                  'description': 'Super Admin menambahkan admin keuangan baru secara manual: ${nameCtrl.text.trim()}',
                                  'target_id': officerId,
                                  'new_value': {
                                    'full_name': nameCtrl.text.trim(),
                                    'username': usernameCtrl.text.trim(),
                                    'role': 'petugas_keuangan',
                                    'assigned_school': school,
                                    'authority_level': authLevel,
                                  },
                                });
                              } catch (_) {}

                              ref.invalidate(adminUsersProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${nameCtrl.text.trim()} berhasil ditambahkan',
                                    ),
                                    backgroundColor: const Color(0xFF006A35),
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocal(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                    backgroundColor: const Color(0xFFBA1A1A),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            'SIMPAN & AKTIFKAN PETUGAS KEUANGAN',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
          hintStyle: GoogleFonts.beVietnamPro(
            color: const Color(0xFF6F7978),
            fontSize: 14,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFFBF9F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFF003434), width: 1.5),
          ),
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
            Text(
              '$label: ',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: const Color(0xFF6F7978),
              ),
            ),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  style: GoogleFonts.beVietnamPro(
                    color: const Color(0xFF1B1C1B),
                    fontSize: 14,
                  ),
                  onChanged: onChanged,
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
              ),
            ),
          ],
        ),
      );
}

