import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_metadata_row.dart';

/// Normalize JSONB values from database (handle String/Map/List, doubles→ints).
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

/// Format value to readable plain text key-value format in natural Indonesian.
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
    if (normalized.isEmpty) return 'Tidak ada data perubahan spesifik';
    final buffer = StringBuffer();

    // Collect and format map entries
    final map = Map<String, dynamic>.from(normalized);

    // If both 'balance' and 'balance_after' exist with equal or redundant values, deduplicate
    if (map.containsKey('balance') && map.containsKey('balance_after')) {
      map.remove('balance_after');
    }
    if (map.containsKey('balance') && map.containsKey('balance_before')) {
      map.remove('balance_before');
    }

    map.forEach((key, val) {
      if (buffer.isNotEmpty) buffer.write('\n');

      String keyLabel = key.toString();
      switch (keyLabel) {
        case 'amount':
        case 'total_amount':
          keyLabel = 'Nominal';
          break;
        case 'balance':
          keyLabel = 'Saldo Kartu';
          break;
        case 'balance_before':
          keyLabel = 'Saldo Sebelum';
          break;
        case 'balance_after':
          keyLabel = 'Saldo Sesudah';
          break;
        case 'refund_amount':
          keyLabel = 'Pengembalian Dana';
          break;
        case 'method':
        case 'purchase_method':
          keyLabel = 'Metode Pembayaran';
          break;
        case 'status':
          keyLabel = 'Status';
          break;
        case 'is_active':
          keyLabel = 'Status Akun';
          break;
        case 'actor_name':
          keyLabel = 'Nama Pelaksana';
          break;
        case 'actor_role':
          keyLabel = 'Peran Pelaksana';
          break;
        case 'student_name':
          keyLabel = 'Nama Siswa';
          break;
        case 'canteen_name':
        case 'operator_name':
          keyLabel = 'Stan Kantin';
          break;
        case 'rfid_uid':
          keyLabel = 'UID Kartu RFID';
          break;
        case 'daily_limit':
          keyLabel = 'Batas Jajan Harian';
          break;
        case 'desc':
        case 'description':
          keyLabel = 'Keterangan';
          break;
        case 'reason':
          keyLabel = 'Alasan';
          break;
        case 'notes':
          keyLabel = 'Catatan';
          break;
        case 'actual_cash':
        case 'physical_cash':
          keyLabel = 'Uang Fisik Kasir';
          break;
        case 'system_cash':
        case 'expected_cash':
          keyLabel = 'Hitungan Sistem';
          break;
        case 'discrepancy':
        case 'variance':
          keyLabel = 'Selisih Kas';
          break;
        case 'officer_name':
          keyLabel = 'Petugas Keuangan';
          break;
        case 'class':
        case 'rombel':
          keyLabel = AppStrings.labelStudentClass;
          break;
        case 'full_name':
        case 'name':
          keyLabel = 'Nama';
          break;
        case 'username':
          keyLabel = 'Username';
          break;
        case 'email':
          keyLabel = 'Email';
          break;
        case 'phone_number':
        case 'parent_phone':
          keyLabel = 'No. Telepon';
          break;
        case 'password':
          keyLabel = 'Kata Sandi';
          break;
        case 'pin':
          keyLabel = 'PIN Transaksi';
          break;
        case 'price':
          keyLabel = 'Harga';
          break;
        case 'category':
          keyLabel = 'Kategori';
          break;
        case 'imported_count':
          keyLabel = 'Jumlah Diimpor';
          break;
        case 'nisn':
          keyLabel = 'NISN';
          break;
        case 'gender':
          keyLabel = 'Jenis Kelamin';
          break;
        default:
          keyLabel = keyLabel.replaceAll('_', ' ');
          if (keyLabel.isNotEmpty) {
            keyLabel = '${keyLabel[0].toUpperCase()}${keyLabel.substring(1)}';
          }
      }

      String valStr = val?.toString() ?? '-';

      // Format monetary numbers
      if (key == 'balance' ||
          key == 'balance_before' ||
          key == 'balance_after' ||
          key == 'price' ||
          key == 'amount' ||
          key == 'total_amount' ||
          key == 'refund_amount' ||
          key == 'actual_cash' ||
          key == 'physical_cash' ||
          key == 'system_cash' ||
          key == 'expected_cash' ||
          key == 'discrepancy' ||
          key == 'variance') {
        final double? numVal = double.tryParse(val.toString());
        if (numVal != null) {
          valStr = CurrencyFormatter.format(numVal);
        }
      } else if (key == 'is_active') {
        valStr = (val == true || val == 'true') ? 'Aktif' : 'Nonaktif / Dibekukan';
      } else if (key == 'actor_role') {
        final roleVal = val.toString().toLowerCase();
        switch (roleVal) {
          case 'petugas_keuangan':
            valStr = 'Petugas Keuangan';
            break;
          case 'petugas_kantin':
            valStr = 'Kasir Kantin';
            break;
          case 'student':
            valStr = 'Siswa';
            break;
          case 'parent':
            valStr = 'Orang Tua';
            break;
          case 'admin':
          case 'super_admin':
            valStr = 'Administrator';
            break;
        }
      } else if (key == 'method' || key == 'purchase_method') {
        final mVal = val.toString().toLowerCase();
        if (mVal == 'cash') {
          valStr = 'Uang Tunai';
        } else if (mVal == 'qris') {
          valStr = 'QRIS Dinamis';
        } else if (mVal == 'rfid' || mVal == 'nfc_rfid') {
          valStr = 'Tap Kartu RFID';
        } else if (mVal == 'app' || mVal == 'app_order') {
          valStr = 'Aplikasi Siswa';
        }
      } else if (key == 'status') {
        final sVal = val.toString().toLowerCase();
        if (sVal == 'success') valStr = 'Sukses';
        if (sVal == 'pending') valStr = 'Menunggu';
        if (sVal == 'refunded') valStr = 'Dikembalikan (Refund)';
        if (sVal == 'cancelled' || sVal == 'canceled') valStr = 'Dibatalkan';
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

/// Full detail bottom sheet for an audit log entry.
class AuditLogDetailSheet extends StatelessWidget {
  final AuditLog log;

  const AuditLogDetailSheet({super.key, required this.log});

  static void show(BuildContext context, AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AuditLogDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = log.createdAt?.toLocal() ?? DateTime.now();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: context.dividerCol, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top grab handle pill
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: context.dividerCol,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Badge + Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.doc_text_search,
                              color: Nebula.teal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    log.actionTypeDisplay,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log.displayTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: context.textSecondary, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: context.dividerCol, thickness: 0.6),
                      const SizedBox(height: 16),

                      // Metadata Rows
                      AuditLogMetadataRow(
                        label: 'Ringkasan',
                        value: log.displaySubtitle,
                      ),
                      AuditLogMetadataRow(
                        label: 'Pelaksana',
                        value: '${log.actorName} (${log.actorRoleDisplay})',
                      ),
                      AuditLogMetadataRow(
                        label: 'Tanggal & Waktu',
                        value: AppDateFormatter.formatDateWithTimeSeconds(date),
                      ),
                      AuditLogMetadataRow(
                        label: 'Alamat IP',
                        value: (log.ipAddress != null && log.ipAddress!.isNotEmpty)
                            ? log.ipAddress!
                            : '127.0.0.1 (Lokal)',
                      ),
                      AuditLogMetadataRow(
                        label: 'Perangkat (User Agent)',
                        value: (log.userAgent != null && log.userAgent!.isNotEmpty)
                            ? log.userAgent!
                            : 'Klien Web Aplikasi',
                      ),
                      const SizedBox(height: 22),

                      // Perubahan Data (Sebelum vs Sesudah)
                      Text(
                        'Rincian Data Perubahan',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SEBELUM
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SEBELUM',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: context.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Nebula.rose.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Nebula.rose.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    _formatToPlainText(log.oldValue),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Nebula.rose,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // SESUDAH
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SESUDAH',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: context.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.25)),
                                  ),
                                  child: Text(
                                    _formatToPlainText(log.newValue),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Nebula.teal,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Button Tutup
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Tutup Rincian',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
