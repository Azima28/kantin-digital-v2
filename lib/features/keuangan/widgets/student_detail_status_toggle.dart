import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/app_confirmation_dialog.dart';
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

    final confirmed = await showAppConfirmationDialog(
      context,
      title: newStatus ? 'Aktifkan Akun Siswa' : 'Blokir Akun Siswa',
      message: newStatus
          ? 'Apakah Anda yakin ingin mengaktifkan kembali akun siswa ini? Siswa dapat kembali bertransaksi dan top-up.'
          : 'Apakah Anda yakin ingin memblokir akun siswa ini? Siswa tidak akan bisa melakukan transaksi jajan atau top-up.',
      confirmLabel: newStatus ? 'Aktifkan' : 'Blokir',
      isDestructive: !newStatus,
      icon: newStatus ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
    );

    if (!confirmed) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/users/${widget.studentId}/status', body: {
        'is_active': newStatus,
      });

      ref.invalidate(keuanganStudentDetailProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akun siswa berhasil ${newStatus ? "diaktifkan" : "diblokir"}.',
            ),
            backgroundColor: newStatus ? Nebula.teal : Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memperbarui status'),
            backgroundColor: Nebula.rose,
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
              ? Nebula.rose.withValues(alpha: 0.08)
              : Nebula.teal.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: widget.isAccountActive
                  ? Nebula.rose.withValues(alpha: 0.2)
                  : Nebula.teal.withValues(alpha: 0.2),
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
                      ? Nebula.rose
                      : Nebula.teal,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
