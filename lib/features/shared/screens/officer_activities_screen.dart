import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

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
    this.primaryColor = const Color(0xFF003434),
    this.accentColor = const Color(0xFF904D00),
  });

  @override
  ConsumerState<OfficerActivitiesScreen> createState() => _OfficerActivitiesScreenState();
}

class _OfficerActivitiesScreenState extends ConsumerState<OfficerActivitiesScreen> {
  late Future<List<Map<String, dynamic>>> _activitiesFuture;
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;

  static const Color successGreen = Color(0xFF006A35);
  static const Color textGray = Color(0xFF6F7978);

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _fetchActivities();
  }

  Future<List<Map<String, dynamic>>> _fetchActivities() async {
    final client = ref.read(supabaseClientProvider);
    final List<dynamic> logs = await client
        .from('audit_logs')
        .select('id, action_type, description, created_at')
        .or('actor_id.eq.${widget.officerId},actor_name.eq.${widget.actorName}')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(logs);
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
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: widget.primaryColor),
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
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat aktivitas: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(color: const Color(0xFFBA1A1A)),
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
                          logs.isEmpty
                              ? 'Belum ada aktivitas transaksi manual.'
                              : 'Tidak ada aktivitas sesuai filter.',
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
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildActivityTile(filtered[index]),
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

  Widget _buildActivityTile(Map<String, dynamic> log) {
    final String actionType = log['action_type']?.toString() ?? '';
    final String desc = log['description']?.toString() ?? '';
    final date = log['created_at'] != null
        ? DateTime.tryParse(log['created_at'].toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    IconData logIcon = CupertinoIcons.doc_text;
    Color logColor = widget.primaryColor;
    if (actionType.contains('KOREKSI')) {
      logIcon = CupertinoIcons.refresh;
      logColor = widget.accentColor;
    } else if (actionType.contains('REGISTRASI')) {
      logIcon = CupertinoIcons.creditcard;
      logColor = successGreen;
    }

    return Container(
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
          CircleAvatar(
            radius: 18,
            backgroundColor: logColor.withValues(alpha: 0.1),
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
                    Text(
                      actionType.replaceAll('_', ' '),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: logColor,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: textGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B1C1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
