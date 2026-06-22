import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';

/// Payment API configuration card (Midtrans).
class AdminPaymentApiCard extends StatelessWidget {
  final bool isSandbox;
  final bool obscureKey;
  final VoidCallback onToggleSandbox;
  final VoidCallback onToggleProd;
  final VoidCallback onToggleObscure;

  const AdminPaymentApiCard({
    super.key,
    required this.isSandbox,
    required this.obscureKey,
    required this.onToggleSandbox,
    required this.onToggleProd,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    const mockClientKey = 'SB-Mid-client-1234567890';
    const mockProdKey = 'PR-Mid-client-0987654321';

    return SettingSectionWidget(
      icon: CupertinoIcons.link,
      title: 'Payment API',
      horizontalPadding: 16,
      verticalPadding: 16,
      iconRadius: 16,
      iconBackgroundColor: AppColors.softOrange.withValues(alpha: 0.3),
      iconColor: AppColors.darkOrange,
      shadowBlurRadius: 15,
      children: [
        Row(
          children: [
            const Text('Midtrans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Active',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.successGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Env', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                GestureDetector(
                  onTap: onToggleSandbox,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSandbox ? AppColors.darkTeal : AppColors.offWhite2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sandbox',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSandbox ? AppColors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleProd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !isSandbox ? AppColors.darkTeal : AppColors.offWhite2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Prod',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: !isSandbox ? AppColors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Client Key', style: TextStyle(fontSize: 10, color: AppColors.textGray)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.offWhite2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  obscureKey
                      ? '••••••••••••••••••••'
                      : (isSandbox ? mockClientKey : mockProdKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 10),
                ),
              ),
              GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscureKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 14,
                  color: AppColors.darkTeal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
