import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/widgets/audit_log_metadata_row.dart';

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

      String keyLabel = key.toString();
      if (keyLabel == 'balance') keyLabel = 'Saldo';
      if (keyLabel == 'is_active') keyLabel = 'Status Aktif';
      if (keyLabel == 'class') keyLabel = AppStrings.labelStudentClass;
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

/// Full detail bottom sheet for an audit log entry.
class AuditLogDetailSheet extends StatelessWidget {
  final AuditLog log;

  const AuditLogDetailSheet({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
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
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.gray400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                log.actionType.toString().replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTeal,
                ),
              ),
              const SizedBox(height: 16),
              AuditLogMetadataRow(
                label: 'Pelaksana',
                value: log.actorName,
              ),
              AuditLogMetadataRow(
                label: 'Tanggal & Waktu',
                value: DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(date),
              ),
              AuditLogMetadataRow(
                label: 'IP Address',
                value: log.ipAddress ?? '127.0.0.1',
              ),
              AuditLogMetadataRow(
                label: 'User Agent',
                value: log.userAgent ?? 'Unknown Client',
              ),
              const SizedBox(height: 24),
              Text(
                'Perubahan Data',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            color: AppColors.errorLightColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatToPlainText(log.oldValue),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.errorDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatToPlainText(log.newValue),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successDark,
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
  }
}
