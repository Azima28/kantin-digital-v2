import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/features/auth/services/auth_service.dart';

// Provider untuk instance SupabaseClient
final Provider<SupabaseClient> supabaseClientProvider =
    Provider<SupabaseClient>((Ref ref) {
      return Supabase.instance.client;
    });

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

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.profile,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? profile,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profile: profile ?? this.profile,
      errorMessage: errorMessage, // We allow setting it to null
    );
  }
}

// StateNotifier untuk mengelola aksi & state autentikasi
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkInitialSession();
  }

  // Cek sesi login saat inisialisasi awal
  Future<void> _checkInitialSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final Session? session = _authService.currentSession;
      if (session != null) {
        final Map<String, dynamic>? profile = await _authService
            .getCurrentProfile();
        if (profile != null && (profile['role'] == 'petugas_kantin' || profile['role'] == 'student')) {
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
  Future<bool> login(String email, String password, {String role = 'petugas_kantin'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final Map<String, dynamic> profile = await _authService.signIn(
        email: email,
        password: password,
        expectedRole: role,
      );
      debugPrint('DEBUG - Login SUCCESS, Profile: $profile');
      state = AuthState(isAuthenticated: true, profile: profile);
      return true;
    } catch (e) {
      debugPrint('DEBUG - Login ERROR: $e');
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
    state = const AuthState(isAuthenticated: false);
  }
}

// Provider untuk StateNotifier
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((Ref ref) {
      final AuthService service = ref.watch(authServiceProvider);
      return AuthNotifier(service);
    });
