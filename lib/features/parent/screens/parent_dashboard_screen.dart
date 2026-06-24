import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/widgets/premium_panel.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/parent/providers/parent_providers.dart';
import 'package:kantin_digital/features/parent/widgets/parent_action_grid.dart';
import 'package:kantin_digital/features/parent/widgets/parent_analisis_period_selector.dart';
import 'package:kantin_digital/features/parent/widgets/parent_category_breakdown.dart';
import 'package:kantin_digital/features/parent/widgets/parent_favorite_products.dart';
import 'package:kantin_digital/features/parent/widgets/parent_transaction_list.dart';
import 'package:kantin_digital/features/parent/widgets/parent_receipt_bottom_sheet.dart';
import 'package:kantin_digital/features/parent/widgets/parent_settings_section.dart';
import 'package:kantin_digital/features/parent/widgets/parent_dashboard_header.dart';
import 'package:kantin_digital/features/parent/widgets/parent_home_tab.dart';
import 'package:kantin_digital/features/parent/widgets/parent_weekly_trend_chart.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

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
      ref.invalidate(siswaStudentProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} menyimpan pengaturan'),
            backgroundColor: AppColors.errorRed2,
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
  Widget _buildHomeTab(String name, String classStr, int balance, double? dailyLimit, List<OperatorTransaction> transactions) {
    return ParentHomeTab(
      studentName: name,
      studentClass: classStr,
      balance: balance,
      dailyLimit: dailyLimit,
      transactions: transactions,
      onViewAllHistory: () {
        setState(() {
          _currentIndex = 2; // Switch to Riwayat tab
        });
      },
    );
  }

  Widget _buildAnalisisTab(List<OperatorTransaction> transactions) {
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

    final double maxWeeklySpend = weeklySpending.reduce((a, b) => a > b ? a : b);

    double catTotal = categorySpending['Makanan']! + categorySpending['Minuman']! + categorySpending['Camilan']!;
    double foodPct = catTotal > 0 ? (categorySpending['Makanan']! / catTotal) * 100 : 0.0;
    double drinkPct = catTotal > 0 ? (categorySpending['Minuman']! / catTotal) * 100 : 0.0;
    double snackPct = catTotal > 0 ? (categorySpending['Camilan']! / catTotal) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cupertino Segmented Control
        ParentAnalisisPeriodSelector(
          selectedPeriod: _selectedPeriod,
          customDateRange: _customDateRange,
          onPeriodChanged: (val) async {
            if (val == 'Kustom') {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
        const SizedBox(height: 16),

        // Summary Info Cards
        ParentActionGrid(
          totalSpending: totalSpending,
          selectedPeriod: _selectedPeriod,
        ),
        const SizedBox(height: 24),

        // Kategori breakdown bars
        Text(
          'KATEGORI JAJAN PALING BANYAK',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ParentCategoryBreakdown(
          foodPct: foodPct,
          drinkPct: drinkPct,
          snackPct: snackPct,
          foodNominal: categorySpending['Makanan']!,
          drinkNominal: categorySpending['Minuman']!,
          snackNominal: categorySpending['Camilan']!,
        ),
        const SizedBox(height: 24),

        // Tren Jajan Mingguan
        Text(
          'TREN JAJAN MINGGUAN (RP)',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ParentWeeklyTrendChart(
          weeklySpending: weeklySpending,
          maxWeeklySpend: maxWeeklySpend,
        ),
        const SizedBox(height: 24),

        // Produk Terfavorit
        Text(
          'PRODUK TERFAVORIT ANAK',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ParentFavoriteProducts(favorites: favorites),
      ],
    );
  }

  Widget _buildRiwayatTab(List<OperatorTransaction> transactions) {
    return ParentTransactionList(
      transactions: transactions,
      searchController: _searchController,
      historyTypeFilter: _historyTypeFilter,
      onHistoryTypeFilterChanged: (val) => setState(() => _historyTypeFilter = val),
      historyDateRange: _historyDateRange,
      onPickDateRange: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.teal),
              ),
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
      onResetDateRange: () => setState(() => _historyDateRange = null),
      getItemsSummary: _getItemsSummary,
      onTransactionTap: _showReceiptBottomSheet,
    );
  }
  void _showReceiptBottomSheet(OperatorTransaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return ParentReceiptBottomSheet(
          transaction: tx,
          getItemsSummary: _getItemsSummary,
        );
      },
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
    return ParentSettingsSection(
      dailyLimitActive: _dailyLimitActive,
      limitController: _limitController,
      cardFrozen: _cardFrozen,
      waAlertsActive: _waAlertsActive,
      phoneController: _phoneController,
      isSaving: _isSavingSettings,
      onDailyLimitChanged: (val) => setState(() => _dailyLimitActive = val),
      onCardFrozenChanged: (val) => setState(() => _cardFrozen = val),
      onWaAlertsChanged: (val) => setState(() => _waAlertsActive = val),
      onSave: _saveSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(parentDashboardProvider(widget.studentId));


    Widget buildHeader() {
      return ParentDashboardHeader(currentIndex: _currentIndex);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SafeArea(child: buildHeader()),
          Expanded(
            child: PremiumPanel(
              isDesktop: MediaQuery.of(context).size.width >= 768,
              child: dataAsync.when(
                data: (data) {
                  final profile = data.profile;
                  final student = data.student;
                  final txs = data.transactions;

                  final String name = profile.fullName ?? AppStrings.adminStudents;
                  final String classStr = student.class_ ?? AppStrings.labelStudentClass;
                  final int balance = student.balance;
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
                        const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
                        const SizedBox(height: 12),
                        Text('${AppStrings.labelFailed} memuat data', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(parentDashboardProvider(widget.studentId)),
                          child: const Text(AppStrings.buttonRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGray,
          backgroundColor: AppColors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house, size: 20),
              activeIcon: Icon(CupertinoIcons.house_fill, size: 20),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar, size: 20),
              activeIcon: Icon(CupertinoIcons.chart_bar_fill, size: 20),
              label: 'Analisis',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.doc_text, size: 20),
              activeIcon: Icon(CupertinoIcons.doc_text_fill, size: 20),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings, size: 20),
              activeIcon: Icon(CupertinoIcons.settings_solid, size: 20),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
