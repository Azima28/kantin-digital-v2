import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';

/// Bottom Sheet for viewing and managing notifications across all roles.
class NotificationsBottomSheet extends ConsumerStatefulWidget {
  const NotificationsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsBottomSheet(),
    );
  }

  @override
  ConsumerState<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends ConsumerState<NotificationsBottomSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _markAllAsRead());
  }

  Future<void> _markAllAsRead() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authNotifierProvider);
      final String? userId = authState.profile?['id']?.toString() ?? client.auth.currentUser?.id;
      if (userId == null) return;

      // Update all unread notifications to read
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      ref.invalidate(userNotificationsProvider);
    } catch (e) {
      debugPrint('Notification markAllAsRead error: $e');
    }
  }

  Future<void> _markAsRead(BuildContext context, String notifId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);
      
      ref.invalidate(userNotificationsProvider);
    } catch (e) {
      debugPrint('Notification markAsRead error: $e');
    }
  }

  Future<void> _clearAllNotifications(BuildContext context) async {
    final client = ref.read(supabaseClientProvider);
    final authState = ref.read(authNotifierProvider);
    final String? userId = authState.profile?['id']?.toString() ?? client.auth.currentUser?.id;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderLight, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Nebula.rose.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.trash, color: Nebula.rose, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Hapus Semua Notifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Apakah Anda yakin ingin menghapus semua notifikasi dari kotak masuk Anda?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          AppStrings.buttonCancel,
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PressScale(
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await client
                                .from('notifications')
                                .delete()
                                .eq('user_id', userId);
                            
                            ref.invalidate(userNotificationsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal menghapus notifikasi'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.rose,
                            disabledBackgroundColor: Nebula.rose,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.borderLight, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.grayLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),

          // Title & Trash Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.bell_fill, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Notifikasi Saya',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.trash, color: AppColors.error, size: 20),
                  tooltip: 'Hapus Semua',
                  onPressed: () => _clearAllNotifications(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.borderLight),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userNotificationsProvider);
              },
              child: notificationsAsync.when(
                data: (List<AppNotification> notifs) {
                  if (notifs.isEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.bell_slash, size: 48, color: context.textSecondary),
                              SizedBox(height: 12),
                              Text(
                                'Kotak masuk kosong',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pemberitahuan transaksi atau broadcast akan muncul di sini.',
                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final notif = notifs[index];
                      final DateTime createdAt = notif.createdAt?.toLocal() ?? DateTime.now();
                      final String timeStr = DateFormat('dd MMM, HH:mm', 'id_ID').format(createdAt);

                      IconData iconData;
                      Color iconColor;
                      Color bgColor;

                      if (notif.type == 'purchase') {
                        iconData = CupertinoIcons.cart;
                        iconColor = AppColors.primary;
                        bgColor = AppColors.primaryLight;
                      } else if (notif.type == 'topup') {
                        iconData = CupertinoIcons.square_arrow_down;
                        iconColor = AppColors.primary;
                        bgColor = AppColors.primaryLight;
                      } else {
                        iconData = CupertinoIcons.bell;
                        iconColor = AppColors.accentOrange;
                        bgColor = AppColors.accentOrangeLight;
                      }

                      return GestureDetector(
                        onTap: () {
                          if (!notif.isRead) {
                            _markAsRead(context, notif.id);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.borderLight,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon badge
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bgColor,
                                ),
                                child: Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      const Text('Gagal memuat notifikasi'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(userNotificationsProvider),
                        child: const Text(AppStrings.buttonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}