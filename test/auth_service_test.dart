import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/features/auth/services/auth_service.dart';

class FakeGoTrueClient extends Fake implements GoTrueClient {
  bool failAuth = false;
  User? mockUser;
  bool signedOut = false;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (failAuth) {
      throw const AuthException('network or database error');
    }
    mockUser = User(
      id: 'mock-user-uuid',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    return AuthResponse(session: null, user: mockUser);
  }

  @override
  User? get currentUser {
    return mockUser;
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    signedOut = true;
    mockUser = null;
  }
}

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
  final FakeGoTrueClient _auth = FakeGoTrueClient();
  dynamic profileToReturn;
  bool dbFails = false;
  int profileQueryCount = 0;

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    if (dbFails) {
      throw Exception('Database query failed');
    }
    if (table == 'parent_students') {
      return FakeSupabaseQueryBuilder({'parent_id': 'parent-uuid', 'student_id': 'student-uuid'});
    }
    if (table == 'profiles') {
      profileQueryCount++;
      if (profileQueryCount == 1 && profileToReturn is Map && (profileToReturn as Map)['role'] == 'parent') {
        return FakeSupabaseQueryBuilder({
          'id': 'student-uuid',
          'email': 'siswa@sekolah.sch.id',
          'role': 'student',
          'nisn': '20260012',
          'full_name': 'Siswa Test',
        });
      }
    }
    return FakeSupabaseQueryBuilder(profileToReturn);
  }
}

void main() {
  group('AuthService Tests', () {
    late FakeSupabaseClient fakeClient;
    late AuthService authService;

    setUp(() {
      fakeClient = FakeSupabaseClient();
      authService = AuthService(fakeClient);
    });

    test('Parent login check with non-numeric NISN throws error', () async {
      expect(
        () => authService.signIn(
          email: 'not-a-number',
          password: 'pwd',
          expectedRole: 'parent',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Akses ditolak: Orang Tua hanya dapat masuk menggunakan NISN Anak (angka).'),
        )),
      );
    });

    test('Auth Success resolves profile role matches', () async {
      fakeClient.profileToReturn = {
        'id': 'mock-user-uuid',
        'email': 'siswa@sekolah.sch.id',
        'role': 'siswa',
        'full_name': 'Siswa Test',
      };

      final result = await authService.signIn(
        email: 'siswa',
        password: 'password',
        expectedRole: 'siswa',
      );

      expect(result['role'], equals('siswa'));
      expect(result['full_name'], equals('Siswa Test'));
    });

    test('Auth Success but role mismatch throws error and signs out', () async {
      fakeClient.profileToReturn = {
        'id': 'mock-user-uuid',
        'email': 'siswa@sekolah.sch.id',
        'role': 'siswa',
        'full_name': 'Siswa Test',
      };

      try {
        await authService.signIn(
          email: 'siswa',
          password: 'password',
          expectedRole: 'petugas_kantin',
        );
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Akses ditolak: Hanya petugas/operator kantin yang dapat masuk ke Kasir.'));
      }

      expect(fakeClient._auth.signedOut, isTrue);
    });

    test('Primary Auth fails, Fallback path succeeds with stored password', () async {
      fakeClient._auth.failAuth = true;
      fakeClient.profileToReturn = {
        'id': 'fallback-uuid',
        'email': 'petugas@sekolah.sch.id',
        'password': 'safe-password',
        'role': 'petugas_kantin',
        'full_name': 'Petugas Fallback',
      };

      try {
        final result = await authService.signIn(
          email: 'petugas@sekolah.sch.id',
          password: 'safe-password',
          expectedRole: 'petugas_kantin',
        );
        expect(result['full_name'], equals('Petugas Fallback'));
      } catch (e) {
        rethrow;
      }
    });

    test('Parent login check with child NISN succeeds', () async {
      fakeClient.profileToReturn = {
        'id': 'parent-uuid',
        'email': 'parent.siswa@sekolah.sch.id',
        'role': 'parent',
        'full_name': 'Orang Tua Siswa Test',
        'password': 'parent-password',
      };

      final result = await authService.signIn(
        email: '20260012',
        password: 'parent-password',
        expectedRole: 'parent',
      );

      expect(result['role'], equals('parent'));
      expect(result['full_name'], equals('Orang Tua Siswa Test'));
      expect(result['student_id'], equals('student-uuid'));
    });
  });
}
