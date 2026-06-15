import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaNotificationsScreen extends ConsumerWidget {
  const SiswaNotificationsScreen({super.key});

  Future<void> _markAsRead(BuildContext context, WidgetRef ref, String notifId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);
      
      ref.invalidate(siswaNotificationsProvider);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
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
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final client = ref.read(supabaseClientProvider);
                await client
                    .from('notifications')
                    .delete()
                    .eq('student_id', studentId);
                
                ref.invalidate(siswaNotificationsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus notifikasi: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(siswaNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: AppColors.error, size: 20),
            onPressed: () => _clearAllNotifications(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaNotificationsProvider);
        },
        child: notificationsAsync.when(
          data: (List<Map<String, dynamic>> notifs) {
            if (notifs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 100),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(CupertinoIcons.bell_slash, size: 48, color: AppColors.textGray),
                          SizedBox(height: 12),
                          Text(
                            'Kotak masuk kosong',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pemberitahuan transaksi akan muncul di sini.',
                            style: TextStyle(color: AppColors.textGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final notif = notifs[index];
                final String id = notif['id']?.toString() ?? '';
                final String title = notif['title']?.toString() ?? 'Pemberitahuan';
                final String message = notif['message']?.toString() ?? '';
                final String type = notif['type']?.toString() ?? 'system';
                final bool isRead = notif['is_read'] ?? false;
                
                final DateTime createdAt = notif['created_at'] != null 
                    ? DateTime.parse(notif['created_at']).toLocal()
                    : DateTime.now();
                final String timeStr = DateFormat('dd MMM, HH:mm').format(createdAt);

                IconData iconData;
                Color iconColor;
                Color bgColor;

                if (type == 'purchase') {
                  iconData = CupertinoIcons.cart;
                  iconColor = AppColors.primary;
                  bgColor = AppColors.primaryLight;
                } else if (type == 'topup') {
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
                    if (!isRead) {
                      _markAsRead(context, ref, id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? AppColors.cardBackground : const Color(0xFFF9F9FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.3),
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
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
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
                                  color: isRead ? AppColors.textGray : AppColors.textDark.withValues(alpha: 0.8),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textGray,
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
          error: (err, stack) => Center(child: Text('Gagal memuat notifikasi: $err', style: const TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }
}
