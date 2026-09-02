import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/services/secure_session_service.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/features/auth/services/auth_service.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

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
  final ApiClient apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// Model State untuk Autentikasi
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? profile;
  final String? errorMessage;
  final String? sessionToken;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.profile,
    this.errorMessage,
    this.sessionToken,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? profile,
    String? errorMessage,
    String? sessionToken,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      sessionToken: sessionToken ?? this.sessionToken,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// StateNotifier untuk mengelola aksi & state autentikasi
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiClient _apiClient;
  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier(this._authService, this._apiClient) : super(const AuthState()) {
    _initAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initAuthListener() async {
    // 0. Listen for sliding session token renewals and account blocked / unauthorized signals from backend
    _apiClient.onTokenRenewed = (String newToken) {
      updateSessionToken(newToken);
    };
    _apiClient.onAccountBlocked = () {
      updateAccountActiveStatus(false);
    };
    _apiClient.onUnauthorized = () async {
      await SecureSessionService.clearSessionData();
      _apiClient.clearAuthToken();
      if (mounted) {
        state = const AuthState(isAuthenticated: false, isInitialized: true, isLoading: false);
      }
    };

    // 1. Check persistent 7-day session storage on launch or page refresh first
    try {
      final cachedSession = await SecureSessionService.getValidSessionData();
      if (cachedSession != null && cachedSession['profile'] != null) {
        final Map<String, dynamic> profile = Map<String, dynamic>.from(cachedSession['profile'] as Map);
        final String? sessionToken = cachedSession['session_token']?.toString();
        if (sessionToken != null && sessionToken.isNotEmpty) {
          _apiClient.setAuthToken(sessionToken);
        }
        state = AuthState(
          isAuthenticated: true,
          profile: profile,
          sessionToken: sessionToken,
          isInitialized: true,
          isLoading: false,
        );

        // Background session verification against backend. It doubles as a profile
        // re-read: the cached copy restored above can be up to 7 days old and is
        // never refreshed otherwise, so a photo changed in an earlier session or
        // on another device would stay invisible on this one.
        refreshProfileFromServer().then((isValid) {
          if (!isValid && mounted) {
            _apiClient.onUnauthorized?.call();
          }
        });
      }
    } catch (e) {
      debugPrint('Error reading cached session: $e');
    }

    // Safety fallback timeout to prevent stuck splash screen on slow network initialization
    Future.delayed(const Duration(seconds: 2), () {
      if (!state.isInitialized && mounted) {
        state = state.copyWith(isInitialized: true, isLoading: false);
      }
    });

    _authSubscription = _authService.onAuthStateChange.listen((profile) async {
      if (profile != null) {
        state = AuthState(
          isAuthenticated: true,
          profile: profile,
          sessionToken: state.sessionToken,
          isInitialized: true,
          isLoading: false,
        );
      } else {
        state = const AuthState(isAuthenticated: false, isInitialized: true, isLoading: false);
      }
    });
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
      final Map<String, dynamic> profile = Map<String, dynamic>.from(result['profile'] as Map);
      final String? sessionToken = result['session_token']?.toString();

      if (sessionToken != null && sessionToken.isNotEmpty) {
        _apiClient.setAuthToken(sessionToken);
      }

      // Persist to 7-day local storage
      await SecureSessionService.saveSessionData(
        profile: profile,
        sessionToken: sessionToken,
      );

      state = AuthState(
        isAuthenticated: true,
        profile: profile,
        sessionToken: sessionToken,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      state = AuthState(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        isInitialized: true,
      );
      return false;
    }
  }

  // Update renewed session token from sliding session seamlessly
  Future<void> updateSessionToken(String newToken) async {
    if (state.sessionToken == newToken) return;
    _apiClient.setAuthToken(newToken);
    if (state.profile != null) {
      await SecureSessionService.saveSessionData(
        profile: state.profile!,
        sessionToken: newToken,
      );
    }
    state = state.copyWith(sessionToken: newToken);
  }

  // Update account active status (e.g. from real-time blocked event or 403 response)
  Future<void> updateAccountActiveStatus(bool isActive) async {
    if (state.profile != null && state.profile!['is_active'] != isActive) {
      final updatedProfile = Map<String, dynamic>.from(state.profile!);
      updatedProfile['is_active'] = isActive;
      await SecureSessionService.saveSessionData(
        profile: updatedProfile,
        sessionToken: state.sessionToken,
      );
      state = state.copyWith(profile: updatedProfile);
    }
  }

  // Update avatar URL in local profile state & persistent storage
  Future<void> updateProfileAvatar(String avatarUrl) async {
    if (state.profile != null) {
      final updatedProfile = Map<String, dynamic>.from(state.profile!);
      updatedProfile['avatar_url'] = avatarUrl;
      await SecureSessionService.saveSessionData(
        profile: updatedProfile,
        sessionToken: state.sessionToken,
      );
      state = state.copyWith(profile: updatedProfile);
    }
  }

  // Re-read the stored profile from the backend and fold it into state + cache.
  // Reports whether the session is still valid, so it can stand in for
  // validateSession() without spending a second round trip.
  Future<bool> refreshProfileFromServer() async {
    final response = await _apiClient.get('/auth/me');
    final bool isSessionValid = response.success && response.statusCode == 200;
    if (!isSessionValid || response.data == null) return isSessionValid;

    try {
      final Map<String, dynamic> server = Map<String, dynamic>.from(response.data as Map);
      // A backend that cannot read the row answers with the raw JWT claims, which
      // carry no id. There is nothing to sync from in that case, and merging it
      // would drop fields the cached profile still holds.
      if (server['id'] == null) return true;

      final Map<String, dynamic> merged = Map<String, dynamic>.from(state.profile ?? {})..addAll(server);
      // avatar_url is omitted from the payload when the profile has none, so it is
      // assigned explicitly: otherwise a photo removed elsewhere would survive in
      // this cache forever.
      merged['avatar_url'] = server['avatar_url'];

      if (!mounted) return true;
      await SecureSessionService.saveSessionData(
        profile: merged,
        sessionToken: state.sessionToken,
      );
      if (mounted) state = state.copyWith(profile: merged);
    } catch (e) {
      debugPrint('[AuthNotifier] Refresh profile error: $e');
    }
    return true;
  }

  // Update profile details (Full name, Email, Username, Phone number, Gender) to Go Backend & persistent local state
  Future<bool> updateProfileDetails({
    required String fullName,
    String? email,
    String? username,
    String? phoneNumber,
    String? gender,
  }) async {
    try {
      final response = await _apiClient.patch('/auth/profile', body: {
        'full_name': fullName.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
        'phone_number': phoneNumber?.trim(),
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
      });
      if (response.success && response.data != null) {
        final updatedMap = Map<String, dynamic>.from(response.data as Map);
        final currentProfile = Map<String, dynamic>.from(state.profile ?? {});
        currentProfile['full_name'] = updatedMap['full_name'] ?? fullName.trim();
        if (email != null && email.trim().isNotEmpty) currentProfile['email'] = updatedMap['email'] ?? email.trim();
        if (username != null && username.trim().isNotEmpty) currentProfile['username'] = updatedMap['username'] ?? username.trim();
        if (phoneNumber != null) currentProfile['phone_number'] = phoneNumber.trim();
        currentProfile['phone'] = phoneNumber?.trim();
        if (gender != null) currentProfile['gender'] = gender.trim();
        if (updatedMap['gender'] != null) currentProfile['gender'] = updatedMap['gender'];
        if (updatedMap['avatar_url'] != null) currentProfile['avatar_url'] = updatedMap['avatar_url'];

        await SecureSessionService.saveSessionData(
          profile: currentProfile,
          sessionToken: state.sessionToken,
        );
        state = state.copyWith(profile: currentProfile);
        return true;
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Update profile error: $e');
    }
    return false;
  }

  // Fungsi Logout Kasir / User
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await SecureSessionService.clearSessionData();
    await _authService.signOut();
    state = const AuthState(isAuthenticated: false, sessionToken: null, isInitialized: true);
  }
}

// Provider untuk StateNotifier
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((Ref ref) {
      final AuthService service = ref.watch(authServiceProvider);
      final ApiClient apiClient = ref.watch(apiClientProvider);
      return AuthNotifier(service, apiClient);
    });
