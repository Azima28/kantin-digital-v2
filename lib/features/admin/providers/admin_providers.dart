import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// ============================================================================
// ADMIN DASHBOARD PROVIDER
// ============================================================================

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) async {
  ref.keepAlive();
  return AdminDashboardData.fromJson({
    'user_count': 0,
    'global_balance': 0,
    'daily_volume': 0,
    'tx_count_today': 0,
    'daily_trend': List.generate(30, (index) => 0),
  });
});

// ============================================================================
// ADMIN USERS PROVIDER
// ============================================================================

final adminRoleFilterProvider = StateProvider<String?>((ref) => null);

final adminUsersProvider = FutureProvider<List<UserProfile>>((
  ref,
) async {
  ref.keepAlive();
  return <UserProfile>[];
});

// ============================================================================
// ADMIN AUDIT LOGS PROVIDER
// ============================================================================

final adminAuditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((
  ref,
) async {
  return <AuditLog>[];
});

// ============================================================================
// ADMIN SETTINGS PROVIDER
// ============================================================================

final adminSettingsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return <String, dynamic>{};
});

// ============================================================================
// ADMIN STUDENT DETAIL PROVIDER
// ============================================================================

final adminStudentDetailProvider = FutureProvider
    .family<AdminStudentDetail, String>((ref, id) async {
      return AdminStudentDetail.fromJson({
        'profile': <String, dynamic>{},
        'student': <String, dynamic>{},
        'transactions': <dynamic>[],
      });
    });

// ============================================================================
// ADMIN PARENT DETAIL PROVIDER
// ============================================================================

final adminParentDetailProvider = FutureProvider
    .family<AdminParentDetail, String>((ref, id) async {
      return AdminParentDetail.fromJson({
        'profile': <String, dynamic>{},
        'children': <dynamic>[],
      });
    });

// ============================================================================
// ADMIN MERCHANT DETAIL PROVIDER
// ============================================================================

final adminMerchantDetailProvider = FutureProvider
    .family<AdminMerchantDetail, String>((ref, id) async {
      final apiClient = ref.read(apiClientProvider);
      final prodRes = await apiClient.get('/products', queryParams: {'canteen_id': id});
      final List<dynamic> products = prodRes.success && prodRes.data != null ? prodRes.data as List<dynamic> : [];

      return AdminMerchantDetail.fromJson({
        'profile': <String, dynamic>{},
        'operator': <String, dynamic>{},
        'products': products,
        'transactions': <dynamic>[],
        'daily_sales_aggregated': 0.0,
        'monthly_sales_aggregated': 0.0,
      });
    });

// ============================================================================
// ADMIN FINANCE DETAIL PROVIDER
// ============================================================================

final adminFinanceDetailProvider = FutureProvider
    .family<AdminFinanceDetail, String>((ref, id) async {
      return AdminFinanceDetail.fromJson({
        'profile': <String, dynamic>{},
        'officer': <String, dynamic>{},
        'logs': <dynamic>[],
      });
    });
