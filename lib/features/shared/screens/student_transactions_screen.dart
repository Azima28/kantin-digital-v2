import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';

class StudentTransactionsScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String title;
  final Color primaryColor;
  final Color accentColor;

  const StudentTransactionsScreen({
    super.key,
    required this.studentId,
    this.title = 'Semua Transaksi',
    this.primaryColor = Nebula.teal,
    this.accentColor = Nebula.amber,
  });

  @override
  ConsumerState<StudentTransactionsScreen> createState() =>
      _StudentTransactionsScreenState();
}

class _StudentTransactionsScreenState
    extends ConsumerState<StudentTransactionsScreen> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;


  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/student/transactions', queryParams: {
        if (widget.studentId.isNotEmpty) 'student_id': widget.studentId,
        'limit': '50',
      });
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['items'] is List) {
          return List<Map<String, dynamic>>.from(data['items'] as List);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  void _refresh() {
    setState(() {
      _transactionsFuture = _fetchTransactions();
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> txs) {
    return txs.where((tx) {
      final createdAt = tx['created_at'];
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

  List<int> _availableYears(List<Map<String, dynamic>> txs) {
    final years = <int>{DateTime.now().year};
    for (final tx in txs) {
      final createdAt = tx['created_at'];
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
        future: _transactionsFuture,
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
                  '${AppStrings.labelFailed} memuat transaksi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Nebula.rose),
                ),
              ),
            );
          }

          final txs = snapshot.data ?? [];
          final filtered = _applyFilters(txs);
          final years = _availableYears(txs);

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
                          '${filtered.length} dari ${txs.length} transaksi',
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
                            label: Text('Reset'),
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
                    ? Center(
                        child: Text(
                          txs.isEmpty
                              ? AppStrings.noTransactions
                              : 'Tidak ada transaksi sesuai filter.',
                          style: GoogleFonts.inter(color: context.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        color: widget.primaryColor,
                        onRefresh: () async => _refresh(),
                        child: Builder(
                          builder: (context) {
                            final List<dynamic> listItems = [];
                            DateTime? lastDate;
                            for (final tx in filtered) {
                              final createdAt = tx['created_at'];
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
                              listItems.add(tx);
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
                                  child: _buildTransactionTile(item as Map<String, dynamic>),
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
            labelBuilder: (month) =>
                DateFormat.MMMM('id_ID').format(DateTime(2024, month)),
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

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = (tx['total_amount'] as num?)?.toInt() ??
        (double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0).toInt();
    final type = tx['type']?.toString() ?? 'purchase';
    final status = tx['status']?.toString() ?? 'success';
    final isTopup = type == 'topup';
    final canteenData = tx['canteen_operators'];
    final canteen = tx['canteen_name']?.toString() ??
        (canteenData is Map<String, dynamic>
            ? canteenData['canteen_name']?.toString()
            : null) ??
        (isTopup ? 'Top-Up Saldo' : 'Stan Kantin');
    final date = tx['created_at'] != null
        ? DateTime.tryParse(tx['created_at'].toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();
    final String? imageUrl = tx['image_url']?.toString();

    final opTx = OperatorTransaction.fromSiswaJson(tx);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showTransactionDetailSheet(context, ref, opTx),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Avatar / Thumbnail
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildFallbackAvatar(isTopup),
                    ),
                  )
                else
                  _buildFallbackAvatar(isTopup),
                const SizedBox(width: 12),

                // Middle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTopup ? 'Top-up Saldo' : canteen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date)} WIB • ${isTopup ? "Koperasi" : (tx['purchase_method'] == 'app' || tx['purchase_method'] == 'app_order' ? "Aplikasi" : "Tap Kartu")}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Amount & Status
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isTopup ? Nebula.teal : (status == 'refunded' ? Nebula.rose : context.textPrimary),
                      ),
                    ),
                    if (status != 'success')
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Nebula.rose.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Nebula.rose,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(bool isTopup) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: isTopup
          ? Nebula.amber.withValues(alpha: 0.12)
          : widget.primaryColor.withValues(alpha: 0.1),
      child: Icon(
        isTopup ? CupertinoIcons.creditcard : Icons.shopping_bag_outlined,
        color: isTopup ? widget.accentColor : widget.primaryColor,
        size: 18,
      ),
    );
  }
}
