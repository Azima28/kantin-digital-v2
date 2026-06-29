import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

// keuanganHistoryProvider is defined in keuangan_providers.dart

class KeuanganHistoryScreen extends ConsumerStatefulWidget {
  const KeuanganHistoryScreen({super.key});

  @override
  ConsumerState<KeuanganHistoryScreen> createState() => _KeuanganHistoryScreenState();
}

class _KeuanganHistoryScreenState extends ConsumerState<KeuanganHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedType = 'Semua'; // 'Semua', 'Top-Up', 'Koreksi', 'Kartu'
  String _selectedDateFilter = 'Semua'; // 'Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final profile = ref.read(authNotifierProvider).profile;
      final actorId = profile?['id']?.toString();
      if (actorId == null) return;
      final dbActionKey = _selectedType == 'Top-Up'
          ? 'TOPUP_TUNAI'
          : (_selectedType == 'Koreksi'
              ? 'KOREKSI_SALDO'
              : (_selectedType == 'Kartu' ? 'KARTU' : 'Semua'));
      final filter = PaginatedAuditLogsFilter(
        actorId: actorId,
        actionType: dbActionKey,
        dateFilter: _selectedDateFilter,
      );
      ref.read(paginatedAuditLogsProvider(filter).notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _showDetailBottomSheet(AuditLog log, NumberFormat fmt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final actionType = log.actionType;
        final desc = log.description;
        final created = log.createdAt?.toLocal() ?? DateTime.now();
        final timeStr = DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID').format(created);
        final oldValue = log.oldValue;
        final newValue = log.newValue;

        // Extract before/after values with null safety
        final balanceBefore = oldValue['balance'];
        final balanceAfter = newValue['balance'];
        final rfidBefore = oldValue['rfid_uid'];
        final rfidAfter = newValue['rfid_uid'];
        final reason = newValue['reason'] ?? '';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // iOS grab handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderGray,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${AppStrings.titleDetail} Aktivitas Keuangan',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkTeal),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Tipe Aksi', actionType.toString().replaceAll('_', ' ')),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildDetailRow('Waktu', timeStr),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                  _buildDetailRow('Keterangan', desc),
                  if (reason.toString().isNotEmpty) ...[
                    const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                    _buildDetailRow('Alasan Koreksi', reason.toString()),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Perubahan Data:',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.nearBlack),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SEBELUM', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedGray)),
                              const SizedBox(height: 6),
                              if (balanceBefore != null)
                                Text(fmt.format(int.tryParse(balanceBefore.toString()) ?? 0), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold))
                              else if (rfidBefore != null)
                                Text('UID: $rfidBefore', style: GoogleFonts.inter(fontSize: 13))
                              else
                                Text('-', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedGray)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SESUDAH', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTeal)),
                              const SizedBox(height: 6),
                              if (balanceAfter != null)
                                Text(fmt.format(int.tryParse(balanceAfter.toString()) ?? 0), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkTeal))
                              else if (rfidAfter != null)
                                Text('UID: $rfidAfter', style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkTeal))
                              else
                                Text('-', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedGray)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'TUTUP',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.nearBlack, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).profile;
    final actorId = profile?['id']?.toString();
    final dbActionKey = _selectedType == 'Top-Up'
        ? 'TOPUP_TUNAI'
        : (_selectedType == 'Koreksi'
            ? 'KOREKSI_SALDO'
            : (_selectedType == 'Kartu' ? 'KARTU' : 'Semua'));
    final filter = PaginatedAuditLogsFilter(
      actorId: actorId,
      actionType: dbActionKey,
      dateFilter: _selectedDateFilter,
    );
    final logsState = ref.watch(paginatedAuditLogsProvider(filter));
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filters row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
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
                          value: _selectedType,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: AppColors.nearBlack, fontSize: 13),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedType = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Transaksi')),
                            DropdownMenuItem(value: 'Top-Up', child: Text('Top-Up Tunai')),
                            DropdownMenuItem(value: 'Koreksi', child: Text(AppStrings.keuanganKoreksiSaldo)),
                            DropdownMenuItem(value: 'Kartu', child: Text('Registrasi Kartu')),
                          ],
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
                          value: _selectedDateFilter,
                          isExpanded: true,
                          style: GoogleFonts.inter(color: AppColors.nearBlack, fontSize: 13),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDateFilter = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Waktu')),
                            DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                            DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
                            DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: Builder(
                builder: (context) {
                  if (logsState.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                      ),
                    );
                  }

                  if (logsState.error != null && logsState.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                            const SizedBox(height: 12),
                            Text('${AppStrings.labelFailed} memuat riwayat'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(paginatedAuditLogsProvider(filter)),
                              child: const Text(AppStrings.buttonRetry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final list = logsState.items;

                  if (list.isEmpty) {
                    return const EmptyStateWidget(
                      message: AppStrings.noTransactions,
                    );
                  }

                  // Calculation for header stats of the day from loaded list
                  double topupSum = 0.0;
                  double correctionSum = 0.0;
                  final today = DateTime.now();
                  final todayStart = DateTime(today.year, today.month, today.day);

                  for (var log in list) {
                    final type = log.actionType;
                    final created = log.createdAt?.toLocal() ?? DateTime.now();

                    if (created.isAfter(todayStart)) {
                      final newValue = log.newValue;
                      final oldValue = log.oldValue;
                      
                      if (type == 'TOPUP_TUNAI') {
                        final int currentB = int.tryParse(oldValue['balance']?.toString() ?? '0') ?? 0;
                        final int newB = int.tryParse(newValue['balance']?.toString() ?? '0') ?? 0;
                        topupSum += (newB - currentB);
                      } else if (type == 'KOREKSI_SALDO') {
                        final int currentB = int.tryParse(oldValue['balance']?.toString() ?? '0') ?? 0;
                        final int newB = int.tryParse(newValue['balance']?.toString() ?? '0') ?? 0;
                        correctionSum += (newB - currentB);
                      }
                    }
                  }

                  return Column(
                    children: [
                      // Statistics Summary Banner (Sticky Header)
                      if (_selectedDateFilter == 'Hari Ini' || _selectedDateFilter == 'Semua')
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkTeal.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkTeal.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Top-Up Hari Ini', style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedGray)),
                                  const SizedBox(height: 2),
                                  Text(fmt.format(topupSum), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                                ],
                              ),
                              Container(width: 1, height: 32, color: AppColors.borderGray),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Koreksi Net Hari Ini', style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedGray)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${correctionSum >= 0 ? "+" : ""}${fmt.format(correctionSum)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: correctionSum >= 0 ? AppColors.successGreen : AppColors.errorRed2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // List of Audit Logs
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => ref.invalidate(paginatedAuditLogsProvider(filter)),
                          color: AppColors.darkTeal,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: list.length + (logsState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == list.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                                  ),
                                );
                              }
                              final log = list[index];
                              final actionType = log.actionType;
                              final desc = log.description;
                              final created = log.createdAt?.toLocal() ?? DateTime.now();
                              final timeStr = DateFormat('HH:mm', 'id_ID').format(created);
                              final dateStr = DateFormat('dd MMM', 'id_ID').format(created);

                              IconData icon = CupertinoIcons.doc_text_fill;
                              Color iconColor = AppColors.darkTeal;

                              if (actionType == 'TOPUP_TUNAI') {
                                icon = CupertinoIcons.arrow_up_circle_fill;
                                iconColor = AppColors.successGreen;
                              } else if (actionType == 'KOREKSI_SALDO') {
                                icon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
                                iconColor = AppColors.errorRed2;
                              } else if (actionType == 'REGISTRASI_KARTU') {
                                icon = CupertinoIcons.wifi;
                                iconColor = AppColors.darkOrange;
                              } else if (actionType == 'UNLINK_KARTU') {
                                icon = CupertinoIcons.clear_circled_solid;
                                iconColor = AppColors.mutedGray;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withValues(alpha: 0.04),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showDetailBottomSheet(log, fmt),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: iconColor.withValues(alpha: 0.08),
                                            child: Icon(icon, color: iconColor, size: 20),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  actionType.toString().replaceAll('_', ' '),
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: iconColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  desc,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppColors.nearBlack,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                timeStr,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.nearBlack,
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: AppColors.mutedGray,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
