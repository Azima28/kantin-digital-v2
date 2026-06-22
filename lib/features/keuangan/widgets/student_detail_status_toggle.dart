import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

/// A button widget to block or unblock a student account.
/// Used inside the keuangan student detail screen.
class StudentDetailStatusToggle extends ConsumerStatefulWidget {
  final String studentId;
  final bool isAccountActive;

  const StudentDetailStatusToggle({
    super.key,
    required this.studentId,
    required this.isAccountActive,
  });

  @override
  ConsumerState<StudentDetailStatusToggle> createState() =>
      _StudentDetailStatusToggleState();
}

class _StudentDetailStatusToggleState
    extends ConsumerState<StudentDetailStatusToggle> {
  bool _isUpdatingStatus = false;

  Future<void> _toggleAccountStatus() async {
    final bool newStatus = !widget.isAccountActive;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(newStatus ? 'Aktifkan Akun' : 'Blokir Akun'),
        content: Text(
          newStatus
              ? 'Apakah Anda yakin ingin mengaktifkan kembali akun siswa ini?'
              : 'Apakah Anda yakin ingin memblokir akun siswa ini? Siswa tidak akan bisa melakukan transaksi jajan atau top-up.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: !newStatus,
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isUpdatingStatus = true;
              });

              try {
                final client = ref.read(supabaseClientProvider);
                final profile = ref.read(authNotifierProvider).profile;
                final actorName = profile?['full_name'] ?? 'Admin Keuangan';
                final actorId = profile?['id'];

                // 1. Update profiles is_active
                await client
                    .from('profiles')
                    .update({'is_active': newStatus})
                    .eq('id', widget.studentId);

                // 2. Update students is_active
                await client
                    .from('students')
                    .update({'is_active': newStatus})
                    .eq('id', widget.studentId);

                // 3. Write to audit logs
                await client.from('audit_logs').insert({
                  'actor_id': actorId,
                  'actor_name': actorName,
                  'action_type':
                      newStatus ? 'AKTIFKAN_AKUN' : 'BLOKIR_AKUN',
                  'description':
                      '${newStatus ? "Mengaktifkan" : "Memblokir"} akun siswa dengan ID: ${widget.studentId}',
                  'target_id': widget.studentId,
                  'old_value': {'is_active': widget.isAccountActive},
                  'new_value': {'is_active': newStatus},
                });

                ref
                    .invalidate(keuanganStudentDetailProvider(widget.studentId));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Akun siswa berhasil ${newStatus ? "diaktifkan" : "diblokir"}.',
                      ),
                      backgroundColor: newStatus
                          ? AppColors.successGreen
                          : AppColors.errorRed2,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${AppStrings.labelFailed} memperbarui status'),
                      backgroundColor: AppColors.errorRed2,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isUpdatingStatus = false;
                  });
                }
              }
            },
            child: Text(newStatus ? 'Aktifkan' : 'Blokir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _isUpdatingStatus ? null : _toggleAccountStatus,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: widget.isAccountActive
              ? AppColors.errorRed2.withValues(alpha: 0.08)
              : AppColors.successGreen.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: widget.isAccountActive
                  ? AppColors.errorRed2.withValues(alpha: 0.2)
                  : AppColors.successGreen.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: _isUpdatingStatus
            ? const CupertinoActivityIndicator()
            : Text(
                widget.isAccountActive
                    ? '🚫 BLOKIR AKUN SISWA'
                    : '✔ AKTIFKAN AKUN SISWA',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: widget.isAccountActive
                      ? AppColors.errorRed2
                      : AppColors.successGreen,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
