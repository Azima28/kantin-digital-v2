import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final url = Uri.parse('https://vgainyzrpfyaakqttjbm.supabase.co/rest/v1/transactions?select=*&limit=5');
    final request = await client.getUrl(url);
    
    // Add headers
    request.headers.add('apikey', 'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI');
    request.headers.add('Authorization', 'Bearer sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('=== Supabase Response Status: ${response.statusCode} ===');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(responseBody);
      if (data.isNotEmpty) {
        print('Columns in transactions: ${data.first.keys.toList()}');
        print('\n=== Sample Data ===');
        for (var row in data) {
          print(row);
        }
      } else {
        print('Transactions table is empty!');
      }
    } else {
      print('Failed to load. Response: $responseBody');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
