import 'package:kantin_digital/core/services/supabase_client.dart';

/// Minimal connectivity checker.
///
/// Performs a lightweight query against the Supabase backend with a 5‑second
/// timeout. Returns `true` if the server responds, `false` otherwise.
///
/// No third‑party package is required — only what the project already depends on.
class ConnectivityService {
  /// Returns `true` when the app can reach the Supabase backend.
  static Future<bool> isOnline() async {
    try {
      final client = SupabaseClientService.getClient();
      await client.from('system_settings').select('id').limit(1).timeout(
        const Duration(seconds: 5),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
