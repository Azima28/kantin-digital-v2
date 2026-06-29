import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class ActivitiesTab extends ConsumerStatefulWidget {
  const ActivitiesTab({super.key});

  @override
  ConsumerState<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends ConsumerState<ActivitiesTab>
    with AutomaticKeepAliveClientMixin {
  String _selectedActivity = 'Semua Aktivitas';
  late final ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

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
      final String? operatorId = authState.profile?['id'];
      if (operatorId == null) return;

      final String? actionType = _selectedActivity == 'Tambah Menu'
          ? 'TAMBAH_PRODUK'
          : _selectedActivity == 'Ubah Menu'
              ? 'UBAH_PRODUK'
              : _selectedActivity == 'Refund Transaksi'
                  ? 'REFUND_TRANSAKSI'
                  : null;

      final filter = PaginatedAuditLogsFilter(
        actorId: operatorId,
        actionType: actionType,
      );
      ref.read(paginatedAuditLogsProvider(filter).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authState = ref.watch(authNotifierProvider);
    final String? operatorId = authState.profile?['id'];

    if (operatorId == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final String? actionType = _selectedActivity == 'Tambah Menu'
        ? 'TAMBAH_PRODUK'
        : _selectedActivity == 'Ubah Menu'
            ? 'UBAH_PRODUK'
            : _selectedActivity == 'Refund Transaksi'
                ? 'REFUND_TRANSAKSI'
                : null;

    final filter = PaginatedAuditLogsFilter(
      actorId: operatorId,
      actionType: actionType,
    );

    final activitiesState = ref.watch(paginatedAuditLogsProvider(filter));

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Dropdown Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivity,
                    isExpanded: true,
                    style: GoogleFonts.inter(
                        color: AppColors.textDark, fontSize: 14),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedActivity = val;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                          value: 'Semua Aktivitas',
                          child: Text('Semua Aktivitas')),
                      DropdownMenuItem(
                          value: 'Tambah Menu',
                          child: Text('Tambah Menu')),
                      DropdownMenuItem(
                          value: 'Ubah Menu', child: Text('Ubah Menu')),
                      DropdownMenuItem(
                          value: 'Refund Transaksi',
                          child: Text('Refund Transaksi')),
                    ],
                  ),
                ),
              ),
            ),

            // Activities List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(paginatedAuditLogsProvider(filter).notifier).loadFirstPage();
                },
                child: () {
                  if (activitiesState.isLoading) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  if (activitiesState.error != null && activitiesState.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppStrings.labelFailed} memuat aktivitas',
                            style: TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(paginatedAuditLogsProvider(filter).notifier).loadFirstPage();
                            },
                            child: const Text(AppStrings.buttonRetry),
                          ),
                        ],
                      ),
                    );
                  }

                  final logs = activitiesState.items;

                  if (logs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(CupertinoIcons.list_bullet,
                                  size: 48, color: AppColors.textGray),
                              SizedBox(height: 12),
                              Text(
                                'Tidak ada aktivitas',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length + (activitiesState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == logs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      }

                      final log = logs[index];
                      final type = log.actionType;
                      final desc = log.description;
                      final createdAt = log.createdAt?.toLocal();
                      final timeStr = createdAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                              .format(createdAt)
                          : '-';

                      IconData iconData = CupertinoIcons.info;
                      Color iconColor = AppColors.primary;

                      if (type == 'TAMBAH_PRODUK') {
                        iconData = CupertinoIcons.add_circled;
                        iconColor = AppColors.success;
                      } else if (type == 'UBAH_PRODUK') {
                        iconData = CupertinoIcons.pencil_circle;
                        iconColor = Colors.orange;
                      } else if (type == 'REFUND_TRANSAKSI') {
                        iconData = CupertinoIcons.arrow_counterclockwise_circle;
                        iconColor = AppColors.error;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(iconData, color: iconColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
