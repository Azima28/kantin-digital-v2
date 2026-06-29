import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/operator_transaction.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

class StudentTransactionsScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String title;
  final Color primaryColor;
  final Color accentColor;

  const StudentTransactionsScreen({
    super.key,
    required this.studentId,
    this.title = 'Semua Transaksi',
    this.primaryColor = AppColors.darkTeal,
    this.accentColor = AppColors.darkOrange,
  });

  @override
  ConsumerState<StudentTransactionsScreen> createState() =>
      _StudentTransactionsScreenState();
}

class _StudentTransactionsScreenState
    extends ConsumerState<StudentTransactionsScreen> {
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final filter = _buildFilter();
      ref.read(paginatedTransactionsProvider(filter).notifier).loadNextPage();
    }
  }

  PaginatedTransactionsFilter _buildFilter() {
    DateTime? startDate;
    DateTime? endDate;

    if (_selectedDate != null) {
      startDate = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0);
      endDate = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, 23, 59, 59);
    } else if (_selectedMonth != null && _selectedYear != null) {
      startDate = DateTime(_selectedYear!, _selectedMonth!, 1, 0, 0, 0);
      endDate = DateTime(_selectedYear!, _selectedMonth! + 1, 1, 0, 0, 0)
          .subtract(const Duration(seconds: 1));
    } else if (_selectedYear != null) {
      startDate = DateTime(_selectedYear!, 1, 1, 0, 0, 0);
      endDate = DateTime(_selectedYear!, 12, 31, 23, 59, 59);
    }

    return PaginatedTransactionsFilter(
      studentId: widget.studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void _refresh() {
    final filter = _buildFilter();
    ref.read(paginatedTransactionsProvider(filter).notifier).loadFirstPage();
  }

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (i) => currentYear - i);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: widget.primaryColor),
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
    final filter = _buildFilter();
    final transactionsState = ref.watch(paginatedTransactionsProvider(filter));
    final years = _availableYears();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.left_chevron, color: widget.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: Icon(CupertinoIcons.refresh, color: widget.primaryColor),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
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
                      '${transactionsState.items.length} transaksi dimuat',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGray,
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
            child: () {
              if (transactionsState.isLoading) {
                return const Center(child: CupertinoActivityIndicator());
              }

              if (transactionsState.error != null &&
                  transactionsState.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${AppStrings.labelFailed} memuat transaksi: ${transactionsState.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  ),
                );
              }

              final txs = transactionsState.items;

              if (txs.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.noTransactions,
                    style: GoogleFonts.inter(color: AppColors.textGray),
                  ),
                );
              }

              return RefreshIndicator(
                color: widget.primaryColor,
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: txs.length +
                      (transactionsState.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == txs.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    return _buildTransactionTile(txs[index]);
                  },
                ),
              );
            }(),
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
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
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
                    color: AppColors.nearBlack,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
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
            color: AppColors.nearBlack,
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

  Widget _buildTransactionTile(OperatorTransaction tx) {
    final amount = tx.totalAmount;
    final type = tx.type ?? 'purchase';
    final status = tx.status ?? 'success';
    final isTopup = type == 'topup';
    final canteen = tx.canteenName ?? 'Stan Kantin';
    final date = tx.createdAt?.toLocal() ?? DateTime.now();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColors.white,
      leading: CircleAvatar(
        backgroundColor: isTopup
            ? AppColors.softOrange
            : widget.primaryColor.withValues(alpha: 0.1),
        child: Icon(
          isTopup ? CupertinoIcons.creditcard : Icons.shopping_bag,
          color: isTopup ? widget.accentColor : widget.primaryColor,
          size: 18,
        ),
      ),
      title: Text(
        isTopup ? 'Top-up Saldo' : canteen,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date)} WIB • ${isTopup ? "Koperasi" : (tx.purchaseMethod == 'app' ? "Aplikasi" : "Kasir")}',
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGray),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isTopup ? AppColors.successGreen : AppColors.error,
            ),
          ),
          if (status != 'success')
            Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}
