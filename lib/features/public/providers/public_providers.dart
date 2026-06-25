import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

// ─── Helper: pairs a Product with its canteen name ───
class ProductWithCanteen {
  final Product product;
  final String canteenName;
  const ProductWithCanteen({required this.product, required this.canteenName});
}

// ─── Provider untuk fetch menu publik (Legacy fallback) ───
final publicMenuProvider = FutureProvider.autoDispose
    .family<List<ProductWithCanteen>, String?>((ref, category) async {
  final client = ref.read(supabaseClientProvider);

  List<dynamic> res;
  if (category != null && category.isNotEmpty) {
    res = await client
        .from('products')
        .select(
            'id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
        .eq('category', category)
        .order('is_available', ascending: false)
        .order('name', ascending: true);
  } else {
    res = await client
        .from('products')
        .select(
            'id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
        .order('is_available', ascending: false)
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

// ─── [NEW] Provider daftar stan kantin aktif untuk filter ───
final publicCanteensProvider = FutureProvider.autoDispose<List<CanteenOperator>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client
      .from('canteen_operators')
      .select('id, canteen_name, balance_earned')
      .order('canteen_name', ascending: true);

  return res.map((e) => CanteenOperator.fromJson(e)).toList();
});

// ─── [NEW] Model filter preview untuk sectioned list ───
class PreviewFilter {
  final String category;
  final String? canteenId;
  const PreviewFilter({required this.category, this.canteenId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewFilter &&
          category == other.category &&
          canteenId == other.canteenId;

  @override
  int get hashCode => category.hashCode ^ canteenId.hashCode;
}

// ─── [NEW] Provider untuk memuat preview 4 item per kategori ───
final categoryPreviewProvider = FutureProvider.autoDispose
    .family<List<ProductWithCanteen>, PreviewFilter>((ref, filter) async {
  final client = ref.read(supabaseClientProvider);
  
  var query = client
      .from('products')
      .select('id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)')
      .eq('category', filter.category);

  if (filter.canteenId != null) {
    query = query.eq('operator_id', filter.canteenId!);
  }

  // Hanya memuat 4 item untuk efisiensi database (preview)
  final res = await query
      .order('is_available', ascending: false)
      .order('name', ascending: true)
      .range(0, 3);

  return res.map((data) {
    final canteenData = data['canteen_operators'];
    final canteenName = canteenData is Map<String, dynamic>
        ? (canteenData['canteen_name'] as String? ?? 'Stan Lainnya')
        : 'Stan Lainnya';
    return ProductWithCanteen(
        product: Product.fromJson(data), canteenName: canteenName);
  }).toList();
});

// ─── [NEW] Objek filter pagination ───
class PaginatedProductsFilter {
  final String? category;
  final String? canteenId;
  final String searchQuery;
  const PaginatedProductsFilter({this.category, this.canteenId, this.searchQuery = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedProductsFilter &&
          category == other.category &&
          canteenId == other.canteenId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => category.hashCode ^ canteenId.hashCode ^ searchQuery.hashCode;
}

// ─── [NEW] Status state pagination ───
class PaginatedProductsState {
  final List<ProductWithCanteen> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final String? error;

  const PaginatedProductsState({
    required this.items,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.error,
  });

  PaginatedProductsState copyWith({
    List<ProductWithCanteen>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? error,
  }) {
    return PaginatedProductsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
    );
  }
}

// ─── [NEW] StateNotifier Pagination dengan Supabase Range ───
class PaginatedProductsNotifier extends StateNotifier<PaginatedProductsState> {
  final Ref ref;
  final PaginatedProductsFilter filter;
  static const int _pageSize = 8; // Memuat 8 jajanan per halaman

  PaginatedProductsNotifier(this.ref, this.filter) : super(const PaginatedProductsState(items: [])) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, hasReachedMax: false);
    try {
      final client = ref.read(supabaseClientProvider);
      var query = client
          .from('products')
          .select('id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)');

      if (filter.category != null) {
        query = query.eq('category', filter.category!);
      }
      if (filter.canteenId != null) {
        query = query.eq('operator_id', filter.canteenId!);
      }
      if (filter.searchQuery.isNotEmpty) {
        query = query.ilike('name', '%${filter.searchQuery}%');
      }

      final res = await query
          .order('is_available', ascending: false)
          .order('name', ascending: true)
          .range(0, _pageSize - 1);

      final items = _mapResponse(res);
      state = PaginatedProductsState(
        items: items,
        isLoading: false,
        hasReachedMax: items.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedMax) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final client = ref.read(supabaseClientProvider);
      final int start = state.items.length;
      final int end = start + _pageSize - 1;

      var query = client
          .from('products')
          .select('id, operator_id, name, price, category, is_available, image_url, canteen_operators(canteen_name)');

      if (filter.category != null) {
        query = query.eq('category', filter.category!);
      }
      if (filter.canteenId != null) {
        query = query.eq('operator_id', filter.canteenId!);
      }
      if (filter.searchQuery.isNotEmpty) {
        query = query.ilike('name', '%${filter.searchQuery}%');
      }

      final res = await query
          .order('is_available', ascending: false)
          .order('name', ascending: true)
          .range(start, end);

      final newItems = _mapResponse(res);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingMore: false,
        hasReachedMax: newItems.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  List<ProductWithCanteen> _mapResponse(List<dynamic> res) {
    return res.map((e) {
      final data = e as Map<String, dynamic>;
      final canteenData = data['canteen_operators'];
      final canteenName = canteenData is Map<String, dynamic>
          ? (canteenData['canteen_name'] as String? ?? 'Stan Lainnya')
          : 'Stan Lainnya';
      return ProductWithCanteen(
          product: Product.fromJson(data), canteenName: canteenName);
    }).toList();
  }
}

// ─── [NEW] Provider keluarga untuk pagination ───
final paginatedProductsProvider = StateNotifierProvider.family<
    PaginatedProductsNotifier, PaginatedProductsState, PaginatedProductsFilter>((ref, filter) {
  return PaginatedProductsNotifier(ref, filter);
});
