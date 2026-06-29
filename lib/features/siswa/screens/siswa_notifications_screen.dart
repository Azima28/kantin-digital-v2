import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/custom_confirm_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaNotificationsScreen extends ConsumerStatefulWidget {
  const SiswaNotificationsScreen({super.key});

  @override
  ConsumerState<SiswaNotificationsScreen> createState() => _SiswaNotificationsScreenState();
}

class _SiswaNotificationsScreenState extends ConsumerState<SiswaNotificationsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final authState = ref.read(authNotifierProvider);
      final String? studentId = authState.profile?['id'];
      if (studentId == null) return;
      ref.read(paginatedNotificationsProvider(studentId).notifier).loadNextPage();
    }
  }

  Future<void> _markAsRead(BuildContext context, String notifId, String studentId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);
      
      ref.read(paginatedNotificationsProvider(studentId).notifier).loadFirstPage();
    } catch (e) {
      debugPrint('Notification markAsRead error: $e');
    }
  }

  Future<void> _clearAllNotifications(BuildContext context, String studentId) async {
    final confirmed = await showCustomConfirmDialog(
      context: context,
      title: 'Hapus Semua Notifikasi',
      message: 'Apakah Anda yakin ingin menghapus semua notifikasi dari kotak masuk Anda?',
      confirmLabel: AppStrings.buttonDelete,
      cancelLabel: AppStrings.buttonCancel,
      isDestructive: true,
      icon: Icons.delete_sweep_rounded,
    );

    if (confirmed && context.mounted) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client
            .from('notifications')
            .delete()
            .eq('student_id', studentId);
        
        ref.read(paginatedNotificationsProvider(studentId).notifier).loadFirstPage();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.labelFailedDeleteNotification),
              backgroundColor: AppColors.errorRed2,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final String? studentId = authState.profile?['id'];

    if (studentId == null) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    final notificationsState = ref.watch(paginatedNotificationsProvider(studentId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: AppColors.error, size: 20),
            onPressed: () => _clearAllNotifications(context, studentId),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paginatedNotificationsProvider(studentId).notifier).loadFirstPage();
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: () {
              if (notificationsState.isLoading) {
                return const Center(child: CupertinoActivityIndicator());
              }

              if (notificationsState.error != null && notificationsState.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('${AppStrings.labelFailed} memuat notifikasi'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(paginatedNotificationsProvider(studentId).notifier).loadFirstPage(),
                        child: const Text(AppStrings.buttonRetry),
                      ),
                    ],
                  ),
                );
              }

              final notifs = notificationsState.items;

              if (notifs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
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
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: notifs.length + (notificationsState.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == notifs.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }

                  final notif = notifs[index];
                  final String id = notif.id;
                  final String title = notif.title;
                  final String message = notif.message;
                  final String type = notif.type;
                  final bool isRead = notif.isRead;
                  
                  final DateTime createdAt = notif.createdAt?.toLocal() ?? DateTime.now();
                  final String timeStr = DateFormat('dd MMM, HH:mm', 'id_ID').format(createdAt);

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
                        _markAsRead(context, id, studentId);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead ? AppColors.cardBackground : AppColors.systemBackground,
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
            }(),
          ),
        ),
      ),
    );
  }
}
