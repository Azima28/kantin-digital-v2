import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_users_tabs.dart';
import 'package:kantin_digital/features/keuangan/widgets/users_add_sheet.dart';
import 'package:kantin_digital/features/keuangan/widgets/users_search_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _searchHint() {
    switch (_tabController.index) {
      case 0:
        return 'Cari nama, NISN, atau kelas...';
      case 1:
        return 'Cari nama atau email...';
      default:
        return 'Cari nama atau username...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Manajemen Pengguna',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_tabController.index != 1)
            IconButton(
              icon: const Icon(
                CupertinoIcons.add_circled_solid,
                color: AppColors.darkTeal,
                size: 26,
              ),
              tooltip: _tabController.index == 0
                  ? '${AppStrings.buttonAdd} Siswa'
                  : '${AppStrings.buttonAdd} Petugas',
              onPressed: () => showAddUserBottomSheet(context, ref, _tabController.index),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.darkTeal,
              unselectedLabelColor: AppColors.mutedGray,
              indicatorColor: AppColors.darkTeal,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: AppStrings.adminStudents),
                Tab(text: 'Orang Tua'),
                Tab(text: 'Petugas Kantin'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          UsersSearchBar(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            hints: [_searchHint()],
            showClear: _searchQuery.isNotEmpty,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StudentsTab(searchQuery: _searchQuery),
                ParentsTab(searchQuery: _searchQuery),
                StaffTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
