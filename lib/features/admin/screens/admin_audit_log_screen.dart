import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/date_filter_modal.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_action_filter.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_detail_sheet.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_tile.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  String _selectedAction = 'Semua Aksi';
  AppDateFilterParam? _dateFilter;

  final List<String> _actions = [
    'Semua Aksi',
    'Registrasi Kartu',
    'Tautan Kartu',
    'Hapus Tautan Kartu',
    'Ubah Kata Sandi',
    'Blokir Akun',
    'Aktifkan Akun',
    'Blokir Kartu',
    'Aktifkan Kartu',
    'Koreksi Saldo',
    'Import Siswa',
    'Top-Up Saldo',
    'Tambah Menu',
    'Ubah Menu',
    'Refund Transaksi',
    'Tambah Pengguna',
    'Ubah Setelan',
  ];

  String _mapActionTypeToFilter(String filter) {
    switch (filter) {
      case 'Registrasi Kartu':
      case 'Tautan Kartu':
        return 'REGISTRASI_KARTU';
      case 'Hapus Tautan Kartu':
        return 'UNLINK_KARTU';
      case 'Ubah Kata Sandi':
        return 'UBAH_PASSWORD';
      case 'Blokir Akun':
        return 'BLOKIR_AKUN';
      case 'Aktifkan Akun':
        return 'AKTIFKAN_AKUN';
      case 'Blokir Kartu':
        return 'BLOKIR_KARTU';
      case 'Aktifkan Kartu':
        return 'AKTIFKAN_KARTU';
      case 'Koreksi Saldo':
        return 'KOREKSI_SALDO';
      case 'Import Siswa':
        return 'IMPORT_SISWA';
      case 'Top-Up Saldo':
        return 'TOPUP_TUNAI';
      case 'Tambah Menu':
        return 'TAMBAH_PRODUK';
      case 'Ubah Menu':
        return 'UBAH_PRODUK';
      case 'Refund Transaksi':
        return 'REFUND_TRANSAKSI';
      case 'Tambah Pengguna':
        return 'TAMBAH_PENGGUNA';
      case 'Ubah Setelan':
        return 'UBAH_SETELAN';
      default:
        return filter;
    }
  }

  Widget _buildDateHeader(BuildContext context, String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Nebula.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Nebula.teal,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: context.borderLight,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    // NOTE: Disini TIDAK pake Scaffold — udah di-wrap AdminMainLayout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER STATIC (gak ikut scroll) ──
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            'Audit Log Explorer',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Nebula.teal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 4.0,
          ),
          child: Text(
            'Pemantauan sistem dan riwayat aktivitas secara real-time.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 8.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: AuditLogActionFilter(
                  selectedAction: _selectedAction,
                  actions: _actions,
                  onChanged: (val) {
                    setState(() {
                      _selectedAction = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              DateFilterPillButton(
                activeFilter: _dateFilter,
                onFilterChanged: (param) {
                  setState(() {
                    _dateFilter = param;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const GradientLine(),
        const SizedBox(height: 8),

        // ── LIST SCROLLABLE ──
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              var filtered = logs;

              if (_selectedAction != 'Semua Aksi') {
                final dbActionKey = _mapActionTypeToFilter(_selectedAction);
                filtered = filtered
                    .where((l) => l.actionType == dbActionKey)
                    .toList();
              }

              if (_dateFilter != null && !_dateFilter!.isAllTime) {
                filtered = filtered
                    .where((l) => _dateFilter!.matches(l.createdAt))
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64, color: context.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada log audit ditemukan.',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group and flatten logs by date
              final List<dynamic> listItems = [];
              DateTime? lastDate;
              for (final log in filtered) {
                final DateTime createdAt = log.createdAt?.toLocal() ?? DateTime.now();
                if (lastDate == null ||
                    lastDate.year != createdAt.year ||
                    lastDate.month != createdAt.month ||
                    lastDate.day != createdAt.day) {
                  final String dateHeaderStr = AppDateFormatter.formatDayFullDate(createdAt);
                  listItems.add(dateHeaderStr);
                  lastDate = createdAt;
                }
                listItems.add(log);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminAuditLogsProvider);
                },
                color: Nebula.teal,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final item = listItems[index];
                    if (item is String) {
                      return _buildDateHeader(context, item);
                    }

                    final log = item as AuditLog;
                    return AuditLogTile(
                      log: log,
                      onDetailTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: context.cardBg,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (_) =>
                              AuditLogDetailSheet(log: log),
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonListTile(),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Nebula.rose),
                  const SizedBox(height: 12),
                  Text('${AppStrings.labelFailed} memuat data'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(adminAuditLogsProvider),
                    child: const Text(AppStrings.buttonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}