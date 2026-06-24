import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/features/auth/services/auth_service.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// Re-export supabaseClientProvider for backward compatibility
export 'package:kantin_digital/core/providers/shared_providers.dart'
    show supabaseClientProvider;

/// Role string constants used across auth logic.
class AuthRoles {
  static const String student = 'student';
  static const String keuangan = 'petugas_keuangan';
  static const String canteen = 'petugas_kantin';
  static const String parent = 'parent';
  static const String superAdmin = 'super_admin';
}

// Provider untuk AuthService
final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref ref,
) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

// Model State untuk Autentikasi
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? profile;
  final String? errorMessage;
  /// Plaintext session token returned by `create_user_session` RPC.
  /// Only the authenticated client holds this — the DB stores only the SHA-256 hash.
  final String? sessionToken;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.profile,
    this.errorMessage,
    this.sessionToken,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? profile,
    String? errorMessage,
    String? sessionToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profile: profile ?? this.profile,
      errorMessage: errorMessage, // We allow setting it to null
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }
}

// StateNotifier untuk mengelola aksi & state autentikasi
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // Delay ke post-frame biar gak trigger rebuild mid-layout
    Future.microtask(_checkInitialSession);
  }

  // Cek sesi login saat inisialisasi awal
  // NOTE: sengaja gak pake isLoading biar gak muncul spinner di tombol login.
  // Loading cuma dipake pas user beneran login, bukan pas startup.
  Future<void> _checkInitialSession() async {
    try {
      final Session? session = _authService.currentSession;
      if (session != null) {
        final Map<String, dynamic>? profile = await _authService
            .getCurrentProfile();
        if (profile != null && (profile['role'] == AuthRoles.canteen || profile['role'] == AuthRoles.student || profile['role'] == AuthRoles.parent || profile['role'] == AuthRoles.superAdmin || profile['role'] == AuthRoles.keuangan)) {
          state = AuthState(isAuthenticated: true, profile: profile);
          return;
        }
      }
      state = const AuthState(isAuthenticated: false);
    } catch (e) {
      state = AuthState(errorMessage: e.toString());
    }
  }

  // Fungsi Login
  Future<bool> login(String email, String password, {String role = ''}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
        expectedRole: role,
      );
      final Map<String, dynamic> profile = result['profile'] as Map<String, dynamic>;
      final String? sessionToken = result['session_token'] as String?;
      state = AuthState(
        isAuthenticated: true,
        profile: profile,
        sessionToken: sessionToken,
      );
      return true;
    } catch (e) {
      state = AuthState(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // Fungsi Logout Kasir
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthState(isAuthenticated: false, sessionToken: null);
  }
}

// Provider untuk StateNotifier
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((Ref ref) {
      final AuthService service = ref.watch(authServiceProvider);
      return AuthNotifier(service);
    });
