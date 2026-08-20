import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/qris_checkout_content.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_quick_amount_item.dart';
import 'package:kantin_digital/features/siswa/widgets/topup_payment_info_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

  static const int minTopup = 10000;
  static const int maxTopup = 2000000;

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
    final cleanDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      setState(() {
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
      _selectedQuickAmount = null;
      _errorMessage = error;
    });
  }

  double _getFinalAmount() {
    if (_selectedQuickAmount != null) {
      return _selectedQuickAmount!.toDouble();
    }
    return CurrencyFormatter.parseClean(_customAmountController.text).toDouble();
  }

  Future<void> _handlePaymentSimulation(double amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authNotifierProvider);
      final String? studentId = authState.profile?['id'];

      if (studentId == null) {
        throw Exception('Identitas siswa tidak ditemukan.');
      }

      final response = await apiClient.post('/finance/topup', body: {
        'student_id': studentId,
        'amount': amount.toInt(),
      });

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal memproses top-up');
      }

      // Invalidate providers to reload UI data
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(siswaNotificationsProvider);
      ref.invalidate(userNotificationsProvider);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        final String msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up gagal: $msg'),
            backgroundColor: Nebula.rose,
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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 1400), // Slow, premium feel
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: AnimatedSuccessSheet(
              amount: amount,
              entranceAnimation: animation,
              onClose: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
            ),
          ),
        );
      },
    );
  }

  void _showCheckoutSheet() {
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Isi Saldo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
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
                Text(
                  '${AppStrings.buttonSelect} Nominal Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Grid nominal
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final int columns = MediaQuery.of(context).size.width > 600 ? 4 : 2;
                    final double itemWidth = (width - (columns - 1) * 12) / columns;
                    const double itemHeight = 62.0;
                    final double ratio = itemWidth / itemHeight;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ratio,
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
                    );
                  },
                ),

                SizedBox(height: 24),

                // Or divider
                Row(
                  children: [
                    Expanded(child: Divider(color: context.borderLight)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.borderLight)),
                  ],
                ),

                const SizedBox(height: 24),

                const GradientLine(),

                // Custom amount title
                Text(
                  'Nominal Lainnya',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Custom text field input with permanent Rp badge and thousands separator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _errorMessage != null
                          ? Nebula.rose
                          : (_customAmountController.text.isNotEmpty
                              ? Nebula.teal
                              : context.dividerCol),
                      width: _errorMessage != null ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Nebula.teal.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Rp',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            const ThousandsSeparatorInputFormatter(maxAmount: maxTopup),
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _errorMessage != null ? Nebula.rose : context.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.grey),
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
                          icon: Icon(CupertinoIcons.clear_circled_solid, color: context.textSecondary, size: 20),
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
                Row(
                  children: [
                    Icon(
                      _errorMessage != null
                          ? CupertinoIcons.exclamationmark_circle_fill
                          : CupertinoIcons.info_circle_fill,
                      size: 13,
                      color: _errorMessage != null ? Nebula.rose : context.textSecondary,
                    ),
                    const SizedBox(width: 5),
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
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(top: BorderSide(color: context.borderLight, width: 0.5)),
              ),
              child: SafeArea(
                  child: PressScale(
                    onTap: _showCheckoutSheet,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _showCheckoutSheet,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LANJUTKAN PEMBAYARAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 16),
                          ],
                        ),
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

class AnimatedSuccessSheet extends StatefulWidget {
  final double amount;
  final Animation<double> entranceAnimation;
  final VoidCallback onClose;

  const AnimatedSuccessSheet({
    super.key,
    required this.amount,
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

    // Controller for horizontal wave oscillation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Faster, more active wave movement
    )..repeat();

    // Animations driven by the master entrance animation
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
    final formattedAmount = CurrencyFormatter.format(widget.amount);
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);

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
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          
          // Large animated liquid checkmark circle
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 110,
              height: 110,
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
                    // Rising wave inside circle
                    AnimatedBuilder(
                      animation: Listenable.merge([widget.entranceAnimation, _waveController]),
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(110, 110),
                          painter: WavePainter(
                            riseValue: _internalRiseAnimation.value,
                            wavePhase: _waveController.value * 2 * math.pi,
                            waveColor: Nebula.teal,
                          ),
                        );
                      },
                    ),
                    // Drawing checkmark
                    Center(
                      child: AnimatedBuilder(
                        animation: _checkmarkAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(60, 60),
                            painter: CheckmarkPainter(
                              progress: _checkmarkAnimation.value,
                              color: context.cardBg,
                              strokeWidth: 5.0,
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
          
          const SizedBox(height: 24),
          
          // Success Title & Details (sliding up slightly)
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
                  'Saldo saku Anda telah berhasil bertambah.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Detail card with premium styling (glassmorphism/flat blend)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.5),
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
                      Divider(height: 24, color: context.borderLight),
                      _buildDetailRow('Metode Pembayaran', 'Simulasi Instan (QRIS)'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Waktu Transaksi', formattedDate),
                      const SizedBox(height: 8),
                      _buildDetailRow('Status', 'Sukses', isStatus: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Done button
          PressScale(
            onTap: widget.onClose,
            child: SizedBox(
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
          ),
        ],
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
            child: const Text(
              'Sukses',
              style: TextStyle(
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
    const double waveHeight = 20.0; // Slightly more height space for pronounced wave
    const double waveAmplitude = 14.0; // Highly visible wave depth
    
    // Tsunami entry delay (left side rises first, right follows)
    const double d = 0.25; 
    
    path.moveTo(0, size.height);

    // Generate path points with localized delay
    for (double x = 0; x <= size.width; x++) {
      // Delay is proportional to x position (left to right)
      final double txProgress = (x / size.width) * d;
      final double tx = ((progress - txProgress) / (1.0 - d)).clamp(0.0, 1.0);
      
      // Calculate the rising baseline for this point
      final double baselineY = size.height - (size.height - waveHeight) * tx;
      
      // Add the active wave oscillation directly (always active)
      final double waveOscillation = waveAmplitude * math.sin((2 * math.pi * x / (size.width * 0.8)) - wavePhase);
      
      // Clamp to size.height to avoid drawing below the sheet's canvas bounds
      double y = baselineY + waveOscillation;
      if (y > size.height) {
        y = size.height;
      }
      
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
