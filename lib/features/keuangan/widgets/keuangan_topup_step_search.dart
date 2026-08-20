import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Step 1 of the top-up flow — student search.
///
/// Displays a search field, search results, and empty/loading states.
class KeuanganTopupStepSearch extends StatefulWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final bool hasSearched;
  final List<StudentWithProfile> searchResults;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalMatches;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final ValueChanged<StudentWithProfile> onStudentSelected;

  const KeuanganTopupStepSearch({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.hasSearched,
    required this.searchResults,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalMatches = 0,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.onStudentSelected,
  });

  @override
  State<KeuanganTopupStepSearch> createState() =>
      _KeuanganTopupStepSearchState();
}

class _KeuanganTopupStepSearchState extends State<KeuanganTopupStepSearch> {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.searchController.text.trim().isNotEmpty
                    ? 'Hasil Pencarian (${widget.searchResults.length}${widget.hasMore ? "/${widget.totalMatches}" : ""}):'
                    : 'Siswa Rekomendasi / Terdaftar (${widget.searchResults.length}${widget.hasMore ? "/${widget.totalMatches}" : ""}):',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.searchResults.length} Siswa',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Nebula.teal,
                  ),
                ),
              ),
            ],
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
              final isAccountBlocked = student.isAccountBlocked;
              final isCardBlocked = student.isCardBlocked;
              final hasRfid = student.hasRfid;

              return Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAccountBlocked
                        ? Nebula.rose.withValues(alpha: 0.5)
                        : (isCardBlocked
                            ? Nebula.amber.withValues(alpha: 0.4)
                            : context.dividerCol),
                    width: isAccountBlocked || isCardBlocked ? 1.2 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isAccountBlocked ? Nebula.rose : Nebula.teal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'NISN: $nisn • Kelas $className',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isAccountBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Nebula.rose.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'AKUN DIBLOKIR',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Nebula.rose,
                                ),
                              ),
                            )
                          else if (isCardBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Nebula.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KARTU DIBEKUKAN',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Nebula.amber,
                                ),
                              ),
                            )
                          else if (!hasRfid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.dividerCol,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BELUM ADA KARTU',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KARTU AKTIF',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Nebula.teal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAccountBlocked
                          ? Nebula.rose.withValues(alpha: 0.1)
                          : Nebula.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAccountBlocked ? 'Lihat' : AppStrings.buttonSelect,
                      style: GoogleFonts.inter(
                        color: isAccountBlocked ? Nebula.rose : Nebula.teal,
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
          if (widget.isLoadingMore) ...[
            const SizedBox(height: 14),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Nebula.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Memuat siswa berikutnya...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Nebula.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (widget.hasMore) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Gulir ke bawah untuk memuat ${widget.totalMatches - widget.searchResults.length} siswa lainnya...',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
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
      ],
    );
  }
}