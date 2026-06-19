import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/services/nfc_service.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/nfc_pulse_animator.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';
import 'package:intl/intl.dart';

class CheckCardScreen extends ConsumerStatefulWidget {
  const CheckCardScreen({super.key});

  @override
  ConsumerState<CheckCardScreen> createState() => _CheckCardScreenState();
}

class _CheckCardScreenState extends ConsumerState<CheckCardScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _studentData;
  String? _errorMessage;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _startNfcScan();
  }

  @override
  void dispose() {
    NfcService.stopScanning();
    super.dispose();
  }

  void _startNfcScan() async {
    setState(() {
      _errorMessage = null;
    });

    final bool isNfcAvailable = await NfcService.isNfcAvailable();
    if (!isNfcAvailable) {
      setState(() {
        _errorMessage = 'Hardware NFC tidak terdeteksi atau dinonaktifkan di perangkat ini. Gunakan simulator di bawah untuk pengujian.';
      });
    }

    NfcService.startScanning(
      onTagDiscovered: (String uid) {
        _fetchStudentDetails(uid);
      },
      onError: (String err) {
        setState(() {
          _errorMessage = err;
        });
      },
    );
  }

  Future<void> _fetchStudentDetails(String rfidUid) async {
    NfcService.stopScanning();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _studentData = null;
      _transactions = [];
    });

    try {
      final client = ref.read(supabaseClientProvider);
      
      // Query student profiles
      final Map<String, dynamic>? student = await client
          .from('students')
          .select('id, class, balance, is_active, profiles:profiles!students_id_fkey(full_name, email)')
          .eq('rfid_uid', rfidUid)
          .maybeSingle();

      if (student == null) {
        setState(() {
          _errorMessage = 'Kartu dengan UID $rfidUid tidak terdaftar di sistem Kantin Digital.';
          _isLoading = false;
        });
        return;
      }

      // Fetch 10 latest transactions
      final List<dynamic> txs = await client
          .from('transactions')
          .select('id, total_amount, type, status, created_at, canteen_operators(canteen_name)')
          .eq('student_id', student['id'])
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _studentData = student;
        _transactions = List<Map<String, dynamic>>.from(txs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil data kartu: $e';
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _studentData = null;
      _errorMessage = null;
      _transactions = [];
    });
    _startNfcScan();
  }

  // Simulated button scanner helper
  void _simulateScan(String rfidUid) {
    _fetchStudentDetails(rfidUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          'Cek Kartu Siswa',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                if (_isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CupertinoActivityIndicator(radius: 16),
                    ),
                  ),
                ] else if (_studentData != null) ...[
                  // Card Details View
                  _buildStudentCardView(_studentData!),
                ] else if (_errorMessage != null && !_errorMessage!.startsWith('Hardware NFC')) ...[
                  // Error view
                  _buildErrorView(),
                ] else ...[
                  // Scanning Idle view
                  _buildScanningView(),
                ],

                const SizedBox(height: 40),

                // Simulator Panel
                _buildSimulatorPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          // Visual Scanning indicator
          const NfcPulseAnimator(
            size: 100,
            color: AppColors.primary,
            child: Icon(
              CupertinoIcons.creditcard,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Siap Memindai Kartu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tempelkan kartu RFID/NFC siswa pada bagian belakang HP untuk membaca data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              height: 1.4,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.accentOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 36,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verifikasi Gagal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _reset,
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCardView(Map<String, dynamic> data) {
    final String name = data['profiles']?['full_name'] ?? 'Siswa';
    final String email = data['profiles']?['email'] ?? '';
    final String studentClass = data['class'] ?? 'Belum Diisi';
    final double balance = double.tryParse(data['balance'].toString()) ?? 0.0;
    final bool isActive = data['is_active'] ?? true;
    final String nis = email.split('@').first; // extract NIS from email local-part

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Initials / Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIS: $nis \u2022 Kelas $studentClass',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0.5, color: AppColors.borderLight),
          // Body Card Info (Balance)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STATUS KARTU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isActive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock_fill,
                            size: 11,
                            color: isActive ? AppColors.primary : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktif' : 'Dibekukan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.primary : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'SALDO AKTIF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGray,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(balance),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0.5, color: AppColors.borderLight),
          // Riwayat Transaksi Card
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RIWAYAT TRANSAKSI (10 TERAKHIR)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentTransactionsScreen(
                              studentId: data['id'],
                              primaryColor: AppColors.primary,
                              accentColor: AppColors.accentOrange,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'Belum ada transaksi.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _transactions.map((tx) {
                      final type = tx['type']?.toString() ?? 'purchase';
                      final isTopup = type == 'topup';
                      final status = tx['status']?.toString() ?? 'success';
                      final isSuccess = status == 'success';
                      final double amount = double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
                      final timestamp = DateTime.tryParse(tx['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
                      final timeStr = DateFormat('dd MMM, HH:mm', 'id_ID').format(timestamp);
                      final canteenName = tx['canteen_operators']?['canteen_name']?.toString() ?? 'Top-up';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isTopup
                                      ? const Color(0xFF006A35).withValues(alpha: 0.08)
                                      : AppColors.primary.withValues(alpha: 0.08),
                                  child: Icon(
                                    isTopup ? CupertinoIcons.arrow_up : CupertinoIcons.cart,
                                    size: 14,
                                    color: isTopup ? const Color(0xFF006A35) : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTopup ? 'Top-Up Saldo' : canteenName,
                                      style: GoogleFonts.beVietnamPro(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isTopup ? "+" : "-"}${CurrencyFormatter.format(amount)}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isTopup ? const Color(0xFF006A35) : AppColors.primary,
                                  ),
                                ),
                                if (!isSuccess)
                                  Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const Divider(height: 0.5, color: AppColors.borderLight),
          // Footer actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _reset,
                child: const Text(
                  'Scan Kartu Lain',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.device_phone_portrait, size: 18, color: AppColors.accentOrange),
              SizedBox(width: 8),
              Text(
                'Simulator Scan Kartu (Dev Only)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Klik tombol di bawah untuk menyimulasikan pembacaan kartu RFID via hardware:',
            style: TextStyle(fontSize: 11, color: AppColors.textGray),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: AppColors.primaryLight,
                side: BorderSide.none,
                label: const Text('Ahmad Subarjo (Aktif)', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _simulateScan('04:A3:F8:12'),
              ),
              ActionChip(
                backgroundColor: AppColors.errorLight,
                side: BorderSide.none,
                label: const Text('Kartu Tidak Terdaftar', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _simulateScan('11:22:33:44'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
