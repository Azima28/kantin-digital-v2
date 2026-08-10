import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
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
      iconBackgroundColor: Nebula.amber.withValues(alpha: 0.3).withValues(alpha: 0.3),
      iconColor: Nebula.amber,
      shadowBlurRadius: 15,
      children: [
        Row(
          children: [
            Text('Midtrans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Nebula.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Active',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Nebula.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Env', style: TextStyle(fontSize: 11, color: context.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                GestureDetector(
                  onTap: onToggleSandbox,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSandbox ? Nebula.teal : context.surfaceBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sandbox',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSandbox ? Colors.white : context.textPrimary,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleProd,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !isSandbox ? Nebula.teal : context.surfaceBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Prod',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: !isSandbox ? Colors.white : context.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Client Key', style: TextStyle(fontSize: 10, color: context.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: context.surfaceBg,
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
                  color: Nebula.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}