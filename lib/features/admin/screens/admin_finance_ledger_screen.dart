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
import 'package:kantin_digital/core/services/report_export_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

class AdminFinanceLedgerScreen extends ConsumerStatefulWidget {
  const AdminFinanceLedgerScreen({super.key});

  @override
  ConsumerState<AdminFinanceLedgerScreen> createState() =>
      _AdminFinanceLedgerScreenState();
}

class _AdminFinanceLedgerScreenState
    extends ConsumerState<AdminFinanceLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Aktif, 2: Kas Hari Ini

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(adminFinanceOfficersLedgerProvider);
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
          'Pembukuan Petugas',
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
            icon: const Icon(CupertinoIcons.share, color: Nebula.teal),
            tooltip: 'Ekspor Rekap Pembukuan',
            onPressed: () {
              final officers = ledgerAsync.valueOrNull ?? [];
              int totalGlobalInflow = 0;
              int totalGlobalOutflow = 0;
              for (final o in officers) {
                totalGlobalInflow += o.totalCashInflow;
                totalGlobalOutflow += o.totalCashOutflow;
              }
              final totalGlobalNet = totalGlobalInflow - totalGlobalOutflow;
              _openMasterExportModal(
                context,
                officers,
                totalGlobalInflow,
                totalGlobalOutflow,
                totalGlobalNet,
              );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise, color: Nebula.teal),
            tooltip: 'Segarkan Data',
            onPressed: () =>
                ref.invalidate(adminFinanceOfficersLedgerProvider),
          ),
        ],
      ),
      body: ledgerAsync.when(
        data: (officers) {
          // Calculate global aggregates
          int totalGlobalInflow = 0;
          int totalGlobalOutflow = 0;
          int totalTodayInflow = 0;
          int totalTodayOutflow = 0;

          for (final o in officers) {
            totalGlobalInflow += o.totalCashInflow;
            totalGlobalOutflow += o.totalCashOutflow;
            totalTodayInflow += o.todayCashInflow;
            totalTodayOutflow += o.todayCashOutflow;
          }
          final totalGlobalNet = totalGlobalInflow - totalGlobalOutflow;

          // Filter by search and filter chips
          var filtered = officers.where((o) {
            final q = _searchQuery.toLowerCase();
            final matchesQuery = o.fullName.toLowerCase().contains(q) ||
                (o.username ?? '').toLowerCase().contains(q) ||
                (o.email ?? '').toLowerCase().contains(q) ||
                o.assignedSchool.toLowerCase().contains(q);

            if (!matchesQuery) return false;

            if (_selectedFilterIndex == 1) {
              return o.isActive;
            } else if (_selectedFilterIndex == 2) {
              return o.todayTxCount > 0 ||
                  o.todayCashInflow > 0 ||
                  o.todayCashOutflow > 0;
            }
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminFinanceOfficersLedgerProvider),
            color: Nebula.teal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. Ringkasan Global Buku Kas Sekolah ───
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
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  Nebula.teal.withValues(alpha: 0.15),
                              child: const Icon(
                                CupertinoIcons.creditcard_fill,
                                color: Nebula.teal,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Kas Fisik di Tangan Petugas',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    fmt.format(totalGlobalNet),
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: totalGlobalNet >= 0
                                          ? Nebula.teal
                                          : Nebula.rose,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🟢 Total Top-Up (Masuk)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fmt.format(totalGlobalInflow),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Nebula.teal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 28,
                              width: 1,
                              color: context.dividerCol,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🔴 Total Tarik Stan (Keluar)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fmt.format(totalGlobalOutflow),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Nebula.rose,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (totalTodayInflow > 0 || totalTodayOutflow > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hari Ini: Inflow +${fmt.format(totalTodayInflow)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Nebula.teal,
                                  ),
                                ),
                                Text(
                                  'Outflow -${fmt.format(totalTodayOutflow)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Nebula.rose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () => _openMasterExportModal(
                              context,
                              officers,
                              totalGlobalInflow,
                              totalGlobalOutflow,
                              totalGlobalNet,
                            ),
                            icon: const Icon(
                              CupertinoIcons.doc_text_fill,
                              size: 14,
                              color: Nebula.teal,
                            ),
                            label: Text(
                              'Ekspor Rekap Pembukuan (Excel & PDF)',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Nebula.teal.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                              backgroundColor:
                                  Nebula.teal.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 2. Search & Filter Bar ───
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: context.dividerCol, width: 0.8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari nama / username petugas...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.search,
                                size: 16,
                                color: Nebula.teal,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ─── 3. Filter Chips ───
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Semua Petugas (${officers.length})',
                          index: 0,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label:
                              'Aktif (${officers.where((o) => o.isActive).length})',
                          index: 1,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Ada Transaksi Hari Ini',
                          index: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 4. List of Officers ───
                  if (filtered.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle_badge_exclam,
                              size: 48,
                              color: context.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada petugas keuangan ditemukan.',
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
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final officer = filtered[index];
                        return _buildOfficerCard(context, officer, fmt);
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
              height: 160,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
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
              Text('Gagal memuat rekap pembukuan: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(adminFinanceOfficersLedgerProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required int index}) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
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

  Widget _buildOfficerCard(
    BuildContext context,
    FinanceOfficerLedgerItem officer,
    NumberFormat fmt,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dividerCol, width: 0.7),
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
          // Header: Avatar, Name, Status Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                          imageUrl:
                              ApiClient.resolveImageUrl(officer.avatarUrl),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              officer.fullName.isNotEmpty
                                  ? officer.fullName[0].toUpperCase()
                                  : 'P',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            officer.fullName.isNotEmpty
                                ? officer.fullName[0].toUpperCase()
                                : 'P',
                            style: GoogleFonts.inter(
                              fontSize: 16,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${officer.assignedSchool} · @${officer.username ?? "petugas"}',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: officer.isActive
                      ? Nebula.teal.withValues(alpha: 0.12)
                      : Nebula.rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  officer.isActive ? 'AKTIF' : 'NONAKTIF',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: officer.isActive ? Nebula.teal : Nebula.rose,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kas di Tangan & Statistik
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.dividerCol, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uang Kas di Tangan:',
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
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: officer.netCashHandled >= 0
                        ? Nebula.teal
                        : Nebula.rose,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // 2 Clean Tiles for Inflow and Outflow
                Row(
                  children: [
                    // Uang Masuk
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                  size: 12,
                                  color: Nebula.teal,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Uang Masuk',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Nebula.teal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
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
                    ),
                    const SizedBox(width: 6),
                    // Uang Keluar
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                  size: 12,
                                  color: Nebula.rose,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Uang Keluar',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Nebula.rose,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 12,
                          color: Nebula.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          officer.assignedSchool,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${officer.totalTransactions} Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Buka Jurnal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/admin/finance-ledger/${officer.id}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Buka Buku Kas & Jurnal Lengkap',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(CupertinoIcons.arrow_right, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMasterExportModal(
    BuildContext context,
    List<FinanceOfficerLedgerItem> officers,
    int totalInflow,
    int totalOutflow,
    int totalNet,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MasterLedgerExportModal(
        officers: officers,
        totalInflow: totalInflow,
        totalOutflow: totalOutflow,
        totalNet: totalNet,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODAL EKSPOR MASTER PEMBUKUAN SELURUH PETUGAS (PDF & EXCEL)
// ══════════════════════════════════════════════════════════════════════════════

class _MasterLedgerExportModal extends StatefulWidget {
  final List<FinanceOfficerLedgerItem> officers;
  final int totalInflow;
  final int totalOutflow;
  final int totalNet;

  const _MasterLedgerExportModal({
    required this.officers,
    required this.totalInflow,
    required this.totalOutflow,
    required this.totalNet,
  });

  @override
  State<_MasterLedgerExportModal> createState() =>
      _MasterLedgerExportModalState();
}

class _MasterLedgerExportModalState extends State<_MasterLedgerExportModal> {
  int _selectedFormat = 0; // 0: PDF, 1: Excel
  int _filterIndex = 0; // 0: Semua Petugas, 1: Hanya Petugas Aktif
  bool _isExporting = false;

  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<FinanceOfficerLedgerItem> _getFilteredOfficers() {
    if (_filterIndex == 1) {
      return widget.officers.where((o) => o.isActive).toList();
    }
    return widget.officers;
  }

  Future<void> _handleDownload() async {
    final filtered = _getFilteredOfficers();
    int inflow = 0;
    int outflow = 0;
    for (final o in filtered) {
      inflow += o.totalCashInflow;
      outflow += o.totalCashOutflow;
    }
    final net = inflow - outflow;

    setState(() => _isExporting = true);
    try {
      if (_selectedFormat == 0) {
        // Ekspor PDF
        await ReportExportService.downloadMasterOfficersLedgerPdf(
          officers: filtered,
          totalInflow: inflow,
          totalOutflow: outflow,
          totalNet: net,
        );
      } else {
        // Ekspor Excel
        await ReportExportService.downloadMasterOfficersLedgerExcel(
          officers: filtered,
          totalInflow: inflow,
          totalOutflow: outflow,
          totalNet: net,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Master Rekap Pembukuan berhasil diekspor (${_selectedFormat == 0 ? "PDF" : "Excel"}).',
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
            content: Text('Gagal mengekspor rekap master: $e',
                style: GoogleFonts.inter()),
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
    final filtered = _getFilteredOfficers();
    int currentNet = 0;
    for (final o in filtered) {
      currentNet += o.netCashHandled;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle drag pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerCol,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ekspor Master Rekap Pembukuan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Unduh pembukuan kas seluruh petugas loket',
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
            ],
          ),
          const SizedBox(height: 18),

          // ─── 1. Pilihan Format (PDF / Excel) ───
          Text(
            '1. FORMAT DOKUMEN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormatCard(
                  title: 'Dokumen PDF',
                  subtitle: 'Berkop Resmi & Siap Cetak',
                  icon: CupertinoIcons.doc_fill,
                  iconColor: const Color(0xFFDC2626),
                  isSelected: _selectedFormat == 0,
                  onTap: () => setState(() => _selectedFormat = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFormatCard(
                  title: 'Excel (.xlsx)',
                  subtitle: 'Tabel Data Akuntansi',
                  icon: CupertinoIcons.table_fill,
                  iconColor: const Color(0xFF16A34A),
                  isSelected: _selectedFormat == 1,
                  onTap: () => setState(() => _selectedFormat = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── 2. Filter Cakupan Petugas ───
          Text(
            '2. CAKUPAN PETUGAS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFilterOption(
                  label: 'Semua Petugas (${widget.officers.length})',
                  isSelected: _filterIndex == 0,
                  onTap: () => setState(() => _filterIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterOption(
                  label:
                      'Petugas Aktif (${widget.officers.where((o) => o.isActive).length})',
                  isSelected: _filterIndex == 1,
                  onTap: () => setState(() => _filterIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── 3. Ringkasan Data Yang Akan Diekspor ───
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.dividerCol, width: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kas Disertakan:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt.format(currentNet),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Nebula.teal,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filtered.length} Petugas',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Nebula.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── 4. Tombol Aksi Download ───
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _handleDownload,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18),
              label: Text(
                _isExporting
                    ? 'Sedang Menyiapkan...'
                    : 'Unduh Rekap Master (${_selectedFormat == 0 ? "PDF" : "Excel"})',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
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
        ],
      ),
    );
  }

  Widget _buildFormatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Nebula.teal.withValues(alpha: 0.08)
              : context.surfaceBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 22, color: iconColor),
                if (isSelected)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 16,
                    color: Nebula.teal,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal : context.surfaceBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

