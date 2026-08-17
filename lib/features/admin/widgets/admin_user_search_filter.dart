import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

/// Search bar and custom pill role filter for the admin users screen.
/// Designed to match the exact design in the user screenshot.
class AdminUserSearchFilter extends ConsumerWidget {
  final TextEditingController searchController;
  final String selectedRoleFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleFilterChanged;

  const AdminUserSearchFilter({
    super.key,
    required this.searchController,
    required this.selectedRoleFilter,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
  });

  String _getDbRoleKey(String uiLabel) {
    switch (uiLabel) {
      case 'Keuangan':
        return 'petugas_keuangan';
      case 'Kantin':
        return 'petugas_kantin';
      case 'Siswa':
        return 'student';
      case 'Orang Tua':
        return 'parent';
      default:
        return 'Semua';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> categories = [
      'Semua',
      'Keuangan',
      'Kantin',
      'Siswa',
      'Orang Tua',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Input Field
          TextField(
            controller: searchController,
            onChanged: (val) {
              onSearchChanged(val.toLowerCase().trim());
            },
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              hintText: 'Cari nama, email, NISN, usn...',
              hintStyle: GoogleFonts.inter(
                color: context.textSecondary.withValues(alpha: 0.75),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                CupertinoIcons.search,
                color: Nebula.teal,
                size: 18,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.isDark ? context.borderLight : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.isDark ? context.borderLight : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Nebula.teal,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Pill Category Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final bool isSelected = selectedRoleFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      onRoleFilterChanged(cat);
                      ref.read(adminRoleFilterProvider.notifier).state =
                          _getDbRoleKey(cat);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Nebula.teal
                            : context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Nebula.teal
                              : context.dividerCol.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}