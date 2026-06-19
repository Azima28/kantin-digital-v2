import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic value;
  FakeSupabaseQueryBuilder(this.value);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
      value is List ? List<Map<String, dynamic>>.from(value) : [Map<String, dynamic>.from(value ?? {})]
    );
  }
}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T value;
  FakePostgrestFilterBuilder(this.value);

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    dynamic singleValue;
    if (value is List && (value as List).isNotEmpty) {
      singleValue = (value as List).first;
    } else {
      singleValue = value;
    }
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(
      singleValue is Map ? Map<String, dynamic>.from(singleValue) : null
    );
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future.value(value).then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final T value;
  FakePostgrestTransformBuilder(this.value);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future.value(value).then(onValue, onError: onError);
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  dynamic studentToReturn;
  List<dynamic> transactionsToReturn = const [];
  dynamic rpcResult;
  String? rpcFunctionCalled;
  Map<String, dynamic>? rpcParamsPassed;

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'students') {
      return FakeSupabaseQueryBuilder(studentToReturn);
    } else {
      return FakeSupabaseQueryBuilder(transactionsToReturn);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rpc) {
      rpcFunctionCalled = invocation.positionalArguments[0] as String;
      rpcParamsPassed = invocation.namedArguments[#params] as Map<String, dynamic>?;
      return FakePostgrestTransformBuilder(rpcResult);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('NfcPaymentNotifier Tests', () {
    late FakeSupabaseClient fakeClient;
    late ProviderContainer container;

    setUp(() {
      fakeClient = FakeSupabaseClient();
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(fakeClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(nfcPaymentProvider);
      expect(state.status, equals(NfcPaymentStatus.idle));
      expect(state.studentUid, isNull);
      expect(state.studentBalance, equals(0.0));
    });

    test('SimulateTagTap transitions to confirmingPayment when balance is sufficient', () async {
      fakeClient.studentToReturn = {
        'id': 'student-123',
        'class': '9A',
        'balance': 15000.0,
        'is_active': true,
        'daily_limit': 0,
        'profiles': {'full_name': 'Budi'},
      };

      final notifier = container.read(nfcPaymentProvider.notifier);
      notifier.simulateTagTap('rfid-uid-111', 10000.0);

      // Yield control to let async code process
      await Future.delayed(Duration.zero);

      // Verify state transition
      final state = container.read(nfcPaymentProvider);
      expect(state.status, equals(NfcPaymentStatus.confirmingPayment));
      expect(state.studentUid, equals('rfid-uid-111'));
      expect(state.studentName, equals('Budi'));
      expect(state.studentBalance, equals(15000.0));
    });

    test('SimulateTagTap transitions to insufficientBalance when balance is low', () async {
      fakeClient.studentToReturn = {
        'id': 'student-123',
        'class': '9A',
        'balance': 5000.0,
        'is_active': true,
        'daily_limit': 0,
        'profiles': {'full_name': 'Budi'},
      };

      final notifier = container.read(nfcPaymentProvider.notifier);
      notifier.simulateTagTap('rfid-uid-111', 10000.0);

      // Yield control
      await Future.delayed(Duration.zero);

      final state = container.read(nfcPaymentProvider);
      expect(state.status, equals(NfcPaymentStatus.insufficientBalance));
      expect(state.studentBalance, equals(5000.0));
    });

    test('SimulateTagTap fails when card is inactive', () async {
      fakeClient.studentToReturn = {
        'id': 'student-123',
        'class': '9A',
        'balance': 15000.0,
        'is_active': false,
        'daily_limit': 0,
        'profiles': {'full_name': 'Budi'},
      };

      final notifier = container.read(nfcPaymentProvider.notifier);
      notifier.simulateTagTap('rfid-uid-111', 10000.0);

      // Yield control
      await Future.delayed(Duration.zero);

      final state = container.read(nfcPaymentProvider);
      expect(state.status, equals(NfcPaymentStatus.error));
      expect(state.errorMessage, contains('tidak aktif atau diblokir'));
    });
  });
}
