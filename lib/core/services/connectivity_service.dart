import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Minimal connectivity checker for Kantin Digital Go Backend.
class ConnectivityService {
  static String get _healthUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file://')) {
        return '$origin/health';
      }
    }
    return const String.fromEnvironment(
      'BACKEND_HEALTH_URL',
      defaultValue: 'https://kantin.zitech.web.id/health',
    );
  }

  /// Returns `true` when the app can reach the Go backend.
  static Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
