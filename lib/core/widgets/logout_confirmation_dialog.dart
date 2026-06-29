import 'package:flutter/material.dart';
import 'package:kantin_digital/core/widgets/custom_confirm_dialog.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  return showCustomConfirmDialog(
    context: context,
    title: 'Konfirmasi Keluar',
    message: 'Apakah kamu yakin ingin keluar dari akun?',
    confirmLabel: 'Keluar',
    isDestructive: true,
    icon: Icons.logout_rounded,
  );
}
