import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class QrisCheckoutContent extends StatefulWidget {
  final double amount;
  final bool isLoading;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;

  const QrisCheckoutContent({
    super.key,
    required this.amount,
    required this.isLoading,
    this.onConfirm,
    required this.onCancel,
  });

  @override
  State<QrisCheckoutContent> createState() => _QrisCheckoutContentState();
}

class _QrisCheckoutContentState extends State<QrisCheckoutContent> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_pinController.text.trim().isEmpty) {
      setState(() {
        _pinError = 'Silakan masukkan sandi / PIN atau gunakan tombol Simulasi Sandi';
      });
      return;
    }
    widget.onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.format(widget.amount),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Nebula.teal,
          ),
        ),
        const SizedBox(height: 16),

        // Simulated QR Code Graphic Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderLight, width: 1),
          ),
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                color: context.surfaceBg,
                child: Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 110,
                    color: context.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'KANTIN DIGITAL COOPERATIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pindai QRIS di atas menggunakan e-wallet atau Mobile Banking Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            color: context.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        // Simulated PIN / Sandi Section with Quick Fill Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.surfaceBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderLight, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sandi / PIN Transaksi',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: widget.isLoading
                        ? null
                        : () {
                            setState(() {
                              _pinController.text = '123456';
                              _pinError = null;
                            });
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.wand_rays, size: 12, color: Nebula.teal),
                          const SizedBox(width: 4),
                          Text(
                            'Simulasi Sandi',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Nebula.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                enabled: !widget.isLoading,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                  color: Nebula.teal,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 20,
                    letterSpacing: 6,
                    color: context.textSecondary.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                onChanged: (_) {
                  if (_pinError != null) {
                    setState(() => _pinError = null);
                  }
                },
              ),
              if (_pinError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _pinError!,
                  style: GoogleFonts.inter(fontSize: 11, color: Nebula.rose, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            onPressed: widget.isLoading ? null : _handleConfirm,
            child: widget.isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text(
                    'KONFIRMASI BAYAR',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onCancel,
            child: const Text(
              'Batalkan',
              style: TextStyle(color: Nebula.rose, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
