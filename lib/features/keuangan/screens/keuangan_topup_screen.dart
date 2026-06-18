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

class KeuanganTopupScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefilledStudent;
  const KeuanganTopupScreen({super.key, this.prefilledStudent});

  @override
  ConsumerState<KeuanganTopupScreen> createState() => _KeuanganTopupScreenState();
}

class _KeuanganTopupScreenState extends ConsumerState<KeuanganTopupScreen> {
  int _currentStep = 1; // 1: Search, 2: Amount, 3: Confirm, 4: Success
  
  // Step 1: Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _selectedStudent;
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  Timer? _debounce;

  // Step 2: Amount
  final TextEditingController _amountController = TextEditingController();
  int? _selectedQuickAmount;
  
  // Transaction details for success state
  String _refCode = '';
  String _successTime = '';
  bool _isLoading = false;

  static const Color primaryTeal = Color(0xFF003434);
  static const Color accentOrange = Color(0xFF904D00);
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
    super.dispose();
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  double _getAmount() {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
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

  Future<void> _processTopup() async {
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
      
      // 1. Fetch current student details
      final studentData = await client
          .from('students')
          .select('balance')
          .eq('id', studentId)
          .single();

      final double currentBalance = double.tryParse(studentData['balance'].toString()) ?? 0.0;
      final double newBalance = currentBalance + amount;

      // 2. Fetch a default operator ID to associate with the transaction (violates NOT NULL if empty)
      final operators = await client.from('canteen_operators').select('id').limit(1);
      if (operators.isEmpty) {
        throw Exception('Tidak ada operator kantin terdaftar untuk mencatat transaksi top-up.');
      }
      final String operatorId = operators.first['id'];

      // 3. Update student balance in DB
      await client
          .from('students')
          .update({'balance': newBalance})
          .eq('id', studentId);

      // 4. Record transaction in DB
      await client.from('transactions').insert({
        'student_id': studentId,
        'operator_id': operatorId,
        'total_amount': amount,
        'type': 'topup',
        'status': 'success',
      });

      // 5. Write audit log
      await client.from('audit_logs').insert({
        'actor_id': actorId,
        'actor_name': actorName,
        'action_type': 'TOPUP_TUNAI',
        'description': 'Top-up tunai sukses sebesar Rp ${NumberFormat.decimalPattern("id_ID").format(amount)} untuk $_studentName',
        'target_id': studentId,
        'old_value': {'balance': currentBalance},
        'new_value': {'balance': newBalance},
      });

      // 6. Create notification for student
      await client.from('notifications').insert({
        'student_id': studentId,
        'title': 'Top-Up Saldo Sukses!',
        'message': 'Pengisian saldo saku sebesar Rp ${NumberFormat.decimalPattern("id_ID").format(amount)} via Kasir Tunai berhasil.',
        'type': 'topup',
      });

      // Invalidate providers to trigger update
      ref.invalidate(keuanganDashboardProvider);
      ref.invalidate(keuanganStudentsProvider);
      ref.invalidate(keuanganStudentDetailProvider(studentId));

      final now = DateTime.now();
      setState(() {
        _refCode = 'TXN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}';
        _successTime = DateFormat('dd MMM yyyy, HH:mm:ss').format(now);
        _currentStep = 4; // success screen
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up gagal: $e'),
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
  String get _studentNisn => _selectedStudent?['nisn'] ?? '-';
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
          'Top-Up Tunai',
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
                    ? 'LANGKAH 2 DARI 3 — Konfirmasi & Nominal'
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

  Widget _buildStep2Amount(NumberFormat fmt) {
    final double amount = _getAmount();
    final double newBalance = _studentBalance + amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Info Bento Card
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
              Row(
                children: [
                  const Icon(CupertinoIcons.checkmark_circle_fill, color: successGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Siswa Ditemukan',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: successGreen, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Nama', _studentName),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('NISN', _studentNisn),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Kelas', 'Kelas $_studentClass'),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Saat Ini', fmt.format(_studentBalance)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Nominal Top-Up (Uang Tunai Diterima)',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B), fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() {
              _selectedQuickAmount = null;
            });
          },
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
        const SizedBox(height: 16),

        // Quick select chips
        Text(
          'Pilih Cepat:',
          style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6F7978)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [20000, 50000, 100000, 150000, 200000, 500000].map((val) {
            final isSelected = _selectedQuickAmount == val;
            return ChoiceChip(
              label: Text(
                fmt.format(val).replaceAll('Rp ', ''),
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : primaryTeal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onQuickAmountSelected(val);
              },
              selectedColor: primaryTeal,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: primaryTeal.withValues(alpha: 0.15)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Saldo Baru (Preview): ${fmt.format(newBalance)}',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTeal),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: amount <= 0 || amount % 1000 != 0
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
    final double newBalance = _studentBalance + amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Bento Card
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
                '📋 RINGKASAN TOP-UP TUNAI',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Nama Siswa', _studentName),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('NISN', _studentNisn),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Kelas', 'Kelas $_studentClass'),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Lama', fmt.format(_studentBalance)),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Nominal Top-Up', '+ ${fmt.format(amount)}', valueColor: successGreen),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Baru', fmt.format(newBalance), isBold: true, valueColor: primaryTeal),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Metode', 'Tunai (Cash)'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processTopup,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Text(
                    '✔ PROSES TOP-UP',
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
            'Aksi ini akan dicatat dalam audit log.',
            style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6F7978)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(NumberFormat fmt) {
    final double amount = _getAmount();
    final double newBalance = _studentBalance + amount;

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
            color: Color(0xFFEAF9EE),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              color: successGreen,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Top-Up Berhasil!',
          style: GoogleFonts.beVietnamPro(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saldo $_studentName berhasil ditambah.',
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
              _buildInfoRow('Nominal Pengisian', fmt.format(amount), valueColor: successGreen, isBold: true),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Saldo Baru', fmt.format(newBalance), isBold: true),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Waktu Transaksi', _successTime),
              const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
              _buildInfoRow('Kode Referensi', _refCode),
            ],
          ),
        ),

        const SizedBox(height: 40),
        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulasi Cetak Struk: Struk dikirim ke printer thermal.'),
                  backgroundColor: successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(CupertinoIcons.printer_fill, size: 18),
            label: Text(
              'CETAK STRUK / BAGIKAN',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryTeal,
              side: const BorderSide(color: primaryTeal),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
