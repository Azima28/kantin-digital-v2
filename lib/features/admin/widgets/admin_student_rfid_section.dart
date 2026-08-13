import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Card showing the RFID status with freeze/unfreeze toggle.
/// Styled as a horizontal action button to match the user screenshot design.
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
    final client = ref.read(supabaseClientProvider);
    final bool newStatus = !widget.isCardActive;

    try {
      // 1. Update students table is_active field
      await client
          .from('students')
          .update({'is_active': newStatus})
          .eq('id', widget.studentId);

      // Write to audit logs
      try {
        final authProfile = ref.read(authNotifierProvider).profile;
        final actorName = authProfile?['full_name'] ?? 'Super Admin';
        final actorId = authProfile?['id'];

        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': newStatus ? 'AKTIFKAN_KARTU' : 'BLOKIR_KARTU',
          'description':
              'Super Admin ${newStatus ? "mengaktifkan kembali" : "membekukan"} kartu RFID siswa dengan ID: ${widget.studentId}',
          'target_id': widget.studentId,
          'old_value': {'is_active': widget.isCardActive},
          'new_value': {'is_active': newStatus},
        });
      } catch (_) {}

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isCardActive
                  ? CupertinoIcons.snow
                  : CupertinoIcons.checkmark_circle,
              color: widget.isCardActive ? Nebula.rose : Nebula.teal,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              widget.isCardActive ? 'Bekukan\nKartu RFID' : 'Aktifkan\nKartu RFID',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isCardActive ? Nebula.rose : Nebula.teal,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
