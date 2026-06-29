import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_action_filter.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_detail_sheet.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_tile.dart';

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedAction = 'Semua Aksi';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final actionKey = _selectedAction == 'Semua Aksi' ? 'Semua' : _mapActionTypeToFilter(_selectedAction);
      final filter = PaginatedAuditLogsFilter(actionType: actionKey);
      ref.read(paginatedAuditLogsProvider(filter).notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final actionKey = _selectedAction == 'Semua Aksi' ? 'Semua' : _mapActionTypeToFilter(_selectedAction);
    final filter = PaginatedAuditLogsFilter(actionType: actionKey);
    final logsState = ref.watch(paginatedAuditLogsProvider(filter));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER STATIC (gak ikut scroll) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            'Audit Log Explorer',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkTeal,
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
              color: AppColors.darkGray,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 8.0,
          ),
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
        const SizedBox(height: 8),

        // ── LIST SCROLLABLE ──
        Expanded(
          child: Builder(
            builder: (context) {
              if (logsState.isLoading) {
                return const Center(
                  child: CupertinoActivityIndicator(
                    color: AppColors.darkTeal,
                  ),
                );
              }

              if (logsState.error != null && logsState.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.errorRed),
                      const SizedBox(height: 12),
                      Text('${AppStrings.labelFailed} memuat data'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(paginatedAuditLogsProvider(filter)),
                        child: const Text(AppStrings.buttonRetry),
                      ),
                    ],
                  ),
                );
              }

              final logs = logsState.items;

              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: AppColors.mutedGray),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada log audit ditemukan.',
                        style: GoogleFonts.inter(
                          color: AppColors.textGray,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(paginatedAuditLogsProvider(filter));
                },
                color: AppColors.darkTeal,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: logs.length + (logsState.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == logs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CupertinoActivityIndicator(color: AppColors.darkTeal),
                        ),
                      );
                    }
                    final log = logs[index];
                    return AuditLogTile(
                      log: log,
                      onDetailTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.white,
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
          ),
        ),
      ],
    );
  }
}
