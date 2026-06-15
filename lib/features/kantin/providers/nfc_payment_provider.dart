import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/services/nfc_service.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';

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
  final double studentBalance;
  final String? errorMessage;

  NfcPaymentState({
    this.status = NfcPaymentStatus.idle,
    this.studentUid,
    this.studentName,
    this.studentClass,
    this.studentBalance = 0.0,
    this.errorMessage,
  });

  NfcPaymentState copyWith({
    NfcPaymentStatus? status,
    String? studentUid,
    String? studentName,
    String? studentClass,
    double? studentBalance,
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
  Future<void> startPaymentSession(double totalAmount) async {
    final bool isNfcAvailable = await NfcService.isNfcAvailable();
    if (!isNfcAvailable) {
      state = NfcPaymentState(
        status: NfcPaymentStatus.scanning, // We still transition to scanning so simulator/debug tap is allowed
        errorMessage: 'Hardware NFC tidak terdeteksi atau dinonaktifkan di perangkat ini.',
      );
    } else {
      state = NfcPaymentState(status: NfcPaymentStatus.scanning);
    }

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
  Future<void> _verifyStudentCard(String rfidUid, double totalAmount) async {
    state = state.copyWith(status: NfcPaymentStatus.verifyingStudent);
    try {
      final client = _ref.read(supabaseClientProvider);
      
      // Query student profiles
      final Map<String, dynamic>? student = await client
          .from('students')
          .select('id, class, balance, is_active, profiles(full_name)')
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

      final String studentName = student['profiles']?['full_name'] ?? 'Siswa';
      final String studentClass = student['class'] ?? 'Belum Diisi';
      final double balance = double.tryParse(student['balance'].toString()) ?? 0.0;

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
        errorMessage: 'Gagal memverifikasi kartu siswa: $e',
      );
    }
  }

  // Trigger from simulator/button for debugging
  void simulateTagTap(String rfidUid, double totalAmount) {
    _verifyStudentCard(rfidUid, totalAmount);
  }

  // Confirm and deduct balance (executes process_purchase)
  Future<bool> confirmPurchase({
    required String operatorId,
    required List<CartItem> items,
    required double totalAmount,
  }) async {
    if (state.studentUid == null) return false;
    
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
          'p_operator_id': operatorId,
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
