import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/admin_import_csv_dialog.dart';
import 'package:kantin_digital/features/admin/widgets/admin_user_list_tile.dart';
import 'package:kantin_digital/features/admin/widgets/admin_user_search_filter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'Semua';
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
          'description':
              'Super Admin ${newStatus ? "mengaktifkan" : "memblokir"} akun dengan ID: $profileId (Role: $role)',
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
            content: Text(
              'Status akun berhasil ${newStatus ? "diaktifkan" : "dinonaktifkan"}.',
            ),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memperbarui status akun'),
            backgroundColor: Nebula.rose,
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
            content: Text(
              '${AppStrings.titleDetail} untuk peran Admin dikelola langsung dari database.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: context.surfaceBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kelola Akun Pengguna',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        actions: [
          if (_selectedRoleFilter != 'Semua' &&
              _selectedRoleFilter != 'Admin' &&
              _selectedRoleFilter != 'Orang Tua')
            IconButton(
              icon: const Icon(CupertinoIcons.square_arrow_down, color: Nebula.teal),
              tooltip: 'Import $_selectedRoleFilter (CSV)',
              onPressed: () =>
                  showImportUsersDialog(context, ref, _selectedRoleFilter),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters panel
          AdminUserSearchFilter(
            searchController: _searchController,
            selectedRoleFilter: _selectedRoleFilter,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            onRoleFilterChanged: (val) {
              setState(() {
                _selectedRoleFilter = val;
              });
            },
          ),

          // User list / grid
          Expanded(
            child: usersAsync.when(
              data: (users) {
                var filtered = users;

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
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminUsersProvider);
                  },
                  color: Nebula.teal,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth >= 700;

                      if (isWide) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 136,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            return AdminUserListTile(
                              user: user,
                              getRoleLabel: _getRoleLabel,
                              onToggleStatus: (id, role, isActive) =>
                                  _toggleUserStatus(id, role, isActive),
                              onNavigateToDetail: (id, role) =>
                                  _navigateToDetail(id, role),
                            );
                          },
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AdminUserListTile(
                              user: user,
                              getRoleLabel: _getRoleLabel,
                              onToggleStatus: (id, role, isActive) =>
                                  _toggleUserStatus(id, role, isActive),
                              onNavigateToDetail: (id, role) =>
                                  _navigateToDetail(id, role),
                            ),
                          );
                          },
                        );
                      },
                    ),
                  );
                },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: 6,
                itemBuilder: (context, index) => const SkeletonListTile(),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                    const SizedBox(height: 12),
                    Text('${AppStrings.labelFailed} memuat data'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminUsersProvider),
                      child: const Text(AppStrings.buttonRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
