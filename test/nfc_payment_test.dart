import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';

void main() {
  group('NfcPaymentNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(nfcPaymentProvider);
      expect(state.status, equals(NfcPaymentStatus.idle));
      expect(state.studentUid, isNull);
      expect(state.studentBalance, equals(0));
    });

    test('Reset state brings back to idle', () {
      final notifier = container.read(nfcPaymentProvider.notifier);
      notifier.resetState();
      final state = container.read(nfcPaymentProvider);
      expect(state.status, equals(NfcPaymentStatus.idle));
    });
  });
}
