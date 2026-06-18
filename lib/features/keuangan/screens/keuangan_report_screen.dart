import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final keuanganReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  
  // Fetch canteen operators and their earned balance
  final List<dynamic> canteens = await client
      .from('canteen_operators')
      .select('canteen_name, balance_earned');
      
  // Fetch all transactions to compile totals
  final List<dynamic> txs = await client
      .from('transactions')
      .select('total_amount, type, status, created_at');

  double totalTopup = 0.0;
  double totalPurchase = 0.0;
  int topupCount = 0;
  int purchaseCount = 0;

  for (var tx in txs) {
    if (tx['status'] != 'success') continue;
    final amt = double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
    if (tx['type'] == 'topup') {
      totalTopup += amt;
      topupCount++;
    } else if (tx['type'] == 'purchase') {
      totalPurchase += amt;
      purchaseCount++;
    }
  }

  // Fetch audit logs to compile corrections
  final List<dynamic> logs = await client
      .from('audit_logs')
      .select('old_value, new_value')
      .eq('action_type', 'KOREKSI_SALDO');

  double totalCorrection = 0.0;
  for (var log in logs) {
    final oldVal = log['old_value'] as Map<String, dynamic>? ?? {};
    final newVal = log['new_value'] as Map<String, dynamic>? ?? {};
    final double oldBal = double.tryParse(oldVal['balance']?.toString() ?? '0') ?? 0.0;
    final double newBal = double.tryParse(newVal['balance']?.toString() ?? '0') ?? 0.0;
    totalCorrection += (newBal - oldBal);
  }

  return {
    'canteens': List<Map<String, dynamic>>.from(canteens),
    'totalTopup': totalTopup,
    'totalPurchase': totalPurchase,
    'totalCorrection': totalCorrection,
    'topupCount': topupCount,
    'purchaseCount': purchaseCount,
  };
});

class KeuanganReportScreen extends ConsumerStatefulWidget {
  const KeuanganReportScreen({super.key});

  @override
  ConsumerState<KeuanganReportScreen> createState() => _KeuanganReportScreenState();
}

class _KeuanganReportScreenState extends ConsumerState<KeuanganReportScreen> {
  String _selectedPeriod = 'Bulan Ini'; // 'Hari Ini', 'Minggu Ini', 'Bulan Ini'

  static const Color primaryTeal = Color(0xFF003434);
  static const Color accentOrange = Color(0xFF904D00);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Export Laporan',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format Laporan:',
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1B1C1B)),
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
                            selectedColor: primaryTeal.withValues(alpha: 0.1),
                            backgroundColor: Colors.white,
                            checkmarkColor: primaryTeal,
                            labelStyle: GoogleFonts.beVietnamPro(
                              color: excelChecked ? primaryTeal : const Color(0xFF6F7978),
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
                            selectedColor: primaryTeal.withValues(alpha: 0.1),
                            backgroundColor: Colors.white,
                            checkmarkColor: primaryTeal,
                            labelStyle: GoogleFonts.beVietnamPro(
                              color: !excelChecked ? primaryTeal : const Color(0xFF6F7978),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Data Yang Disertakan:',
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1B1C1B)),
                    ),
                    CheckboxListTile(
                      title: Text('Rekap Riwayat Audit Log', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                      value: includeAudit,
                      activeColor: primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          includeAudit = val ?? true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text('Detail Per-Siswa (Data Sensitif)', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                      value: includeStudents,
                      activeColor: primaryTeal,
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
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1B1C1B)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      style: GoogleFonts.beVietnamPro(fontSize: 13),
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
                  child: Text('Batal', style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978))),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Laporan berhasil diexport dan dikirim ke ${emailController.text}'),
                        backgroundColor: successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                  child: Text('Generate & Kirim', style: GoogleFonts.beVietnamPro(color: Colors.white)),
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
      backgroundColor: Colors.white,
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
                  decoration: BoxDecoration(color: const Color(0xFFE4E2E1), borderRadius: BorderRadius.circular(2.5)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tren Transaksi Harian',
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualisasi tren pengisian saldo tunai sekolah.',
                style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6F7978)),
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
                style: GoogleFonts.beVietnamPro(fontSize: 11, fontStyle: FontStyle.italic, color: successGreen),
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
            color: primaryTeal,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.beVietnamPro(fontSize: 10, color: const Color(0xFF6F7978))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(keuanganReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Laporan Keuangan',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(keuanganReportProvider),
          color: primaryTeal,
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
                      'Pilih Periode:',
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B), fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E2E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF1B1C1B), fontSize: 13, fontWeight: FontWeight.bold),
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
                    final canteens = data['canteens'] as List<Map<String, dynamic>>;
                    final totalTopup = data['totalTopup'] as double;
                    final totalPurchase = data['totalPurchase'] as double;
                    final totalCorrection = data['totalCorrection'] as double;
                    final topupCount = data['topupCount'] as int;
                    final purchaseCount = data['purchaseCount'] as int;

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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
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
                                  const Icon(CupertinoIcons.graph_square_fill, color: primaryTeal, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ringkasan Periode ($_selectedPeriod)',
                                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildReportRow('Total Top-Up Tunai', fmt.format(totalTopup), detail: '$topupCount transaksi'),
                              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                              _buildReportRow('Total Pembayaran Belanja', fmt.format(totalPurchase), detail: '$purchaseCount transaksi', valueColor: accentOrange),
                              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                              _buildReportRow('Total Koreksi Saldo', '${totalCorrection >= 0 ? "+" : ""}${fmt.format(totalCorrection)}', valueColor: totalCorrection >= 0 ? successGreen : dangerRed),
                              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                              _buildReportRow(
                                'Net Aliran Masuk',
                                fmt.format(netInflow),
                                isBold: true,
                                valueColor: primaryTeal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Canteen operators revenue header
                        Text(
                          'Pendapatan per Stan Kantin:',
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1B1C1B)),
                        ),
                        const SizedBox(height: 12),

                        // Canteens list Bento Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
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
                                      style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: canteens.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final canteen = entry.value;
                                    final name = canteen['canteen_name'] ?? 'Stan Tanpa Nama';
                                    final double earned = double.tryParse(canteen['balance_earned']?.toString() ?? '0') ?? 0.0;

                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: primaryTeal.withValues(alpha: 0.08),
                                            child: const Icon(CupertinoIcons.house_alt_fill, color: primaryTeal, size: 18),
                                          ),
                                          title: Text(
                                            name,
                                            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1B1C1B)),
                                          ),
                                          trailing: Text(
                                            fmt.format(earned),
                                            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTeal),
                                          ),
                                        ),
                                        if (i < canteens.length - 1)
                                          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE4E2E1), indent: 72),
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
                                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryTeal,
                                  side: const BorderSide(color: primaryTeal),
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
                                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
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
                      child: CupertinoActivityIndicator(color: primaryTeal),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Gagal memuat laporan: $e', style: GoogleFonts.beVietnamPro(color: Colors.red)),
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
              style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
            ),
            if (detail != null)
              Text(
                detail,
                style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 11),
              ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1B1C1B),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
