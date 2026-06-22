import 'package:flutter/cupertino.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(AppStrings.titleConfirmation),
      content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Keluar dari Akun'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.buttonCancel),
        ),
      ],
    ),
  );
  return result ?? false;
}
