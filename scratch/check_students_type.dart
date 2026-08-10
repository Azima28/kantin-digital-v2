import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  try {
    print('Checking students type in database...');
    // We can query pg_class via pg_catalog or a custom RPC if available, or just check information_schema
    // Wait, we don't have direct SQL runner, but maybe we can query pg_class if RLS/permissions allow?
    // Let's try to query public tables via postgrest if there is any mapping.
    // Usually, information_schema is not exposed to PostgREST unless explicitly done.
    // Let's check if we can query it:
    final res = await client.from('students').select('*').limit(1);
    print('First row of students: $res');
  } catch (e) {
    print('Error: $e');
  }
}
