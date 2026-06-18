import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final keuanganHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final profile = ref.read(authNotifierProvider).profile;
  final actorId = profile?['id'];

  // Guard: if actor ID is not available, return empty list
  if (actorId == null || actorId.toString().isEmpty) {
    return <Map<String, dynamic>>[];
  }

  final List<dynamic> res = await client
      .from('audit_logs')
      .select('id, action_type, description, created_at, old_value, new_value, target_id')
      .eq('actor_id', actorId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
});

class KeuanganHistoryScreen extends ConsumerStatefulWidget {
  const KeuanganHistoryScreen({super.key});

  @override
  ConsumerState<KeuanganHistoryScreen> createState() => _KeuanganHistoryScreenState();
}

class _KeuanganHistoryScreenState extends ConsumerState<KeuanganHistoryScreen> {
  String _selectedType = 'Semua'; // 'Semua', 'Top-Up', 'Koreksi', 'Kartu'
  String _selectedDateFilter = 'Semua'; // 'Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini'

  static const Color primaryTeal = Color(0xFF003434);
  static const Color accentOrange = Color(0xFF904D00);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

  void _showDetailBottomSheet(Map<String, dynamic> log, NumberFormat fmt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final actionType = log['action_type'] ?? '';
        final desc = log['description'] ?? '';
        final created = DateTime.parse(log['created_at']).toLocal();
        final timeStr = DateFormat('dd MMMM yyyy, HH:mm:ss').format(created);
        final oldValue = log['old_value'] as Map<String, dynamic>? ?? {};
        final newValue = log['new_value'] as Map<String, dynamic>? ?? {};

        // Extract before/after values
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
                        color: const Color(0xFFE4E2E1),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Detail Aktivitas Keuangan',
                    style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTeal),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Tipe Aksi', actionType.toString().replaceAll('_', ' ')),
                  const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                  _buildDetailRow('Waktu', timeStr),
                  const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                  _buildDetailRow('Keterangan', desc),
                  if (reason.toString().isNotEmpty) ...[
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildDetailRow('Alasan Koreksi', reason.toString()),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Perubahan Data:',
                    style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF9F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E2E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SEBELUM', style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6F7978))),
                              const SizedBox(height: 6),
                              if (balanceBefore != null)
                                Text(fmt.format(double.tryParse(balanceBefore.toString()) ?? 0.0), style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold))
                              else if (rfidBefore != null)
                                Text('UID: $rfidBefore', style: GoogleFonts.beVietnamPro(fontSize: 13))
                              else
                                Text('-', style: GoogleFonts.beVietnamPro(fontSize: 13, color: const Color(0xFF6F7978))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF9F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E2E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SESUDAH', style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                              const SizedBox(height: 6),
                              if (balanceAfter != null)
                                Text(fmt.format(double.tryParse(balanceAfter.toString()) ?? 0.0), style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTeal))
                              else if (rfidAfter != null)
                                Text('UID: $rfidAfter', style: GoogleFonts.beVietnamPro(fontSize: 13, color: primaryTeal))
                              else
                                Text('-', style: GoogleFonts.beVietnamPro(fontSize: 13, color: const Color(0xFF6F7978))),
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
                        backgroundColor: primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'TUTUP',
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white),
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
            style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B), fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(keuanganHistoryProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E2E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF1B1C1B), fontSize: 13),
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
                            DropdownMenuItem(value: 'Koreksi', child: Text('Koreksi Saldo')),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E2E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDateFilter,
                          isExpanded: true,
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF1B1C1B), fontSize: 13),
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
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(keuanganHistoryProvider),
                color: primaryTeal,
                child: historyAsync.when(
                  data: (logs) {
                    final today = DateTime.now();
                    final todayStart = DateTime(today.year, today.month, today.day);

                    // Filter logs
                    final filtered = logs.where((log) {
                      final type = log['action_type'] ?? '';
                      final created = DateTime.parse(log['created_at']).toLocal();

                      // Type filter
                      bool matchesType = true;
                      if (_selectedType == 'Top-Up') {
                        matchesType = type == 'TOPUP_TUNAI';
                      } else if (_selectedType == 'Koreksi') {
                        matchesType = type == 'KOREKSI_SALDO';
                      } else if (_selectedType == 'Kartu') {
                        matchesType = type == 'REGISTRASI_KARTU' || type == 'UNLINK_KARTU';
                      }

                      // Date filter
                      bool matchesDate = true;
                      if (_selectedDateFilter == 'Hari Ini') {
                        matchesDate = created.isAfter(todayStart);
                      } else if (_selectedDateFilter == 'Minggu Ini') {
                        matchesDate = created.isAfter(today.subtract(const Duration(days: 7)));
                      } else if (_selectedDateFilter == 'Bulan Ini') {
                        matchesDate = created.isAfter(today.subtract(const Duration(days: 30)));
                      }

                      return matchesType && matchesDate;
                    }).toList();

                    if (filtered.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(CupertinoIcons.square_list, size: 64, color: Color(0xFF6F7978)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada transaksi',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Semua transaksi kasir Anda akan muncul di sini.',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      color: const Color(0xFF6F7978),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Calculation for header stats of the day
                    double topupSum = 0.0;
                    double correctionSum = 0.0;
                    for (var log in filtered) {
                      final type = log['action_type'] ?? '';
                      final created = DateTime.parse(log['created_at']).toLocal();

                      if (created.isAfter(todayStart)) {
                        final newValue = log['new_value'] as Map<String, dynamic>? ?? {};
                        final oldValue = log['old_value'] as Map<String, dynamic>? ?? {};
                        
                        if (type == 'TOPUP_TUNAI') {
                          final double currentB = double.tryParse(oldValue['balance']?.toString() ?? '0') ?? 0.0;
                          final double newB = double.tryParse(newValue['balance']?.toString() ?? '0') ?? 0.0;
                          topupSum += (newB - currentB);
                        } else if (type == 'KOREKSI_SALDO') {
                          final double currentB = double.tryParse(oldValue['balance']?.toString() ?? '0') ?? 0.0;
                          final double newB = double.tryParse(newValue['balance']?.toString() ?? '0') ?? 0.0;
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
                              color: primaryTeal.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryTeal.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Top-Up Hari Ini', style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF6F7978))),
                                    const SizedBox(height: 2),
                                    Text(fmt.format(topupSum), style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: successGreen)),
                                  ],
                                ),
                                Container(width: 1, height: 32, color: const Color(0xFFE4E2E1)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Koreksi Net Hari Ini', style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF6F7978))),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${correctionSum >= 0 ? "+" : ""}${fmt.format(correctionSum)}',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: correctionSum >= 0 ? successGreen : dangerRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // List of Audit Logs
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final log = filtered[index];
                              final actionType = log['action_type'] ?? '';
                              final desc = log['description'] ?? '';
                              final created = DateTime.parse(log['created_at']).toLocal();
                              final timeStr = DateFormat('HH:mm').format(created);
                              final dateStr = DateFormat('dd MMM').format(created);

                              IconData icon = CupertinoIcons.doc_text_fill;
                              Color iconColor = primaryTeal;

                              if (actionType == 'TOPUP_TUNAI') {
                                icon = CupertinoIcons.arrow_up_circle_fill;
                                iconColor = successGreen;
                              } else if (actionType == 'KOREKSI_SALDO') {
                                icon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
                                iconColor = dangerRed;
                              } else if (actionType == 'REGISTRASI_KARTU') {
                                icon = CupertinoIcons.wifi;
                                iconColor = accentOrange;
                              } else if (actionType == 'UNLINK_KARTU') {
                                icon = CupertinoIcons.clear_circled_solid;
                                iconColor = const Color(0xFF6F7978);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: iconColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  desc,
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontSize: 12,
                                                    color: const Color(0xFF1B1C1B),
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
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1B1C1B),
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 10,
                                                  color: const Color(0xFF6F7978),
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
                      child: Text('Gagal memuat riwayat: $e', style: GoogleFonts.beVietnamPro(color: Colors.red)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
