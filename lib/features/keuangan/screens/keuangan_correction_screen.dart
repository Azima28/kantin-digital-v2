import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/keuangan/widgets/correction_form.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_correction_step_confirm.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_correction_step_search.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_correction_success_screen.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_step_indicator.dart';

class KeuanganCorrectionScreen extends ConsumerStatefulWidget {
  final StudentWithProfile? prefilledStudent;
  const KeuanganCorrectionScreen({super.key, this.prefilledStudent});

  @override
  ConsumerState<KeuanganCorrectionScreen> createState() =>
      _KeuanganCorrectionScreenState();
}

class _KeuanganCorrectionScreenState
    extends ConsumerState<KeuanganCorrectionScreen> {
  int _currentStep =
      1; // 1: Search, 2: Correction details, 3: Confirm, 4: Success

  // Step 1: Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  StudentWithProfile? _selectedStudent;
  List<StudentWithProfile> _searchResults = [];
  bool _hasSearched = false;
  Timer? _debounce;

  // Step 2: Correction Details — state stored from CorrectionForm callback
  int _storedAmount = 0;
  bool _storedIsAddition = false;
  String _storedReason = '';

  // Success details
  String _refCode = '';
  String _successTime = '';
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    if (widget.prefilledStudent != null) {
      _selectedStudent = widget.prefilledStudent;
      _currentStep = 2; // Skip search step
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int get _studentBalance => _selectedStudent?.balance ?? 0;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchStudent(query);
    });
  }

  Future<void> _searchStudent(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final client = ref.read(supabaseClientProvider);

      // Query profiles for student matching NISN or name (fuzzy search)
      final List<dynamic> res = await client
          .from('profiles')
          .select(
            'id, full_name, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid)',
          )
          .eq('role', 'student')
          .or('nisn.ilike."%$query%",full_name.ilike."%$query%"')
          .limit(5);

      setState(() {
        _searchResults = res
            .map(
              (e) =>
                  StudentWithProfile.fromJoinedJson(e as Map<String, dynamic>),
            )
            .toList();
        _hasSearched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pencarian gagal: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _processCorrection() async {
    // Show confirmation dialog first
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text('${AppStrings.titleConfirmation} Koreksi Saldo'),
        content: const Text(
          'Aksi ini bersifat permanen dan akan dicatat dalam Audit Log Dinas yang dapat diperiksa oleh Super Admin kapan saja. Lanjutkan?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: !_storedIsAddition,
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeCorrectionInDB();
            },
            child: const Text('Proses'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCorrectionInDB() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final profile = ref.read(authNotifierProvider).profile;
      final actorId = profile?['id'];

      final studentId = _selectedStudent!.id;
      final int amount = _storedAmount;
      final int finalNewBalance = _storedIsAddition
          ? _studentBalance + amount
          : _studentBalance - amount;
      final String reason = _storedReason;

      // Call RPC process_correction (handles balance update, audit log, notification)
      await client.rpc('process_correction', params: {
        'p_student_id': studentId,
        'p_new_balance': finalNewBalance,
        'p_operator_id': actorId,
        'p_reason': reason,
      });

      // Invalidate providers
      ref.invalidate(keuanganDashboardProvider);
      ref.invalidate(keuanganStudentsProvider);
      ref.invalidate(keuanganStudentDetailProvider(studentId));

      final now = DateTime.now();
      setState(() {
        _refCode =
            'ADJ-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}';
        _successTime = DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(now);
        _currentStep = 4; // success screen
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Koreksi gagal'),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _studentName => _selectedStudent?.fullName ?? AppStrings.adminStudents;
  String get _studentClass => _selectedStudent?.class_ ?? '-';
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppStrings.keuanganKoreksiSaldo,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
            fontSize: 18,
          ),
        ),
        leading: _currentStep == 4
            ? const SizedBox() // Disable back button on success screen
            : IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () {
                  if (_currentStep == 1) {
                    context.pop();
                  } else if (_currentStep == 2) {
                    if (widget.prefilledStudent != null) {
                      context.pop();
                    } else {
                      setState(() {
                        _currentStep = 1;
                      });
                    }
                  } else if (_currentStep == 3) {
                    setState(() {
                      _currentStep = 2;
                    });
                  }
                },
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicators for steps
            if (_currentStep < 4) _buildProgressIndicator(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildStepContent(fmt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return KeuanganStepIndicator(
      currentStep: _currentStep,
      step1Label: 'LANGKAH 1 DARI 3 — Cari Siswa',
      step2Label: 'LANGKAH 2 DARI 3 — Detail Koreksi',
      step3Label: 'LANGKAH 3 DARI 3 — ${AppStrings.titleConfirmation}',
    );
  }

  Widget _buildStepContent(NumberFormat fmt) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Search();
      case 2:
        return _buildStep2Details(fmt);
      case 3:
        return _buildStep3Confirm(fmt);
      case 4:
        return _buildSuccessScreen(fmt);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Search() {
    return KeuanganCorrectionStepSearch(
      searchController: _searchController,
      isSearching: _isSearching,
      hasSearched: _hasSearched,
      searchResults: _searchResults,
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: (val) {
        _debounce?.cancel();
        _searchStudent(val);
      },
      onSearchCleared: () {
        _searchController.clear();
        _searchStudent('');
      },
      onStudentSelected: (student) {
        setState(() {
          _selectedStudent = student;
          _currentStep = 2;
        });
      },
    );
  }

  Widget _buildStep2Details(NumberFormat fmt) {
    return CorrectionForm(
      key: ValueKey('correction_form_${_selectedStudent?.id}'),
      selectedStudent: _selectedStudent!,
      fmt: fmt,
      onSubmit: (int amount, bool isAddition, String reason) {
        setState(() {
          _storedAmount = amount;
          _storedIsAddition = isAddition;
          _storedReason = reason;
          _currentStep = 3;
        });
      },
    );
  }

  Widget _buildStep3Confirm(NumberFormat fmt) {
    final int amount = _storedAmount;
    return KeuanganCorrectionStepConfirm(
      fmt: fmt,
      studentName: _studentName,
      studentClass: _studentClass,
      studentBalance: _studentBalance,
      amount: amount,
      isAddition: _storedIsAddition,
      reason: _storedReason,
      isLoading: _isLoading,
      onProcess: _processCorrection,
    );
  }

  Widget _buildSuccessScreen(NumberFormat fmt) {
    final int amount = _storedAmount;
    return KeuanganCorrectionSuccessScreen(
      fmt: fmt,
      studentName: _studentName,
      studentBalance: _studentBalance,
      amount: amount,
      isAddition: _storedIsAddition,
      successTime: _successTime,
      refCode: _refCode,
    );
  }
}
