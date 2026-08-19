import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

class AdminFinanceOfficerLedgerDetailScreen extends ConsumerStatefulWidget {
  final String officerId;
  const AdminFinanceOfficerLedgerDetailScreen({
    super.key,
    required this.officerId,
  });

  @override
  ConsumerState<AdminFinanceOfficerLedgerDetailScreen> createState() =>
      _AdminFinanceOfficerLedgerDetailScreenState();
}

class _AdminFinanceOfficerLedgerDetailScreenState
    extends ConsumerState<AdminFinanceOfficerLedgerDetailScreen> {
  int _selectedCategoryTab = 0; // 0: Semua, 1: Inflow (+), 2: Outflow (-), 3: Koreksi (±)
  int _selectedDateFilter = 0; // 0: Semua Waktu, 1: Hari Ini, 2: 7 Hari Terakhir, 3: 30 Hari Terakhir

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(adminFinanceOfficerLedgerDetailProvider(widget.officerId));
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: context.surfaceBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buku Kas Petugas',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise, color: Nebula.teal),
            tooltip: 'Segarkan',
            onPressed: () => ref.invalidate(
              adminFinanceOfficerLedgerDetailProvider(widget.officerId),
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          final officer = detail.officer;
          final allJournals = detail.recentJournals;

          // Filter by Date
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));

          var filteredJournals = allJournals.where((j) {
            if (j.createdAt == null) return true;
            if (_selectedDateFilter == 1) {
              return j.createdAt!.isAfter(startOfToday);
            } else if (_selectedDateFilter == 2) {
              return j.createdAt!.isAfter(sevenDaysAgo);
            } else if (_selectedDateFilter == 3) {
              return j.createdAt!.isAfter(thirtyDaysAgo);
            }
            return true;
          }).toList();

          // Filter by Category Tab
          if (_selectedCategoryTab == 1) {
            filteredJournals = filteredJournals
                .where((j) => j.category == 'INFLOW' || j.type == 'TOPUP')
                .toList();
          } else if (_selectedCategoryTab == 2) {
            filteredJournals = filteredJournals
                .where(
                    (j) => j.category == 'OUTFLOW' || j.type == 'WITHDRAWAL')
                .toList();
          } else if (_selectedCategoryTab == 3) {
            filteredJournals = filteredJournals
                .where((j) =>
                    j.category == 'ADJUSTMENT' ||
                    j.type.contains('KOREKSI') ||
                    j.type.contains('ADJUSTMENT'))
                .toList();
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              adminFinanceOfficerLedgerDetailProvider(widget.officerId),
            ),
            color: Nebula.teal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. Header Rekonsiliasi Kas Petugas ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.dividerCol, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: context.shadowColor,
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Nebula.teal.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: (officer.avatarUrl != null &&
                                        officer.avatarUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: ApiClient.resolveImageUrl(
                                            officer.avatarUrl),
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Center(
                                          child: Text(
                                            officer.fullName.isNotEmpty
                                                ? officer.fullName[0]
                                                    .toUpperCase()
                                                : 'P',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Nebula.teal,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          officer.fullName.isNotEmpty
                                              ? officer.fullName[0]
                                                  .toUpperCase()
                                              : 'P',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Nebula.teal,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    officer.fullName,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${officer.assignedSchool} · Otoritas ${officer.authorityLevel}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: context.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: officer.isActive
                                    ? Nebula.teal.withValues(alpha: 0.12)
                                    : Nebula.rose.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                officer.isActive ? 'AKTIF' : 'NONAKTIF',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: officer.isActive
                                      ? Nebula.teal
                                      : Nebula.rose,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 14),

                        // Highlight Uang Kas Fisik
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.surfaceBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: context.dividerCol, width: 0.6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kas Fisik Wajib di Tangan:',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fmt.format(officer.netCashHandled),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: officer.netCashHandled >= 0
                                      ? Nebula.teal
                                      : Nebula.rose,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '🟢 Top-Up',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: context.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          fmt.format(officer.totalCashInflow),
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Nebula.teal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '🔴 Tarik Kas',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: context.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          fmt.format(officer.totalCashOutflow),
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Nebula.rose,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '⚖️ Koreksi',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: context.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${officer.totalCorrectionsCount} Kali',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Nebula.amber,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 2. Filter Rentang Tanggal ───
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDateChip('Semua Waktu', 0),
                        const SizedBox(width: 6),
                        _buildDateChip('Hari Ini', 1),
                        const SizedBox(width: 6),
                        _buildDateChip('7 Hari Terakhir', 2),
                        const SizedBox(width: 6),
                        _buildDateChip('30 Hari Terakhir', 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── 3. Tab Kategori Jurnal ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.dividerCol, width: 0.6),
                    ),
                    child: Row(
                      children: [
                        _buildCategoryTab(
                          'Semua (${allJournals.length})',
                          0,
                        ),
                        _buildCategoryTab(
                          'Top-Up (+)',
                          1,
                          activeColor: Nebula.teal,
                        ),
                        _buildCategoryTab(
                          'Tarik (-)',
                          2,
                          activeColor: Nebula.rose,
                        ),
                        _buildCategoryTab(
                          'Koreksi (±)',
                          3,
                          activeColor: Nebula.amber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 4. List Jurnal Transaksi ───
                  if (filteredJournals.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.doc_text_search,
                              size: 48,
                              color: context.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada jurnal transaksi pada filter ini.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredJournals.length,
                      itemBuilder: (context, index) {
                        final journal = filteredJournals[index];
                        return _buildJournalCard(context, journal, fmt);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => Shimmer(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderLight, width: 0.8),
              ),
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('Gagal memuat detail buku kas: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  adminFinanceOfficerLedgerDetailProvider(widget.officerId),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, int index) {
    final isSelected = _selectedDateFilter == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDateFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(
    String label,
    int index, {
    Color activeColor = Nebula.teal,
  }) {
    final isSelected = _selectedCategoryTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryTab = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildJournalCard(
    BuildContext context,
    OfficerJournalEntry j,
    NumberFormat fmt,
  ) {
    Color itemColor = Nebula.teal;
    IconData itemIcon = CupertinoIcons.arrow_down_circle_fill;
    String sign = '+';

    if (j.category == 'OUTFLOW' || j.type == 'WITHDRAWAL') {
      itemColor = Nebula.rose;
      itemIcon = CupertinoIcons.arrow_up_circle_fill;
      sign = '-';
    } else if (j.category == 'ADJUSTMENT' || j.type.contains('KOREKSI')) {
      itemColor = Nebula.amber;
      itemIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
      sign = '±';
    }

    final dateStr = j.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(j.createdAt!.toLocal())
        : '-';

    String targetDisplay = j.targetName;
    if (j.type == 'KOREKSI_SALDO' || targetDisplay == 'students' || targetDisplay == 'keuangan' || targetDisplay == 'Sistem') {
      targetDisplay = 'Koreksi Saldo Siswa';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerCol, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: itemColor.withValues(alpha: 0.12),
            child: Icon(itemIcon, color: itemColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        targetDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sign${fmt.format(j.amount)}',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: itemColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      j.type.replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: itemColor,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (j.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Catatan: ${j.notes}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: context.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
