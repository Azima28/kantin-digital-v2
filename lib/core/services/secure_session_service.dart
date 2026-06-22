import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSessionService {
  static const _sessionKey = 'supabase_session';

  static Future<FlutterSecureStorage?> get _storage async {
    if (kIsWeb) return null; // Web: unsupported
    try {
      return const FlutterSecureStorage();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSession(String sessionJson) async {
    final s = await _storage;
    await s?.write(key: _sessionKey, value: sessionJson);
  }

  static Future<String?> getSession() async {
    final s = await _storage;
    return s?.read(key: _sessionKey);
  }

  static Future<void> clearSession() async {
    final s = await _storage;
    await s?.delete(key: _sessionKey);
  }

  /// Initialize auth state listener to persist session to secure storage
  static Future<void> initAuthListener() async {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          final session = data.session;
          if (session != null) {
            final sessionJson = jsonEncode({
              'access_token': session.accessToken,
              'refresh_token': session.refreshToken,
            });
            saveSession(sessionJson);
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          clearSession();
        }
      });
    } catch (_) {
      // Web atau platform lain: skip secure storage, Supabase handle sendiri
    }
  }
}
