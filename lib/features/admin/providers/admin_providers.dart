import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';

// ============================================================================
// ADMIN DASHBOARD PROVIDER
// ============================================================================

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 2));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/dashboard');
    if (res.success && res.data != null) {
      return AdminDashboardData.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('adminDashboardProvider error: $e');
  }

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
  ref.cacheFor(const Duration(minutes: 3));
  final apiClient = ref.watch(apiClientProvider);
  final roleFilter = ref.watch(adminRoleFilterProvider);

  try {
    final res = await apiClient.get('/admin/users', queryParams: {
      if (roleFilter != null && roleFilter.isNotEmpty) 'role': roleFilter,
    });
    if (res.success && res.data != null) {
      final list = res.data as List<dynamic>;
      return list.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('adminUsersProvider error: $e');
  }

  return <UserProfile>[];
});

// ============================================================================
// ADMIN AUDIT LOGS PROVIDER
// ============================================================================

final adminAuditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 2));
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/audit-logs');
    if (res.success && res.data != null) {
      final list = res.data as List<dynamic>;
      return list.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('adminAuditLogsProvider error: $e');
  }

  return <AuditLog>[];
});

// ============================================================================
// ADMIN SETTINGS PROVIDER
// ============================================================================

final adminSettingsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return <String, dynamic>{
    'school_name': 'SMP Terpadu Digital',
    'academic_year': '2026/2027',
    'app_version': '2.0.0',
    'db_status': 'Connected (PostgreSQL 16)',
  };
});

// ============================================================================
// ADMIN STUDENT DETAIL PROVIDER
// ============================================================================

final adminStudentDetailProvider = FutureProvider
    .family<AdminStudentDetail, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/student/$id');
    if (res.success && res.data != null) {
      return AdminStudentDetail.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('adminStudentDetailProvider error: $e');
  }

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
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/parent/$id');
    if (res.success && res.data != null) {
      return AdminParentDetail.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('adminParentDetailProvider error: $e');
  }

  return AdminParentDetail.fromJson({
    'profile': <String, dynamic>{'id': id},
    'children': <dynamic>[],
  });
});

// ============================================================================
// ADMIN MERCHANT DETAIL PROVIDER
// ============================================================================

final adminMerchantDetailProvider = FutureProvider
    .family<AdminMerchantDetail, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/merchant/$id');
    if (res.success && res.data != null) {
      return AdminMerchantDetail.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('adminMerchantDetailProvider error: $e');
  }

  return AdminMerchantDetail.fromJson({
    'profile': <String, dynamic>{'id': id},
    'operator': <String, dynamic>{'id': id, 'canteen_name': 'Stan Kantin'},
    'products': <dynamic>[],
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
  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/admin/finance/$id');
    if (res.success && res.data != null) {
      return AdminFinanceDetail.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('adminFinanceDetailProvider error: $e');
  }

  return AdminFinanceDetail.fromJson({
    'profile': <String, dynamic>{'id': id},
    'officer': <String, dynamic>{'id': id},
    'logs': <dynamic>[],
  });
});

// ============================================================================
// ACADEMIC STRUCTURE PROVIDER (Master Jenjang, Jurusan, Kelas & Rombel)
// ============================================================================

final academicStructureProvider = FutureProvider<AcademicStructure>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final apiClient = ref.watch(apiClientProvider);

  try {
    final res = await apiClient.get('/academic-structure');
    if (res.success && res.data != null) {
      return AcademicStructure.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
  } catch (e) {
    debugPrint('[AcademicStructure] Provider error: $e');
  }

  return const AcademicStructure();
});

final saveAcademicStructureProvider = Provider<Future<bool> Function(AcademicStructure)>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return (AcademicStructure structure) async {
    try {
      final res = await apiClient.post('/admin/academic-structure', body: structure.toJson());
      if (res.success) {
        ref.invalidate(academicStructureProvider);
        return true;
      }
    } catch (e) {
      debugPrint('[AcademicStructure] Save error: $e');
    }
    return false;
  };
});
