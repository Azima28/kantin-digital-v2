import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Normalize JSONB values from Supabase (handle String/Map/List, doubles→ints).
dynamic _normalizeJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    try {
      value = jsonDecode(value);
    } catch (_) {
      return value;
    }
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _normalizeJsonValue(v)));
  } else if (value is List) {
    return value.map(_normalizeJsonValue).toList();
  } else if (value is double && value == value.toInt()) {
    return value.toInt();
  }
  return value;
}

/// Format value to readable plain text key-value format.
String _formatToPlainText(dynamic value) {
  if (value == null) return '-';
  dynamic normalized;
  try {
    normalized = _normalizeJsonValue(value);
  } catch (_) {
    normalized = value;
  }
  if (normalized == null) return '-';

  if (normalized is Map) {
    if (normalized.isEmpty) return '-';
    final buffer = StringBuffer();
    normalized.forEach((key, val) {
      if (buffer.isNotEmpty) buffer.write('\n');

      // Make key user-friendly
      String keyLabel = key.toString();
      if (keyLabel == 'balance') keyLabel = 'Saldo';
      if (keyLabel == 'is_active') keyLabel = 'Status Aktif';
      if (keyLabel == 'class') keyLabel = 'Kelas';
      if (keyLabel == 'rfid_uid') keyLabel = 'RFID UID';
      if (keyLabel == 'imported_count') keyLabel = 'Jumlah Diimport';
      if (keyLabel == 'name') keyLabel = 'Nama';
      if (keyLabel == 'price') keyLabel = 'Harga';
      if (keyLabel == 'category') keyLabel = 'Kategori';
      if (keyLabel == 'relation') keyLabel = 'Hubungan';
      if (keyLabel == 'phone_number') keyLabel = 'No. Telepon';
      if (keyLabel == 'email') keyLabel = 'Email';
      if (keyLabel == 'username') keyLabel = 'Username';
      if (keyLabel == 'password') keyLabel = 'Kata Sandi';
      if (keyLabel == 'nisn') keyLabel = 'NISN';

      // Format value
      String valStr = val?.toString() ?? '-';
      if (key == 'balance' || key == 'price' || key == 'amount') {
        final double? numVal = double.tryParse(val.toString());
        if (numVal != null) {
          valStr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(numVal);
        }
      } else if (key == 'is_active') {
        valStr = val == true ? 'Aktif' : 'Nonaktif';
      }

      buffer.write('$keyLabel: $valStr');
    });
    return buffer.toString();
  } else if (normalized is List) {
    if (normalized.isEmpty) return '-';
    return normalized.join(', ');
  }

  return normalized.toString();
}

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  String _selectedAction = 'All Actions';

  final List<String> _actions = [
    'All Actions',
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

  void _showLogDetailBottomSheet(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final date = log.createdAt?.toLocal() ?? DateTime.now();

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // iOS Grab Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFC8C8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detail Header
                  Text(
                    log.actionType.toString().replaceAll('_', ' '),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003434),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata cards
                  _buildMetadataRow('Pelaksana', log.actorName),
                  _buildMetadataRow(
                    'Tanggal & Waktu',
                    DateFormat('dd MMM yyyy, HH:mm:ss').format(date),
                  ),
                  _buildMetadataRow('IP Address', log.ipAddress ?? '127.0.0.1'),
                  _buildMetadataRow(
                    'User Agent',
                    log.userAgent ?? 'Unknown Client',
                  ),
                  const SizedBox(height: 24),

                  // JSON Diff Header
                  Text(
                    'Perubahan Data',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B1C1B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // JSON Diff Boxes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Old Value
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SEBELUM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatToPlainText(log.oldValue),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF93000A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // New Value
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SESUDAH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF9EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatToPlainText(log.newValue),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF005026),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3F4848),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B1C1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    const Color primaryTeal = Color(0xFF003434);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Audit Log Explorer',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
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
                  'Real-time system monitoring and activity history.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: const Color(0xFF3F4848),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEDEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAction,
                      isExpanded: true,
                      icon: const Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: primaryTeal,
                      ),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1B),
                      ),
                      items: _actions.map((a) {
                        return DropdownMenuItem(value: a, child: Text(a));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAction = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Timeline logs
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                // Filter locally
                var filtered = logs;

                if (_selectedAction != 'All Actions') {
                  final dbActionKey = _mapActionTypeToFilter(_selectedAction);
                  filtered = filtered
                      .where((l) => l.actionType == dbActionKey)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada log audit ditemukan.',
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.textGray,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminAuditLogsProvider);
                  },
                  color: primaryTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final log = filtered[index];
                      final String actionType = log.actionType;
                      final String desc = log.description;
                      final String actor = log.actorName;
                      final date = log.createdAt?.toLocal() ?? DateTime.now();

                      // Format time relative
                      final diff = DateTime.now().difference(date);
                      String timeStr = 'Just now';
                      if (diff.inDays > 0) {
                        timeStr = '${diff.inDays} days ago';
                      } else if (diff.inHours > 0) {
                        timeStr = '${diff.inHours} hours ago';
                      } else if (diff.inMinutes > 0) {
                        timeStr = '${diff.inMinutes} mins ago';
                      }

                      Color actionColor = primaryTeal;
                      IconData actionIcon = CupertinoIcons.settings;
                      if (actionType == 'KOREKSI_SALDO') {
                        actionColor = const Color(0xFFBA1A1A);
                        actionIcon =
                            CupertinoIcons.exclamationmark_triangle_fill;
                      } else if (actionType == 'REGISTRASI_KARTU') {
                        actionColor = const Color(0xFF003718);
                        actionIcon = CupertinoIcons.creditcard_fill;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Badge
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: actionColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                actionIcon,
                                color: actionColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Main log info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: actionColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                          child: Text(
                                            actionType.replaceAll('_', ' '),
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: actionColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    desc,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pelaksana: $actor',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _showLogDetailBottomSheet(log),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Detail Log Perubahan',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          CupertinoIcons.arrow_right,
                                          size: 14,
                                          color: primaryTeal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CupertinoActivityIndicator(color: primaryTeal),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
