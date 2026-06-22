import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
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
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Audit Log Explorer',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle & Dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemantauan sistem dan riwayat aktivitas secara real-time.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 16),
                AuditLogActionFilter(
                  selectedAction: _selectedAction,
                  actions: _actions,
                  onChanged: (val) {
                    setState(() {
                      _selectedAction = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Timeline logs
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

                if (filtered.isEmpty) {
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
                    ref.invalidate(adminAuditLogsProvider);
                  },
                  color: AppColors.darkTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final log = filtered[index];
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
              loading: () => const Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.darkTeal,
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.errorRed),
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
      ),
    );
  }
}
