import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  
  // Fetch profiles with columns
  final List<dynamic> res = await client
      .from('profiles')
      .select('id, full_name, email, role, username, nisn, is_active')
      .order('full_name', ascending: true);
      
  return List<Map<String, dynamic>>.from(res);
});

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
                      children: const {
                        'Semua': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        'Keuangan': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('Keuangan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        'Kantin': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('Kantin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        'Siswa': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('Siswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        'Orang Tua': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('Orang Tua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
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
                  filtered = filtered.where((u) => u['role'] == dbRoleFilter).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((u) {
                    final fullName = (u['full_name'] ?? '').toString().toLowerCase();
                    final email = (u['email'] ?? '').toString().toLowerCase();
                    final username = (u['username'] ?? '').toString().toLowerCase();
                    final nisn = (u['nisn'] ?? '').toString().toLowerCase();
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
                      final String id = user['id'] ?? '';
                      final String fullName = user['full_name'] ?? 'User Baru';
                      final String role = user['role'] ?? 'student';
                      final String email = user['email'] ?? '';
                      final String username = user['username'] ?? '';
                      final String nisn = user['nisn'] ?? '';
                      final bool isActive = user['is_active'] ?? true;

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Status: ',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          color: const Color(0xFF3F4848),
                                        ),
                                      ),
                                      Text(
                                        isActive ? 'AKTIF' : 'DIBLOKIR',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? const Color(0xFF006A35) : const Color(0xFFBA1A1A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(width: 8),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: CupertinoSwitch(
                                          value: isActive,
                                          activeTrackColor: primaryTeal,
                                          onChanged: (val) => _toggleUserStatus(id, role, isActive),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Detail trigger link
                                InkWell(
                                  onTap: () => _navigateToDetail(id, role),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Detail & Riwayat',
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
                              ],
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
    );
  }
}
