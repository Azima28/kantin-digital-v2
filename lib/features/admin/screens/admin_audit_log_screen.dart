import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final client = ref.read(supabaseClientProvider);

      final List<dynamic> res = await client
          .from('audit_logs')
          .select(
            'id, actor_id, actor_name, action_type, description, target_id, old_value, new_value, ip_address, user_agent, created_at',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    });

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
    'Balance Correction',
    'Card Registration',
    'System Settings',
  ];

  /// Normalizes JSON data for display. Handles:
  /// - String input (parses JSON if possible)
  /// - Map/List input (recursively normalizes)
  /// - Doubles that are whole numbers → converts to int
  dynamic _normalizeJsonValue(dynamic value) {
    if (value == null) return null;

    // If Supabase returns JSONB as a String, try parsing it first
    if (value is String) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return value; // not JSON, return as-is
      }
    }

    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), _normalizeJsonValue(v)),
      );
    } else if (value is List) {
      return value.map(_normalizeJsonValue).toList();
    } else if (value is double && value == value.toInt()) {
      return value.toInt();
    }
    return value;
  }

  /// Formats a normalized JSON value as a pretty-printed JSON string.
  String _formatJson(dynamic value) {
    try {
      final normalized = _normalizeJsonValue(value);
      if (normalized == null) return '{}';
      return const JsonEncoder.withIndent('  ').convert(normalized);
    } catch (_) {
      // Fallback: return raw toString if encoding fails
      return value?.toString() ?? '{}';
    }
  }

  String _mapActionTypeToFilter(String filter) {
    switch (filter) {
      case 'Balance Correction':
        return 'KOREKSI_SALDO';
      case 'Card Registration':
        return 'REGISTRASI_KARTU';
      case 'System Settings':
        return 'SETELAN_SISTEM';
      default:
        return filter;
    }
  }

  void _showLogDetailBottomSheet(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final date = log['created_at'] != null
            ? DateTime.parse(log['created_at']).toLocal()
            : DateTime.now();

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
                    log['action_type'].toString().replaceAll('_', ' '),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003434),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata cards
                  _buildMetadataRow('Pelaksana', log['actor_name']),
                  _buildMetadataRow(
                    'Tanggal & Waktu',
                    DateFormat('dd MMM yyyy, HH:mm:ss').format(date),
                  ),
                  _buildMetadataRow(
                    'IP Address',
                    log['ip_address'] ?? '127.0.0.1',
                  ),
                  _buildMetadataRow(
                    'User Agent',
                    log['user_agent'] ?? 'Unknown Client',
                  ),
                  const SizedBox(height: 24),

                  // JSON Diff Header
                  Text(
                    'Perubahan Data (JSON Diff)',
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
                              'BEFORE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatJson(log['old_value']),
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: Color(0xFF93000A),
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
                              'AFTER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF9EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatJson(log['new_value']),
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: Color(0xFF005026),
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

  Widget _buildMetadataRow(String label, dynamic value) {
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
              (value ?? '-').toString(),
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
                      .where((l) => l['action_type'] == dbActionKey)
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
                      final String actionType = log['action_type'] ?? '';
                      final String desc = log['description'] ?? '';
                      final String actor = log['actor_name'] ?? 'System';
                      final date = log['created_at'] != null
                          ? DateTime.parse(log['created_at']).toLocal()
                          : DateTime.now();

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
