import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 7-Day Persistent JWT & Profile Session Service for Kantin Digital v2.0
/// Works across Web, Android, iOS, Windows, Mac, Linux.
class SecureSessionService {
  static const String _sessionKey = 'supabase_session';
  static const String _profileKey = 'kantin_digital_session_profile';
  static const String _sessionTokenKey = 'kantin_digital_session_token';
  static const String _timestampKey = 'kantin_digital_session_timestamp';

  /// Maximum session validity period in days (7 days)
  static const int maxSessionDays = 7;

  static Future<FlutterSecureStorage?> get _storage async {
    if (kIsWeb) return null;
    try {
      return const FlutterSecureStorage();
    } catch (_) {
      return null;
    }
  }

  /// Save session data (profile, RPC token, timestamp) to persistent storage
  static Future<void> saveSessionData({
    required Map<String, dynamic> profile,
    String? sessionToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile));
      if (sessionToken != null) {
        await prefs.setString(_sessionTokenKey, sessionToken);
      }
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());

      // Also attempt secure storage on non-web
      final s = await _storage;
      if (s != null) {
        await s.write(key: _sessionKey, value: jsonEncode(profile));
      }
    } catch (_) {}
  }

  /// Get valid cached session if within 7 days limit
  static Future<Map<String, dynamic>?> getValidSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? timestampStr = prefs.getString(_timestampKey);
      final String? profileStr = prefs.getString(_profileKey);

      if (timestampStr == null || profileStr == null) return null;

      final DateTime timestamp = DateTime.parse(timestampStr);
      final int ageInDays = DateTime.now().difference(timestamp).inDays;

      if (ageInDays >= maxSessionDays) {
        // Session expired (>= 7 days) — clear storage
        await clearSessionData();
        return null;
      }

      final Map<String, dynamic> profile = jsonDecode(profileStr) as Map<String, dynamic>;
      final String? sessionToken = prefs.getString(_sessionTokenKey);

      return {
        'profile': profile,
        'session_token': sessionToken,
      };
    } catch (_) {
      return null;
    }
  }

  /// Clear all saved session data on logout or 7-day expiration
  static Future<void> clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_sessionTokenKey);
      await prefs.remove(_timestampKey);

      final s = await _storage;
      if (s != null) {
        await s.delete(key: _sessionKey);
      }
    } catch (_) {}
  }

  /// Backward compatibility helpers
  static Future<void> saveSession(String sessionJson) async {
    final s = await _storage;
    await s?.write(key: _sessionKey, value: sessionJson);
  }

  static Future<void> clearSession() async {
    await clearSessionData();
  }

  /// Initialize auth state listener to persist session automatically
  static Future<void> initAuthListener() async {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedOut) {
          clearSessionData();
        }
      });
    } catch (_) {}
  }
}
