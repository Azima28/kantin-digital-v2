import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/qris_checkout_content.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_quick_amount_item.dart';
import 'package:kantin_digital/features/siswa/widgets/topup_payment_info_card.dart';
import 'package:google_fonts/google_fonts.dart';

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

      // Get operator ID from auth context or fetch first available operator
      final authProfile = authState.profile;
      String operatorId = authProfile?['operator_id'] ?? '';

      if (operatorId.isEmpty) {
        final operators = await client.from('canteen_operators').select('id').limit(1);
        if (operators.isEmpty) {
          throw Exception('Tidak ada operator kantin terdaftar untuk mencatat transaksi top-up.');
        }
        operatorId = operators.first['id'];
      }

      // Replace direct update with RPC
      await client.rpc('process_topup', params: {
        'p_student_id': studentId,
        'p_amount': amount,
        'p_operator_id': operatorId,
        'p_method': 'simulasi',
        'p_notes': 'Top-up mandiri siswa',
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
            content: const Text('Top-up gagal'),
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
      backgroundColor: AppColors.white,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: QrisCheckoutContent(
            amount: amount,
            isLoading: _isLoading,
            onConfirm: _isLoading
                ? null
                : () async {
                    await _handlePaymentSimulation(amount);
                  },
            onCancel: () => Navigator.pop(context),
          ),
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick nominal title
                const Text(
                  '${AppStrings.buttonSelect} Nominal Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Grid nominal
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 3.0 : 2.2,
                  children: [
                    SiswaQuickAmountItem(
                      amount: 10000,
                      label: '10k',
                      description: 'Rp 10.000',
                      isSelected: _selectedQuickAmount == 10000,
                      onTap: () => _onQuickAmountSelected(10000),
                    ),
                    SiswaQuickAmountItem(
                      amount: 20000,
                      label: '20k',
                      description: 'Rp 20.000',
                      isSelected: _selectedQuickAmount == 20000,
                      onTap: () => _onQuickAmountSelected(20000),
                    ),
                    SiswaQuickAmountItem(
                      amount: 50000,
                      label: '50k',
                      description: 'Rp 50.000',
                      isSelected: _selectedQuickAmount == 50000,
                      onTap: () => _onQuickAmountSelected(50000),
                    ),
                    SiswaQuickAmountItem(
                      amount: 100000,
                      label: '100k',
                      description: 'Rp 100.000',
                      isSelected: _selectedQuickAmount == 100000,
                      onTap: () => _onQuickAmountSelected(100000),
                    ),
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

                const TopupPaymentInfoCard(),
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
                        Text('LANJUTKAN PEMBAYARAN', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(CupertinoIcons.arrow_right, color: AppColors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
     ),
    );
  }

}
