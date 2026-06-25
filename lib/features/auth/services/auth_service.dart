import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/secure_session_service.dart';
import '../../../core/constants/app_strings.dart';

class AuthService {
  final SupabaseClient _client;
  Map<String, dynamic>? _currentProfile;

  AuthService(this._client);

  /// Initialise session persistence: save/restore session tokens
  /// via flutter_secure_storage whenever Supabase auth state changes.
  void init() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        final sessionJson = jsonEncode({
          'access_token': data.session?.accessToken,
          'refresh_token': data.session?.refreshToken,
        });
        SecureSessionService.saveSession(sessionJson);
      } else if (data.event == AuthChangeEvent.signedOut) {
        SecureSessionService.clearSession();
      }
    });
  }

  // Sign In with dual-path strategy:
  //   1. Primary: Supabase Auth (signInWithPassword) — establishes JWT session for RLS
  //   2. Fallback: Profiles-based password check — keeps app usable if Auth is down
  // Returns: Map with keys 'profile' (Map) and 'session_token' (String?)
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
          throw Exception(
            'Akses ditolak: Orang Tua hanya dapat masuk menggunakan NISN Anak (angka).',
          );
        }
      }

      // --- Step 1: Resolve the actual email and find the profile ---
      // Users may log in with email, username, or NISN.
      String resolvedEmail = inputLower;
      Map<String, dynamic>? preloadedProfile;

      if (expectedRole == 'parent') {
        // Resolve parent login via RPC (bypasses RLS restrictions)
        final parentResult = await _client.rpc('resolve_parent_login', params: {
          'p_student_nisn': rawInput,
        });

        final Map<String, dynamic> result;
        if (parentResult is Map<String, dynamic>) {
          result = parentResult;
        } else if (parentResult is String) {
          result = jsonDecode(parentResult) as Map<String, dynamic>;
        } else {
          result = {};
        }

        if (result['found'] != true) {
          throw Exception(result['error'] ?? 'NISN Anak tidak terdaftar.');
        }

        preloadedProfile = result;
        resolvedEmail = result['email'] as String;
      } else if (!inputLower.contains('@')) {
        // Try to find profile by username via RPC (bypasses RLS)
        try {
          final identityResult = await _client.rpc('get_email_for_login', params: {
            'p_input': rawInput,
          });

          final Map<String, dynamic> result;
          if (identityResult is Map<String, dynamic>) {
            result = identityResult;
          } else if (identityResult is String) {
            result = jsonDecode(identityResult) as Map<String, dynamic>;
          } else {
            result = {};
          }

          if (result['found'] == true) {
            preloadedProfile = result;
            resolvedEmail = result['email'] as String;
          } else {
            resolvedEmail = '$inputLower@sekolah.sch.id';
          }
        } catch (_) {
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
        // If Supabase Auth fails (e.g. invalid credentials, network/server issues),
        // we fall through to the profiles-based fallback check in Step 4.
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

      // --- Step 4: Fallback — profile-based password verification via RPC ---
      if (!authSessionEstablished) {
        try {
          final response = await _client.rpc('verify_password', params: {
            'p_email': resolvedEmail,
            'p_password': password,
          });
          
          final Map<String, dynamic> result;
          if (response is Map<String, dynamic>) {
            result = response;
          } else if (response is String) {
            result = jsonDecode(response) as Map<String, dynamic>;
          } else {
            result = {};
          }
          
          if (result['found'] == false || result['password_valid'] == false) {
            throw Exception('Email/Username/NISN atau kata sandi salah.');
          }
          
          // Build profile from RPC response (exclude internal fields)
          // verify_password returns nested {found, password_valid, profile: {...}}
          if (result['profile'] != null && result['profile'] is Map) {
            profile = Map<String, dynamic>.from(result['profile'] as Map);
          } else {
            profile = Map<String, dynamic>.from(result);
          }

          // Try to establish a real Supabase Auth session so RLS works.
          // The password is validated above, so this should succeed.
          try {
            await _client.auth.signInWithPassword(
              email: resolvedEmail,
              password: password,
            );
            authSessionEstablished = true;
            // Re-fetch profile via authenticated session for accuracy
            final String userId = _client.auth.currentUser?.id ?? '';
            if (userId.isNotEmpty) {
              final authedProfile = await _client
                  .from('profiles')
                  .select()
                  .eq('id', userId)
                  .maybeSingle();
              if (authedProfile != null) {
                profile = Map<String, dynamic>.from(authedProfile);
              }
            }
          } catch (_) {
            // Session establishment failed — continue with profile from RPC.
            // App will work but some RLS-dependent features may be limited.
          }
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Email/Username/NISN atau kata sandi salah.');
        }
      }

      if (profile == null) {
        if (authSessionEstablished) await _client.auth.signOut();
        throw Exception('Profil pengguna tidak ditemukan di database.');
      }

      final String role = profile['role'] ?? '';

      // Prevent parent login on general siswa/staff tab
      if (role == 'parent' && expectedRole != 'parent') {
        if (authSessionEstablished) await _client.auth.signOut();
        throw Exception(
          'Akses ditolak: Silakan gunakan pilihan login Orang Tua.',
        );
      }

      // Authorization check: must match expected role if provided
      if (expectedRole.isNotEmpty && role != expectedRole) {
        if (authSessionEstablished) await _client.auth.signOut();
        if (expectedRole == 'petugas_kantin') {
          throw Exception(
            'Akses ditolak: Hanya petugas/operator kantin yang dapat masuk ke Kasir.',
          );
        } else if (expectedRole == 'student') {
          throw Exception('Akses ditolak: Akun ini bukan akun siswa.');
        } else {
          throw Exception('Akses ditolak: Hak akses tidak sesuai.');
        }
      }

      if (profile['role'] == 'parent') {
        try {
          final link = await _client
              .from('parent_students')
              .select('student_id')
              .eq('parent_id', profile['id'])
              .maybeSingle();
          if (link != null) {
            profile = Map<String, dynamic>.from(profile);
            profile['student_id'] = link['student_id'];
          }
        } catch (_) {}
      }

      _currentProfile = profile;

      // --- Step 5: Obtain a secure hashed session token for transactional RPCs ---
      // Only for operational roles that perform purchases/topups/corrections.
      String? sessionToken;
      try {
        final sessionResult = await _client.rpc('create_user_session', params: {
          'p_email': resolvedEmail,
          'p_password': password,
        });
        final Map<String, dynamic> sessionData;
        if (sessionResult is Map<String, dynamic>) {
          sessionData = sessionResult;
        } else if (sessionResult is String) {
          sessionData = jsonDecode(sessionResult) as Map<String, dynamic>;
        } else {
          sessionData = {};
        }
        if (sessionData['success'] == true) {
          sessionToken = sessionData['session_token'] as String?;
        }
      } catch (_) {
        // Non-fatal: session token is best-effort. App functions, but transactional
        // RPCs will fail if token is null — user will see a friendly error message.
      }

      return {'profile': profile!, 'session_token': sessionToken};
    } catch (e) {
      final String errString = e.toString();
      if (errString.contains('SocketException') ||
          errString.contains('Failed host lookup')) {
        throw Exception(
          '${AppStrings.labelFailed} menghubungkan ke server. Periksa koneksi internet Anda atau pastikan URL Supabase sudah benar.',
        );
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  // Sign Out current session (both Supabase Auth, local profile cache,
  // and secure storage)
  Future<void> signOut() async {
    _currentProfile = null;
    await SecureSessionService.clearSession();
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors
    }
  }

  // Check if session is active via Supabase Auth
  Session? get currentSession => _client.auth.currentSession;

  // Get auth state changes stream from Supabase Auth
  Stream<dynamic> get onAuthStateChange => _client.auth.onAuthStateChange;

  // Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (_currentProfile != null) return _currentProfile;

    final session = _client.auth.currentSession;
    if (session != null) {
      try {
        var profile = await _client
            .from('profiles')
            .select('*')
            .eq('id', session.user.id)
            .maybeSingle();

        // Remove password hash from profile (never needed after auth)
        if (profile != null && profile.containsKey('password')) {
          profile = Map<String, dynamic>.from(profile);
          profile.remove('password');
        }
        
        if (profile != null && profile['role'] == 'parent') {
          try {
            final link = await _client
                .from('parent_students')
                .select('student_id')
                .eq('parent_id', profile['id'])
                .maybeSingle();
            if (link != null) {
              profile = Map<String, dynamic>.from(profile);
              profile['student_id'] = link['student_id'];
            }
          } catch (_) {}
        }

        _currentProfile = profile;
        return profile;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
