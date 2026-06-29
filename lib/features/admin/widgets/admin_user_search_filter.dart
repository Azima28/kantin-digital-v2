import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Search bar and role filter for the admin users screen.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          // Search input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                onSearchChanged(val.toLowerCase().trim());
              },
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Cari nama, email, NISN, usn...',
                hintStyle: TextStyle(color: AppColors.textGray),
                prefixIcon:
                    Icon(CupertinoIcons.search, color: AppColors.mutedGray),
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
                groupValue: selectedRoleFilter,
                selectedColor: AppColors.darkTeal,
                unselectedColor: AppColors.white,
                borderColor: AppColors.borderGray,
                pressedColor: AppColors.darkTeal.withValues(alpha: 0.1),
                children: {
                  'Semua': _buildRoleFilterSegment('Semua'),
                  'Keuangan': _buildRoleFilterSegment('Keuangan'),
                  'Kantin': _buildRoleFilterSegment('Kantin'),
                  'Siswa': _buildRoleFilterSegment('Siswa'),
                  'Orang Tua': _buildRoleFilterSegment('Orang Tua'),
                },
                onValueChanged: (val) {
                  onRoleFilterChanged(val);
                },
              ),
            ),
          ),
        ],
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
}
