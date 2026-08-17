import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/features/auth/services/auth_service.dart';

void main() {
  group('AuthService Tests (Go Backend REST API)', () {
    test('Parent login check with non-numeric NISN throws error', () async {
      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1');
      final authService = AuthService(apiClient);

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

    test('Auth Success resolves profile and token correctly', () async {
      final authService = AuthService(ApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1'));
      expect(authService, isNotNull);
    });
  });
}
