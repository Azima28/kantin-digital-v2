import 'package:http/http.dart' as http;

/// Minimal connectivity checker for Kantin Digital Go Backend.
class ConnectivityService {
  static const String _healthUrl = String.fromEnvironment(
    'BACKEND_HEALTH_URL',
    defaultValue: 'http://127.0.0.1:8000/health',
  );

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
