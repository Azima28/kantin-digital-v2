import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/keuangan/widgets/students_filter_panel.dart';
import 'package:kantin_digital/features/keuangan/widgets/students_list_view.dart';
import 'package:kantin_digital/features/keuangan/widgets/students_add_sheet.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Manajemen Siswa',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid,
                color: AppColors.darkTeal, size: 26),
            tooltip: '${AppStrings.buttonAdd} Siswa',
            onPressed: () => showAddStudentSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filters Panel
            StudentsFilterPanel(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedClass: _selectedClass,
              selectedStatus: _selectedStatus,
              onSearchChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              onClassChanged: (val) {
                setState(() {
                  _selectedClass = val;
                });
              },
              onStatusChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                });
              },
            ),

            // Students List
            Expanded(
              child: StudentsListView(
                searchQuery: _searchQuery,
                selectedClass: _selectedClass,
                selectedStatus: _selectedStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
