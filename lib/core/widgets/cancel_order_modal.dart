import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';

/// Modal dialog for cancelling an order.
/// Automatically detects user role (student vs cafeteria staff)
/// to display appropriate list of cancellation reasons.
class CancelOrderModal extends ConsumerStatefulWidget {
  final String orderId;
  final VoidCallback? onSuccess;

  const CancelOrderModal({
    super.key,
    required this.orderId,
    this.onSuccess,
  });

  /// Shows the cancel order modal with customized transitions.
  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    VoidCallback? onSuccess,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CancelOrderDialog',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuad,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return CancelOrderModal(
          orderId: orderId,
          onSuccess: onSuccess,
        );
      },
    );
  }

  @override
  ConsumerState<CancelOrderModal> createState() => _CancelOrderModalState();
}

class _CancelOrderModalState extends ConsumerState<CancelOrderModal> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _studentReasons = [
    'Saya salah memilih menu.',
    'Saya salah jumlah pesanan.',
    'Saya berubah pikiran.',
    'Waktu pengambilan sudah tidak sesuai.',
    'Saldo saya tidak mencukupi.',
    'Saya ingin memesan dari kantin lain.',
    'Saya tidak jadi membeli makanan.',
    'Pesanan terlalu lama diproses.',
    'Terjadi kesalahan pada pesanan.',
    'Lainnya.',
  ];

  final List<String> _staffReasons = [
    'Bahan makanan habis.',
    'Menu sedang tidak tersedia.',
    'Terjadi kesalahan stok.',
    'Kantin sedang tutup.',
    'Peralatan memasak mengalami kendala.',
    'Pesanan tidak dapat dipenuhi tepat waktu.',
    'Terjadi kesalahan pada pesanan.',
    'Pembayaran tidak berhasil diverifikasi.',
    'Pesanan terindikasi duplikat.',
    'Lainnya.',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Lainnya.') {
      return _customReasonController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _handleConfirm() async {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String finalReason = _selectedReason == 'Lainnya.'
        ? _customReasonController.text.trim()
        : _selectedReason!;

    try {
      final apiClient = ref.read(apiClientProvider);

      final authState = ref.read(authNotifierProvider);
      final role = authState.profile?['role']?.toString();
      final bool isStudent = role == 'student';

      final String status = isStudent ? 'Menunggu Pembatalan' : 'Dibatalkan';
      final response = await apiClient.patch(
        '/orders/${widget.orderId}/status',
        body: {
          'status': status,
          'cancel_request_reason': finalReason,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal memproses pembatalan');
      }

      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(siswaActiveOrdersProvider);
      ref.invalidate(canteenOrdersProvider);

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membatalkan pesanan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.profile?['role']?.toString();
    final bool isStudent = role == 'student';
    final List<String> reasons = isStudent ? _studentReasons : _staffReasons;

    final String titleText = isStudent
        ? 'Mengapa Anda ingin membatalkan pesanan?'
        : 'Mengapa pesanan dibatalkan?';

    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 600 ? 540.0 : screenWidth * 0.90;
    final bool isMobileLayout = screenWidth < 500;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context, false);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HEADER ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLightColor.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppColors.errorRed2,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Batalkan Pesanan',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih alasan pembatalan pesanan. Informasi ini akan digunakan untuk meningkatkan kualitas layanan kantin.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 1, color: context.borderLight),

                // ── CONTENT (SCROLLABLE REASONS) ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Option Radio Tiles
                        ...reasons.map((reason) {
                          final bool isSelected = _selectedReason == reason;
                          return _CancelReasonTile(
                            label: reason,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedReason = reason;
                              });
                            },
                          );
                        }),

                        // Animated Expanding Textarea
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutQuad,
                          child: _selectedReason == 'Lainnya.'
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alasan lainnya',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _customReasonController,
                                        maxLines: 3,
                                        keyboardType: TextInputType.multiline,
                                        onChanged: (text) {
                                          setState(() {}); // trigger isValid update
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Tuliskan alasan pembatalan...',
                                          hintStyle: GoogleFonts.inter(
                                            color: context.textSecondary,
                                            fontSize: 14,
                                          ),
                                          contentPadding: const EdgeInsets.all(12),
                                          filled: true,
                                          fillColor: context.surfaceBg,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: context.borderLight),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: context.borderLight),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: AppColors.primary),
                                          ),
                                        ),
                                        style: GoogleFonts.inter(fontSize: 14),
                                      ),
                                      if (_customReasonController.text.trim().isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4, left: 2),
                                          child: Text(
                                            'Wajib menuliskan alasan lainnya.',
                                            style: GoogleFonts.inter(
                                              color: AppColors.errorRed2,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Error message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
                                  color: AppColors.errorRed2,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.errorRed2,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Divider(height: 1, color: context.borderLight),

                // ── ACTIONS ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: isMobileLayout
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _isValid && !_isLoading ? _handleConfirm : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.errorRed2,
                                foregroundColor: context.cardBg,
                                disabledBackgroundColor: AppColors.errorRed2.withValues(alpha: 0.5),
                                disabledForegroundColor: context.cardBg.withValues(alpha: 0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.cardBg,
                                      ),
                                    )
                                  : Text(
                                      'Konfirmasi Pembatalan',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: BorderSide(color: context.borderLight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Kembali',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: context.borderLight),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  'Kembali',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isValid && !_isLoading ? _handleConfirm : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.errorRed2,
                                  foregroundColor: context.cardBg,
                                  disabledBackgroundColor: AppColors.errorRed2.withValues(alpha: 0.5),
                                  disabledForegroundColor: context.cardBg.withValues(alpha: 0.7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.cardBg,
                                        ),
                                      )
                                    : Text(
                                        'Konfirmasi Pembatalan',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelReasonTile extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CancelReasonTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CancelReasonTile> createState() => _CancelReasonTileState();
}

class _CancelReasonTileState extends State<_CancelReasonTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (hovered) {
        setState(() {
          _isHovered = hovered;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.4)
              : (_isHovered ? context.surfaceBg : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected ? AppColors.primary : AppColors.gray400,
                  width: widget.isSelected ? 6 : 2,
                ),
                color: Colors.transparent,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: widget.isSelected ? AppColors.teal : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}