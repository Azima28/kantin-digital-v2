import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class KeuanganReportScreen extends ConsumerStatefulWidget {
  const KeuanganReportScreen({super.key});

  @override
  ConsumerState<KeuanganReportScreen> createState() => _KeuanganReportScreenState();
}

class _KeuanganReportScreenState extends ConsumerState<KeuanganReportScreen> {
  String _selectedPeriod = 'Bulan Ini'; // 'Hari Ini', 'Minggu Ini', 'Bulan Ini'


  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool excelChecked = true;
        bool includeAudit = true;
        bool includeStudents = false;
        final emailController = TextEditingController(text: 'kepsekolah@smp-terpadu.sch.id');

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Export Laporan',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.darkTeal, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format Laporan:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.nearBlack),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Excel (.xlsx)')),
                            selected: excelChecked,
                            onSelected: (val) {
                              setDialogState(() {
                                excelChecked = true;
                              });
                            },
                            selectedColor: AppColors.darkTeal.withValues(alpha: 0.1),
                            backgroundColor: AppColors.white,
                            checkmarkColor: AppColors.darkTeal,
                            labelStyle: GoogleFonts.inter(
                              color: excelChecked ? AppColors.darkTeal : AppColors.mutedGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('PDF')),
                            selected: !excelChecked,
                            onSelected: (val) {
                              setDialogState(() {
                                excelChecked = false;
                              });
                            },
                            selectedColor: AppColors.darkTeal.withValues(alpha: 0.1),
                            backgroundColor: AppColors.white,
                            checkmarkColor: AppColors.darkTeal,
                            labelStyle: GoogleFonts.inter(
                              color: !excelChecked ? AppColors.darkTeal : AppColors.mutedGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${AppStrings.buttonSelect} Data Yang Disertakan:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.nearBlack),
                    ),
                    CheckboxListTile(
                      title: Text('Rekap Riwayat Audit Log', style: GoogleFonts.inter(fontSize: 12)),
                      value: includeAudit,
                      activeColor: AppColors.darkTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          includeAudit = val ?? true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text('${AppStrings.titleDetail} Per-Siswa (Data Sensitif)', style: GoogleFonts.inter(fontSize: 12)),
                      value: includeStudents,
                      activeColor: AppColors.darkTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          includeStudents = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kirim Ke Email:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.nearBlack),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'email@sekolah.sch.id',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.buttonCancel, style: GoogleFonts.inter(color: AppColors.mutedGray)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Laporan berhasil diexport dan dikirim ke ${emailController.text}'),
                        backgroundColor: AppColors.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkTeal),
                  child: Text('Generate & Kirim', style: GoogleFonts.inter(color: AppColors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTrendsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2.5)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tren Transaksi Harian',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkTeal),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualisasi tren pengisian saldo tunai sekolah.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedGray),
              ),
              const SizedBox(height: 24),
              // Simulated bar chart
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(40, 'Sen'),
                    _buildBar(60, 'Sel'),
                    _buildBar(85, 'Rab'),
                    _buildBar(35, 'Kam'),
                    _buildBar(110, 'Jum'),
                    _buildBar(15, 'Sab'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '* Tren meningkat 15% dari rata-rata minggu lalu.',
                style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.successGreen),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double heightPercentage, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: heightPercentage,
          decoration: BoxDecoration(
            color: AppColors.darkTeal,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.mutedGray)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(keuanganReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Laporan Keuangan',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(keuanganReportProvider),
          color: AppColors.darkTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.buttonSelect} Periode:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.nearBlack, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          style: GoogleFonts.inter(color: AppColors.nearBlack, fontSize: 13, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPeriod = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                            DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
                            DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                reportAsync.when(
                  data: (data) {
                    final rawCanteens = data['canteens'] as List<dynamic>;
                    final canteens = rawCanteens
                        .map((e) => CanteenOperator.fromJson(
                            Map<String, dynamic>.from(e)))
                        .toList();
                    final totalTopup = (data['totalTopup'] as num?)?.toDouble() ?? 0.0;
                    final totalPurchase = (data['totalPurchase'] as num?)?.toDouble() ?? 0.0;
                    final totalCorrection = (data['totalCorrection'] as num?)?.toDouble() ?? 0.0;
                    final topupCount = (data['topupCount'] as num?)?.toInt() ?? 0;
                    final purchaseCount = (data['purchaseCount'] as num?)?.toInt() ?? 0;

                    // Calculate net balance flow
                    final netInflow = totalTopup + totalCorrection;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.graph_square_fill, color: AppColors.darkTeal, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ringkasan Periode ($_selectedPeriod)',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkTeal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildReportRow('Total Top-Up Tunai', fmt.format(totalTopup), detail: '$topupCount transaksi'),
                              const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                              _buildReportRow('Total Pembayaran Belanja', fmt.format(totalPurchase), detail: '$purchaseCount transaksi', valueColor: AppColors.darkOrange),
                              const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                              _buildReportRow('Total Koreksi Saldo', '${totalCorrection >= 0 ? "+" : ""}${fmt.format(totalCorrection)}', valueColor: totalCorrection >= 0 ? AppColors.successGreen : AppColors.errorRed2),
                              const Divider(height: 16, thickness: 0.5, color: AppColors.borderGray),
                              _buildReportRow(
                                'Net Aliran Masuk',
                                fmt.format(netInflow),
                                isBold: true,
                                valueColor: AppColors.darkTeal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Canteen operators revenue header
                        Text(
                          'Pendapatan per Stan Kantin:',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.nearBlack),
                        ),
                        const SizedBox(height: 12),

                        // Canteens list Bento Card
                        Container(
                          width: double.infinity,
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
                          child: canteens.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'Belum ada pendapatan terekam untuk stan kantin.',
                                      style: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: canteens.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final canteen = entry.value;
                                    final name = canteen.canteenName;
                                    final int earned = canteen.balanceEarned;

                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.darkTeal.withValues(alpha: 0.08),
                                            child: const Icon(CupertinoIcons.house_alt_fill, color: AppColors.darkTeal, size: 18),
                                          ),
                                          title: Text(
                                            name,
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.nearBlack),
                                          ),
                                          trailing: Text(
                                            fmt.format(earned),
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkTeal),
                                          ),
                                        ),
                                        if (i < canteens.length - 1)
                                          const Divider(height: 1, thickness: 0.5, color: AppColors.borderGray, indent: 72),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showTrendsBottomSheet,
                                icon: const Icon(CupertinoIcons.chart_bar, size: 18),
                                label: Text(
                                  'Grafik Tren',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.darkTeal,
                                  side: const BorderSide(color: AppColors.darkTeal),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showExportDialog,
                                icon: const Icon(CupertinoIcons.share_up, size: 18),
                                label: Text(
                                  'Export Laporan',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkTeal,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                          const SizedBox(height: 12),
                          Text('${AppStrings.labelFailed} memuat laporan'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(keuanganReportProvider),
                            child: const Text(AppStrings.buttonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? valueColor, String? detail}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
            ),
            if (detail != null)
              Text(
                detail,
                style: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 11),
              ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.nearBlack,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
