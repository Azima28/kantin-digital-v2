import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Step 1 of the correction flow — student search.
///
/// Displays a search field, search results, and empty/loading states.
class KeuanganCorrectionStepSearch extends StatefulWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final bool hasSearched;
  final List<StudentWithProfile> searchResults;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final ValueChanged<StudentWithProfile> onStudentSelected;

  const KeuanganCorrectionStepSearch({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.hasSearched,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.onStudentSelected,
  });

  @override
  State<KeuanganCorrectionStepSearch> createState() =>
      _KeuanganCorrectionStepSearchState();
}

class _KeuanganCorrectionStepSearchState
    extends State<KeuanganCorrectionStepSearch> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Masukkan NISN atau Nama Siswa:',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.searchController,
          onChanged: (val) {
            widget.onSearchChanged(val.trim());
          },
          onSubmitted: (val) {
            widget.onSearchSubmitted(val.trim());
          },
          decoration: InputDecoration(
            hintText: 'Masukkan NISN atau Nama Lengkap...',
            hintStyle: GoogleFonts.inter(
              color: context.textSecondary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: context.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide:
                  BorderSide(color: Nebula.teal, width: 1.5),
            ),
            suffixIcon: widget.isSearching
                ? Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Nebula.teal,
                      ),
                    ),
                  )
                : widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: context.textSecondary,
                          size: 18,
                        ),
                        onPressed: widget.onSearchCleared,
                      )
                    : Icon(
                        CupertinoIcons.search,
                        color: context.textSecondary,
                        size: 20,
                      ),
          ),
        ),
        const SizedBox(height: 20),

        if (widget.isSearching && widget.searchResults.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CupertinoActivityIndicator(color: Nebula.teal),
            ),
          )
        else if (widget.hasSearched && widget.searchResults.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Siswa tidak ditemukan.',
                style: GoogleFonts.inter(
                  color: Nebula.rose,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else if (widget.searchResults.isNotEmpty) ...[
          Text(
            'Hasil Pencarian (${widget.searchResults.length}):',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.searchResults.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = widget.searchResults[index];
              final name = student.fullName;
              final nisn = student.nisn ?? '-';
              final className = student.class_ ?? '-';

              return Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.dividerCol),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Nebula.teal,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'NISN: $nisn • Kelas $className',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.buttonSelect,
                      style: GoogleFonts.inter(
                        color: Nebula.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  onTap: () {
                    widget.onStudentSelected(student);
                  },
                ),
              );
            },
          ),
        ] else
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 48,
                    color: Nebula.teal.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ketik nama atau NISN siswa\nuntuk memulai pencarian.',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}