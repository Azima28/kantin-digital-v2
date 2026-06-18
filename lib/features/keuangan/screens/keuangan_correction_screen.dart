import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_dashboard_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_students_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_student_detail_screen.dart';

class KeuanganCorrectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefilledStudent;
  const KeuanganCorrectionScreen({super.key, this.prefilledStudent});

  @override
  ConsumerState<KeuanganCorrectionScreen> createState() => _KeuanganCorrectionScreenState();
}

class _KeuanganCorrectionScreenState extends ConsumerState<KeuanganCorrectionScreen> {
  int _currentStep = 1; // 1: Search, 2: Correction details, 3: Confirm, 4: Success
  
  // Step 1: Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _selectedStudent;
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  Timer? _debounce;

  // Step 2: Correction Details
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isAddition = false; // false = reduce balance, true = add balance

  // Success details
  String _refCode = '';
  String _successTime = '';
  bool _isLoading = false;

  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

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
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double _getAmount() {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  double _getNewBalance() {
    final double amount = _getAmount();
    if (_isAddition) {
      return _studentBalance + amount;
    } else {
      return _studentBalance - amount;
    }
  }

  bool _isReasonValid() {
    return _reasonController.text.trim().length >= 10;
  }

  bool _isBalanceValid() {
    final double amount = _getAmount();
    if (amount <= 0) return false;
    if (!_isAddition && amount > _studentBalance) {
      return false; // cannot reduce below 0
    }
    return true;
  }

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
          .select('id, full_name, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid)')
          .eq('role', 'student')
          .or('nisn.ilike."%$query%",full_name.ilike."%$query%"')
          .limit(5);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(res);
        _hasSearched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pencarian gagal: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: dangerRed,
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
        title: const Text('Konfirmasi Koreksi Saldo'),
        content: const Text(
          'Aksi ini bersifat permanen dan akan dicatat dalam Audit Log Dinas yang dapat diperiksa oleh Super Admin kapan saja. Lanjutkan?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: !_isAddition,
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
      final actorName = profile?['full_name'] ?? 'Admin Keuangan';
      final actorId = profile?['id'];
      
      final studentId = _selectedStudent!['id'];
      final double amount = _getAmount();
      final double finalNewBalance = _getNewBalance();
      final String reason = _reasonController.text.trim();

      // 1. Update student balance in DB
      await client
          .from('students')
          .update({'balance': finalNewBalance})
          .eq('id', studentId);

      // 2. Write to audit logs table
      await client.from('audit_logs').insert({
        'actor_id': actorId,
        'actor_name': actorName,
        'action_type': 'KOREKSI_SALDO',
        'description': 'Koreksi saldo ${_isAddition ? "penambahan" : "pengurangan"} sebesar Rp ${NumberFormat.decimalPattern("id_ID").format(amount)} untuk $_studentName. Alasan: $reason',
        'target_id': studentId,
        'old_value': {'balance': _studentBalance},
        'new_value': {'balance': finalNewBalance, 'reason': reason},
      });

      // 3. Send system notification to student
      await client.from('notifications').insert({
        'student_id': studentId,
        'title': 'Koreksi Saldo!',
        'message': 'Saldo Anda telah disesuaikan oleh admin menjadi Rp ${NumberFormat.decimalPattern("id_ID").format(finalNewBalance)}. Alasan: $reason',
        'type': 'system',
      });

      // Invalidate providers
      ref.invalidate(keuanganDashboardProvider);
      ref.invalidate(keuanganStudentsProvider);
      ref.invalidate(keuanganStudentDetailProvider(studentId));

      final now = DateTime.now();
      setState(() {
        _refCode = 'ADJ-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}';
        _successTime = DateFormat('dd MMM yyyy, HH:mm:ss').format(now);
        _currentStep = 4; // success screen
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koreksi gagal: $e'),
            backgroundColor: dangerRed,
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

  String get _studentName => _selectedStudent?['full_name'] ?? 'Siswa';
  String get _studentClass => _selectedStudent?['students']?['class'] ?? '-';
  double get _studentBalance => double.tryParse(_selectedStudent?['students']?['balance']?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Koreksi Saldo',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 18),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildStepContent(fmt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentStep == 1
                ? 'LANGKAH 1 DARI 3 — Cari Siswa'
                : _currentStep == 2
                    ? 'LANGKAH 2 DARI 3 — Detail Koreksi'
                    : 'LANGKAH 3 DARI 3 — Konfirmasi',
            style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6F7978)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep >= 2 ? primaryTeal : const Color(0xFFE4E2E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep >= 3 ? primaryTeal : const Color(0xFFE4E2E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Masukkan NISN atau Nama Siswa:',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1B), fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: (val) {
            _onSearchChanged(val.trim());
          },
          onSubmitted: (val) {
            _debounce?.cancel();
            _searchStudent(val.trim());
          },
          decoration: InputDecoration(
            hintText: 'Masukkan NISN atau Nama Lengkap...',
            hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, color: Color(0xFF6F7978), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchStudent('');
                        },
                      )
                    : const Icon(CupertinoIcons.search, color: Color(0xFF6F7978), size: 20),
          ),
        ),
        const SizedBox(height: 20),

        if (_isSearching && _searchResults.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CupertinoActivityIndicator(color: primaryTeal),
            ),
          )
        else if (_hasSearched && _searchResults.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Siswa tidak ditemukan.',
                style: GoogleFonts.beVietnamPro(color: dangerRed, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else if (_searchResults.isNotEmpty) ...[
          Text(
            'Hasil Pencarian (${_searchResults.length}):',
            style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6F7978)),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = _searchResults[index];
              final name = student['full_name'] ?? 'Tanpa Nama';
              final nisn = student['nisn'] ?? '-';
              final className = student['students']?['class'] ?? '-';
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E2E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    name,
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 14),
                  ),
                  subtitle: Text(
                    'NISN: $nisn • Kelas $className',
                    style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pilih',
                      style: GoogleFonts.beVietnamPro(
                        color: primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedStudent = student;
                      _currentStep = 2;
                    });
                  },
                ),
              );
            },
          ),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(CupertinoIcons.search, size: 48, color: primaryTeal.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'Ketik nama atau NISN siswa\nuntuk memulai pencarian.',
                    style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep2Details(NumberFormat fmt) {
    final double amount = _getAmount();
    final double newBalance = _getNewBalance();
    final bool balanceValid = _isBalanceValid();
    final bool reasonValid = _isReasonValid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
            children: [
              _buildInfoRow('Nama Siswa', _studentName),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Kelas', 'Kelas $_studentClass'),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Saat Ini', fmt.format(_studentBalance)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Type of correction
        Text(
          'Jenis Koreksi',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddition = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_isAddition ? dangerRed.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: !_isAddition ? dangerRed : const Color(0xFFE4E2E1)),
                  ),
                  child: Center(
                    child: Text(
                      'Kurangi Saldo',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        color: !_isAddition ? dangerRed : const Color(0xFF6F7978),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddition = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isAddition ? successGreen.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isAddition ? successGreen : const Color(0xFFE4E2E1)),
                  ),
                  child: Center(
                    child: Text(
                      'Tambah Saldo',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        color: _isAddition ? successGreen : const Color(0xFF6F7978),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Nominal
        Text(
          'Nominal Koreksi',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B), fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B)),
            hintText: '0',
            hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (amount > 0 && !_isAddition && amount > _studentBalance)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '⚠️ Saldo tidak mencukupi untuk pengurangan.',
              style: GoogleFonts.beVietnamPro(color: dangerRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

        Text(
          'Saldo Setelah Koreksi: ${fmt.format(newBalance)}',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: balanceValid ? primaryTeal : dangerRed,
          ),
        ),
        const SizedBox(height: 20),

        // Reason
        Text(
          'Alasan Koreksi (Wajib)',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B), fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Masukkan alasan koreksi secara detail...',
            hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Minimal 10 karakter. (Saat ini: ${_reasonController.text.trim().length} karakter)',
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            color: reasonValid ? successGreen : const Color(0xFF6F7978),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !balanceValid || !reasonValid
                ? null
                : () {
                    setState(() {
                      _currentStep = 3;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'LANJUT → KONFIRMASI',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Confirm(NumberFormat fmt) {
    final double amount = _getAmount();
    final double newBalance = _getNewBalance();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirm Bento Card
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
              Text(
                '⚠️ RINGKASAN KOREKSI SALDO',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: dangerRed, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Nama Siswa', _studentName),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Kelas', 'Kelas $_studentClass'),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Lama', fmt.format(_studentBalance)),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow(
                'Koreksi',
                '${_isAddition ? "+" : "-"}${fmt.format(amount)}',
                valueColor: _isAddition ? successGreen : dangerRed,
                isBold: true,
              ),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Baru', fmt.format(newBalance), isBold: true, valueColor: primaryTeal),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Alasan Koreksi', _reasonController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processCorrection,
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Text(
                    '✔ KUNCI & PROSES KOREKSI',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Aksi ini memerlukan konfirmasi keamanan tambahan.',
            style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6F7978)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(NumberFormat fmt) {
    final double amount = _getAmount();
    final double newBalance = _getNewBalance();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Success Icon
        Container(
          height: 80,
          width: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFEECEB),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.checkmark_shield_fill,
              color: dangerRed,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Koreksi Berhasil!',
          style: GoogleFonts.beVietnamPro(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saldo $_studentName berhasil disesuaikan.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: const Color(0xFF6F7978),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Detail Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4E2E1)),
          ),
          child: Column(
            children: [
              _buildInfoRow('Saldo Sebelum', fmt.format(_studentBalance)),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow(
                'Penyesuaian',
                '${_isAddition ? "+" : "-"}${fmt.format(amount)}',
                valueColor: _isAddition ? successGreen : dangerRed,
                isBold: true,
              ),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Baru', fmt.format(newBalance), isBold: true),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Waktu Transaksi', _successTime),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Kode Koreksi', _refCode),
            ],
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/finance');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'KEMBALI KE BERANDA',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1B1C1B),
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
