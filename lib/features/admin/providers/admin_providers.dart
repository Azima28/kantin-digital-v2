import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';

// ============================================================================
// ADMIN DASHBOARD PROVIDER
// ============================================================================

/// Fetch ringkasan dashboard super admin: jumlah user, total saldo global,
/// volume transaksi harian, dan jumlah transaksi hari ini.
/// Digunakan di: admin_dashboard_screen.dart
final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) async {
  final client = ref.read(supabaseClientProvider);

  double studentBalanceSum = 0;
  double merchantBalanceSum = 0;
  int userCount = 0;
  int totalTransactionsToday = 0;
  double transactionVolumeToday = 0;

  try {
    // 1. Fetch Student Balance
    final studentRes = await client.from('students').select('balance');
    for (var row in studentRes) {
      studentBalanceSum += double.tryParse(row['balance'].toString()) ?? 0.0;
    }

    // 2. Fetch Merchant Balance
    final merchantRes = await client
        .from('canteen_operators')
        .select('balance_earned');
    for (var row in merchantRes) {
      merchantBalanceSum +=
          double.tryParse(row['balance_earned'].toString()) ?? 0.0;
    }

    // 2b. Fetch user count
    final profilesRes = await client.from('profiles').select('id');
    userCount = profilesRes.length;

    // 3. Fetch Transactions Today
    final now = DateTime.now().toLocal();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final txRes = await client
        .from('transactions')
        .select('total_amount')
        .eq('status', 'success')
        .eq('type', 'purchase')
        .gte('created_at', '${todayStr}T00:00:00Z');

    totalTransactionsToday = txRes.length;
    for (var row in txRes) {
      transactionVolumeToday +=
          double.tryParse(row['total_amount'].toString()) ?? 0.0;
    }

    // 4. Fetch last 30 days of transactions for trend
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 29)).toLocal();
    final thirtyDaysAgoStr =
        "${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}T00:00:00+07:00";

    final trendTxs = await client
        .from('transactions')
        .select('total_amount, created_at')
        .eq('status', 'success')
        .eq('type', 'purchase')
        .gte('created_at', thirtyDaysAgoStr);

    // Group by date
    final Map<String, double> dailyVolumes = {};
    for (var row in trendTxs) {
      final String? createdAt = row['created_at']?.toString();
      if (createdAt != null) {
        final txDate = DateTime.parse(createdAt).toLocal();
        final dateKey =
            "${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')}";
        final double amount =
            double.tryParse(row['total_amount']?.toString() ?? '0') ?? 0.0;
        dailyVolumes[dateKey] = (dailyVolumes[dateKey] ?? 0.0) + amount;
      }
    }

    // Populate last 30 days
    final List<double> dailyTrend = [];
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i)).toLocal();
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      dailyTrend.add(dailyVolumes[dateKey] ?? 0.0);
    }

    return AdminDashboardData.fromJson({
      'user_count': userCount,
      'global_balance': studentBalanceSum + merchantBalanceSum,
      'daily_volume': transactionVolumeToday,
      'tx_count_today': totalTransactionsToday,
      'daily_trend': dailyTrend,
    });
  } catch (e) {
    // Fallback if DB query fails
    return AdminDashboardData.fromJson({
      'user_count': userCount,
      'global_balance': studentBalanceSum + merchantBalanceSum,
      'daily_volume': transactionVolumeToday,
      'tx_count_today': totalTransactionsToday,
      'daily_trend': List.generate(30, (index) => 0.0),
    });
  }
});

// ============================================================================
// ADMIN USERS PROVIDER
// ============================================================================

/// Fetch semua user profiles untuk manajemen user super admin.
/// Digunakan di: admin_users_screen.dart
final adminUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) async {
  final client = ref.read(supabaseClientProvider);

  final List<dynamic> res = await client
      .from('profiles')
      .select('id, full_name, email, role, username, nisn, is_active')
      .order('full_name', ascending: true);

  return res
      .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ============================================================================
// ADMIN AUDIT LOGS PROVIDER
// ============================================================================

/// Fetch semua audit log untuk monitoring super admin.
/// Digunakan di: admin_audit_log_screen.dart
final adminAuditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((
  ref,
) async {
  final client = ref.read(supabaseClientProvider);

  final List<dynamic> res = await client
      .from('audit_logs')
      .select(
        'id, actor_id, actor_name, action_type, description, target_id, old_value, new_value, ip_address, user_agent, created_at',
      )
      .order('created_at', ascending: false);

  return res.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
});

// ============================================================================
// ADMIN SETTINGS PROVIDER
// ============================================================================

/// Fetch system settings untuk halaman pengaturan super admin.
/// Digunakan di: admin_settings_screen.dart
final adminSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final client = ref.read(supabaseClientProvider);

  final List<dynamic> res = await client
      .from('system_settings')
      .select('key, value');
  final Map<String, dynamic> settings = {};
  for (var row in res) {
    settings[row['key']] = row['value'];
  }
  return settings;
});

// ============================================================================
// ADMIN STUDENT DETAIL PROVIDER
// ============================================================================

/// Fetch detail lengkap siswa (profile + student + recent transactions).
/// Digunakan di: admin_student_detail_screen.dart
final adminStudentDetailProvider = FutureProvider.autoDispose
    .family<AdminStudentDetail, String>((ref, id) async {
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      // 2. Fetch student
      final student = await client
          .from('students')
          .select()
          .eq('id', id)
          .single();

      // 3. Fetch recent transactions
      final List<dynamic> txs = await client
          .from('transactions')
          .select(
            'id, total_amount, type, status, created_at, canteen_operators(canteen_name)',
          )
          .eq('student_id', id)
          .order('created_at', ascending: false)
          .limit(10);

      return AdminStudentDetail.fromJson({
        'profile': profile,
        'student': student,
        'transactions': List<Map<String, dynamic>>.from(txs),
      });
    });

// ============================================================================
// ADMIN PARENT DETAIL PROVIDER
// ============================================================================

/// Fetch detail lengkap orang tua (profile + linked children).
/// Digunakan di: admin_parent_detail_screen.dart
final adminParentDetailProvider = FutureProvider.autoDispose
    .family<AdminParentDetail, String>((ref, id) async {
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      // 2. Fetch linked children data
      final List<dynamic> childrenRes = await client
          .from('parent_students')
          .select(
            'student_id, students!parent_students_student_id_fkey(class, profiles!students_id_fkey(full_name))',
          )
          .eq('parent_id', id);

      return AdminParentDetail.fromJson({
        'profile': profile,
        'children': List<Map<String, dynamic>>.from(childrenRes),
      });
    });

// ============================================================================
// ADMIN MERCHANT DETAIL PROVIDER
// ============================================================================

/// Fetch detail lengkap merchant (profile + operator + products + sales metrics).
/// Digunakan di: admin_merchant_detail_screen.dart
final adminMerchantDetailProvider = FutureProvider.autoDispose
    .family<AdminMerchantDetail, String>((ref, id) async {
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      // 2. Fetch merchant operator details
      final operator = await client
          .from('canteen_operators')
          .select()
          .eq('id', id)
          .single();

      // 3. Fetch products catalog
      final List<dynamic> products = await client
          .from('products')
          .select('id, operator_id, name, price, category, is_available')
          .eq('operator_id', id)
          .order('name', ascending: true);

      // 4. Fetch recent transactions
      final List<dynamic> txs = await client
          .from('transactions')
          .select(
            'id, total_amount, created_at, student_id, students!transactions_student_id_fkey(profiles!students_id_fkey(nisn))',
          )
          .eq('operator_id', id)
          .eq('status', 'success')
          .eq('type', 'purchase')
          .order('created_at', ascending: false)
          .limit(10);

      // Calculate live sales metrics
      double dailySales = 0;
      double monthlySales = 0;
      final now = DateTime.now().toLocal();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final startOfMonthStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

      // Fetch all transactions this month for live aggregation
      final List<dynamic> monthTxs = await client
          .from('transactions')
          .select('total_amount, created_at')
          .eq('operator_id', id)
          .eq('status', 'success')
          .eq('type', 'purchase')
          .gte('created_at', '${startOfMonthStr}T00:00:00Z');

      for (var tx in monthTxs) {
        final double amount =
            double.tryParse(tx['total_amount'].toString()) ?? 0.0;
        monthlySales += amount;

        final txDateStr = tx['created_at'] != null
            ? DateTime.parse(
                tx['created_at'],
              ).toLocal().toIso8601String().substring(0, 10)
            : '';
        if (txDateStr == todayStr) {
          dailySales += amount;
        }
      }

      return AdminMerchantDetail.fromJson({
        'profile': profile,
        'operator': operator,
        'products': List<Map<String, dynamic>>.from(products),
        'transactions': List<Map<String, dynamic>>.from(txs),
        'daily_sales_aggregated': dailySales,
        'monthly_sales_aggregated': monthlySales,
      });
    });

// ============================================================================
// ADMIN FINANCE DETAIL PROVIDER
// ============================================================================

/// Fetch detail lengkap finance officer (profile + officer + audit activities).
/// Digunakan di: admin_finance_detail_screen.dart
final adminFinanceDetailProvider = FutureProvider.autoDispose
    .family<AdminFinanceDetail, String>((ref, id) async {
      final client = ref.read(supabaseClientProvider);

      // 1. Fetch profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      // 2. Fetch finance officer assignments
      final officer = await client
          .from('finance_officers')
          .select()
          .eq('id', id)
          .single();

      // 3. Fetch audit activities by this officer
      final List<dynamic> logs = await client
          .from('audit_logs')
          .select('id, actor_name, action_type, description, created_at')
          .or('actor_id.eq.$id,actor_name.eq.${profile['full_name']}')
          .order('created_at', ascending: false)
          .limit(10);

      return AdminFinanceDetail.fromJson({
        'profile': profile,
        'officer': officer,
        'logs': List<Map<String, dynamic>>.from(logs),
      });
    });
