import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  try {
    print('=== LIST OF ALL ORDERS ===');
    final List<dynamic> orders = await client.from('orders').select('*');
    print('Total orders: ${orders.length}');
    for (var o in orders) {
      print('Order: $o');
    }
  } catch (e) {
    print('Error: $e');
  }
}
