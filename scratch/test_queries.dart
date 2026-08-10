import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing SupabaseClient...');
  final client = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  print('\n--- Testing Student Query ---');
  try {
    final res = await client
        .from('profiles')
        .select(
          'id, full_name, email, nisn, is_active, students:students!students_id_fkey(class, balance, rfid_uid, is_active)',
        )
        .eq('role', 'student')
        .order('full_name', ascending: true);
    print('Student Query Success! Retrieved ${res.length} rows.');
    if (res.isNotEmpty) {
      print('First Student: ${res.first}');
    }
  } catch (e) {
    print('Student Query Failed: $e');
  }

  print('\n--- Testing Parent Query ---');
  try {
    final res = await client
        .from('profiles')
        .select(
          'id, full_name, email, phone_number, is_active, created_at, parent_students!parent_students_parent_id_fkey(students!parent_students_student_id_fkey(id, class, profiles:profiles!students_id_fkey(full_name, nisn)))',
        )
        .eq('role', 'parent')
        .order('full_name', ascending: true);
    print('Parent Query Success! Retrieved ${res.length} rows.');
    if (res.isNotEmpty) {
      print('First Parent: ${res.first}');
    }
  } catch (e) {
    print('Parent Query Failed: $e');
  }
}
