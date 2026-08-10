import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

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
            color: Nebula.teal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Nebula.teal.withValues(alpha: 0.15),
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
                color: Nebula.teal,
              ),
              const SizedBox(width: 8),
              Text(
                selectedLoginTab == 0
                    ? 'Masuk sebagai Orang Tua'
                    : 'Kembali ke Login Siswa / Staff',
                style: TextStyle(
                  color: Nebula.teal,
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
