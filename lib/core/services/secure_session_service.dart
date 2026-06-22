import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSessionService {
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'supabase_session';

  static Future<void> saveSession(String sessionJson) async {
    await _storage.write(key: _sessionKey, value: sessionJson);
  }

  static Future<String?> getSession() async {
    return await _storage.read(key: _sessionKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  /// Initialize auth state listener to persist session to secure storage
  static Future<void> initAuthListener() async {
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
  }
}
