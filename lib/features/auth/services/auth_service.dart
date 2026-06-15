import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  Map<String, dynamic>? _currentProfile;

  AuthService(this._client);

  // Sign In using email and password queried directly from profiles table
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    String expectedRole = 'petugas_kantin',
  }) async {
    try {
      String queryEmail = email.trim().toLowerCase();
      
      // Mock Parent Account
      if ((queryEmail == '20260012' || queryEmail == '20260012@sekolah.sch.id') && password == 'parent123') {
        if (expectedRole != 'parent') {
          throw Exception('Akun ini adalah akun Orang Tua. Silakan masuk melalui Portal Orang Tua.');
        }
        final parentProfile = {
          'id': 'parent-id-wali-ahmad',
          'email': 'orangtua@sekolah.sch.id',
          'full_name': 'Budi Subarjo (Wali Ahmad)',
          'role': 'parent',
          'student_id': '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'
        };
        _currentProfile = parentProfile;
        return parentProfile;
      }

      // If it looks like a NIS (numeric or doesn't have @), append domain suffix for students
      if (expectedRole == 'student' && !queryEmail.contains('@')) {
        queryEmail = '$queryEmail@sekolah.sch.id';
      }

      // Query profiles directly
      final Map<String, dynamic>? profile = await _client
          .from('profiles')
          .select()
          .eq('email', queryEmail)
          .eq('password', password)
          .maybeSingle();

      if (profile == null) {
        throw Exception('Email/NIS atau kata sandi salah.');
      }

      final String role = profile['role'] ?? '';
      
      // Authorization check: must match expected role
      if (role != expectedRole) {
        if (expectedRole == 'petugas_kantin') {
          throw Exception('Akses ditolak: Hanya petugas/operator kantin yang dapat masuk ke Kasir.');
        } else if (expectedRole == 'student') {
          throw Exception('Akses ditolak: Akun ini bukan akun siswa.');
        } else {
          throw Exception('Akses ditolak: Hak akses tidak sesuai.');
        }
      }

      _currentProfile = profile;
      return profile;
    } on PostgrestException catch (e) {
      // Menangkap error jika kolom password tidak ditemukan di database
      if (e.code == '42703' || e.message.contains('password')) {
        throw Exception(
          'Konfigurasi database belum lengkap. Kolom "password" belum ditambahkan ke tabel "profiles". '
          'Silakan jalankan query migrasi SQL yang saya berikan di Supabase.',
        );
      }
      throw Exception('Gagal menghubungi database (${e.code}): ${e.message}');
    } catch (e) {
      final String errString = e.toString();
      // Menangkap error koneksi internet
      if (errString.contains('SocketException') || errString.contains('Failed host lookup')) {
        throw Exception(
          'Gagal menghubungkan ke server. Periksa koneksi internet Anda atau pastikan URL Supabase sudah benar.',
        );
      }
      // Meneruskan exception jika sudah berupa custom Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  // Sign Out current session
  Future<void> signOut() async {
    _currentProfile = null;
  }

  // Check if session is active
  Session? get currentSession => null;

  // Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    return _currentProfile;
  }
}
