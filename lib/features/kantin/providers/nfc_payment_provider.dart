import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/services/nfc_service.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

enum NfcPaymentStatus {
  idle,
  scanning,
  verifyingStudent,
  confirmingPayment,
  insufficientBalance,
  processingPurchase,
  success,
  error,
}

class NfcPaymentState {
  final NfcPaymentStatus status;
  final String? studentUid;
  final String? studentName;
  final String? studentClass;
  final int studentBalance;
  final String? errorMessage;

  NfcPaymentState({
    this.status = NfcPaymentStatus.idle,
    this.studentUid,
    this.studentName,
    this.studentClass,
    this.studentBalance = 0,
    this.errorMessage,
  });

  NfcPaymentState copyWith({
    NfcPaymentStatus? status,
    String? studentUid,
    String? studentName,
    String? studentClass,
    int? studentBalance,
    String? errorMessage,
  }) {
    return NfcPaymentState(
      status: status ?? this.status,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentClass: studentClass ?? this.studentClass,
      studentBalance: studentBalance ?? this.studentBalance,
      errorMessage: errorMessage,
    );
  }
}

class NfcPaymentNotifier extends StateNotifier<NfcPaymentState> {
  final Ref _ref;
  NfcPaymentNotifier(this._ref) : super(NfcPaymentState());

  // Check availability and start scanning
  Future<void> startPaymentSession(int totalAmount) async {
    final bool isNfcAvailable = await NfcService.isNfcAvailable();
    if (!isNfcAvailable) {
      state = NfcPaymentState(
        status: NfcPaymentStatus.scanning, // We still transition to scanning so simulator/debug tap is allowed
        errorMessage: 'Hardware NFC tidak terdeteksi atau dinonaktifkan di perangkat ini.',
      );
      // Skip startScanning since hardware is not present/available
      return;
    }

    state = NfcPaymentState(status: NfcPaymentStatus.scanning);

    NfcService.startScanning(
      onTagDiscovered: (String uid) {
        _verifyStudentCard(uid, totalAmount);
      },
      onError: (String err) {
        state = state.copyWith(
          status: NfcPaymentStatus.error,
          errorMessage: err,
        );
      },
    );
  }

  // Verification step
  Future<void> _verifyStudentCard(String rfidUid, int totalAmount) async {
    state = state.copyWith(status: NfcPaymentStatus.verifyingStudent);
    try {
      final client = _ref.read(supabaseClientProvider);
      
      // Query student profiles
      final Map<String, dynamic>? student = await client
          .from('students')
          .select('id, class, balance, is_active, daily_limit, profiles:profiles!students_id_fkey(full_name)')
          .eq('rfid_uid', rfidUid)
          .maybeSingle();

      if (student == null) {
        state = state.copyWith(
          status: NfcPaymentStatus.error,
          errorMessage: 'Kartu siswa tidak terdaftar di sistem koperasi.',
        );
        return;
      }

      final bool isActive = student['is_active'] ?? false;
      if (!isActive) {
        state = state.copyWith(
          status: NfcPaymentStatus.error,
          errorMessage: 'Kartu siswa ini berstatus tidak aktif atau diblokir.',
        );
        return;
      }

      final String studentId = student['id'];
      final int dailyLimit = student['daily_limit'] != null 
          ? (student['daily_limit'] as num?)?.toInt() ?? 0 
          : 0;

      // Check daily limit if set and active
      if (dailyLimit > 0) {
        final now = DateTime.now().toLocal();
        final localTodayStart = DateTime(now.year, now.month, now.day);
        final startOfDayUtc = localTodayStart.toUtc().toIso8601String();

        final List<dynamic> todayTxs = await client
            .from('transactions')
            .select('total_amount')
            .eq('student_id', studentId)
            .eq('type', 'purchase')
            .eq('status', 'success')
            .gte('created_at', startOfDayUtc);

        int todaySpending = 0;
        for (var tx in todayTxs) {
          todaySpending += int.tryParse(tx['total_amount'].toString()) ?? 0;
        }

        if ((todaySpending + totalAmount) > dailyLimit) {
          state = state.copyWith(
            status: NfcPaymentStatus.error,
            errorMessage: 'Batas jajan harian terlampaui.',
          );
          return;
        }
      }

      final String studentName = student['profiles']?['full_name'] ?? AppStrings.adminStudents;
      final String studentClass = student['class'] ?? 'Belum Diisi';
      final int balance = (student['balance'] as num?)?.toInt() ?? 0;

      if (balance >= totalAmount) {
        state = state.copyWith(
          status: NfcPaymentStatus.confirmingPayment,
          studentUid: rfidUid,
          studentName: studentName,
          studentClass: studentClass,
          studentBalance: balance,
        );
      } else {
        state = state.copyWith(
          status: NfcPaymentStatus.insufficientBalance,
          studentUid: rfidUid,
          studentName: studentName,
          studentClass: studentClass,
          studentBalance: balance,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: NfcPaymentStatus.error,
        errorMessage: '${AppStrings.labelFailed} memverifikasi kartu siswa',
      );
    }
  }

  // Trigger from simulator/button for debugging
  void simulateTagTap(String rfidUid, int totalAmount) {
    _verifyStudentCard(rfidUid, totalAmount);
  }

  // Confirm and deduct balance (executes process_purchase)
  Future<bool> confirmPurchase({
    required String sessionToken,
    required List<CartItem> items,
    required int totalAmount,
  }) async {
    if (state.studentUid == null) return false;
    // Prevent double-tap: if already processing, ignore subsequent calls
    if (state.status == NfcPaymentStatus.processingPurchase) return false;
    
    state = state.copyWith(status: NfcPaymentStatus.processingPurchase);
    try {
      final client = _ref.read(supabaseClientProvider);

      // Map cart items format to match p_items JSONB parameter
      final List<Map<String, dynamic>> cartItemsJson = items.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit_price': item.price,
        'custom_notes': item.notes ?? '',
      }).toList();

      await client.rpc(
        'process_purchase',
        params: {
          'p_rfid_uid': state.studentUid,
          'p_session_token': sessionToken,
          'p_items': cartItemsJson,
          'p_total_amount': totalAmount,
        },
      );

      // Trigger standard iOS haptic feedback for success
      HapticFeedback.mediumImpact();

      state = state.copyWith(status: NfcPaymentStatus.success);

      // Invalidate revenue provider and clear cart
      _ref.read(cartProvider.notifier).clearCart();
      _ref.invalidate(todayRevenueProvider);
      _ref.invalidate(operatorTransactionsProvider);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        status: NfcPaymentStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // Cancel and reset
  void resetState() {
    NfcService.stopScanning();
    state = NfcPaymentState(status: NfcPaymentStatus.idle);
  }
}

final StateNotifierProvider<NfcPaymentNotifier, NfcPaymentState> nfcPaymentProvider =
    StateNotifierProvider<NfcPaymentNotifier, NfcPaymentState>((Ref ref) {
  return NfcPaymentNotifier(ref);
});
