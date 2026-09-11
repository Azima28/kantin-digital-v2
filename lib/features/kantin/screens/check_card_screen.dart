import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/services/nfc_service.dart';
import 'package:kantin_digital/features/kantin/widgets/card_check_result_panel.dart';
import 'package:kantin_digital/features/kantin/widgets/card_check_simulator.dart';

import 'package:kantin_digital/core/utils/responsive.dart';

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
      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.get('/pos/scan-card', queryParams: {'rfid': rfidUid});

      Student student;
      String studentName = 'Siswa (Kartu Terdeteksi)';
      String studentEmail = 'siswa@kantin.id';

      if (response.success && response.data != null) {
        final studentJson = response.data as Map<String, dynamic>;
        student = Student.fromJson(studentJson);
        final profile = studentJson['profile'] is Map ? studentJson['profile'] as Map<String, dynamic> : null;
        studentName = profile?['full_name']?.toString() ?? studentJson['full_name']?.toString() ?? studentJson['name']?.toString() ?? 'Siswa';
        studentEmail = profile?['email']?.toString() ?? studentJson['email']?.toString() ?? '';

        List<OperatorTransaction> txList = [];
        try {
          final txRes = await apiClient.get('/student/transactions', queryParams: {
            'student_id': student.id,
            'limit': '10',
          });
          if (txRes.success && txRes.data != null) {
            final rawList = txRes.data is Map && (txRes.data as Map)['items'] is List
                ? (txRes.data as Map)['items'] as List
                : (txRes.data is List ? txRes.data as List : []);
            txList = rawList
                .map((item) => OperatorTransaction.fromSiswaJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _student = student;
            _studentName = studentName;
            _studentEmail = studentEmail;
            _transactions = txList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _student = null;
            _errorMessage = response.message ?? 'Kartu RFID tidak terdaftar pada akun siswa manapun atau sudah tidak berlaku.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _student = null;
          _errorMessage = 'Gagal memeriksa kartu: $e';
          _transactions = [];
          _isLoading = false;
        });
      }
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
    final isDesktop = Responsive.isDesktop(context) || MediaQuery.of(context).size.width >= 800;

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
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 700),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Result / Scanning View
                      Expanded(
                        flex: 6,
                        child: _buildMainContentView(),
                      ),
                      const SizedBox(width: 32),
                      // Right Column: Simulator Panel
                      Expanded(
                        flex: 5,
                        child: CardCheckSimulator(onSimulateScan: _simulateScan),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildMainContentView(),
                      const SizedBox(height: 32),
                      CardCheckSimulator(onSimulateScan: _simulateScan),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentView() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CupertinoActivityIndicator(radius: 16),
        ),
      );
    } else if (_student != null) {
      return StudentCardView(
        student: _student!,
        studentName: _studentName ?? AppStrings.adminStudents,
        studentEmail: _studentEmail ?? '',
        transactions: _transactions,
        onReset: _reset,
      );
    } else if (_errorMessage != null &&
        !_errorMessage!.startsWith('Hardware NFC')) {
      return ErrorView(
        errorMessage: _errorMessage!,
        onRetry: _reset,
      );
    } else {
      return ScanningView(errorMessage: _errorMessage);
    }
  }
}