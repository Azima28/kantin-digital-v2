import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

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
    final studentsAsync = ref.watch(keuanganStudentsProvider);

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
              hintStyle: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
              prefixIcon: Icon(CupertinoIcons.search, color: context.textSecondary),
              filled: true,
              fillColor: context.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.dividerCol),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.dividerCol),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Nebula.teal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dropdown Filters
          studentsAsync.when(
            data: (list) {
              // Get unique classes
              final classes = {'Semua'};
              for (var student in list) {
                if (student.class_ != null) {
                  classes.add(student.class_!);
                }
              }

              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.dividerCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClass,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13),
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
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.dividerCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13),
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
                            DropdownMenuItem(value: 'Kartu Belum Terdaftar', child: Text('Kartu Belum Terdaftar')),
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