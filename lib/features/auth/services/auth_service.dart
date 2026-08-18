import 'dart:async';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/services/secure_session_service.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class AuthService {
  final ApiClient _apiClient;
  Map<String, dynamic>? _currentProfile;
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  AuthService(this._apiClient);

  Stream<Map<String, dynamic>?> get onAuthStateChange =>
      _authStateController.stream;

  void init() {
    // Persistent session initialization
  }

  // Sign In using dedicated Golang REST API
  // Returns: Map with keys 'profile' (Map) and 'session_token' (String?)
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    String expectedRole = '',
  }) async {
    try {
      final String rawInput = email.trim();

      // Validation for parent expected role: must be a numeric NISN
      if (expectedRole == 'parent') {
        final isNumeric = RegExp(r'^\d+$').hasMatch(rawInput);
        if (!isNumeric) {
          throw Exception(
            'Akses ditolak: Orang Tua hanya dapat masuk menggunakan NISN Anak (angka).',
          );
        }
      }

      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'identifier': rawInput,
          'password': password,
          if (expectedRole.isNotEmpty) 'role': expectedRole,
        },
      );

      if (!response.success || response.data == null) {
        final errMsg = response.message ?? 'Email/Username/NISN atau kata sandi salah.';
        throw Exception(errMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final String? token = data['token'] as String?;
      final Map<String, dynamic>? userMap = data['user'] as Map<String, dynamic>?;

      if (token == null || userMap == null) {
        throw Exception('Respons login dari server tidak valid.');
      }

      // Configure ApiClient with Bearer JWT
      _apiClient.setAuthToken(token);

      final Map<String, dynamic> profile = Map<String, dynamic>.from(userMap);
      if (data['student'] != null) {
        profile['student_id'] = (data['student'] as Map<String, dynamic>)['id'];
        profile['balance'] = (data['student'] as Map<String, dynamic>)['balance'];
        profile['rfid_uid'] = (data['student'] as Map<String, dynamic>)['rfid_uid'];
      }

      final String role = profile['role']?.toString() ?? '';

      // Prevent parent login on general siswa/staff tab
      if (role == 'parent' && expectedRole != 'parent') {
        throw Exception('Akses ditolak: Silakan gunakan pilihan login Orang Tua.');
      }

      // Role check
      if (expectedRole.isNotEmpty && role != expectedRole) {
        if (expectedRole == 'petugas_kantin') {
          throw Exception('Akses ditolak: Hanya petugas/operator kantin yang dapat masuk ke Kasir.');
        } else if (expectedRole == 'student') {
          throw Exception('Akses ditolak: Akun ini bukan akun siswa.');
        } else {
          throw Exception('Akses ditolak: Hak akses tidak sesuai.');
        }
      }

      _currentProfile = profile;
      _authStateController.add(profile);

      return {
        'profile': profile,
        'session_token': token,
      };
    } catch (e) {
      final String errString = e.toString();
      if (errString.contains('SocketException') ||
          errString.contains('Failed host lookup') ||
          errString.contains('Koneksi ke backend gagal')) {
        throw Exception(
          '${AppStrings.labelFailed} menghubungkan ke server Go backend.',
        );
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  // Sign Out current session
  Future<void> signOut() async {
    _currentProfile = null;
    _apiClient.clearAuthToken();
    await SecureSessionService.clearSessionData();
    _authStateController.add(null);
  }

  // Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (_currentProfile != null) return _currentProfile;

    final token = _apiClient.authToken;
    if (token != null && token.isNotEmpty) {
      final response = await _apiClient.get('/auth/me');
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _currentProfile = data;
        return data;
      }
    }
    return null;
  }

  void dispose() {
    _authStateController.close();
  }
}
