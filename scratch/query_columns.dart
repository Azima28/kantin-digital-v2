import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://vgainyzrpfyaakqttjbm.supabase.co',
    'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI',
  );

  print("=== 1. Checking Columns of 'transactions' ===");
  try {
    // Select one row from transactions and print keys
    final List<dynamic> txs = await supabase
        .from('transactions')
        .select('*')
        .limit(1);

    if (txs.isNotEmpty) {
      print("Columns in transactions table: ${txs.first.keys.toList()}");
    } else {
      print("Transactions table is empty!");
    }
  } catch (e) {
    print("Error getting columns: $e");
  }

  print("\n=== 2. Checking Recent Transactions Data ===");
  try {
    final List<dynamic> txs = await supabase
        .from('transactions')
        .select('*, canteen_operators(canteen_name)')
        .limit(5);

    for (var tx in txs) {
      print(tx);
    }
  } catch (e) {
    print("Error getting recent transactions: $e");
  }
}
