import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';

class OfficerActivitiesScreen extends ConsumerStatefulWidget {
  final String officerId;
  final String actorName;
  final String title;
  final Color primaryColor;
  final Color accentColor;

  const OfficerActivitiesScreen({
    super.key,
    required this.officerId,
    required this.actorName,
    this.title = 'Semua Aktivitas',
    this.primaryColor = Nebula.teal,
    this.accentColor = Nebula.amber,
  });

  @override
  ConsumerState<OfficerActivitiesScreen> createState() => _OfficerActivitiesScreenState();
}

class _OfficerActivitiesScreenState extends ConsumerState<OfficerActivitiesScreen> {
  late Future<List<Map<String, dynamic>>> _activitiesFuture;
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;


  @override
  void initState() {
    super.initState();
    _activitiesFuture = _fetchActivities();
  }

  Future<List<Map<String, dynamic>>> _fetchActivities() async {
    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. If officerId is provided, first try getting ledger details which has rich journal entries
      if (widget.officerId.isNotEmpty) {
        final ledgerRes = await apiClient.get('/admin/finance-officers/${widget.officerId}/ledger');
        if (ledgerRes.success && ledgerRes.data != null) {
          final data = Map<String, dynamic>.from(ledgerRes.data as Map);
          final recent = data['recent_journals'];
          if (recent is List && recent.isNotEmpty) {
            return List<Map<String, dynamic>>.from(
              recent.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
        }
      }

      // 2. Fallback to /pos/sales-history or /admin/audit-logs
      final response = await apiClient.get('/pos/sales-history', queryParams: {
        if (widget.officerId.isNotEmpty) 'operator_id': widget.officerId,
        'limit': '50',
      });
      if (response.success && response.data != null) {
        final raw = response.data;
        if (raw is List && raw.isNotEmpty) {
          return List<Map<String, dynamic>>.from(
            raw.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }

      // 3. Fallback to audit logs
      final auditRes = await apiClient.get('/admin/audit-logs', queryParams: {
        'limit': '50',
      });
      if (auditRes.success && auditRes.data != null) {
        final raw = auditRes.data;
        if (raw is List) {
          return List<Map<String, dynamic>>.from(
            raw.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }

      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  void _refresh() {
    setState(() {
      _activitiesFuture = _fetchActivities();
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> logs) {
    return logs.where((log) {
      final createdAt = log['created_at'];
      if (createdAt == null) return false;
      final date = DateTime.tryParse(createdAt.toString())?.toLocal();
      if (date == null) return false;

      if (_selectedDate != null &&
          (date.year != _selectedDate!.year ||
              date.month != _selectedDate!.month ||
              date.day != _selectedDate!.day)) {
        return false;
      }

      if (_selectedMonth != null && date.month != _selectedMonth) {
        return false;
      }

      if (_selectedYear != null && date.year != _selectedYear) {
        return false;
      }

      return true;
    }).toList();
  }

  List<int> _availableYears(List<Map<String, dynamic>> logs) {
    final years = <int>{DateTime.now().year};
    for (final log in logs) {
      final createdAt = log['created_at'];
      final date = createdAt == null
          ? null
          : DateTime.tryParse(createdAt.toString())?.toLocal();
      if (date != null) years.add(date.year);
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: widget.primaryColor,
                  onPrimary: Colors.white,
                  surface: context.isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSurface: context.isDark ? Colors.white : const Color(0xFF0F172A),
                  surfaceTint: Colors.transparent,
                ),
            dialogTheme: DialogThemeData(
              backgroundColor: context.isDark ? const Color(0xFF1E293B) : Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: context.isDark ? const Color(0xFF1E293B) : Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: context.isDark ? const Color(0xFF1E293B) : Colors.white,
              headerForegroundColor: context.isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedDate = null;
      _selectedMonth = null;
      _selectedYear = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        leading: IconButton(
          icon: Icon(CupertinoIcons.left_chevron, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: Icon(CupertinoIcons.refresh, color: context.textPrimary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonListTile(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${AppStrings.labelFailed} memuat aktivitas: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Nebula.rose),
                ),
              ),
            );
          }

          final logs = snapshot.data ?? [];
          final filtered = _applyFilters(logs);
          final years = _availableYears(logs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    _buildFilters(years),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${filtered.length} dari ${logs.length} aktivitas',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDate != null ||
                            _selectedMonth != null ||
                            _selectedYear != null)
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(CupertinoIcons.clear, size: 14),
                            label: const Text('Reset'),
                            style: TextButton.styleFrom(
                              foregroundColor: widget.primaryColor,
                              textStyle: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyStateWidget(
                        message: AppStrings.labelNoData,
                      )
                    : RefreshIndicator(
                        color: widget.primaryColor,
                        onRefresh: () async => _refresh(),
                        child: Builder(
                          builder: (context) {
                            final List<dynamic> listItems = [];
                            DateTime? lastDate;
                            for (final log in filtered) {
                              final createdAt = log['created_at'];
                              final date = createdAt == null
                                  ? null
                                  : DateTime.tryParse(createdAt.toString())?.toLocal();
                              if (date != null) {
                                if (lastDate == null ||
                                    lastDate.year != date.year ||
                                    lastDate.month != date.month ||
                                    lastDate.day != date.day) {
                                  final String dateHeaderStr = AppDateFormatter.formatDayFullDate(date);
                                  listItems.add(dateHeaderStr);
                                  lastDate = date;
                                }
                              }
                              listItems.add(log);
                            }

                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: listItems.length,
                              itemBuilder: (context, index) {
                                final item = listItems[index];
                                if (item is String) {
                                  return _buildDateHeader(item);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildActivityTile(item as Map<String, dynamic>),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: widget.primaryColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: context.dividerCol,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<int> years) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final children = [
          _filterButton(
            icon: CupertinoIcons.calendar,
            label: _selectedDate == null
                ? 'Tanggal'
                : DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!),
            onTap: _pickDate,
          ),
          _filterDropdown<int>(
            value: _selectedMonth,
            hint: 'Bulan',
            items: List.generate(12, (i) => i + 1),
            labelBuilder: (month) => DateFormat.MMMM('id_ID').format(DateTime(2024, month)),
            onChanged: (value) {
              setState(() {
                _selectedMonth = value;
                if (_selectedDate != null && value != _selectedDate!.month) {
                  _selectedDate = null;
                }
              });
            },
          ),
          _filterDropdown<int>(
            value: _selectedYear,
            hint: 'Tahun',
            items: years,
            labelBuilder: (year) => year.toString(),
            onChanged: (value) {
              setState(() {
                _selectedYear = value;
                if (_selectedDate != null && value != _selectedDate!.year) {
                  _selectedDate = null;
                }
              });
            },
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              Row(children: [Expanded(child: children[0])]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: children[1]),
                  const SizedBox(width: 8),
                  Expanded(child: children[2]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 8),
            Expanded(child: children[1]),
            const SizedBox(width: 8),
            Expanded(child: children[2]),
          ],
        );
      },
    );
  }

  Widget _filterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerCol),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: widget.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T value) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          icon: Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: widget.primaryColor,
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> log) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Extract type / action_type
    String actionType = log['action_type']?.toString() ?? log['type']?.toString() ?? '';
    if (actionType.isEmpty) {
      actionType = 'TRANSAKSI';
    }

    // Extract amount
    final int amount = int.tryParse(log['amount']?.toString() ?? '') ??
        int.tryParse(log['total_amount']?.toString() ?? '') ??
        int.tryParse(log['refund_amount']?.toString() ?? '') ??
        0;

    // Extract target / related names
    final String targetName = log['target_name']?.toString() ??
        log['student_name']?.toString() ??
        log['canteen_name']?.toString() ??
        log['actor_name']?.toString() ??
        '';

    final String notes = log['notes']?.toString() ?? '';
    String desc = log['description']?.toString() ?? '';

    final String category = log['category']?.toString() ?? '';
    final bool isInflow = category == 'INFLOW' || actionType == 'TOPUP' || actionType == 'topup' || actionType.contains('TOPUP');
    final bool isOutflow = category == 'OUTFLOW' || actionType == 'WITHDRAWAL' || actionType == 'withdrawal' || actionType.contains('PAYOUT') || actionType.contains('WITHDRAWAL');

    if (desc.isEmpty) {
      if (notes.isNotEmpty) {
        desc = notes;
      } else if (isInflow) {
        desc = targetName.isNotEmpty ? 'Top-Up saldo untuk $targetName' : 'Setoran Top-Up Tunai';
      } else if (isOutflow) {
        desc = targetName.isNotEmpty ? 'Pencairan Kas Stan $targetName' : 'Penarikan Kas Stan (Payout)';
      } else if (targetName.isNotEmpty) {
        desc = 'Transaksi dengan $targetName';
      } else {
        desc = 'Mutasi Kas Petugas';
      }
    }

    // Human readable action label
    String displayType = actionType.replaceAll('_', ' ');
    if (displayType == 'WITHDRAWAL' || displayType == 'withdrawal') {
      displayType = 'TARIK KAS STAN';
    } else if (displayType == 'TOPUP' || displayType == 'topup') {
      displayType = 'TOP-UP SALDO';
    } else if (displayType == 'KOREKSI SALDO' || displayType.contains('KOREKSI')) {
      displayType = 'PENYESUAIAN KAS';
    }

    final date = log['created_at'] != null
        ? DateTime.tryParse(log['created_at'].toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    IconData logIcon = CupertinoIcons.doc_text_fill;
    Color logColor = widget.primaryColor;
    String sign = '';

    if (isInflow) {
      logIcon = CupertinoIcons.arrow_down_circle_fill;
      logColor = Nebula.teal;
      sign = '+';
    } else if (isOutflow) {
      logIcon = CupertinoIcons.arrow_up_circle_fill;
      logColor = Nebula.rose;
      sign = '-';
    } else if (actionType.contains('BATAL') || actionType.contains('REFUND')) {
      logIcon = CupertinoIcons.arrow_counterclockwise_circle_fill;
      logColor = Nebula.rose;
    } else if (actionType.contains('REGISTRASI')) {
      logIcon = CupertinoIcons.creditcard_fill;
      logColor = Nebula.teal;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dividerCol, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: logColor.withValues(alpha: 0.12),
            child: Icon(logIcon, color: logColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        displayType,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: logColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm', 'id_ID').format(date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (amount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$sign${fmt.format(amount)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: logColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
