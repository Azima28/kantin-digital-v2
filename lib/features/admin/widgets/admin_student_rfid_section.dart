import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

/// Card showing the RFID status with freeze/unfreeze toggle.
/// Responsive and overflow-proof.
class AdminStudentRfidSection extends ConsumerStatefulWidget {
  final String studentId;
  final bool isCardActive;

  const AdminStudentRfidSection({
    super.key,
    required this.studentId,
    required this.isCardActive,
  });

  @override
  ConsumerState<AdminStudentRfidSection> createState() =>
      _AdminStudentRfidSectionState();
}

class _AdminStudentRfidSectionState
    extends ConsumerState<AdminStudentRfidSection> {
  Future<void> _toggleFreezeCard() async {
    final bool newStatus = !widget.isCardActive;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/student/card-status', body: {
        'student_id': widget.studentId,
        'is_active': newStatus,
      });

      ref.invalidate(adminStudentDetailProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kartu RFID berhasil ${newStatus ? "diaktifkan kembali" : "dibekukan"}.',
            ),
            backgroundColor: newStatus ? Nebula.teal : Nebula.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memperbarui status kartu'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFreezeCard,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.isCardActive
              ? Nebula.rose.withValues(alpha: 0.1)
              : Nebula.teal.withValues(alpha: 0.1),
          border: Border.all(
            color: widget.isCardActive
                ? Nebula.rose.withValues(alpha: 0.3)
                : Nebula.teal.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isCardActive
                  ? CupertinoIcons.snow
                  : CupertinoIcons.checkmark_circle,
              color: widget.isCardActive ? Nebula.rose : Nebula.teal,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.isCardActive ? 'Bekukan\nKartu' : 'Aktifkan\nKartu',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isCardActive ? Nebula.rose : Nebula.teal,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
