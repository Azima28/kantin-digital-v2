import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  try {
    final profileId = 'aa697fa2-bf4f-4d92-bb63-547a46985025';
    
    print('Querying active orders for profileId: $profileId ...');
    final response = await client
        .from('orders')
        .select(
            'id, student_id, student_name, status, delivery_location, total_amount, created_at, cancel_request_reason, order_items(product_name, quantity, price)')
        .eq('student_id', profileId)
        .not('status', 'in', '("Selesai","Dibatalkan")');
        
    print('Query returned: $response');
  } catch (e) {
    print('Error: $e');
  }
}
