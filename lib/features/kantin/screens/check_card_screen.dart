import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/nfc_service.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/widgets/card_check_result_panel.dart';
import 'package:kantin_digital/features/kantin/widgets/card_check_simulator.dart';

class CheckCardScreen extends ConsumerStatefulWidget {
  const CheckCardScreen({super.key});

  @override
  ConsumerState<CheckCardScreen> createState() => _CheckCardScreenState();
}

class _CheckCardScreenState extends ConsumerState<CheckCardScreen> {
  bool _isLoading = false;
  Student? _student;
  String? _studentName;
  String? _studentEmail;
  String? _errorMessage;
  List<OperatorTransaction> _transactions = [];

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
        _errorMessage =
            'Hardware NFC tidak terdeteksi atau dinonaktifkan di perangkat ini. Gunakan simulator di bawah untuk pengujian.';
      });
      return;
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
      _student = null;
      _studentName = null;
      _studentEmail = null;
      _transactions = [];
    });

    try {
      final client = ref.read(supabaseClientProvider);

      // Query student profiles
      final Map<String, dynamic>? studentJson = await client
          .from('students')
          .select(
              'id, class, balance, is_active, profiles:profiles!students_id_fkey(full_name, email)')
          .eq('rfid_uid', rfidUid)
          .maybeSingle();

      if (studentJson == null) {
        setState(() {
          _errorMessage =
              'Kartu dengan UID $rfidUid tidak terdaftar di sistem Kantin Digital.';
          _isLoading = false;
        });
        return;
      }

      final student = Student.fromJson(studentJson);
      final profilesData = studentJson['profiles'] as Map<String, dynamic>?;
      final studentName =
          profilesData?['full_name'] as String? ?? AppStrings.adminStudents;
      final studentEmail = profilesData?['email'] as String? ?? '';

      // Fetch 10 latest transactions
      final List<dynamic> txs = await client
          .from('transactions')
          .select(
              'id, total_amount, type, status, created_at, canteen_operators(canteen_name)')
          .eq('student_id', student.id)
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _student = student;
        _studentName = studentName;
        _studentEmail = studentEmail;
        _transactions = txs
            .map((e) =>
                OperatorTransaction.fromSiswaJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${AppStrings.labelFailed} mengambil data kartu';
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _student = null;
      _studentName = null;
      _studentEmail = null;
      _errorMessage = null;
      _transactions = [];
    });
    _startNfcScan();
  }

  void _simulateScan(String rfidUid) {
    _fetchStudentDetails(rfidUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Cek Kartu Siswa',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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

                if (_isLoading) ...{
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CupertinoActivityIndicator(radius: 16),
                    ),
                  ),
                } else if (_student != null) ...{
                  StudentCardView(
                    student: _student!,
                    studentName: _studentName ?? AppStrings.adminStudents,
                    studentEmail: _studentEmail ?? '',
                    transactions: _transactions,
                    onReset: _reset,
                  ),
                } else if (_errorMessage != null &&
                    !_errorMessage!.startsWith('Hardware NFC')) ...{
                  ErrorView(
                    errorMessage: _errorMessage!,
                    onRetry: _reset,
                  ),
                } else ...{
                  ScanningView(errorMessage: _errorMessage),
                },

                const SizedBox(height: 40),

                CardCheckSimulator(onSimulateScan: _simulateScan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
