import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase.instance.client.
///
/// Provides a single access point so services (e.g. [ConnectivityService])
/// can depend on a stable import instead of calling Supabase.instance directly.
class SupabaseClientService {
  static SupabaseClient getClient() => Supabase.instance.client;
}
