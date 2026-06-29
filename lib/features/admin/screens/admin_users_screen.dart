import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/admin_import_csv_dialog.dart';
import 'package:kantin_digital/features/admin/widgets/admin_user_list_tile.dart';
import 'package:kantin_digital/features/admin/widgets/admin_add_student_sheet.dart';
import 'package:kantin_digital/features/admin/widgets/admin_user_search_filter.dart';
import 'package:kantin_digital/features/admin/widgets/admin_add_canteen_sheet.dart';
import 'package:kantin_digital/features/admin/widgets/admin_add_finance_sheet.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedRoleFilter = 'Semua'; // 'Semua', 'Keuangan', 'Kantin', 'Siswa', 'Orang Tua'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final dbRole = _getDbRoleKey(_selectedRoleFilter);
      final filter = PaginatedProfilesFilter(role: dbRole, searchQuery: _searchQuery);
      ref.read(paginatedProfilesProvider(filter).notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

  Future<void> _toggleUserStatus(
      String profileId, String role, bool currentStatus, PaginatedProfilesFilter filter) async {
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
      ref.invalidate(paginatedProfilesProvider(filter));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status akun berhasil ${newStatus ? "diaktifkan" : "dinonaktifkan"}.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memperbarui status akun'),
            backgroundColor: AppColors.errorRed2,
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
            content: Text('${AppStrings.titleDetail} untuk peran Admin dikelola langsung dari database.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbRole = _getDbRoleKey(_selectedRoleFilter);
    final filter = PaginatedProfilesFilter(role: dbRole, searchQuery: _searchQuery);
    final profilesState = ref.watch(paginatedProfilesProvider(filter));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kelola Akun Pengguna',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
        actions: [
          if (_selectedRoleFilter != 'Semua' &&
              _selectedRoleFilter != 'Admin' &&
              _selectedRoleFilter != 'Orang Tua')
            IconButton(
              icon: const Icon(CupertinoIcons.square_arrow_down, color: AppColors.darkTeal),
              tooltip: 'Import $_selectedRoleFilter (CSV)',
              onPressed: () => showImportUsersDialog(context, ref, _selectedRoleFilter),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters panel
          AdminUserSearchFilter(
            searchController: _searchController,
            selectedRoleFilter: _selectedRoleFilter,
            onSearchChanged: _onSearchChanged,
            onRoleFilterChanged: (val) {
              setState(() {
                _selectedRoleFilter = val;
              });
            },
          ),

          // User list
          Expanded(
            child: Builder(
              builder: (context) {
                if (profilesState.isLoading) {
                  return const Center(
                    child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                  );
                }

                if (profilesState.error != null && profilesState.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                        const SizedBox(height: 12),
                        Text('${AppStrings.labelFailed} memuat data'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(paginatedProfilesProvider(filter)),
                          child: const Text(AppStrings.buttonRetry),
                        ),
                      ],
                    ),
                  );
                }

                final users = profilesState.items;

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada pengguna ditemukan.',
                      style: GoogleFonts.inter(
                        color: AppColors.textGray,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(paginatedProfilesProvider(filter));
                  },
                  color: AppColors.darkTeal,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: users.length + (profilesState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                          ),
                        );
                      }
                      final user = users[index];
                      return AdminUserListTile(
                        user: user,
                        getRoleLabel: _getRoleLabel,
                        onToggleStatus: (id, role, isActive) =>
                            _toggleUserStatus(id, role, isActive, filter),
                        onNavigateToDetail: (id, role) =>
                            _navigateToDetail(id, role),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (_selectedRoleFilter != 'Semua' &&
              _selectedRoleFilter != 'Orang Tua')
          ? FloatingActionButton.small(
              backgroundColor: AppColors.darkTeal,
              shape: const CircleBorder(),
              child: const Icon(CupertinoIcons.add, color: AppColors.white),
              onPressed: () => _showAddUserSheet(context, _selectedRoleFilter),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    showAddStudentSheet(context, ref);
  }

  void _showAddCanteenSheet(BuildContext context) {
    showAddCanteenSheet(context, ref);
  }

  void _showAddFinanceSheet(BuildContext context) {
    showAddFinanceSheet(context, ref);
  }
}

