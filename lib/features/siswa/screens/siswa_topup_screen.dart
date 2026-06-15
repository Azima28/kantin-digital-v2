import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaTopUpScreen extends ConsumerStatefulWidget {
  const SiswaTopUpScreen({super.key});

  @override
  ConsumerState<SiswaTopUpScreen> createState() => _SiswaTopUpScreenState();
}

class _SiswaTopUpScreenState extends ConsumerState<SiswaTopUpScreen> {
  final TextEditingController _customAmountController = TextEditingController();
  int? _selectedQuickAmount = 20000; // default 20k
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
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

    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authNotifierProvider);
      final String? studentId = authState.profile?['id'];

      if (studentId == null) {
        throw Exception('Identitas siswa tidak ditemukan.');
      }

      // 1. Fetch current student details to calculate new balance
      final student = await client
          .from('students')
          .select('balance')
          .eq('id', studentId)
          .single();

      final double currentBalance = double.tryParse(student['balance'].toString()) ?? 0.0;
      final double newBalance = currentBalance + amount;

      // 2. Fetch a default operator ID to associate with the transaction
      final operators = await client.from('canteen_operators').select('id').limit(1);
      String operatorId = '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c'; // default fallback
      if (operators.isNotEmpty) {
        operatorId = operators.first['id'];
      }

      // 3. Update student balance in DB
      await client
          .from('students')
          .update({'balance': newBalance})
          .eq('id', studentId);

      // 4. Record the topup transaction
      await client.from('transactions').insert({
        'student_id': studentId,
        'operator_id': operatorId,
        'total_amount': amount,
        'type': 'topup',
        'status': 'success',
      });

      // 5. Send notification to the student inbox
      await client.from('notifications').insert({
        'student_id': studentId,
        'title': 'Top-Up Saldo Sukses!',
        'message': 'Pengisian saldo saku sebesar ${CurrencyFormatter.format(amount)} via QRIS berhasil.',
        'type': 'topup',
      });

      // Invalidate providers to reload UI data
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(siswaNotificationsProvider);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        _showSuccessDialog(amount);
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(double amount) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Top-Up Berhasil!'),
        content: Text('Selamat, saldo saku Anda telah bertambah sebesar ${CurrencyFormatter.format(amount)}.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Selesai'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to dashboard
            },
          ),
        ],
      ),
    );
  }

  void _showCheckoutSheet() {
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
                    'Simulasi QRIS Pembayaran',
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

                  // Simulated QR Code Graphic Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: Column(
                      children: [
                        // Draw a mock QR code layout using containers
                        Container(
                          width: 180,
                          height: 180,
                          color: const Color(0xFFF2F2F7),
                          child: Center(
                            child: Icon(
                              Icons.qr_code_2,
                              size: 130,
                              color: AppColors.textDark.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'KANTIN DIGITAL COOPERATIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pindai QRIS di atas menggunakan e-wallet atau Mobile Banking Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                              'Simulasikan Pembayaran Sukses',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          'Isi Saldo',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick nominal title
                const Text(
                  'Pilih Nominal Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Grid 2x2 nominal
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildQuickAmountItem(10000, '10k', 'Rp 10.000'),
                    _buildQuickAmountItem(20000, '20k', 'Rp 20.000'),
                    _buildQuickAmountItem(50000, '50k', 'Rp 50.000'),
                    _buildQuickAmountItem(100000, '100k', 'Rp 100.000'),
                  ],
                ),

                const SizedBox(height: 24),

                // Or divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.borderLight)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.borderLight)),
                  ],
                ),

                const SizedBox(height: 24),

                // Custom amount title
                const Text(
                  'Nominal Lainnya',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Custom text field input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _errorMessage != null ? AppColors.error : AppColors.borderLight,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            fillColor: Colors.transparent,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onCustomAmountChanged,
                        ),
                      ),
                      if (_customAmountController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textGray, size: 20),
                          onPressed: () {
                            setState(() {
                              _customAmountController.clear();
                              _errorMessage = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Minimal top-up Rp 10.000',
                  style: TextStyle(
                    fontSize: 11,
                    color: _errorMessage != null ? AppColors.error : AppColors.textGray,
                    fontWeight: _errorMessage != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 24),

                // Payment context info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.qrcode_viewfinder,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'QRIS / Virtual Account (Instan)',
                              style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mendukung pembayaran dari semua e-wallet (GoPay, OVO, Dana) dan mobile banking.',
                              style: TextStyle(fontSize: 11, color: AppColors.textGray, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // spacing for bottom bar
              ],
            ),
          ),

          // Bottom fixed button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.borderLight, width: 0.5)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _showCheckoutSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('LANJUTKAN PEMBAYARAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountItem(int amount, String label, String sub) {
    final bool isSelected = _selectedQuickAmount == amount;

    return GestureDetector(
      onTap: () => _onQuickAmountSelected(amount),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
