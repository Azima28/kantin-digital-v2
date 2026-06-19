import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/parent/providers/parent_providers.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ParentDashboardScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  int _currentIndex = 0; // Tab index: 0=Beranda, 1=Analisis, 2=Riwayat, 3=Pengaturan

  // Tab 1 (Analisis) State
  String _selectedPeriod = 'Minggu Ini'; // 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Kustom'
  DateTimeRange? _customDateRange;

  // Tab 2 (Riwayat) State
  final _searchController = TextEditingController();
  String _historyTypeFilter = 'Semua'; // 'Semua', 'Belanja', 'Top-up'
  DateTimeRange? _historyDateRange;

  // Tab 3 (Pengaturan) State
  bool _settingsLoaded = false;
  bool _dailyLimitActive = false;
  final _limitController = TextEditingController();
  bool _cardFrozen = false;
  bool _waAlertsActive = false;
  final _phoneController = TextEditingController();
  bool _isSavingSettings = false;

  @override
  void dispose() {
    _searchController.dispose();
    _limitController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initSettingsIfRequired(Student student) {
    if (_settingsLoaded) return;

    final double? dailyLimit = student.dailyLimit;
    final bool isActive = student.isActive;
    final bool waEnabled = student.waNotificationsEnabled;
    final String? parentPhone = student.parentPhone;

    _dailyLimitActive = dailyLimit != null && dailyLimit > 0;
    _limitController.text = dailyLimit != null ? dailyLimit.toInt().toString() : '';
    _cardFrozen = !isActive;
    _waAlertsActive = waEnabled;
    _phoneController.text = parentPhone ?? '';

    _settingsLoaded = true;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSavingSettings = true;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final ParentDashboardData? oldData = ref.read(parentDashboardProvider(widget.studentId)).value;
      final bool oldIsActive = oldData?.student.isActive ?? true;

      final double? newLimit = _dailyLimitActive 
          ? double.tryParse(_limitController.text.trim()) ?? 0.0
          : null;
      final bool newIsActive = !_cardFrozen;
      final bool newWaEnabled = _waAlertsActive;
      final String newParentPhone = _phoneController.text.trim();

      await client.from('students').update({
        'daily_limit': newLimit,
        'is_active': newIsActive,
        'wa_notifications_enabled': newWaEnabled,
        'parent_phone': newParentPhone.isNotEmpty ? newParentPhone : null,
      }).eq('id', widget.studentId);

      // Audit Log for freeze/unfreeze card by Parent
      if (oldIsActive != newIsActive) {
        try {
          final authProfile = ref.read(authNotifierProvider).profile;
          final actorName = authProfile?['full_name'] ?? 'Orang Tua';
          final actorId = authProfile?['id'];

          await client.from('audit_logs').insert({
            'actor_id': actorId,
            'actor_name': actorName,
            'action_type': newIsActive ? 'AKTIFKAN_KARTU' : 'BLOKIR_KARTU',
            'description': 'Orang Tua ${newIsActive ? "mengaktifkan" : "membekukan"} kartu RFID anak: ${oldData?.profile.fullName ?? widget.studentId}',
            'target_id': widget.studentId,
            'old_value': {'is_active': oldIsActive},
            'new_value': {'is_active': newIsActive},
          });
        } catch (_) {}
      }

      ref.invalidate(parentDashboardProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan!'),
            backgroundColor: Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengaturan: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
      }
    }
  }

  // Helper calculation methods
  double _getTodaySpending(List<OperatorTransaction> transactions) {
    final now = DateTime.now().toLocal();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    double sum = 0.0;
    for (var tx in transactions) {
      if (tx.status == 'success' && tx.type == 'purchase') {
        final txDateStr = tx.createdAt != null 
            ? tx.createdAt!.toLocal().toIso8601String().substring(0, 10)
            : '';
        if (txDateStr == todayStr) {
          sum += tx.totalAmount;
        }
      }
    }
    return sum;
  }

  List<OperatorTransaction> _filterTransactionsByPeriod(List<OperatorTransaction> transactions, String period) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    DateTime start;
    DateTime end = today.add(const Duration(days: 1)); // end of today

    if (period == 'Hari Ini') {
      start = today;
    } else if (period == 'Minggu Ini') {
      int daysToSubtract = today.weekday - 1;
      start = today.subtract(Duration(days: daysToSubtract));
    } else if (period == 'Bulan Ini') {
      start = DateTime(today.year, today.month, 1);
    } else {
      // Kustom
      if (_customDateRange != null) {
        start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day).add(const Duration(days: 1));
      } else {
        start = today.subtract(const Duration(days: 7));
      }
    }

    return transactions.where((tx) {
      if (tx.status != 'success') return false;
      final txDate = tx.createdAt?.toLocal() ?? DateTime.now();
      return txDate.isAfter(start) && txDate.isBefore(end);
    }).toList();
  }

  Map<String, double> _calculateCategorySpending(List<OperatorTransaction> periodTxs) {
    double food = 0.0;
    double drink = 0.0;
    double snack = 0.0;

    for (var tx in periodTxs) {
      if (tx.type != 'purchase') continue;
      final items = tx.transactionItems ?? [];
      if (items.isEmpty) {
        food += tx.totalAmount;
      } else {
        for (var item in items) {
          final qty = item.quantity;
          final price = item.unitPrice;
          final category = item.product?['category']?.toString() ?? 'makanan';
          final amount = qty * price;
          if (category == 'makanan') {
            food += amount;
          } else if (category == 'minuman') {
            drink += amount;
          } else if (category == 'camilan') {
            snack += amount;
          } else {
            food += amount;
          }
        }
      }
    }
    return {'Makanan': food, 'Minuman': drink, 'Camilan': snack};
  }

  List<double> _calculateWeeklySpending(List<OperatorTransaction> transactions) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    int daysToSubtract = today.weekday - 1;
    final monday = today.subtract(Duration(days: daysToSubtract));

    List<double> dailySpending = List.filled(7, 0.0);
    for (var tx in transactions) {
      if (tx.status != 'success' || tx.type != 'purchase') continue;
      final txDate = tx.createdAt?.toLocal() ?? DateTime.now();
      final difference = txDate.difference(monday).inDays;
      if (difference >= 0 && difference < 7) {
        dailySpending[difference] += tx.totalAmount;
      }
    }
    return dailySpending;
  }

  List<MapEntry<String, int>> _calculateFavoriteItems(List<OperatorTransaction> periodTxs) {
    Map<String, int> frequencies = {};
    for (var tx in periodTxs) {
      if (tx.type != 'purchase') continue;
      final items = tx.transactionItems ?? [];
      for (var item in items) {
        final name = item.productName;
        final qty = item.quantity;
        frequencies[name] = (frequencies[name] ?? 0) + qty;
      }
    }
    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  // Tab View Builders
  Widget _buildHomeTab(String name, String classStr, double balance, double? dailyLimit, List<OperatorTransaction> transactions) {
    final double todaySpending = _getTodaySpending(transactions);
    final now = DateTime.now().toLocal();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayTxs = transactions.where((tx) {
      final txDateStr = tx.createdAt != null 
          ? tx.createdAt!.toLocal().toIso8601String().substring(0, 10)
          : '';
      return txDateStr == todayStr;
    }).toList();

    const Color primaryTeal = Color(0xFF006767);
    const Color orangeAccent = Color(0xFF904D00);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profil Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0x1A006767),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.person_fill, color: primaryTeal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      classStr,
                      style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Saldo Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF005E5E), Color(0xFF008282)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006767).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'SALDO SAKU AKTIF',
                style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(balance),
                    style: GoogleFonts.beVietnamPro(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9500),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.push('/parent/topup/${widget.studentId}'),
                    child: Text(
                      'ISI SALDO',
                      style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Batas Saku Progress
        Text(
          'BATAS SAKU HARIAN',
          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: dailyLimit != null && dailyLimit > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batas Pengeluaran',
                          style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${CurrencyFormatter.format(todaySpending)} / ${CurrencyFormatter.format(dailyLimit)}',
                          style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (todaySpending / dailyLimit).clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: const Color(0xFFF0EDED),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (todaySpending / dailyLimit) > 0.9 ? const Color(0xFFBA1A1A) : primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Terpakai ${( (todaySpending / dailyLimit) * 100 ).toStringAsFixed(0)}% hari ini.',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Batas saku harian tidak diaktifkan.',
                      style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Aktivitas Terakhir
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AKTIVITAS TERAKHIR HARI INI',
              style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Switch to Riwayat tab
                });
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayTxs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
            ),
            child: Center(
              child: Text(
                'Belum ada aktivitas jajan hari ini.',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayTxs.length,
              separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFE4E2E1)),
              itemBuilder: (context, i) {
                final tx = todayTxs[i];
                final double amount = tx.totalAmount;
                final type = tx.type ?? 'purchase';
                final bool isTopup = type == 'topup';
                final canteen = tx.canteenName ?? 'Stan Kantin';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isTopup ? const Color(0xFFFFDCC3) : const Color(0xFF8FF3F2).withValues(alpha: 0.3),
                    child: Icon(isTopup ? Icons.account_balance : Icons.restaurant, color: isTopup ? orangeAccent : primaryTeal, size: 18),
                  ),
                  title: Text(
                    isTopup ? 'Top-Up Sukses' : canteen,
                    style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    _getItemsSummary(tx),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                  ),
                  trailing: Text(
                    '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isTopup ? const Color(0xFF006A35) : const Color(0xFFBA1A1A),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnalisisTab(List<OperatorTransaction> transactions) {
    const Color primaryTeal = Color(0xFF006767);
    const Color orangeAccent = Color(0xFF904D00);

    final periodTxs = _filterTransactionsByPeriod(transactions, _selectedPeriod);
    final categorySpending = _calculateCategorySpending(periodTxs);
    final weeklySpending = _calculateWeeklySpending(transactions);
    final favorites = _calculateFavoriteItems(periodTxs);

    double totalSpending = 0.0;
    for (var tx in periodTxs) {
      if (tx.type == 'purchase') {
        totalSpending += tx.totalAmount;
      }
    }

    final double maxWeeklySpend = weeklySpending.reduce(max);
    final daysOfWeek = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    double catTotal = categorySpending['Makanan']! + categorySpending['Minuman']! + categorySpending['Camilan']!;
    double foodPct = catTotal > 0 ? (categorySpending['Makanan']! / catTotal) * 100 : 0.0;
    double drinkPct = catTotal > 0 ? (categorySpending['Minuman']! / catTotal) * 100 : 0.0;
    double snackPct = catTotal > 0 ? (categorySpending['Camilan']! / catTotal) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cupertino Segmented Control
        SizedBox(
          width: double.infinity,
          child: CupertinoSegmentedControl<String>(
            groupValue: _selectedPeriod,
            selectedColor: primaryTeal,
            unselectedColor: Colors.white,
            borderColor: const Color(0xFFE4E2E1),
            pressedColor: const Color(0x1A006767),
            children: const {
              'Hari Ini': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Hari Ini', style: TextStyle(fontSize: 12))),
              'Minggu Ini': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Minggu', style: TextStyle(fontSize: 12))),
              'Bulan Ini': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Bulan', style: TextStyle(fontSize: 12))),
              'Kustom': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Kustom', style: TextStyle(fontSize: 12))),
            },
            onValueChanged: (val) async {
              if (val == 'Kustom') {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: primaryTeal),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  setState(() {
                    _customDateRange = range;
                    _selectedPeriod = val;
                  });
                }
              } else {
                setState(() {
                  _selectedPeriod = val;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        if (_selectedPeriod == 'Kustom' && _customDateRange != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Periode: ${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGray),
            ),
          ),

        // Summary Info Cards
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Belanja', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(CurrencyFormatter.format(totalSpending), style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700, color: primaryTeal)),
                ],
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE4E2E1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rata-rata Harian', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(CurrencyFormatter.format(totalSpending / (_selectedPeriod == 'Hari Ini' ? 1 : (_selectedPeriod == 'Minggu Ini' ? 7 : 30))), style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700, color: orangeAccent)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Kategori breakdown bars
        Text(
          'KATEGORI JAJAN PALING BANYAK',
          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Column(
            children: [
              _buildCategoryProgressRow('Makanan', foodPct, categorySpending['Makanan']!, primaryTeal),
              const SizedBox(height: 16),
              _buildCategoryProgressRow('Minuman', drinkPct, categorySpending['Minuman']!, orangeAccent),
              const SizedBox(height: 16),
              _buildCategoryProgressRow('Camilan', snackPct, categorySpending['Camilan']!, const Color(0xFF5A4432)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tren Jajan Mingguan
        Text(
          'TREN JAJAN MINGGUAN (RP)',
          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          height: 190,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final double value = weeklySpending[index];
              final double heightPct = maxWeeklySpend > 0 ? (value / maxWeeklySpend) : 0.0;
              final double barHeight = heightPct * 110;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value > 0 ? '${(value / 1000).toStringAsFixed(0)}k' : '',
                    style: GoogleFonts.beVietnamPro(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textGray),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: barHeight < 4 ? 4 : barHeight,
                    decoration: BoxDecoration(
                      color: value > 0 ? primaryTeal : const Color(0xFFF0EDED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    daysOfWeek[index],
                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // Produk Terfavorit
        Text(
          'PRODUK TERFAVORIT ANAK',
          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: favorites.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('Belum ada produk favorit pada periode ini.', style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: favorites.length,
                  separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFE4E2E1)),
                  itemBuilder: (context, i) {
                    final item = favorites[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF6F3F2),
                        child: Text('${i + 1}', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: primaryTeal)),
                      ),
                      title: Text(item.key, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      trailing: Text('${item.value}x dibeli', style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGray)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgressRow(String title, double pct, double nominal, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title (${pct.toStringAsFixed(0)}%)',
              style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            Text(
              CurrencyFormatter.format(nominal),
              style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textGray),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0EDED),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(List<OperatorTransaction> transactions) {
    const Color primaryTeal = Color(0xFF006767);
    const Color successGreen = Color(0xFF006A35);
    const Color orangeAccent = Color(0xFF904D00);

    // Apply search filter
    final String query = _searchController.text.toLowerCase().trim();
    var filtered = transactions.where((tx) {
      if (query.isEmpty) return true;
      final summary = _getItemsSummary(tx).toLowerCase();
      final canteen = (tx.canteenName ?? '').toLowerCase();
      return summary.contains(query) || canteen.contains(query);
    }).toList();

    // Apply type filter
    if (_historyTypeFilter == 'Belanja') {
      filtered = filtered.where((tx) => tx.type == 'purchase').toList();
    } else if (_historyTypeFilter == 'Top-up') {
      filtered = filtered.where((tx) => tx.type == 'topup').toList();
    }

    // Apply date range filter
    if (_historyDateRange != null) {
      final start = DateTime(_historyDateRange!.start.year, _historyDateRange!.start.month, _historyDateRange!.start.day);
      final end = DateTime(_historyDateRange!.end.year, _historyDateRange!.end.month, _historyDateRange!.end.day).add(const Duration(days: 1));
      filtered = filtered.where((tx) {
        final date = tx.createdAt?.toLocal() ?? DateTime.now();
        return date.isAfter(start) && date.isBefore(end);
      }).toList();
    }

    // Group by Date for display
    Map<String, List<OperatorTransaction>> grouped = {};
    for (var tx in filtered) {
      final date = tx.createdAt?.toLocal() ?? DateTime.now();
      final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      if (grouped[dateStr] == null) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.search, color: AppColors.textGray, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Cari transaksi atau nama stan...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textGray, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Type Segment Filter
        Row(
          children: [
            Expanded(
              child: CupertinoSegmentedControl<String>(
                groupValue: _historyTypeFilter,
                selectedColor: primaryTeal,
                unselectedColor: Colors.white,
                borderColor: const Color(0xFFE4E2E1),
                pressedColor: const Color(0x1A006767),
                children: const {
                  'Semua': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Semua', style: TextStyle(fontSize: 11))),
                  'Belanja': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Belanja', style: TextStyle(fontSize: 11))),
                  'Top-up': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Top-up', style: TextStyle(fontSize: 11))),
                },
                onValueChanged: (val) => setState(() => _historyTypeFilter = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date Picker button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE4E2E1)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primaryTeal)),
                  child: child!,
                );
              },
            );
            if (range != null) {
              setState(() {
                _historyDateRange = range;
              });
            }
          },
          icon: const Icon(CupertinoIcons.calendar, color: primaryTeal, size: 16),
          label: Text(
            _historyDateRange != null
                ? '${DateFormat('dd MMM').format(_historyDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_historyDateRange!.end)}'
                : 'Pilih Rentang Tanggal...',
            style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTeal),
          ),
        ),
        if (_historyDateRange != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _historyDateRange = null),
              child: const Text('Reset Tanggal', style: TextStyle(fontSize: 11, color: AppColors.error)),
            ),
          ),
        const SizedBox(height: 16),

        // Grouped List
        if (grouped.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                children: [
                  const Icon(CupertinoIcons.tray, color: AppColors.textGray, size: 40),
                  const SizedBox(height: 12),
                  Text('Transaksi tidak ditemukan.', style: GoogleFonts.beVietnamPro(color: AppColors.textGray, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateHeader = grouped.keys.elementAt(index);
              final dayTxs = grouped[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Text(
                      dateHeader.toUpperCase(),
                      style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGray, letterSpacing: 0.5),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayTxs.length,
                      separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFE4E2E1)),
                      itemBuilder: (context, i) {
                        final tx = dayTxs[i];
                        final double amount = tx.totalAmount;
                        final type = tx.type ?? 'purchase';
                        final bool isTopup = type == 'topup';
                        final canteen = tx.canteenName ?? 'Stan Kantin';

                        return ListTile(
                          onTap: () => _showReceiptBottomSheet(tx),
                          leading: CircleAvatar(
                            backgroundColor: isTopup ? const Color(0xFFFFF2E0) : const Color(0x1A006767),
                            child: Icon(isTopup ? Icons.account_balance : Icons.restaurant, color: isTopup ? orangeAccent : primaryTeal, size: 16),
                          ),
                          title: Text(
                            isTopup ? 'Top-Up Sukses' : canteen,
                            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            _getItemsSummary(tx),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textGray),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isTopup ? successGreen : const Color(0xFFBA1A1A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.textGray),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _showReceiptBottomSheet(OperatorTransaction tx) {
    const Color primaryTeal = Color(0xFF006767);
    const Color successGreen = Color(0xFF006A35);
    final double amount = tx.totalAmount;
    final String type = tx.type ?? 'purchase';
    final bool isTopup = type == 'topup';
    final String canteen = tx.canteenName ?? 'Stan Kantin';
    final DateTime date = tx.createdAt?.toLocal() ?? DateTime.now();
    final items = tx.transactionItems ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // iOS Grab Handle
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE4E2E1), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text('DETAIL STRUK', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 24),

                // Success stamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: successGreen, size: 20),
                    const SizedBox(width: 8),
                    Text('Transaksi Berhasil', style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: successGreen)),
                  ],
                ),
                const SizedBox(height: 24),

                // Transaction parameters
                _buildSheetReceiptRow('ID Transaksi', tx.id.substring(0, 18).toUpperCase()),
                const SizedBox(height: 12),
                _buildSheetReceiptRow('Waktu Transaksi', '${DateFormat('dd MMM yyyy, HH:mm').format(date)} WIB'),
                const SizedBox(height: 12),
                _buildSheetReceiptRow('Lokasi / Metode', isTopup ? 'Top-up Transfer Bank' : canteen),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE4E2E1), height: 1),
                const SizedBox(height: 16),

                if (!isTopup && items.isNotEmpty) ...[
                  Text('RINCIAN ITEM BELANJA:', style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final qty = item.quantity;
                      final price = item.unitPrice;
                      final name = item.productName;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${qty}x $name', style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
                          Text(CurrencyFormatter.format(qty * price), style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE4E2E1), height: 1),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL NOMINAL', style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w800, color: primaryTeal),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Struk PDF berhasil diunduh ke perangkat.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(CupertinoIcons.arrow_down_to_line, color: Colors.white, size: 16),
                  label: Text(
                    'UNDUH STRUK PDF',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _getItemsSummary(OperatorTransaction tx) {
    if (tx.type == 'topup') {
      return 'Top-up saldo digital';
    }
    final items = tx.transactionItems ?? [];
    if (items.isEmpty) {
      return 'Pembelian jajanan';
    }
    return items.map((item) {
      final qty = item.quantity;
      final name = item.productName;
      return "${qty}x $name";
    }).join(', ');
  }

  Widget _buildPengaturanTab() {
    const Color primaryTeal = Color(0xFF006767);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily limit toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batasi Jajan Harian',
                          style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Batasi pengeluaran saku maksimal anak per hari.',
                          style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _dailyLimitActive,
                    activeTrackColor: primaryTeal,
                    onChanged: (val) {
                      setState(() {
                        _dailyLimitActive = val;
                      });
                    },
                  ),
                ],
              ),
              if (_dailyLimitActive) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE4E2E1), height: 1),
                const SizedBox(height: 16),
                Text(
                  'Batas Maksimal Per Hari (Rupiah)',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF9F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
                  ),
                  child: Row(
                    children: [
                      Text('Rp ', style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Expanded(
                        child: TextField(
                          controller: _limitController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          decoration: const InputDecoration(hintText: 'Masukkan nominal limit...', border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Freeze Card toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bekukan Kartu RFID Anak',
                      style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nonaktifkan seketika jika kartu anak hilang/terjatuh.',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _cardFrozen,
                activeTrackColor: const Color(0xFFBA1A1A),
                onChanged: (val) {
                  setState(() {
                    _cardFrozen = val;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // WA Alert toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifikasi WhatsApp Wali',
                          style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kirim WhatsApp peringatan setiap anak tap jajan di kantin.',
                          style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _waAlertsActive,
                    activeTrackColor: primaryTeal,
                    onChanged: (val) {
                      setState(() {
                        _waAlertsActive = val;
                      });
                    },
                  ),
                ],
              ),
              if (_waAlertsActive) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE4E2E1), height: 1),
                const SizedBox(height: 16),
                Text(
                  'Nomor WhatsApp Penerima Notifikasi',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF9F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: const InputDecoration(hintText: 'Contoh: 081234567890', border: InputBorder.none),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Save Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSavingSettings ? null : _saveSettings,
          child: _isSavingSettings
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
                  'SIMPAN PENGATURAN SAKU',
                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(parentDashboardProvider(widget.studentId));

    const Color primaryTeal = Color(0xFF006767);
    const Color bgWarm = Color(0xFFFBF9F8);
    const Color borderOutline = Color(0xFFE4E2E1);

    Widget buildHeader() {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: borderOutline, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => context.go('/parent'),
              icon: const Icon(CupertinoIcons.left_chevron, size: 14, color: primaryTeal),
              label: Text(
                'Ganti NISN',
                style: GoogleFonts.beVietnamPro(color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _currentIndex == 0
                      ? 'Beranda Wali'
                      : _currentIndex == 1
                          ? 'Analisis Jajan'
                          : _currentIndex == 2
                              ? 'Riwayat Saku'
                              : 'Pengaturan',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
            ),
            const Icon(CupertinoIcons.bell, color: primaryTeal, size: 20),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgWarm,
      body: Column(
        children: [
          SafeArea(child: buildHeader()),
          Expanded(
            child: dataAsync.when(
              data: (data) {
                final profile = data.profile;
                final student = data.student;
                final txs = data.transactions;

                final String name = profile.fullName ?? 'Siswa';
                final String classStr = student.class_ ?? 'Kelas';
                final double balance = student.balance;
                final double? dailyLimit = student.dailyLimit;

                // Bind settings to local state once
                _initSettingsIfRequired(student);

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: _currentIndex == 0
                          ? _buildHomeTab(name, classStr, balance, dailyLimit, txs)
                          : _currentIndex == 1
                              ? _buildAnalisisTab(txs)
                              : _currentIndex == 2
                                  ? _buildRiwayatTab(txs)
                                  : _buildPengaturanTab(),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(80.0),
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data: $err', textAlign: TextAlign.center, style: GoogleFonts.beVietnamPro(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryTeal,
        unselectedItemColor: AppColors.textGray,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill, size: 20), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar_fill, size: 20), label: 'Analisis'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text_fill, size: 20), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings_solid, size: 20), label: 'Setting'),
        ],
      ),
    );
  }
}
