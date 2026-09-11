import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

/// Modal dialog for canteen staff to confirm and approve a student's cancellation request.
/// Does not ask for cancellation reasons because the student already submitted one.
class ApproveCancellationDialog extends ConsumerStatefulWidget {
  final OrderItem order;

  const ApproveCancellationDialog({super.key, required this.order});

  /// Shows the confirmation dialog with smooth transition.
  static Future<bool?> show(
    BuildContext context, {
    required OrderItem order,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ApproveCancellationDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return ApproveCancellationDialog(order: order);
      },
    );
  }

  @override
  ConsumerState<ApproveCancellationDialog> createState() =>
      _ApproveCancellationDialogState();
}

class _ApproveCancellationDialogState
    extends ConsumerState<ApproveCancellationDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleApprove() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.patch(
        '/orders/${widget.order.id}/status',
        body: {
          'status': 'Dibatalkan',
          if (widget.order.cancelRequestReason != null &&
              widget.order.cancelRequestReason!.trim().isNotEmpty)
            'cancel_request_reason': widget.order.cancelRequestReason!.trim(),
        },
      );

      if (!response.success) {
        throw Exception(
            response.message ?? 'Gagal memproses persetujuan pembatalan');
      }

      // Invalidate relevant providers to update order lists and balances
      ref.invalidate(canteenOrdersProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(operatorTransactionsProvider);
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaActiveOrdersProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final formattedAmount = CurrencyFormatter.format(order.totalAmount);
    final studentName = order.studentName.isNotEmpty ? order.studentName : 'Siswa';
    final hasReason = order.cancelRequestReason != null &&
        order.cancelRequestReason!.trim().isNotEmpty;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.dividerCol, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Nebula.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Nebula.amber.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Nebula.amber,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setujui Pembatalan Pesanan',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Permohonan pembatalan diajukan oleh murid',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Refund Details Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.dividerCol, width: 0.7),
                  ),
                  child: Column(
                    children: [
                      // Total Refund Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pengembalian Saldo',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            formattedAmount,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Nebula.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: context.dividerCol),
                      const SizedBox(height: 10),

                      // Student Name Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dikembalikan ke Akun',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              studentName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      // Student reason section if provided
                      if (hasReason) ...[
                        const SizedBox(height: 10),
                        Divider(height: 1, color: context.dividerCol),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Alasan Murid:',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Nebula.rose.withValues(alpha: 0.2),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            '"${order.cancelRequestReason!.trim()}"',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Informative explanation message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle_fill,
                      size: 15,
                      color: Nebula.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saldo sebesar $formattedAmount akan langsung masuk kembali ke akun $studentName seketika setelah disetujui.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),

                // Error Message Banner
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Nebula.rose.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Nebula.rose.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Nebula.rose,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textSecondary,
                          side: BorderSide(color: context.dividerCol),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.buttonCancel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.rose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Setujui & Kembalikan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
