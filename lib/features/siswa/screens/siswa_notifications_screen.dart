import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaNotificationsScreen extends ConsumerWidget {
  const SiswaNotificationsScreen({super.key});

  Future<void> _markAsRead(BuildContext context, WidgetRef ref, String notifId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/student/notifications/$notifId/read');
      ref.invalidate(siswaNotificationsProvider);
    } catch (e) {
      debugPrint('Notification markAsRead error: $e');
    }
  }

  Future<void> _clearAllNotifications(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authNotifierProvider);
    final String? studentId = authState.profile?['id'];
    if (studentId == null) return;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text('Apakah Anda yakin ingin menghapus semua notifikasi dari kotak masuk Anda?'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiClient = ref.read(apiClientProvider);
                await apiClient.patch('/student/notifications/read-all');
                ref.invalidate(siswaNotificationsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.labelFailedDeleteNotification), backgroundColor: Nebula.rose),
                  );
                }
              }
            },
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(siswaNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: Nebula.rose, size: 20),
            onPressed: () => _clearAllNotifications(context, ref),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaNotificationsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: notificationsAsync.when(
              data: (List<AppNotification> notifs) {
                if (notifs.isEmpty) {
                  return Center(
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
                          'Pemberitahuan transaksi akan muncul di sini.',
                          style: TextStyle(color: context.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    final notif = notifs[index];
                    final String id = notif.id;
                    final String title = notif.title;
                    final String message = notif.message;
                    final String type = notif.type;
                    final bool isRead = notif.isRead;
                    
                    final DateTime createdAt = notif.createdAt?.toLocal() ?? DateTime.now();
                    final String timeStr = AppDateFormatter.formatShortDateWithTime(createdAt);

                    IconData iconData;
                    Color iconColor;
                    Color bgColor;

                    if (type == 'purchase') {
                      iconData = CupertinoIcons.cart;
                      iconColor = Nebula.teal;
                      bgColor = Nebula.teal.withValues(alpha: 0.08);
                    } else if (type == 'topup') {
                      iconData = CupertinoIcons.square_arrow_down;
                      iconColor = Nebula.teal;
                      bgColor = Nebula.teal.withValues(alpha: 0.08);
                    } else {
                      iconData = CupertinoIcons.bell;
                      iconColor = Nebula.amber;
                      bgColor = Nebula.amberLight;
                    }

                    return PressScale(
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(context, ref, id);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? context.cardBg : context.surfaceBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead ? context.dividerCol : Nebula.teal.withValues(alpha: 0.3),
                            width: isRead ? 0.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type Icon circle badge
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

                            // Title, text and time stamp
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Nebula.teal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRead ? context.textSecondary : context.textPrimary.withValues(alpha: 0.8),
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
              loading: () => Shimmer(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderLight, width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonCircle(size: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SkeletonBox(width: 130, height: 14, borderRadius: 4),
                                SizedBox(height: 6),
                                SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                                SizedBox(height: 8),
                                SkeletonBox(width: 80, height: 10, borderRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                    const                     SizedBox(height: 12),
                    Text('${AppStrings.labelFailed} memuat notifikasi'),
                    const SizedBox(height: 8),
                    const GradientLine(),
                    const SizedBox(height: 8),
                    PressScale(
                      onTap: () => ref.invalidate(siswaNotificationsProvider),
                      child: ElevatedButton(
                        onPressed: () => ref.invalidate(siswaNotificationsProvider),
                        child: const Text(AppStrings.buttonRetry),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}