import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/parent/widgets/parent_amount_selector.dart';
import 'package:kantin_digital/features/siswa/widgets/qris_checkout_content.dart';
import 'package:kantin_digital/features/parent/providers/parent_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

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

  int? _selectedQuickAmount = 100000;
  String? _errorMessage;
  bool _isLoading = false;

  static const int minTopup = 10000;
  static const int maxTopup = 2000000;

  @override
  void initState() {
    super.initState();
    _customAmountController.text = CurrencyFormatter.formatWithoutPrefix(100000);
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _customAmountController.text = CurrencyFormatter.formatWithoutPrefix(amount);
      _errorMessage = null;
    });
  }

  void _onCustomAmountChanged(String val) {
    final cleanDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      setState(() {
        _selectedQuickAmount = null;
        _errorMessage = null;
      });
      return;
    }

    final int parsed = int.tryParse(cleanDigits) ?? 0;
    String? error;
    if (parsed > maxTopup) {
      error = 'Maksimal top-up Rp 2.000.000 per transaksi';
    } else if (parsed > 0 && parsed < minTopup) {
      error = 'Minimal top-up Rp 10.000';
    }

    setState(() {
      if ([20000, 50000, 100000, 200000].contains(parsed)) {
        _selectedQuickAmount = parsed;
      } else {
        _selectedQuickAmount = null;
      }
      _errorMessage = error;
    });
  }

  double _getFinalAmount() {
    final clean = CurrencyFormatter.parseClean(_customAmountController.text);
    if (clean > 0) {
      return clean.toDouble();
    }
    if (_selectedQuickAmount != null) {
      return _selectedQuickAmount!.toDouble();
    }
    return 0;
  }

  Future<void> _handlePaymentSimulation(double amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.post('/parent/topup', body: {
        'student_id': widget.studentId,
        'amount': amount.toInt(),
        'payment_method': 'qris',
      });

      if (!response.success) {
        throw Exception(response.message ?? 'Top-up gagal');
      }

      // Invalidate dashboard provider so that balance & transactions update immediately
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(parentDashboardProvider(widget.studentId));
      ref.invalidate(userNotificationsProvider);

      if (mounted) {
        Navigator.pop(context); // Close the QRIS bottom sheet
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet/modal
        final String msg = e.toString().replaceFirst('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up gagal: $msg'),
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

  void _showQrisModal() {
    if (!_formKey.currentState!.validate()) return;

    final double amount = _getFinalAmount();
    if (amount < minTopup) {
      setState(() {
        _errorMessage = 'Minimal nominal isi saldo adalah Rp 10.000';
      });
      return;
    }
    if (amount > maxTopup) {
      setState(() {
        _errorMessage = 'Maksimal nominal isi saldo adalah Rp 2.000.000 per transaksi';
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: context.cardBg,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
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
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(CupertinoIcons.person_fill, size: 14, color: context.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${widget.studentName} (Kelas ${widget.studentClass})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form card
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.dividerCol, width: 1),
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
                Container(height: 4, color: Nebula.amber),

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
                          color: context.textPrimary,
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
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorMessage != null
                                    ? Nebula.rose
                                    : (_customAmountController.text.isNotEmpty
                                        ? Nebula.teal
                                        : context.dividerCol),
                                width: _errorMessage != null ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.25), width: 0.8),
                                  ),
                                  child: Text(
                                    'Rp',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _customAmountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      const ThousandsSeparatorInputFormatter(maxAmount: maxTopup),
                                    ],
                                    onChanged: _onCustomAmountChanged,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _errorMessage != null ? Nebula.rose : context.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: GoogleFonts.inter(color: context.textSecondary.withValues(alpha: 0.5)),
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _errorMessage != null
                                    ? CupertinoIcons.exclamationmark_circle_fill
                                    : CupertinoIcons.info_circle_fill,
                                size: 13,
                                color: _errorMessage != null ? Nebula.rose : context.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _errorMessage ?? 'Minimal Rp 10.000 • Maksimal Rp 2.000.000 per transaksi',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _errorMessage != null ? Nebula.rose : context.textSecondary,
                                    fontWeight: _errorMessage != null ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            color: Nebula.rose,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Pay button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: _showQrisModal,
                        icon: Icon(CupertinoIcons.qrcode, color: context.cardBg, size: 18),
                        label: Text(
                          'BAYAR SEKARANG VIA QRIS',
                          style: GoogleFonts.inter(
                            color: context.cardBg,
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
                          Icon(CupertinoIcons.lock_fill, color: context.textSecondary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Pembayaran aman dan terenkripsi',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textSecondary,
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
              icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal, size: 14),
              label: Text(
                'Kembali Pantau Anak',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Nebula.teal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 1400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: AnimatedSuccessSheet(
            amount: amount,
            studentName: widget.studentName,
            entranceAnimation: animation,
            onClose: () {
              Navigator.pop(context); // Close dialog
              context.go('/parent/dashboard/${widget.studentId}'); // Go back to parent dashboard
            },
          ),
        );
      },
    );
  }
}

class AnimatedSuccessSheet extends StatefulWidget {
  final double amount;
  final String studentName;
  final Animation<double> entranceAnimation;
  final VoidCallback onClose;

  const AnimatedSuccessSheet({
    super.key,
    required this.amount,
    required this.studentName,
    required this.entranceAnimation,
    required this.onClose,
  });

  @override
  State<AnimatedSuccessSheet> createState() => _AnimatedSuccessSheetState();
}

class _AnimatedSuccessSheetState extends State<AnimatedSuccessSheet> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _internalRiseAnimation;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.entranceAnimation,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: widget.entranceAnimation,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.entranceAnimation,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _internalRiseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.entranceAnimation,
        curve: const Interval(0.4, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.entranceAnimation,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = CurrencyFormatter.format(widget.amount.toInt());
    final now = DateTime.now();
    final formattedDate = AppDateFormatter.formatDateWithTime(now);

    return AnimatedBuilder(
      animation: Listenable.merge([widget.entranceAnimation, _waveController]),
      builder: (context, child) {
        return ClipPath(
          clipper: WaveTopClipper(
            wavePhase: _waveController.value * 2 * math.pi,
            progress: widget.entranceAnimation.value,
          ),
          child: child,
        );
      },
      child: Container(
        color: context.cardBg,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back Button on Top Left
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.arrow_left),
                    color: context.textPrimary,
                    iconSize: 22,
                    onPressed: widget.onClose,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Nebula.teal.withValues(alpha: 0.3),
                                  width: 4,
                                ),
                                color: Nebula.teal.withValues(alpha: 0.05),
                              ),
                              child: ClipOval(
                                child: Stack(
                                  children: [
                                    AnimatedBuilder(
                                      animation: Listenable.merge([widget.entranceAnimation, _waveController]),
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: const Size(100, 100),
                                          painter: WavePainter(
                                            riseValue: _internalRiseAnimation.value,
                                            wavePhase: _waveController.value * 2 * math.pi,
                                            waveColor: Nebula.teal,
                                          ),
                                        );
                                      },
                                    ),
                                    Center(
                                      child: AnimatedBuilder(
                                        animation: _checkmarkAnimation,
                                        builder: (context, child) {
                                          return CustomPaint(
                                            size: const Size(54, 54),
                                            painter: CheckmarkPainter(
                                              progress: _checkmarkAnimation.value,
                                              color: context.cardBg,
                                              strokeWidth: 4.5,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: widget.entranceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Text(
                                  'Top-Up Berhasil!',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Saldo $formattedAmount telah berhasil ditambahkan ke akun ${widget.studentName}.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.dividerCol, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'NOMINAL TOP-UP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: context.textSecondary,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formattedAmount,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Nebula.teal,
                                        ),
                                      ),
                                      Divider(height: 24, color: context.dividerCol),
                                      _buildDetailRow('Penerima', widget.studentName),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Metode Pembayaran', 'Simulasi Instan (QRIS)'),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Waktu Transaksi', formattedDate),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Status', 'Berhasil', isStatus: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Nebula.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              onPressed: widget.onClose,
                              child: Text(
                                'Selesai',
                                style: TextStyle(
                                  color: context.cardBg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Nebula.teal,
              ),
            ),
          )
        else
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double riseValue; // 0.0 to 1.0
  final double wavePhase; // 0.0 to 2*pi
  final Color waveColor;

  WavePainter({
    required this.riseValue,
    required this.wavePhase,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Calculate the height of the liquid level.
    // riseValue = 0 means empty (bottom of circle, y = size.height)
    // riseValue = 1 means full (top of circle, y = 0)
    final double level = size.height * (1.0 - riseValue);
    
    // Wave parameters
    final double amplitude = riseValue > 0.0 && riseValue < 1.0 ? 6.0 : 0.0; // wave flattens when empty or full
    final double wavelength = size.width;

    path.moveTo(0, size.height);
    path.lineTo(0, level);

    // Draw the wave across the width
    for (double x = 0; x <= size.width; x++) {
      final double y = level + amplitude * math.sin((2 * math.pi * x / wavelength) + wavePhase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.riseValue != riseValue || oldDelegate.wavePhase != wavePhase;
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Define the checkmark points relative to size
    final start = Offset(size.width * 0.27, size.height * 0.5);
    final mid = Offset(size.width * 0.45, size.height * 0.66);
    final end = Offset(size.width * 0.73, size.height * 0.35);

    // Draw checkmark progressively based on progress
    if (progress < 0.4) {
      // First segment (start to mid)
      final currentProgress = progress / 0.4;
      final currentOffset = Offset(
        start.dx + (mid.dx - start.dx) * currentProgress,
        start.dy + (mid.dy - start.dy) * currentProgress,
      );
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentOffset.dx, currentOffset.dy);
    } else {
      // First segment is complete
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);
      
      // Second segment (mid to end)
      final currentProgress = (progress - 0.4) / 0.6;
      final currentOffset = Offset(
        mid.dx + (end.dx - mid.dx) * currentProgress,
        mid.dy + (end.dy - mid.dy) * currentProgress,
      );
      path.lineTo(currentOffset.dx, currentOffset.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class WaveTopClipper extends CustomClipper<Path> {
  final double wavePhase;
  final double progress; // 0.0 to 1.0

  WaveTopClipper({
    required this.wavePhase,
    required this.progress,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // When progress reaches 1.0 (settled), clip nothing (full rectangle) so top is 100% full & flat
    if (progress >= 1.0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // Dynamic wave amplitude that gently tapers to 0 as progress approaches 1.0
    final double waveAmplitude = 18.0 * (1.0 - progress);
    const double d = 0.25;

    path.moveTo(0, size.height);

    // Generate path points with localized rising delay
    for (double x = 0; x <= size.width; x++) {
      final double txProgress = (x / size.width) * d;
      final double tx = ((progress - txProgress) / (1.0 - d)).clamp(0.0, 1.0);

      final double baselineY = size.height * (1.0 - tx);
      final double waveOscillation = waveAmplitude * math.sin((2 * math.pi * x / (size.width * 0.8)) - wavePhase);

      double y = (baselineY + waveOscillation).clamp(0.0, size.height);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveTopClipper oldClipper) {
    return oldClipper.wavePhase != wavePhase || oldClipper.progress != progress;
  }
}
