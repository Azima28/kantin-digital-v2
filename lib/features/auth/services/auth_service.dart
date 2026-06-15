import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // Sign In using email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // 1. Authenticate with Supabase Auth
    final AuthResponse response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final User? user = response.user;
    if (user == null) {
      throw Exception('Gagal masuk: Data pengguna kosong.');
    }

    try {
      // 2. Fetch profile role from public.profiles
      final Map<String, dynamic>? profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await signOut();
        throw Exception('Profil Anda tidak ditemukan di database.');
      }

      final String role = profile['role'] ?? '';
      
      // 3. Authorization check: must be petugas_kantin
      if (role != 'petugas_kantin') {
        await signOut();
        throw Exception('Akses ditolak: Hanya petugas/operator kantin yang dapat masuk ke Kasir.');
      }

      return profile;
    } catch (e) {
      // Ensure we clean up the auth session if database check fails
      await signOut();
      rethrow;
    }
  }

  // Sign Out current session
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Check if session is active
  Session? get currentSession => _client.auth.currentSession;

  // Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final User? user = _client.auth.currentUser;
    if (user == null) return null;

    return await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }
}
