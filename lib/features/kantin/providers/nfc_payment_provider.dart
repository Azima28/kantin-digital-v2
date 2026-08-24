import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/services/nfc_service.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
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
  final String? studentId;
  final String? studentUid;
  final String? studentName;
  final String? studentClass;
  final int studentBalance;
  final String? errorMessage;

  NfcPaymentState({
    this.status = NfcPaymentStatus.idle,
    this.studentId,
    this.studentUid,
    this.studentName,
    this.studentClass,
    this.studentBalance = 0,
    this.errorMessage,
  });

  NfcPaymentState copyWith({
    NfcPaymentStatus? status,
    String? studentId,
    String? studentUid,
    String? studentName,
    String? studentClass,
    int? studentBalance,
    String? errorMessage,
  }) {
    return NfcPaymentState(
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
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
        status: NfcPaymentStatus.scanning,
        errorMessage: 'Hardware NFC tidak terdeteksi atau dinonaktifkan di perangkat ini.',
      );
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
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/pos/scan-card', queryParams: {'rfid': rfidUid});

      if (!response.success || response.data == null) {
        state = state.copyWith(
          status: NfcPaymentStatus.error,
          errorMessage: response.message ?? 'Kartu siswa tidak terdaftar di sistem koperasi.',
        );
        return;
      }

      final student = response.data as Map<String, dynamic>;
      final bool isActive = student['is_active'] == true;
      if (!isActive) {
        state = state.copyWith(
          status: NfcPaymentStatus.error,
          errorMessage: 'Kartu siswa ini berstatus tidak aktif atau diblokir.',
        );
        return;
      }

      final String studentId = student['id']?.toString() ?? '';
      final String studentName = student['full_name']?.toString() ?? student['name']?.toString() ?? AppStrings.adminStudents;
      final String studentClass = student['class']?.toString() ?? 'Belum Diisi';
      final int balance = (student['balance'] as num?)?.toInt() ?? 0;

      if (balance >= totalAmount) {
        state = state.copyWith(
          status: NfcPaymentStatus.confirmingPayment,
          studentId: studentId,
          studentUid: rfidUid,
          studentName: studentName,
          studentClass: studentClass,
          studentBalance: balance,
        );
      } else {
        state = state.copyWith(
          status: NfcPaymentStatus.insufficientBalance,
          studentId: studentId,
          studentUid: rfidUid,
          studentName: studentName,
          studentClass: studentClass,
          studentBalance: balance,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: NfcPaymentStatus.error,
        errorMessage: '${AppStrings.labelFailed} memverifikasi kartu siswa: $e',
      );
    }
  }

  // Trigger from simulator/button for debugging
  void simulateTagTap(String rfidUid, int totalAmount) {
    _verifyStudentCard(rfidUid, totalAmount);
  }

  // Confirm and deduct balance (executes Go ACID checkout)
  Future<bool> confirmPurchase({
    required String sessionToken,
    required List<CartItem> items,
    required int totalAmount,
  }) async {
    if (state.studentId == null && state.studentUid == null) return false;
    if (state.status == NfcPaymentStatus.processingPurchase) return false;

    state = state.copyWith(status: NfcPaymentStatus.processingPurchase);
    try {
      final apiClient = _ref.read(apiClientProvider);

      final List<Map<String, dynamic>> itemsPayload = items.map((item) {
        String customNotes = item.notes ?? '';
        if (item.selectedOptions.isNotEmpty) {
          final optionsStr = item.selectedOptions.join(', ');
          customNotes = customNotes.isNotEmpty
              ? '$optionsStr | $customNotes'
              : optionsStr;
        }
        return {
          'product_id': item.productId,
          'product_name': item.name,
          'quantity': item.quantity,
          'unit_price': item.price,
          'selected_options': item.selectedOptions,
          'custom_notes': customNotes,
        };
      }).toList();

      final response = await apiClient.post(
        '/pos/checkout',
        body: {
          'student_id': state.studentId ?? '',
          'total_amount': totalAmount,
          'purchase_method': 'nfc_rfid',
          'items': itemsPayload,
        },
      );

      if (!response.success) {
        state = state.copyWith(
          status: NfcPaymentStatus.error,
          errorMessage: response.message ?? 'Transaksi gagal diproses.',
        );
        return false;
      }

      // Trigger standard haptic feedback for success
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
