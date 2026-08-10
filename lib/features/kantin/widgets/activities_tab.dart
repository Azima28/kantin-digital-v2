import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/providers/operator_activities_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class ActivitiesTab extends ConsumerStatefulWidget {
  const ActivitiesTab({super.key});

  @override
  ConsumerState<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends ConsumerState<ActivitiesTab> {
  String _selectedActivity = 'Semua Aktivitas';

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(operatorActivitiesProvider);

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
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderLight, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivity,
                    isExpanded: true,
                    style: GoogleFonts.inter(
                        color: context.textPrimary, fontSize: 14),
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
              child: activitiesAsync.when(
                data: (List<AuditLog> logs) {
                  // Filter logs
                  final filtered = logs.where((log) {
                    final type = log.actionType;
                    if (_selectedActivity == 'Tambah Menu') {
                      return type == 'TAMBAH_PRODUK';
                    } else if (_selectedActivity == 'Ubah Menu') {
                      return type == 'UBAH_PRODUK';
                    } else if (_selectedActivity == 'Refund Transaksi') {
                      return type == 'REFUND_TRANSAKSI';
                    }
                    return true; // Semua Aktivitas
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.list_bullet,
                              size: 48, color: context.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada aktivitas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final log = filtered[index];
                      final type = log.actionType;
                      final desc = log.description;
                      final createdAt = log.createdAt?.toLocal();
                      final timeStr = createdAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                              .format(createdAt)
                          : '-';

                      IconData iconData = CupertinoIcons.info;
                      Color iconColor = Nebula.teal;

                      if (type == 'TAMBAH_PRODUK') {
                        iconData = CupertinoIcons.add_circled;
                        iconColor = Nebula.teal;
                      } else if (type == 'UBAH_PRODUK') {
                        iconData = CupertinoIcons.pencil_circle;
                        iconColor = Colors.orange;
                      } else if (type == 'REFUND_TRANSAKSI') {
                        iconData = CupertinoIcons.arrow_counterclockwise_circle;
                        iconColor = Nebula.rose;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: context.borderLight, width: 0.5),
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.textSecondary,
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
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.labelFailed} memuat aktivitas',
                        style: TextStyle(color: Nebula.rose),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(operatorActivitiesProvider),
                        child: const Text(AppStrings.buttonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}