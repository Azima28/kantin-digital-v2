import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/parent/screens/parent_dashboard_screen.dart';

class ParentTopUpScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ParentTopUpScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentTopUpScreen> createState() => _ParentTopUpScreenState();
}

class _ParentTopUpScreenState extends ConsumerState<ParentTopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customAmountController = TextEditingController();
  final _senderNameController = TextEditingController(text: 'Budi Subarjo');
  final _senderPhoneController = TextEditingController(text: '08123456789');

  int? _selectedQuickAmount = 100000; // default 100k
  String? _errorMessage;
  bool _isLoading = false;
  String _studentName = 'Siswa';
  String _studentClass = '';

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Fetch profile
      final profile = await client.from('profiles').select('full_name').eq('id', widget.studentId).single();
      // Fetch student
      final student = await client.from('students').select('class').eq('id', widget.studentId).single();
      
      setState(() {
        _studentName = profile['full_name'] ?? 'Siswa';
        _studentClass = student['class'] ?? '';
      });
    } catch (_) {
      // Keep defaults
    }
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _customAmountController.clear();
      _errorMessage = null;
    });
  }

  void _onCustomAmountChanged(String val) {
    if (val.isNotEmpty) {
      setState(() {
        _selectedQuickAmount = null;
        _errorMessage = null;
      });
    }
  }

  double _getFinalAmount() {
    if (_selectedQuickAmount != null) {
      return _selectedQuickAmount!.toDouble();
    }
    return double.tryParse(_customAmountController.text) ?? 0.0;
  }

  Future<void> _handlePaymentSimulation(double amount, String method) async {
    setState(() {
      _isLoading = true;
    });

    final senderName = _senderNameController.text.trim();
    final senderPhone = _senderPhoneController.text.trim();

    try {
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch current student details
      final student = await client
          .from('students')
          .select('balance')
          .eq('id', widget.studentId)
          .single();

      final double currentBalance = double.tryParse(student['balance'].toString()) ?? 0.0;
      final double newBalance = currentBalance + amount;

      // 2. Fetch a default operator ID to associate with the transaction
      final operators = await client.from('canteen_operators').select('id').limit(1);
      if (operators.isEmpty) {
        throw Exception('Tidak ada stan kantin terdaftar untuk mencatat transaksi topup.');
      }
      final String operatorId = operators.first['id'];

      // 3. Update student balance in DB
      await client
          .from('students')
          .update({'balance': newBalance})
          .eq('id', widget.studentId);

      // 4. Record transaction
      await client.from('transactions').insert({
        'student_id': widget.studentId,
        'operator_id': operatorId,
        'total_amount': amount,
        'type': 'topup',
        'status': 'success',
      });

      // 5. Create notification for student
      await client.from('notifications').insert({
        'student_id': widget.studentId,
        'title': 'Top-Up Saldo Sukses!',
        'message': 'Pengisian saldo saku sebesar ${CurrencyFormatter.format(amount)} via $method berhasil.',
        'type': 'topup',
      });

      // Invalidate dashboard provider so that it updates
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(parentDashboardProvider(widget.studentId));

      if (mounted) {
        Navigator.pop(context); // Close the Midtrans snap modal
        context.push('/parent/receipt', extra: {
          'orderId': 'PR-${Random().nextInt(899999999) + 100000000}',
          'date': DateTime.now().toIso8601String(),
          'senderName': senderName,
          'senderPhone': senderPhone,
          'studentName': _studentName,
          'amount': amount,
          'newBalance': newBalance,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet/modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up gagal: $e'),
            backgroundColor: AppColors.error,
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

  void _showMidtransSnapModal() {
    if (!_formKey.currentState!.validate()) return;

    final double amount = _getFinalAmount();
    if (amount < 10000) {
      setState(() {
        _errorMessage = 'Minimal nominal isi saldo adalah Rp 10.000';
      });
      return;
    }

    final String orderId = 'KD-${Random().nextInt(899999) + 100000}';
    String selectedMethod = 'QRIS'; // Default choice
    bool showInstructions = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            // Method details map helper
            final Map<String, dynamic> methodDetails = {
              'QRIS': {
                'title': 'QRIS',
                'icon': CupertinoIcons.qrcode,
                'subtext': 'Gopay, ShopeePay, Dana',
              },
              'BCA VA': {
                'title': 'BCA Virtual Account',
                'icon': Icons.account_balance,
                'subtext': 'Transfer dari BCA',
              },
              'Mandiri VA': {
                'title': 'Mandiri Virtual Account',
                'icon': Icons.account_balance,
                'subtext': 'Transfer dari Livin\'',
              },
              'Alfamart': {
                'title': 'Alfamart / Indomaret',
                'icon': Icons.storefront,
                'subtext': 'Bayar di kasir',
              },
            };

            Widget buildMethodRadio(String key, String title, String subtext, IconData icon) {
              final isSelected = selectedMethod == key;
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    selectedMethod = key;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x0D006767) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF006767) : const Color(0xFFE4E2E1),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: const Color(0xFF006767), size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtext,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF006767) : AppColors.textGray,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF006767),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }

            final double modalWidth = MediaQuery.of(context).size.width;
            final bool isModalMobile = modalWidth < 600;

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: isModalMobile ? const EdgeInsets.all(12) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isModalMobile ? 16 : 24),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: isModalMobile 
                      ? MediaQuery.of(context).size.height * 0.9 
                      : MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3F2),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(isModalMobile ? 16 : 24)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.shield_fill, color: Color(0xFF006767), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'MIDTRANS SNAP',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.xmark, color: AppColors.textGray, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: showInstructions
                            // Step 2: Pay details & simulation trigger
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Text(
                                      'Simulasi Pembayaran Anda',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Selected method indicator
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBF9F8),
                                      border: Border.all(color: const Color(0xFFE4E2E1)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(methodDetails[selectedMethod]['icon'], color: const Color(0xFF006767)),
                                        const SizedBox(width: 12),
                                        Text(
                                          methodDetails[selectedMethod]['title'],
                                          style: GoogleFonts.beVietnamPro(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          CurrencyFormatter.format(amount),
                                          style: GoogleFonts.beVietnamPro(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF006767),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  if (selectedMethod == 'QRIS') ...[
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFE4E2E1)),
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.white,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.qrcode,
                                          size: 160,
                                          color: Color(0xFF1B1C1C),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Silakan scan QR code di atas menggunakan Gopay, ShopeePay, OVO, Dana atau aplikasi pembayaran QRIS lainnya.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ] else if (selectedMethod.contains('VA')) ...[
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFBF9F8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE4E2E1)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Nomor Virtual Account',
                                            style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '8910${_senderPhoneController.text.padRight(10, '0').substring(0, 10)}',
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                  color: const Color(0xFF006767),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(CupertinoIcons.doc_on_doc, color: Color(0xFF006767), size: 16),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Lakukan transfer total tagihan ke nomor Virtual Account di atas melalui M-Banking atau ATM.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFBF9F8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE4E2E1)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Kode Pembayaran Kasir',
                                            style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'KD-${Random().nextInt(89999) + 10000}',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF006767),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Berikan kode pembayaran di atas ke kasir Alfamart atau Indomaret terdekat untuk menyelesaikan top-up.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 32),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9500),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            setModalState(() {});
                                            await _handlePaymentSimulation(amount, methodDetails[selectedMethod]['title']);
                                          },
                                    child: _isLoading
                                        ? const CupertinoActivityIndicator(color: Colors.white)
                                        : Text(
                                            'SIMULASIKAN PEMBAYARAN SUKSES',
                                            style: GoogleFonts.beVietnamPro(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        showInstructions = false;
                                      });
                                    },
                                    child: Text(
                                      'Ganti Metode Pembayaran',
                                      style: GoogleFonts.beVietnamPro(
                                        color: const Color(0xFF006767),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            // Step 1: Bill & Method Choice list
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Total bill box
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBF9F8),
                                      border: Border.all(color: const Color(0xFFE4E2E1)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Total Tagihan',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          CurrencyFormatter.format(amount),
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF006767),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Order ID: $orderId',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Text(
                                    'Pilih Metode Pembayaran',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  buildMethodRadio('QRIS', 'QRIS', 'Gopay, ShopeePay, Dana', CupertinoIcons.qrcode_viewfinder),
                                  buildMethodRadio('BCA VA', 'BCA Virtual Account', 'Transfer dari BCA', Icons.account_balance),
                                  buildMethodRadio('Mandiri VA', 'Mandiri Virtual Account', 'Transfer dari Livin\'', Icons.account_balance),
                                  buildMethodRadio('Alfamart', 'Alfamart / Indomaret', 'Bayar di kasir', Icons.storefront),
                                ],
                              ),
                      ),
                    ),

                    // Footer
                    if (!showInstructions)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE4E2E1), width: 1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006767),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                setModalState(() {
                                    showInstructions = true;
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'LANJUTKAN PEMBAYARAN',
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.lock_fill, color: AppColors.textGray, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Pembayaran Aman via Midtrans',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAmountItem(int amount, String label) {
    final bool isSelected = _selectedQuickAmount == amount;
    return GestureDetector(
      onTap: () => _onQuickAmountSelected(amount),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8FF3F2).withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF006767) : const Color(0xFFE4E2E1),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF006767).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF006767) : AppColors.textDark,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006767),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const Color primaryTeal = Color(0xFF006767);
    const Color bgWarm = Color(0xFFFBF9F8);
    const Color borderOutline = Color(0xFFE4E2E1);

    return Scaffold(
      backgroundColor: bgWarm,
      body: Column(
        children: [
          // Header Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: borderOutline, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_left, color: primaryTeal, size: 22),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kantin Digital',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Page title & subtitle
                        Text(
                          'Formulir Top-up Saldo Online',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(CupertinoIcons.person_fill, size: 14, color: AppColors.textGray),
                            const SizedBox(width: 6),
                            Text(
                              '$_studentName (Kelas $_studentClass)',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderOutline, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Decorative orange bar
                              Container(height: 4, color: const Color(0xFFFF9500)),
                              
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Section 1: Nominal Choices
                                    Text(
                                      'Pilih Nominal Top-up',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: screenWidth < 480 ? 2 : 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: screenWidth < 480 ? 2.5 : 2.2,
                                      children: [
                                        _buildQuickAmountItem(10000, 'Rp 10.000'),
                                        _buildQuickAmountItem(20000, 'Rp 20.000'),
                                        _buildQuickAmountItem(50000, 'Rp 50.000'),
                                        _buildQuickAmountItem(100000, 'Rp 100.000'),
                                        _buildQuickAmountItem(200000, 'Rp 200.000'),
                                        _buildQuickAmountItem(500000, 'Rp 500.000'),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Custom input box
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Atau Kustom (Minimal Rp 10.000)',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: borderOutline, width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Rp ',
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _customAmountController,
                                                  keyboardType: TextInputType.number,
                                                  onChanged: _onCustomAmountChanged,
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: '0',
                                                    hintStyle: GoogleFonts.beVietnamPro(color: AppColors.textGray.withValues(alpha: 0.5)),
                                                    border: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                                    filled: false,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: borderOutline, height: 1),
                                    const SizedBox(height: 24),

                                    // Section 2: Sender Details
                                    Text(
                                      'Detail Pengirim',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Sender Name Input
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nama Pengirim',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: borderOutline, width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(CupertinoIcons.profile_circled, color: AppColors.textGray, size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _senderNameController,
                                                  keyboardType: TextInputType.name,
                                                  style: GoogleFonts.beVietnamPro(fontSize: 14),
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                                    filled: false,
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.trim().isEmpty) {
                                                      return 'Nama pengirim wajib diisi';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Sender Phone Input
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nomor WA/HP',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: borderOutline, width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(CupertinoIcons.phone, color: AppColors.textGray, size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _senderPhoneController,
                                                  keyboardType: TextInputType.phone,
                                                  style: GoogleFonts.beVietnamPro(fontSize: 14),
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                                    filled: false,
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.trim().isEmpty) {
                                                      return 'Nomor WA/HP wajib diisi';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Nota tagihan akan dikirimkan ke nomor ini.',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 11,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    if (_errorMessage != null) ...[
                                      Text(
                                        _errorMessage!,
                                        style: GoogleFonts.beVietnamPro(
                                          color: AppColors.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Pay button
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(999), // pill shape per HTML button
                                        ),
                                      ),
                                      onPressed: _showMidtransSnapModal,
                                      icon: const Icon(CupertinoIcons.creditcard, color: Colors.white, size: 16),
                                      label: Text(
                                        'BAYAR SEKARANG VIA MIDTRANS',
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(CupertinoIcons.lock_fill, color: AppColors.textGray, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pembayaran aman dan terenkripsi',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Back link
                        Center(
                          child: TextButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(CupertinoIcons.left_chevron, color: primaryTeal, size: 14),
                            label: Text(
                              'Kembali Pantau Anak',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Minimal Footer
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F3F2),
              border: Border(top: BorderSide(color: borderOutline, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '© 2024 Kantin Digital. All rights reserved.',
                style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textGray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
