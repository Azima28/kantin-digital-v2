import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  try {
    print('=== LIST OF ALL STUDENTS ===');
    final List<dynamic> students = await client.from('students').select('*');
    print('Total students: ${students.length}');
    for (var s in students) {
      print('Student: $s');
    }
  } catch (e) {
    print('Error: $e');
  }
}
