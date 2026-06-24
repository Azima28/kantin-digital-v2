import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/notifications_bottom_sheet.dart';

/// Reusable Notification Bell icon widget with unread count badge.
/// Opens the [NotificationsBottomSheet] on tap.
class NotificationBell extends ConsumerWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            unreadCount > 0 ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
            color: color ?? AppColors.primary,
            size: 22,
          ),
          onPressed: () => NotificationsBottomSheet.show(context),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 15,
                  minHeight: 15,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
