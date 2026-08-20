import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/date_filter_modal.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
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
  int _selectedCategoryIndex = 0; // 0: Semua, 1: Mutasi Finansial, 2: Kartu RFID, 3: Akun & Keamanan

  final List<String> _actions = [
    'Semua Aksi',
    'Top-Up Siswa',
    'Tarik Saldo Stan (Payout)',
    'Refund Transaksi',
    'Registrasi Kartu',
    'Tautan Kartu',
    'Hapus Tautan Kartu',
    'Blokir Kartu',
    'Aktifkan Kartu',
    'Ubah Kata Sandi',
    'Blokir Akun',
    'Aktifkan Akun',
    'Import Siswa',
    'Tambah Menu',
    'Ubah Menu',
    'Tambah Pengguna',
    'Ubah Setelan',
  ];

  String _mapActionTypeToFilter(String filter) {
    switch (filter) {
      case 'Top-Up Siswa':
        return 'TOPUP_TUNAI';
      case 'Tarik Saldo Stan (Payout)':
        return 'MERCHANT_PAYOUT';
      case 'Refund Transaksi':
        return 'REFUND_TRANSAKSI';
      case 'Registrasi Kartu':
      case 'Tautan Kartu':
        return 'REGISTRASI_KARTU';
      case 'Hapus Tautan Kartu':
        return 'UNLINK_KARTU';
      case 'Blokir Kartu':
        return 'BLOKIR_KARTU';
      case 'Aktifkan Kartu':
        return 'AKTIFKAN_KARTU';
      case 'Ubah Kata Sandi':
        return 'UBAH_PASSWORD';
      case 'Blokir Akun':
        return 'BLOKIR_AKUN';
      case 'Aktifkan Akun':
        return 'AKTIFKAN_AKUN';
      case 'Import Siswa':
        return 'IMPORT_SISWA';
      case 'Tambah Menu':
        return 'TAMBAH_PRODUK';
      case 'Ubah Menu':
        return 'UBAH_PRODUK';
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

    final categories = [
      {'label': 'Semua', 'icon': CupertinoIcons.square_grid_2x2},
      {'label': 'Mutasi Finansial', 'icon': CupertinoIcons.arrow_right_arrow_left_circle_fill},
      {'label': 'Kartu RFID', 'icon': CupertinoIcons.creditcard_fill},
      {'label': 'Akun & Akses', 'icon': CupertinoIcons.shield_fill},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER STATIC ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
            'Pemantauan sistem, mutasi keuangan, dan riwayat aktivitas real-time.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── KATEGORI CEPAT (Slider Chips) ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(categories.length, (idx) {
              final isSelected = _selectedCategoryIndex == idx;
              final cat = categories[idx];

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = idx;
                      _selectedAction = 'Semua Aksi';
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Nebula.teal : context.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Nebula.teal : context.dividerCol,
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 13,
                          color: isSelected ? Colors.white : Nebula.teal,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat['label']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),

        // ── FILTER ROW (Aksi & Tanggal) ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 4.0,
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

              // Filter Category Chips
              if (_selectedCategoryIndex == 1) {
                // Mutasi Finansial: TOPUP, PAYOUT, REFUND
                filtered = filtered.where((l) {
                  final a = l.actionType;
                  return a == 'TOPUP_TUNAI' || a == 'TOPUP' || a == 'MERCHANT_PAYOUT' ||
                      a == 'REFUND_TRANSAKSI' || a == 'BATAL_PESANAN';
                }).toList();
              } else if (_selectedCategoryIndex == 2) {
                // Kartu RFID
                filtered = filtered.where((l) {
                  final a = l.actionType;
                  return a.contains('KARTU') || a == 'REGISTRASI_KARTU' || a == 'UNLINK_KARTU' || a == 'BLOKIR_KARTU' || a == 'AKTIFKAN_KARTU';
                }).toList();
              } else if (_selectedCategoryIndex == 3) {
                // Akun & Akses
                filtered = filtered.where((l) {
                  final a = l.actionType;
                  return a == 'BLOKIR_AKUN' || a == 'AKTIFKAN_AKUN' || a == 'UBAH_PASSWORD' || a == 'TAMBAH_PENGGUNA' || a == 'IMPORT_SISWA';
                }).toList();
              }

              // Specific Action Dropdown Filter
              if (_selectedAction != 'Semua Aksi') {
                final dbActionKey = _mapActionTypeToFilter(_selectedAction);
                filtered = filtered
                    .where((l) => l.actionType == dbActionKey)
                    .toList();
              }

              // Date Filter
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coba ganti filter atau pilih rentang tanggal lain.',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminAuditLogsProvider);
                },
                color: Nebula.teal,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    final currentDay = AppDateFormatter.formatDate(log.createdAt);
                    final prevDay = index > 0 ? AppDateFormatter.formatDate(filtered[index - 1].createdAt) : null;
                    final showHeader = prevDay != currentDay;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) _buildDateHeader(context, currentDay),
                        AuditLogTile(
                          log: log,
                          onDetailTap: () => AuditLogDetailSheet.show(context, log),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => Shimmer(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 4,
                itemBuilder: (context, index) => Container(
                  height: 90,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
              ),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                  const SizedBox(height: 12),
                  Text('${AppStrings.labelFailed} memuat log audit: $err'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(adminAuditLogsProvider),
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
