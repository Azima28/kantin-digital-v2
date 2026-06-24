import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/models/models.dart';

// ============================================================================
// SUPABASE CLIENT
// ============================================================================

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ============================================================================
// TRANSACTION TYPES - Cached, shared across all features
// ============================================================================

/// Cache transaksi types agar tidak berulang kali query.
/// Digunakan di banyak screen (top-up, adjustment, dll).
final transactionTypesProvider =
    FutureProvider.autoDispose<List<TransactionType>>((ref) async {
  // Hardcoded — DB only uses string types ('purchase', 'topup')
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
  try {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) return null;

    final data = await client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  } catch (e, st) {
    debugPrint('currentUserProfileProvider error: $e\n$st');
    rethrow;
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
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('profiles')
        .select(
            'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return StudentWithProfile.fromJoinedJson(data);
  } catch (e, st) {
    debugPrint('studentByIdProvider error: $e\n$st');
    rethrow;
  }
});

// ============================================================================
// RFID PROVIDERS (via students.rfid_uid — no separate rfid_cards table)
// ============================================================================

/// Ambil semua siswa yang punya RFID terdaftar.
final rfidCardsProvider =
    FutureProvider<List<Student>>((ref) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('students')
        .select('*, profiles!inner(*)')
        .not('rfid_uid', 'is', null)
        .order('rfid_uid');
    return data
        .map((e) => Student.fromJson(e))
        .toList();
  } catch (e, st) {
    debugPrint('rfidCardsProvider error: $e\n$st');
    rethrow;
  }
});

/// Cek apakah RFID UID sudah terdaftar ke siswa.
/// Returns Student jika ditemukan, null jika belum terdaftar.
final rfidByUidProvider =
    FutureProvider.family<Student?, String>((ref, uid) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('students')
        .select('*, profiles!inner(*)')
        .eq('rfid_uid', uid)
        .maybeSingle();
    if (data == null) return null;
    return Student.fromJson(data);
  } catch (e, st) {
    debugPrint('rfidByUidProvider error: $e\n$st');
    rethrow;
  }
});

// ============================================================================
// GLOBAL NOTIFICATIONS PROVIDERS (Multi-Role)
// ============================================================================

/// Fetch all notifications for currently logged in user (Siswa, Kantin, Keuangan, Admin)
final userNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) return <AppNotification>[];

    final List<dynamic> response = await client
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return response
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
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
