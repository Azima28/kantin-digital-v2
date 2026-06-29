import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

class StudentsFilterPanel extends ConsumerWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedClass;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onStatusChanged;

  const StudentsFilterPanel({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedClass,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onClassChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama, NISN, atau kelas...',
              hintStyle: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 14),
              prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.mutedGray),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.darkTeal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dropdown Filters
          classesAsync.when(
            data: (classesList) {
              final rombelsList = ref.watch(rombelsProvider).value ?? [];
              final classes = {'Semua'};
              for (var c in classesList) {
                if (rombelsList.isEmpty) {
                  classes.add(c.name);
                } else {
                  for (var r in rombelsList) {
                    if (r.name != '-') {
                      classes.add('${c.name}-${r.name}');
                    } else {
                      classes.add(c.name);
                    }
                  }
                }
              }

              final activeClass = classes.contains(selectedClass) ? selectedClass : 'Semua';

              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activeClass,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: AppColors.nearBlack, fontSize: 13),
                          onChanged: (val) {
                            if (val != null) {
                              onClassChanged(val);
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
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: AppColors.nearBlack, fontSize: 13),
                          onChanged: (val) {
                            if (val != null) {
                              onStatusChanged(val);
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
    );
  }
}
