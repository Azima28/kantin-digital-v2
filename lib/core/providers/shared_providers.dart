import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

// ============================================================================
// DEDICATED GOLANG BACKEND API CLIENT
// ============================================================================

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ============================================================================
// TRANSACTION TYPES - Cached, shared across all features
// ============================================================================

/// Cache transaksi types agar tidak berulang kali query.
final transactionTypesProvider =
    FutureProvider.autoDispose<List<TransactionType>>((ref) async {
  return [
    TransactionType(id: 'purchase', name: 'Pembelian'),
    TransactionType(id: 'topup', name: 'Top-Up'),
    TransactionType(id: 'refund', name: 'Refund'),
  ];
});

/// Map transaction type id -> TransactionType untuk lookup cepat.
final transactionTypeMapProvider =
    FutureProvider.autoDispose<Map<String, TransactionType>>((ref) async {
  final types = await ref.watch(transactionTypesProvider.future);
  return {for (var t in types) t.id: t};
});

// ============================================================================
// CURRENT USER PROFILE
// ============================================================================

/// Fetch profile user yang sedang login.
final currentUserProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  ref.keepAlive();
  try {
    final authState = ref.watch(authNotifierProvider);
    if (authState.profile != null) {
      return UserProfile.fromJson(authState.profile!);
    }

    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/auth/me');
    if (response.success && response.data != null) {
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  } catch (e, st) {
    debugPrint('currentUserProfileProvider error: $e\n$st');
    return null;
  }
});

// ============================================================================
// STUDENT LOOKUP PROVIDERS
// ============================================================================

/// Fetch single student by ID (dengan profile join).
final studentByIdProvider =
    FutureProvider.family<StudentWithProfile?, String>(
        (ref, id) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/student/me');
    if (response.success && response.data != null) {
      return StudentWithProfile.fromJoinedJson(response.data as Map<String, dynamic>);
    }
    return null;
  } catch (e, st) {
    debugPrint('studentByIdProvider error: $e\n$st');
    return null;
  }
});

// ============================================================================
// RFID PROVIDERS
// ============================================================================

/// Ambil semua siswa yang punya RFID terdaftar.
final rfidCardsProvider =
    FutureProvider<List<Student>>((ref) async {
  try {
    return <Student>[];
  } catch (e, st) {
    debugPrint('rfidCardsProvider error: $e\n$st');
    return <Student>[];
  }
});

/// Cek apakah RFID UID sudah terdaftar ke siswa.
/// Returns Student jika ditemukan, null jika belum terdaftar.
final rfidByUidProvider =
    FutureProvider.family<Student?, String>((ref, uid) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/pos/scan-card', queryParams: {'uid': uid});
    if (response.success && response.data != null) {
      return Student.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  } catch (e, st) {
    debugPrint('rfidByUidProvider error: $e\n$st');
    return null;
  }
});

// ============================================================================
// GLOBAL NOTIFICATIONS PROVIDERS (Multi-Role)
// ============================================================================

/// Fetch all notifications for currently logged in user (Siswa, Kantin, Keuangan, Admin)
final userNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null || profile['is_active'] == false) return <AppNotification>[];

    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/student/notifications');
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <AppNotification>[];
  } catch (e, st) {
    debugPrint('userNotificationsProvider error: $e\n$st');
    return <AppNotification>[];
  }
});

/// Count of unread notifications for currently logged in user
final unreadNotificationsCountProvider =
    Provider.autoDispose<int>((ref) {
  final notifsAsync = ref.watch(userNotificationsProvider);
  return notifsAsync.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
