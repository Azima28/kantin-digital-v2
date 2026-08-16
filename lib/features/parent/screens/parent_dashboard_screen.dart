import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/widgets/premium_panel.dart';
import 'package:kantin_digital/core/widgets/premium_bottom_nav_bar.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
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
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
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
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} menyimpan pengaturan'),
            backgroundColor: Nebula.rose,
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
      studentId: widget.studentId,
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
                      colorScheme: const ColorScheme.light(primary: Nebula.teal),
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
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: context.textPrimary, letterSpacing: 0.5),
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
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: context.textPrimary, letterSpacing: 0.5),
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
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: context.textPrimary, letterSpacing: 0.5),
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
                colorScheme: ColorScheme.light(primary: Nebula.teal),
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
      backgroundColor: context.cardBg,
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

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Wali Murid';
    final String email = authState.profile?['email'] ?? '';

    return Container(
      width: 240,
      color: context.cardBg,
      child: Column(
        children: [
          // Sidebar Header (Logo & Title)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.square_grid_2x2_fill,
                    color: Nebula.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PORTAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Nebula.teal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'ORANG TUA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.borderLight),
          const SizedBox(height: 16),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                  index: 0,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'Analisis',
                  index: 1,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Riwayat',
                  index: 2,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Setting',
                  index: 3,
                ),
              ],
            ),
          ),

          // User Profile Card & Logout at bottom
          Divider(height: 1, thickness: 0.5, color: context.borderLight),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                  child: const Icon(Icons.person_outline_rounded, color: Nebula.teal, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Nebula.rose, size: 18),
                  onPressed: () async {
                    final confirmed = await showLogoutConfirmationDialog(context);
                    if (confirmed == true && context.mounted) {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = isDark ? const Color(0xFF00C4B4) : Nebula.teal;
    final Color activeBg = isDark
        ? const Color(0xFF00C4B4).withValues(alpha: 0.12)
        : Nebula.teal.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : context.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    String title = '';
    switch (_currentIndex) {
      case 0:
        title = 'Beranda Wali';
        break;
      case 1:
        title = 'Analisis Jajan';
        break;
      case 2:
        title = 'Riwayat Saku';
        break;
      case 3:
        title = 'Pengaturan';
        break;
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(bottom: BorderSide(color: context.dividerCol, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const NotificationBell(color: Nebula.teal),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(parentDashboardProvider(widget.studentId));
    final bool isWide = MediaQuery.of(context).size.width >= 768;

    Widget buildHeader() {
      return ParentDashboardHeader(currentIndex: _currentIndex);
    }

    if (isWide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            _buildSidebar(context, ref),
            VerticalDivider(width: 0.5, thickness: 0.5, color: context.borderLight),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopHeader(context),
                  Expanded(
                    child: PremiumPanel(
                      isDesktop: true,
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
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
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
                        loading: () => Shimmer(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: context.borderLight, width: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: context.cardBg,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: context.borderLight, width: 0.8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: context.cardBg,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: context.borderLight, width: 0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const SkeletonBox(width: 140, height: 14, borderRadius: 4),
                                const SizedBox(height: 12),
                                ...List.generate(3, (i) => const SkeletonListTile()),
                              ],
                            ),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Nebula.rose, size: 48),
                                const SizedBox(height: 12),
                                Text('${AppStrings.labelFailed} memuat data', textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                PressScale(
                                  onTap: () => ref.invalidate(parentDashboardProvider(widget.studentId)),
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: Text(AppStrings.buttonRetry),
                                  ),
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
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SafeArea(child: buildHeader()),
          Expanded(
            child: PremiumPanel(
              isDesktop: false,
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
                        const Icon(Icons.error_outline, color: Nebula.rose, size: 48),
                        const SizedBox(height: 12),
                        Text('${AppStrings.labelFailed} memuat data', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        PressScale(
                          onTap: () => ref.invalidate(parentDashboardProvider(widget.studentId)),
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Text(AppStrings.buttonRetry),
                          ),
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
      bottomNavigationBar: PremiumBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          PremiumBottomNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Beranda',
          ),
          PremiumBottomNavBarItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics_rounded,
            label: 'Analisis',
          ),
          PremiumBottomNavBarItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Riwayat',
          ),
          PremiumBottomNavBarItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
