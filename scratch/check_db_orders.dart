import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  try {
    final profileId = 'aa697fa2-bf4f-4d92-bb63-547a46985025';
    print('Querying using profile_id and actual database column names...');
    final student = await client
        .from('students')
        .select('id, balance, card_uid, status')
        .eq('profile_id', profileId)
        .maybeSingle();
    print('Result: $student');
  } catch (e) {
    print('Error: $e');
  }
}
