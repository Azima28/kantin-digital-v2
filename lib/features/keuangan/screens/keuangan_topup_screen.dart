import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_topup_step_amount.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_topup_step_confirm.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_topup_step_search.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_topup_success_screen.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_step_indicator.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';

class KeuanganTopupScreen extends ConsumerStatefulWidget {
  final StudentWithProfile? prefilledStudent;
  const KeuanganTopupScreen({super.key, this.prefilledStudent});

  @override
  ConsumerState<KeuanganTopupScreen> createState() =>
      _KeuanganTopupScreenState();
}

class _KeuanganTopupScreenState extends ConsumerState<KeuanganTopupScreen> {
  int _currentStep = 1; // 1: Search, 2: Amount, 3: Confirm, 4: Success

  // Master Cache & In-Memory Filter Pool
  static List<StudentWithProfile> _globalStudentPool = [];
  List<StudentWithProfile> _allStudents = [];
  List<StudentWithProfile> _allMatchingList = [];
  List<StudentWithProfile> _initialStudents = [];
  List<StudentWithProfile> _searchResults = [];

  // Infinite Scroll & Pagination State
  final ScrollController _scrollController = ScrollController();
  int _currentDisplayLimit = 10;
  bool _isLoadingMore = false;

  // Step 1: Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  StudentWithProfile? _selectedStudent;
  bool _hasSearched = false;
  Timer? _debounce;

  // Step 2: Amount
  final TextEditingController _amountController = TextEditingController();
  int? _selectedQuickAmount;

  // Transaction details for success state
  String _refCode = '';
  String _successTime = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.prefilledStudent != null) {
      _selectedStudent = widget.prefilledStudent;
      _currentStep = 2; // Skip search step
    } else {
      if (_globalStudentPool.isNotEmpty) {
        _applyStudentPool(_globalStudentPool);
      }
      _loadStudents();
    }
  }

  void _onScroll() {
    if (_currentStep != 1) return;
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 60) {
      _loadMoreStudents();
    }
  }

  void _loadMoreStudents() {
    if (_isLoadingMore) return;
    if (_currentDisplayLimit >= _allMatchingList.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentDisplayLimit += 10;
          _searchResults = _allMatchingList.take(_currentDisplayLimit).toList();
          _isLoadingMore = false;
        });
      }
    });
  }

  void _applyStudentPool(List<StudentWithProfile> list) {
    _allStudents = List.from(list);
    final shuffled = List<StudentWithProfile>.from(list)..shuffle();
    _initialStudents = shuffled;
    if (_searchController.text.trim().isEmpty) {
      _allMatchingList = shuffled;
      _currentDisplayLimit = 10;
      _searchResults = _allMatchingList.take(_currentDisplayLimit).toList();
    } else {
      _filterLocally(_searchController.text.trim());
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isSearching = _searchResults.isEmpty);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/student/lookup');

      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final students = list
            .map((item) => StudentWithProfile.fromApiJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();

        _globalStudentPool = students;
        if (mounted) {
          setState(() {
            _applyStudentPool(students);
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      final fmt = NumberFormat('#,###', 'id_ID');
      _amountController.text = fmt.format(amount);
    });
  }

  int _getAmount() {
    final clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  /// ⚡ 100% Client-Side Instant Substring Search (0 Network Requests saat mengetik)
  void _filterLocally(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      setState(() {
        _allMatchingList = _initialStudents;
        _currentDisplayLimit = 10;
        _searchResults = _allMatchingList.take(_currentDisplayLimit).toList();
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    if (_allStudents.isEmpty) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () => _fallbackNetworkSearch(clean));
      return;
    }

    final filtered = _allStudents.where((s) {
      final name = s.fullName.toLowerCase();
      final nisn = (s.nisn ?? '').toLowerCase();
      final cls = (s.class_ ?? '').toLowerCase();
      final email = (s.email ?? '').toLowerCase();
      return name.contains(clean) ||
          nisn.contains(clean) ||
          cls.contains(clean) ||
          email.contains(clean);
    }).toList();

    setState(() {
      _allMatchingList = filtered;
      _currentDisplayLimit = 10;
      _searchResults = _allMatchingList.take(_currentDisplayLimit).toList();
      _hasSearched = true;
      _isSearching = false;
    });

    if (filtered.isEmpty) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () => _fallbackNetworkSearch(clean));
    }
  }

  Future<void> _fallbackNetworkSearch(String clean) async {
    if (clean.isEmpty) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/student/lookup', queryParams: {'search': clean});
      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final results = list
            .map((item) => StudentWithProfile.fromApiJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();

        for (final r in results) {
          if (!_allStudents.any((s) => s.id == r.id)) {
            _allStudents.add(r);
            _globalStudentPool.add(r);
          }
        }

        if (mounted && _searchController.text.trim().toLowerCase() == clean) {
          setState(() {
            _allMatchingList = results;
            _currentDisplayLimit = 10;
            _searchResults = _allMatchingList.take(_currentDisplayLimit).toList();
            _hasSearched = true;
          });
        }
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    _filterLocally(query);
  }

  Future<void> _processTopup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final studentId = _selectedStudent!.id;
      final int amount = _getAmount();

      final response = await apiClient.post('/finance/topup', body: {
        'student_id': studentId,
        'amount': amount,
      });

      if (!response.success) {
        throw Exception(response.message ?? 'Top-up gagal');
      }

      // Invalidate providers to trigger update
      ref.invalidate(keuanganDashboardProvider);
      ref.invalidate(keuanganStudentsProvider);
      ref.invalidate(keuanganStudentDetailProvider(studentId));
      ref.invalidate(userNotificationsProvider);
      ref.invalidate(keuanganHistoryProvider);

      final now = DateTime.now();
      setState(() {
        _refCode =
            'TXN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}';
        _successTime = DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(now);
        _currentStep = 4; // success screen
      });

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil Disimpan',
          message: 'Top-up saldo siswa $_studentName telah aman diproses.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Top-up gagal'),
            backgroundColor: Nebula.rose,
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
  String get _studentNisn => _selectedStudent?.nisn ?? '-';
  String get _studentClass => _selectedStudent?.class_ ?? '-';
  int get _studentBalance => _selectedStudent?.balance ?? 0;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Top-Up Tunai',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
            fontSize: 18,
          ),
        ),
        leading: _currentStep == 4
            ? const SizedBox() // Disable back button on success screen
            : PressScale(
                onTap: () {
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
                child: IconButton(
                  icon: const Icon(CupertinoIcons.back),
                  onPressed: null,
                ),
              ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Progress indicators for steps
                if (_currentStep < 4) _buildProgressIndicator(),
                if (_currentStep < 4) const GradientLine(height: 1, margin: EdgeInsets.symmetric(vertical: 0)),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return KeuanganStepIndicator(
      currentStep: _currentStep,
      step1Label: 'LANGKAH 1 DARI 3 — Cari Siswa',
      step2Label:
          'LANGKAH 2 DARI 3 — ${AppStrings.titleConfirmation} & Nominal',
      step3Label:
          'LANGKAH 3 DARI 3 — ${AppStrings.titleConfirmation}',
    );
  }

  Widget _buildStepContent(NumberFormat fmt) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Search();
      case 2:
        return _buildStep2Amount(fmt);
      case 3:
        return _buildStep3Confirm(fmt);
      case 4:
        return _buildSuccessScreen(fmt);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Search() {
    final bool hasMore = _currentDisplayLimit < _allMatchingList.length;
    return KeuanganTopupStepSearch(
      searchController: _searchController,
      isSearching: _isSearching,
      hasSearched: _hasSearched,
      searchResults: _searchResults,
      isLoadingMore: _isLoadingMore,
      hasMore: hasMore,
      totalMatches: _allMatchingList.length,
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: (val) {
        _debounce?.cancel();
        _filterLocally(val);
      },
      onSearchCleared: () {
        _debounce?.cancel();
        _searchController.clear();
        setState(() {
          _allMatchingList = _initialStudents;
          _currentDisplayLimit = 10;
          _searchResults = _allMatchingList.take(_currentDisplayLimit).toList();
          _hasSearched = false;
          _isSearching = false;
        });
      },
      onStudentSelected: (student) {
        setState(() {
          _selectedStudent = student;
          _currentStep = 2;
        });
      },
    );
  }

  Widget _buildStep2Amount(NumberFormat fmt) {
    return KeuanganTopupStepAmount(
      fmt: fmt,
      studentName: _studentName,
      studentNisn: _studentNisn,
      studentClass: _studentClass,
      studentBalance: _studentBalance,
      amountController: _amountController,
      selectedQuickAmount: _selectedQuickAmount,
      onQuickAmountSelected: _onQuickAmountSelected,
      onChanged: () {
        setState(() {
          _selectedQuickAmount = null;
        });
      },
      onContinue: () {
        setState(() {
          _currentStep = 3;
        });
      },
    );
  }

  Widget _buildStep3Confirm(NumberFormat fmt) {
    final int amount = _getAmount();
    return KeuanganTopupStepConfirm(
      fmt: fmt,
      studentName: _studentName,
      studentNisn: _studentNisn,
      studentClass: _studentClass,
      studentBalance: _studentBalance,
      amount: amount,
      isLoading: _isLoading,
      onProcess: _processTopup,
    );
  }

  Widget _buildSuccessScreen(NumberFormat fmt) {
    final int amount = _getAmount();
    final int newBalance = _studentBalance + amount;

    return KeuanganTopupSuccessScreen(
      studentName: _studentName,
      amount: amount,
      newBalance: newBalance,
      successTime: _successTime,
      refCode: _refCode,
      fmt: fmt,
    );
  }
}
