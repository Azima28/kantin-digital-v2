import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_users_tabs.dart';
import 'package:kantin_digital/features/keuangan/widgets/users_add_sheet.dart';
import 'package:kantin_digital/features/keuangan/widgets/users_search_bar.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';

// ── Main Screen ─────────────────────────────────────────────────────────────

class KeuanganUsersScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const KeuanganUsersScreen({
    super.key,
    this.initialIndex = 0,
  });

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
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant KeuanganUsersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      final target = widget.initialIndex.clamp(0, 2);
      if (_tabController.index != target) {
        _tabController.animateTo(target);
      }
    }
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
        return 'Cari nama stan atau username...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Manajemen Pengguna',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 17,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_tabController.index != 1)
            PressScale(
              onTap: () => showAddUserBottomSheet(context, ref, _tabController.index),
              child: IconButton(
                icon: const Icon(
                  CupertinoIcons.add_circled_solid,
                  color: Nebula.teal,
                  size: 22,
                ),
                tooltip: _tabController.index == 0
                    ? '${AppStrings.buttonAdd} Siswa'
                    : '${AppStrings.buttonAdd} Petugas',
                onPressed: () => showAddUserBottomSheet(context, ref, _tabController.index),
              ),
            ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.dividerCol, width: 0.8),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false, // 3 tabs equally distributed across screen
              labelColor: Nebula.teal,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: Nebula.teal,
              indicatorWeight: 2.5,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
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
          const SizedBox(height: 4),
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
