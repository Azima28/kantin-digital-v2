import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  Map<String, dynamic>? _currentProfile;

  AuthService(this._client);

  // Sign In using email and password queried directly from profiles table
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // Query profiles directly
    final Map<String, dynamic>? profile = await _client
        .from('profiles')
        .select()
        .eq('email', email)
        .eq('password', password)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Email atau kata sandi salah.');
    }

    final String role = profile['role'] ?? '';
    
    // Authorization check: must be petugas_kantin
    if (role != 'petugas_kantin') {
      throw Exception('Akses ditolak: Hanya petugas/operator kantin yang dapat masuk ke Kasir.');
    }

    _currentProfile = profile;
    return profile;
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
