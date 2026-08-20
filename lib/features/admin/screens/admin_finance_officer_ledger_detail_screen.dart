import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/services/report_export_service.dart';
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
  int _selectedCategoryTab = 0; // 0: Semua, 1: Inflow (+), 2: Outflow (-), 3: Sesi Shift
  int _selectedDateFilter = 0; // 0: Semua Waktu, 1: Hari Ini, 2: 7 Hari Terakhir, 3: 30 Hari Terakhir

  Future<void> _verifyShift(String shiftId, int shiftNumber) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post('/admin/finance/shift/$shiftId/verify');
      if (res.success) {
        ref.invalidate(adminAllShiftsProvider(widget.officerId));
        ref.invalidate(adminFinanceOfficersLedgerProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shift #$shiftNumber berhasil diverifikasi & setoran fisik disahkan.'),
              backgroundColor: Nebula.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memverifikasi shift: $e'), backgroundColor: Nebula.rose),
        );
      }
    }
  }

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
          detailAsync.maybeWhen(
            data: (detail) => IconButton(
              icon: const Icon(CupertinoIcons.square_arrow_up, color: Nebula.teal),
              tooltip: 'Ekspor & Bagikan',
              onPressed: () => _openExportModal(context, detail),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
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
                                'Uang Kas Fisik di Tangan Petugas:',
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
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: officer.netCashHandled >= 0
                                      ? Nebula.teal
                                      : Nebula.rose,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // 2 Clean Tiles for Inflow and Outflow
                              Row(
                                children: [
                                  // Uang Masuk (Top-Up)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Nebula.teal.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Nebula.teal.withValues(alpha: 0.2),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons.arrow_down_left_circle_fill,
                                                size: 13,
                                                color: Nebula.teal,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Uang Masuk',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Nebula.teal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            fmt.format(officer.totalCashInflow),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Nebula.teal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Uang Keluar (Tarik Stan)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Nebula.rose.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Nebula.rose.withValues(alpha: 0.2),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons.arrow_up_right_circle_fill,
                                                size: 13,
                                                color: Nebula.rose,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Uang Keluar',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Nebula.rose,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            fmt.format(officer.totalCashOutflow),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Nebula.rose,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Loket & Total Transaksi Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 13,
                                        color: Nebula.teal,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        officer.assignedSchool,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${allJournals.length} Transaksi',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // ── Tombol Cepat Ekspor & Bagikan Laporan ──
                              InkWell(
                                onTap: () => _openExportModal(context, detail),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Nebula.teal.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.square_arrow_up,
                                        size: 15,
                                        color: Nebula.teal,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Ekspor & Bagikan Laporan Kas',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Nebula.teal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 13,
                                        color: Nebula.teal,
                                      ),
                                    ],
                                  ),
                                ),
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
                          'Tarik Stan (-)',
                          2,
                          activeColor: Nebula.rose,
                        ),
                        _buildCategoryTab(
                          'Sesi Shift',
                          3,
                          activeColor: const Color(0xFF0284C7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 4. List Jurnal Transaksi / Sesi Shift ───
                  if (_selectedCategoryTab == 3) ...[
                    _buildShiftsSection(context, fmt, officer),
                  ] else if (filteredJournals.isEmpty) ...[
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

  Widget _buildShiftsSection(
    BuildContext context,
    NumberFormat fmt,
    FinanceOfficerLedgerItem officer,
  ) {
    final shiftsAsync = ref.watch(adminAllShiftsProvider(widget.officerId));

    return shiftsAsync.when(
      data: (shifts) {
        if (shifts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.lock_shield,
                    size: 48,
                    color: context.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat sesi tutup kasir untuk petugas ini.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shifts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final shift = shifts[index];
            final isVerified = shift.isVerified;
            final isMatched = shift.isBalanced;
            final isShort = shift.isDeficit;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isVerified
                      ? Nebula.teal.withValues(alpha: 0.3)
                      : (isMatched
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : Nebula.amber.withValues(alpha: 0.4)),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.lock_shield_fill,
                              color: Color(0xFF0284C7),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sesi Shift #${shift.shiftNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Nebula.teal.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isVerified ? 'TERVERIFIKASI' : 'MENUNGGU AUDIT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isVerified ? Nebula.teal : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Periode: ${shift.formattedStartedAt} s/d ${shift.formattedClosedAt}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Uang Masuk (+):', style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary)),
                      Text('+${fmt.format(shift.totalInflow)} (${shift.topupCount} tx)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Nebula.teal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Uang Keluar (-):', style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary)),
                      Text('-${fmt.format(shift.totalOutflow)} (${shift.payoutCount} tx)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Nebula.rose)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target Sistem:', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textPrimary)),
                      Text(fmt.format(shift.expectedCash),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fisik Diserahkan:', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                      Text(fmt.format(shift.actualPhysicalCash),
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? Nebula.teal.withValues(alpha: 0.08)
                          : (isShort
                              ? Nebula.rose.withValues(alpha: 0.08)
                              : Nebula.amber.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status Rekonsiliasi:',
                            style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                        Text(
                          isMatched
                              ? 'PAS / Rp 0 Selisih'
                              : (isShort
                                  ? 'KURANG -${fmt.format(shift.difference.abs())}'
                                  : 'LEBIH +${fmt.format(shift.difference.abs())}'),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isMatched
                                ? Nebula.teal
                                : (isShort ? Nebula.rose : Nebula.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (shift.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Catatan: "${shift.notes}"',
                      style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: context.textSecondary),
                    ),
                  ],
                  if (!isVerified) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyShift(shift.id, shift.shiftNumber),
                        icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 16),
                        label: Text(
                          'Verifikasi & Terima Amplop Fisik',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Nebula.teal, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Diverifikasi oleh ${shift.verifierName ?? "Super Admin"}',
                          style: GoogleFonts.inter(fontSize: 10.5, color: Nebula.teal, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Nebula.teal))),
      error: (err, _) => Center(child: Text('Gagal memuat sesi shift: $err', style: GoogleFonts.inter(color: Nebula.rose))),
    );
  }

  void _openExportModal(
      BuildContext context, FinanceOfficerLedgerDetail detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OfficerLedgerExportModal(
        officer: detail.officer,
        allJournals: detail.recentJournals,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODAL EKSPOR BUKU KAS & FILTER KALENDER RENTANG TANGGAL
// ══════════════════════════════════════════════════════════════════════════════

class _OfficerLedgerExportModal extends StatefulWidget {
  final FinanceOfficerLedgerItem officer;
  final List<OfficerJournalEntry> allJournals;

  const _OfficerLedgerExportModal({
    required this.officer,
    required this.allJournals,
  });

  @override
  State<_OfficerLedgerExportModal> createState() =>
      _OfficerLedgerExportModalState();
}

class _OfficerLedgerExportModalState extends State<_OfficerLedgerExportModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _datePresetIndex = 0; // 0: Semua, 1: Hari Ini, 2: 7 Hari, 3: 30 Hari, 4: Kustom
  int _selectedFormat = 0; // 0: PDF, 1: Excel
  bool _isExporting = false;

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _applyPreset(0);
  }

  void _applyPreset(int index) {
    final now = DateTime.now();
    setState(() {
      _datePresetIndex = index;
      if (index == 0) {
        // Semua Waktu
        _startDate = null;
        _endDate = null;
      } else if (index == 1) {
        // Hari Ini
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (index == 2) {
        // 7 Hari Terakhir
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (index == 3) {
        // 30 Hari Terakhir
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      }
    });
  }

  List<OfficerJournalEntry> _getFilteredJournals() {
    return widget.allJournals.where((j) {
      if (j.createdAt == null) return true;
      final local = j.createdAt!.toLocal();
      if (_startDate != null && local.isBefore(_startDate!)) return false;
      if (_endDate != null && local.isAfter(_endDate!)) return false;
      return true;
    }).toList();
  }

  String _getPeriodLabel() {
    if (_startDate == null && _endDate == null) {
      return 'Semua Waktu';
    }
    if (_startDate != null && _endDate != null) {
      if (_dateFmt.format(_startDate!) == _dateFmt.format(_endDate!)) {
        return _dateFmt.format(_startDate!);
      }
      return '${_dateFmt.format(_startDate!)} - ${_dateFmt.format(_endDate!)}';
    }
    if (_startDate != null) {
      return 'Sejak ${_dateFmt.format(_startDate!)}';
    }
    return 'Sampai ${_dateFmt.format(_endDate!)}';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH TANGGAL AWAL (DARI)',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        _datePresetIndex = 4; // Kustom
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? now),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH TANGGAL AKHIR (SAMPAI)',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_startDate != null && _startDate!.isAfter(_endDate!)) {
          _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        }
        _datePresetIndex = 4; // Kustom
      });
    }
  }

  Future<void> _handleDownload() async {
    final filtered = _getFilteredJournals();
    final period = _getPeriodLabel();
    final totalInflow = filtered
        .where((j) => j.category == 'INFLOW' || j.type == 'TOPUP')
        .fold(0, (sum, j) => sum + j.amount);
    final totalOutflow = filtered
        .where((j) => j.category == 'OUTFLOW' || j.type == 'WITHDRAWAL')
        .fold(0, (sum, j) => sum + j.amount);
    final netCash = totalInflow - totalOutflow;

    setState(() => _isExporting = true);
    try {
      if (_selectedFormat == 0) {
        // Ekspor PDF
        await ReportExportService.downloadOfficerLedgerPdf(
          officer: widget.officer,
          journals: filtered,
          period: period,
          totalInflow: totalInflow,
          totalOutflow: totalOutflow,
          netCash: netCash,
        );
      } else {
        // Ekspor Excel
        await ReportExportService.downloadOfficerLedgerExcel(
          officer: widget.officer,
          journals: filtered,
          period: period,
          totalInflow: totalInflow,
          totalOutflow: totalOutflow,
          netCash: netCash,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan Buku Kas berhasil diekspor (${_selectedFormat == 0 ? "PDF" : "Excel"}).',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor laporan: $e', style: GoogleFonts.inter()),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShareWhatsApp() async {
    final filtered = _getFilteredJournals();
    final period = _getPeriodLabel();
    final totalInflow = filtered
        .where((j) => j.category == 'INFLOW' || j.type == 'TOPUP')
        .fold(0, (sum, j) => sum + j.amount);
    final totalOutflow = filtered
        .where((j) => j.category == 'OUTFLOW' || j.type == 'WITHDRAWAL')
        .fold(0, (sum, j) => sum + j.amount);
    final netCash = totalInflow - totalOutflow;

    setState(() => _isExporting = true);
    try {
      await ReportExportService.shareOfficerLedgerViaWhatsApp(
        officer: widget.officer,
        journals: filtered,
        period: period,
        totalInflow: totalInflow,
        totalOutflow: totalOutflow,
        netCash: netCash,
        asPdf: _selectedFormat == 0,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Membuka WhatsApp dan menyiapkan file laporan untuk dibagikan.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan ke WhatsApp: $e', style: GoogleFonts.inter()),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredJournals();
    final totalInflow = filtered
        .where((j) => j.category == 'INFLOW' || j.type == 'TOPUP')
        .fold(0, (sum, j) => sum + j.amount);
    final totalOutflow = filtered
        .where((j) => j.category == 'OUTFLOW' || j.type == 'WITHDRAWAL')
        .fold(0, (sum, j) => sum + j.amount);
    final netCash = totalInflow - totalOutflow;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        16;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.dividerCol, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Grab Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Modal Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text_fill,
                      color: Nebula.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ekspor & Bagikan Buku Kas',
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
                          '${widget.officer.fullName} • ${widget.officer.assignedSchool}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                    color: context.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // ── Scrollable Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Bagian Filter Rentang Tanggal ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1. RENTANG TANGGAL LAPORAN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _getPeriodLabel(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Preset Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('Semua', 0),
                          const SizedBox(width: 6),
                          _buildPresetChip('Hari Ini', 1),
                          const SizedBox(width: 6),
                          _buildPresetChip('7 Hari', 2),
                          const SizedBox(width: 6),
                          _buildPresetChip('30 Hari', 3),
                          const SizedBox(width: 6),
                          _buildPresetChip('Kustom Kalender', 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dua Kartu Kalender: Dari Tanggal & Sampai Tanggal
                    Row(
                      children: [
                        // Dari Tanggal
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _datePresetIndex == 4
                                      ? Nebula.teal.withValues(alpha: 0.5)
                                      : context.dividerCol,
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.calendar,
                                        size: 13,
                                        color: Nebula.teal,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Dari Tanggal',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _startDate != null ? _dateFmt.format(_startDate!) : 'Awal',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sampai Tanggal
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _datePresetIndex == 4
                                      ? Nebula.teal.withValues(alpha: 0.5)
                                      : context.dividerCol,
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.calendar_today,
                                        size: 13,
                                        color: Nebula.teal,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Sampai Tanggal',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _endDate != null ? _dateFmt.format(_endDate!) : 'Hari Ini',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Live Preview Ringkasan Kas Terpilih ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Nebula.teal.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rincian Kas Periode Terpilih:',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Nebula.teal,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Nebula.teal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${filtered.length} Transaksi',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Nebula.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPreviewTile(
                                  label: 'Uang Masuk (+)',
                                  value: _fmt.format(totalInflow),
                                  color: Nebula.teal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPreviewTile(
                                  label: 'Uang Keluar (-)',
                                  value: _fmt.format(totalOutflow),
                                  color: Nebula.rose,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.surfaceBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.dividerCol, width: 0.6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kas Fisik di Tangan:',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  _fmt.format(netCash),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: netCash >= 0 ? Nebula.teal : Nebula.rose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 3. Pilih Format Dokumen ──
                    Text(
                      '2. PILIH FORMAT DOKUMEN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Nebula.teal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // PDF Card
                        Expanded(
                          child: _buildFormatCard(
                            title: 'PDF Resmi',
                            subtitle: 'Berkop, TTD & QR',
                            icon: CupertinoIcons.doc_text_fill,
                            index: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Excel Card
                        Expanded(
                          child: _buildFormatCard(
                            title: 'Excel (.xlsx)',
                            subtitle: 'Multi-Sheet & Rumus',
                            icon: CupertinoIcons.table_fill,
                            index: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── 4. Tombol Aksi Download & Share WhatsApp ──
                    if (_isExporting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(color: Nebula.teal),
                        ),
                      )
                    else ...[
                      // Tombol 1: Download / Cetak File
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _handleDownload,
                          icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18),
                          label: Text(
                            'Download & Cetak Laporan (${_selectedFormat == 0 ? "PDF" : "Excel"})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tombol 2: Bagikan ke WhatsApp
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _handleShareWhatsApp,
                          icon: const Icon(CupertinoIcons.share, size: 18),
                          label: Text(
                            'Bagikan ke WhatsApp (Teks & File ${_selectedFormat == 0 ? "PDF" : "Excel"})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int index) {
    final isSelected = _datePresetIndex == index;
    return InkWell(
      onTap: () {
        if (index == 4) {
          _pickStartDate();
        } else {
          _applyPreset(index);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal : context.surfaceBg,
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

  Widget _buildPreviewTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedFormat == index;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal.withValues(alpha: 0.1) : context.surfaceBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Nebula.teal : context.dividerCol.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : context.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Nebula.teal : context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 16,
                color: Nebula.teal,
              ),
          ],
        ),
      ),
    );
  }
}

