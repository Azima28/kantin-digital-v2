import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// ─── Helper: pairs a Product with its canteen name ───
class ProductWithCanteen {
  final Product product;
  final String canteenName;
  const ProductWithCanteen({required this.product, required this.canteenName});
}

// ─── Provider untuk fetch menu publik ───
final publicMenuProvider = FutureProvider.autoDispose
    .family<List<ProductWithCanteen>, String?>((ref, category) async {
  final client = ref.read(supabaseClientProvider);

  List<dynamic> res;
  if (category != null && category.isNotEmpty) {
    res = await client
        .from('products')
        .select(
            'id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
        .eq('is_available', true)
        .eq('category', category)
        .order('name', ascending: true);
  } else {
    res = await client
        .from('products')
        .select(
            'id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
        .eq('is_available', true)
        .order('name', ascending: true);
  }

  return res.map((e) {
    final data = e as Map<String, dynamic>;
    final canteenData = data['canteen_operators'];
    final canteenName = canteenData is Map<String, dynamic>
        ? (canteenData['canteen_name'] as String? ?? 'Stan Lainnya')
        : 'Stan Lainnya';
    return ProductWithCanteen(
        product: Product.fromJson(data), canteenName: canteenName);
  }).toList();
});
