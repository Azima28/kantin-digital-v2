import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/parent/widgets/parent_amount_selector.dart';
import 'package:kantin_digital/features/parent/widgets/parent_midtrans_payment_modal.dart';
import 'package:kantin_digital/features/parent/providers/parent_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

class ParentTopUpForm extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final String studentClass;

  const ParentTopUpForm({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
  });

  @override
  ConsumerState<ParentTopUpForm> createState() => _ParentTopUpFormState();
}

class _ParentTopUpFormState extends ConsumerState<ParentTopUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _customAmountController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();

  int? _selectedQuickAmount = 100000;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
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

  Future<void> _handlePaymentSimulation(double amount, String method) async {
    setState(() {
      _isLoading = true;
    });

    final senderName = _senderNameController.text.trim();
    final senderPhone = _senderPhoneController.text.trim();

    try {
      final client = ref.read(supabaseClientProvider);

      final sessionToken = ref.read(authNotifierProvider).sessionToken;

      if (sessionToken == null || sessionToken.isEmpty) {
        throw Exception('Sesi tidak valid. Silakan keluar dan masuk kembali.');
      }

      // Use RPC for atomic topup
      await client.rpc('process_topup', params: {
        'p_student_id': widget.studentId,
        'p_amount': amount,
        'p_session_token': sessionToken,
        'p_method': 'transfer',
        'p_notes': 'Top-up oleh orang tua',
      });

      // Re-fetch student to get updated balance for receipt
      final updatedStudent = await client
          .from('students')
          .select('balance')
          .eq('id', widget.studentId)
          .maybeSingle();
      final int newBalance = (updatedStudent?['balance'] as num?)?.toInt() ?? 0;

      // Invalidate dashboard provider so that it updates
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(parentDashboardProvider(widget.studentId));
      ref.invalidate(userNotificationsProvider);

      if (mounted) {
        Navigator.pop(context); // Close the Midtrans snap modal
        context.push('/parent/receipt', extra: {
          'orderId': 'PR-${Random().nextInt(899999999) + 100000000}',
          'date': DateTime.now().toIso8601String(),
          'senderName': senderName,
          'senderPhone': senderPhone,
          'studentName': widget.studentName,
          'amount': amount,
          'newBalance': newBalance,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet/modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Top-up gagal'),
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

  Future<void> _showMidtransSnapModal() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = _getFinalAmount();
    if (amount < 10000) {
      setState(() {
        _errorMessage = 'Minimal nominal isi saldo adalah Rp 10.000';
      });
      return;
    }

    await showParentMidtransPaymentModal(
      context: context,
      ref: ref,
      amount: amount,
      senderPhone: _senderPhoneController.text,
      studentId: widget.studentId,
      studentName: widget.studentName,
      isLoading: _isLoading,
      onPay: _handlePaymentSimulation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page title & subtitle
          Text(
            'Formulir Top-up Saldo Online',
            style: GoogleFonts.inter(
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
                '${widget.studentName} (Kelas ${widget.studentClass})',
                style: GoogleFonts.inter(
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
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray, width: 1),
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
                Container(height: 4, color: AppColors.accentOrange),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Nominal Choices
                      Text(
                        '${AppStrings.buttonSelect} Nominal Top-up',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ParentAmountSelector(
                        selectedAmount: _selectedQuickAmount,
                        onAmountSelected: _onQuickAmountSelected,
                        screenWidth: screenWidth,
                      ),
                      const SizedBox(height: 16),

                      // Custom input box
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atau Kustom (Minimal Rp 10.000)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGray, width: 1),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Rp ',
                                  style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: GoogleFonts.inter(color: AppColors.textGray.withValues(alpha: 0.5)),
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
                      const Divider(color: AppColors.borderGray, height: 1),
                      const SizedBox(height: 24),

                      // Section 2: Sender Details
                      Text(
                        '${AppStrings.titleDetail} Pengirim',
                        style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGray, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.profile_circled, color: AppColors.textGray, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _senderNameController,
                                    keyboardType: TextInputType.name,
                                    style: GoogleFonts.inter(fontSize: 14),
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
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGray, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.phone, color: AppColors.textGray, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _senderPhoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.inter(fontSize: 14),
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
                            style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: _showMidtransSnapModal,
                        icon: const Icon(CupertinoIcons.creditcard, color: AppColors.white, size: 16),
                        label: Text(
                          'BAYAR SEKARANG VIA MIDTRANS',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
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
                            style: GoogleFonts.inter(
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
              icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary, size: 14),
              label: Text(
                'Kembali Pantau Anak',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
