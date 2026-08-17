import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

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
  int _selectedCategoryIndex = 0; // 0: Semua, 1: Pesanan, 2: Ulasan, 3: Info

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _markAllAsRead());
  }

  Future<void> _markAllAsRead() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/student/notifications/read-all');
      ref.invalidate(userNotificationsProvider);
    } catch (e) {
      debugPrint('Notification markAllAsRead error: $e');
    }
  }

  Future<void> _markAsRead(BuildContext context, String notifId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/student/notifications/$notifId/read');
      ref.invalidate(userNotificationsProvider);
    } catch (e) {
      debugPrint('Notification markAsRead error: $e');
    }
  }

  Future<void> _clearAllNotifications(BuildContext context) async {
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
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Apakah Anda yakin ingin menghapus seluruh riwayat notifikasi Anda? Tindakan ini tidak dapat dibatalkan.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: context.dividerCol),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: context.textPrimary,
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
                            final apiClient = ref.read(apiClientProvider);
                            final res = await apiClient.delete('/student/notifications');
                            if (res.success) {
                              ref.invalidate(userNotificationsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Semua notifikasi berhasil dihapus'),
                                    backgroundColor: Nebula.teal,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
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

  bool _isPesanan(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t == 'purchase' || t == 'order' || t == 'refund' || t == 'topup';
  }

  bool _isUlasan(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t == 'review' || t == 'ulasan';
  }

  bool _isInfo(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t == 'system' || t == 'info' || t == 'broadcast';
  }

  Widget _buildCategoryTabs(BuildContext context, List<AppNotification> allNotifs) {
    final int countPesanan = allNotifs.where((n) => _isPesanan(n.type)).length;
    final int countUlasan = allNotifs.where((n) => _isUlasan(n.type)).length;
    final int countInfo = allNotifs.where((n) => _isInfo(n.type)).length;

    final List<Map<String, dynamic>> tabs = [
      {'index': 0, 'label': 'Semua', 'count': allNotifs.length},
      {'index': 1, 'label': 'Pesanan', 'count': countPesanan},
      {'index': 2, 'label': 'Ulasan', 'count': countUlasan},
      {'index': 3, 'label': 'Info', 'count': countInfo},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final int index = tab['index'];
          final String label = tab['label'];
          final int count = tab['count'];
          final bool isSelected = index == _selectedCategoryIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Nebula.teal : context.surfaceBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Nebula.teal : context.borderLight,
                      width: isSelected ? 1.0 : 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Nebula.teal.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : context.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Nebula.teal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

          // Category Filter Chips
          notificationsAsync.maybeWhen(
            data: (allNotifs) => _buildCategoryTabs(context, allNotifs),
            orElse: () => const SizedBox.shrink(),
          ),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userNotificationsProvider);
              },
              child: notificationsAsync.when(
                data: (List<AppNotification> allNotifs) {
                  final notifs = allNotifs.where((n) {
                    if (_selectedCategoryIndex == 1 && !_isPesanan(n.type)) return false;
                    if (_selectedCategoryIndex == 2 && !_isUlasan(n.type)) return false;
                    if (_selectedCategoryIndex == 3 && !_isInfo(n.type)) return false;
                    return true;
                  }).toList();

                  if (notifs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.bell_slash, size: 48, color: context.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'Kotak masuk kosong',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pemberitahuan transaksi, ulasan, atau broadcast akan muncul di sini.',
                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final notif = notifs[index];
                      final DateTime createdAt = notif.createdAt?.toLocal() ?? DateTime.now();
                      final String timeStr = AppDateFormatter.formatShortDateWithTime(createdAt);

                      IconData iconData;
                      Color iconColor;
                      Color bgColor;

                      if (notif.type == 'purchase' || notif.type == 'order') {
                        iconData = CupertinoIcons.cart;
                        iconColor = AppColors.primary;
                        bgColor = AppColors.primaryLight;
                      } else if (notif.type == 'topup') {
                        iconData = CupertinoIcons.square_arrow_down;
                        iconColor = AppColors.primary;
                        bgColor = AppColors.primaryLight;
                      } else if (notif.type == 'review' || notif.type == 'ulasan') {
                        iconData = Icons.star_rounded;
                        iconColor = const Color(0xFFFFC107);
                        bgColor = const Color(0xFFFFC107).withValues(alpha: 0.15);
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
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(14),
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
                                  size: 20,
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
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: context.textSecondary.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (!notif.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4, left: 4),
                                  decoration: const BoxDecoration(
                                    color: Nebula.teal,
                                    shape: BoxShape.circle,
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
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SkeletonListTile(),
                    ),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppStrings.labelFailed} memuat notifikasi',
                          style: TextStyle(color: context.errorColor, fontSize: 13),
                        ),
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
          ),
        ],
      ),
    );
  }
}
