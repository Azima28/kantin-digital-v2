import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class StudentTransactionsScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String title;
  final Color primaryColor;
  final Color accentColor;

  const StudentTransactionsScreen({
    super.key,
    required this.studentId,
    this.title = 'Semua Transaksi',
    this.primaryColor = const Color(0xFF003434),
    this.accentColor = const Color(0xFF904D00),
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

  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);
  static const Color textGray = Color(0xFF6F7978);

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    final client = ref.read(supabaseClientProvider);
    final List<dynamic> txs = await client
        .from('transactions')
        .select(
          'id, total_amount, type, status, created_at, canteen_operators(canteen_name)',
        )
        .eq('student_id', widget.studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(txs);
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
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.left_chevron, color: widget.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.beVietnamPro(
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat transaksi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(color: dangerRed),
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
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: textGray,
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
                              textStyle: GoogleFonts.beVietnamPro(
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
                              ? 'Belum ada transaksi.'
                              : 'Tidak ada transaksi sesuai filter.',
                          style: GoogleFonts.beVietnamPro(color: textGray),
                        ),
                      )
                    : RefreshIndicator(
                        color: widget.primaryColor,
                        onRefresh: () async => _refresh(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildTransactionTile(filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
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
                : DateFormat('dd MMM yyyy').format(_selectedDate!),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E2E1)),
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
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1C1B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E2E1)),
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
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B1C1B),
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
    final amount =
        double.tryParse(tx['total_amount']?.toString() ?? '0') ?? 0.0;
    final type = tx['type']?.toString() ?? 'purchase';
    final status = tx['status']?.toString() ?? 'success';
    final isTopup = type == 'topup';
    final canteenData = tx['canteen_operators'];
    final canteen = canteenData is Map<String, dynamic>
        ? canteenData['canteen_name']?.toString() ?? 'Stan Kantin'
        : 'Stan Kantin';
    final date = tx['created_at'] != null
        ? DateTime.tryParse(tx['created_at'].toString())?.toLocal() ??
              DateTime.now()
        : DateTime.now();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: isTopup
            ? const Color(0xFFFFDCC3)
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
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date),
        style: GoogleFonts.beVietnamPro(fontSize: 11, color: textGray),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isTopup ? successGreen : dangerRed,
            ),
          ),
          if (status != 'success')
            Text(
              status.toUpperCase(),
              style: GoogleFonts.beVietnamPro(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: dangerRed,
              ),
            ),
        ],
      ),
    );
  }
}
