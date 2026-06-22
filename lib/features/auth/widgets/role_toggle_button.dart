import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class RoleToggleButton extends ConsumerWidget {
  final int selectedLoginTab;
  final VoidCallback onToggle;
  final VoidCallback? onClearFields;

  const RoleToggleButton({
    super.key,
    required this.selectedLoginTab,
    required this.onToggle,
    this.onClearFields,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedLoginTab == 0
                    ? CupertinoIcons.person_2
                    : CupertinoIcons.arrow_left_square,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                selectedLoginTab == 0
                    ? 'Masuk sebagai Orang Tua'
                    : 'Kembali ke Login Siswa / Staff',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
