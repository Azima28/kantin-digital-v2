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

class ParentTopUpScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ParentTopUpScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentTopUpScreen> createState() => _ParentTopUpScreenState();
}

class _ParentTopUpScreenState extends ConsumerState<ParentTopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customAmountController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();

  int? _selectedQuickAmount = 50000; // default 50k
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

  Future<void> _handlePaymentSimulation(double amount) async {
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
        'message': 'Pengisian saldo saku sebesar ${CurrencyFormatter.format(amount)} via QRIS berhasil.',
        'type': 'topup',
      });

      // Invalidate dashboard provider so that it updates
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet modal
        context.push('/parent/receipt', extra: {
          'orderId': 'PR-${Random().nextInt(899999) + 100000}',
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
        Navigator.pop(context); // Close bottom sheet
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

  void _showCheckoutSheet() {
    if (!_formKey.currentState!.validate()) return;

    final double amount = _getFinalAmount();
    if (amount < 10000) {
      setState(() {
        _errorMessage = 'Minimal nominal isi saldo adalah Rp 10.000';
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // iOS grab handle
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Simulasi Pembayaran Midtrans Snap',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(CupertinoIcons.shield_fill, color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Secure Checkout by Midtrans',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment methods list mockup
                  _buildPaymentMockupItem('QRIS (Dana, Gopay, OVO)', CupertinoIcons.qrcode),
                  _buildPaymentMockupItem('Virtual Account Bank (BCA, Mandiri)', CupertinoIcons.building_2_fill),
                  _buildPaymentMockupItem('Kartu Kredit / Debit', CupertinoIcons.creditcard_fill),
                  
                  const SizedBox(height: 28),
                  
                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setSheetState(() {});
                              await _handlePaymentSimulation(amount);
                            },
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text(
                              'SIMULASIKAN PEMBAYARAN SUKSES',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Batalkan',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
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

  Widget _buildPaymentMockupItem(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
          const Spacer(),
          const Icon(CupertinoIcons.circle, color: AppColors.textGray, size: 16),
        ],
      ),
    );
  }

  Widget _buildQuickAmountItem(int amount, String label, String displayPrice) {
    final bool isSelected = _selectedQuickAmount == amount;
    return GestureDetector(
      onTap: () => _onQuickAmountSelected(amount),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5EA),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayPrice,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFBDC9C8).withValues(alpha: 0.3), width: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Top-up Saldo Online',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receiver Student Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.arrow_down_circle_fill, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Siswa Penerima:', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                              const SizedBox(height: 2),
                              Text('$_studentName (Kelas $_studentClass)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Pilih Nominal Top-Up:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  // Grid Choice
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      _buildQuickAmountItem(20000, '20k', 'Rp 20.000'),
                      _buildQuickAmountItem(50000, '50k', 'Rp 50.000'),
                      _buildQuickAmountItem(100000, '100k', 'Rp 100.000'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Custom Input Text Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Atau Kustom: Rp ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _customAmountController,
                            keyboardType: TextInputType.number,
                            onChanged: _onCustomAmountChanged,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'e.g. 150000',
                              hintStyle: TextStyle(color: Color(0xFFBDC9C8), fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Data Pengirim (Orang Tua):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  // Sender Name & Phone
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _senderNameController,
                          keyboardType: TextInputType.name,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap Pengirim',
                            labelStyle: TextStyle(color: AppColors.textGray, fontSize: 13),
                            hintText: 'e.g. Budi Subarjo',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama pengirim wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 1, color: AppColors.borderLight),
                        TextFormField(
                          controller: _senderPhoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp / HP',
                            labelStyle: TextStyle(color: AppColors.textGray, fontSize: 13),
                            hintText: 'e.g. 08123456789',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nomor WhatsApp wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: _showCheckoutSheet,
                      child: const Text(
                        'BAYAR SEKARANG VIA MIDTRANS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
