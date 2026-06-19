import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  Map<String, dynamic>? _currentProfile;

  AuthService(this._client);

  // Sign In with dual-path strategy:
  //   1. Primary: Supabase Auth (signInWithPassword) — establishes JWT session for RLS
  //   2. Fallback: Profiles-based password check — keeps app usable if Auth is down
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    String expectedRole = '',
  }) async {
    try {
      final String rawInput = email.trim();
      final String inputLower = rawInput.toLowerCase();

      // Validation for parent expected role: must be a numeric NISN
      if (expectedRole == 'parent') {
        final isNumeric = RegExp(r'^\d+$').hasMatch(rawInput);
        if (!isNumeric) {
          throw Exception('Akses ditolak: Orang Tua hanya dapat masuk menggunakan NISN Anak (angka).');
        }
      }

      // --- Step 1: Resolve the actual email and find the profile ---
      // Users may log in with email, username, or NISN.
      String resolvedEmail = inputLower;
      Map<String, dynamic>? preloadedProfile;

      if (!inputLower.contains('@')) {
        // Try to find profile by username
        try {
          preloadedProfile = await _client
              .from('profiles')
              .select()
              .eq('username', rawInput)
              .maybeSingle();
        } catch (_) {
          preloadedProfile = null;
        }

        // Try by NISN if username didn't match
        if (preloadedProfile == null) {
          try {
            preloadedProfile = await _client
                .from('profiles')
                .select()
                .eq('nisn', rawInput)
                .maybeSingle();
          } catch (_) {
            preloadedProfile = null;
          }
        }

        if (preloadedProfile != null && preloadedProfile['email'] != null) {
          resolvedEmail = preloadedProfile['email'] as String;
        } else {
          resolvedEmail = '$inputLower@sekolah.sch.id';
        }
      }

      // --- Step 2: Try Supabase Auth (Primary Path) ---
      bool authSessionEstablished = false;
      try {
        await _client.auth.signInWithPassword(
          email: resolvedEmail,
          password: password,
        );
        authSessionEstablished = true;
      } on AuthException {
        // All Supabase Auth errors (including "Invalid login credentials")
        // fall through to the fallback profiles-based password check below.
        // This ensures login works even if a user exists in profiles but
        // not yet in auth.users, or if the auth.users password differs
        // from the profiles.password column.
      } catch (_) {
        // Other unexpected errors — fall through to fallback
      }

      // --- Step 3: Fetch or use preloaded profile ---
      Map<String, dynamic>? profile = preloadedProfile;

      if (authSessionEstablished) {
        // Auth succeeded — fetch profile by user ID for most accurate data
        final String userId = _client.auth.currentUser?.id ?? '';
        if (userId.isNotEmpty && profile == null) {
          profile = await _client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
        }
        profile ??= await _client
              .from('profiles')
              .select()
              .eq('email', resolvedEmail)
              .maybeSingle();
      }

      // --- Step 4: Fallback — profiles-based password verification ---
      if (!authSessionEstablished) {
        if (profile == null) {
          // Try to find profile by email for fallback auth
          try {
            profile = await _client
                .from('profiles')
                .select()
                .eq('email', resolvedEmail)
                .maybeSingle();
          } catch (_) {
            profile = null;
          }
        }

        if (profile == null) {
          throw Exception('Email/Username/NISN atau kata sandi salah.');
        }

        // Verify password against the profiles.password column
        final String storedPassword = profile['password']?.toString() ?? '';
        if (storedPassword != password) {
          throw Exception('Email/Username/NISN atau kata sandi salah.');
        }
        // Note: In fallback mode, no Supabase Auth session is established.
        // auth.uid() will be NULL in RLS policies. Some write operations
        // (audit_logs, corrections) may fail until Supabase Auth is restored.
      }

      if (profile == null) {
        if (authSessionEstablished) await _client.auth.signOut();
        throw Exception('Profil pengguna tidak ditemukan di database.');
      }

      final String role = profile['role'] ?? '';

      // Prevent parent login on general siswa/staff tab
      if (role == 'parent' && expectedRole != 'parent') {
        if (authSessionEstablished) await _client.auth.signOut();
        throw Exception('Akses ditolak: Silakan gunakan pilihan login Orang Tua.');
      }

      // Authorization check: must match expected role if provided
      if (expectedRole.isNotEmpty && role != expectedRole) {
        if (authSessionEstablished) await _client.auth.signOut();
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
    } catch (e) {
      final String errString = e.toString();
      if (errString.contains('SocketException') || errString.contains('Failed host lookup')) {
        throw Exception(
          'Gagal menghubungkan ke server. Periksa koneksi internet Anda atau pastikan URL Supabase sudah benar.',
        );
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  // Sign Out current session (both Supabase Auth and local profile cache)
  Future<void> signOut() async {
    _currentProfile = null;
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }
  }

  // Check if session is active via Supabase Auth
  Session? get currentSession => _client.auth.currentSession;

  // Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (_currentProfile != null) return _currentProfile;

    final session = _client.auth.currentSession;
    if (session != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();
        _currentProfile = profile;
        return profile;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
