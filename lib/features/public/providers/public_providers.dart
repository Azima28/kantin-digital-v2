import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';

// ─── Helper: pairs a Product with its canteen name & delivery settings ───
class ProductWithCanteen {
  final Product product;
  final String canteenName;
  final bool isDeliveryEnabled;
  final int deliveryFee;

  const ProductWithCanteen({
    required this.product,
    required this.canteenName,
    this.isDeliveryEnabled = true,
    this.deliveryFee = 2000,
  });
}

// ─── Provider untuk fetch menu publik (Cache Window 5 Menit) ───
final publicMenuProvider = FutureProvider.autoDispose
    .family<List<ProductWithCanteen>, String?>((ref, category) async {
  ref.cacheFor(const Duration(minutes: 5));
  final apiClient = ref.read(apiClientProvider);
  final queryParams = <String, dynamic>{};
  if (category != null && category.isNotEmpty) {
    queryParams['category'] = category;
  }

  final response = await apiClient.get('/products', queryParams: queryParams);
  if (response.success && response.data != null) {
    final list = response.data as List<dynamic>;
    return list.map((e) {
      final data = e as Map<String, dynamic>;
      final canteenName = data['canteen_name'] as String? ?? 'Stan Kantin';
      final isDeliveryEnabled = data['is_delivery_enabled'] as bool? ?? true;
      final deliveryFee = (data['delivery_fee'] as num?)?.toInt() ?? 2000;
      return ProductWithCanteen(
        product: Product.fromJson(data),
        canteenName: canteenName,
        isDeliveryEnabled: isDeliveryEnabled,
        deliveryFee: deliveryFee,
      );
    }).toList();
  }
  return <ProductWithCanteen>[];
});

// ─── Provider daftar stan kantin aktif (Cache Window 5 Menit) ───
final publicCanteensProvider = FutureProvider.autoDispose<List<CanteenOperator>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/canteens');
  if (response.success && response.data != null) {
    final list = response.data as List<dynamic>;
    return list.map((e) => CanteenOperator.fromJson(e as Map<String, dynamic>)).toList();
  }
  return <CanteenOperator>[];
});

// ─── Model filter preview untuk sectioned list ───
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

// ─── Provider untuk memuat preview 4 item per kategori (Cache Window 3 Menit) ───
final categoryPreviewProvider = FutureProvider.autoDispose
    .family<List<ProductWithCanteen>, PreviewFilter>((ref, filter) async {
  ref.cacheFor(const Duration(minutes: 3));
  final apiClient = ref.read(apiClientProvider);
  final queryParams = <String, dynamic>{
    'category': filter.category,
  };
  if (filter.canteenId != null && filter.canteenId != 'semua') {
    queryParams['canteen_id'] = filter.canteenId;
  }

  final response = await apiClient.get('/products', queryParams: queryParams);
  if (response.success && response.data != null) {
    final list = response.data as List<dynamic>;
    return list.take(4).map((data) {
      final map = data as Map<String, dynamic>;
      final canteenName = map['canteen_name'] as String? ?? 'Stan Kantin';
      final isDeliveryEnabled = map['is_delivery_enabled'] as bool? ?? true;
      final deliveryFee = (map['delivery_fee'] as num?)?.toInt() ?? 2000;
      return ProductWithCanteen(
        product: Product.fromJson(map),
        canteenName: canteenName,
        isDeliveryEnabled: isDeliveryEnabled,
        deliveryFee: deliveryFee,
      );
    }).toList();
  }
  return <ProductWithCanteen>[];
});

// ─── Objek filter pagination ───
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

// ─── Status state pagination ───
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

// ─── StateNotifier Pagination ───
class PaginatedProductsNotifier extends StateNotifier<PaginatedProductsState> {
  final Ref ref;
  final PaginatedProductsFilter filter;

  PaginatedProductsNotifier(this.ref, this.filter) : super(const PaginatedProductsState(items: [])) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, hasReachedMax: false);
    try {
      final apiClient = ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{};
      if (filter.category != null) {
        queryParams['category'] = filter.category;
      }
      if (filter.canteenId != null && filter.canteenId != 'semua') {
        queryParams['canteen_id'] = filter.canteenId;
      }
      if (filter.searchQuery.isNotEmpty) {
        queryParams['search'] = filter.searchQuery;
      }

      final response = await apiClient.get('/products', queryParams: queryParams);
      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final items = list.map((e) {
          final data = e as Map<String, dynamic>;
          final canteenName = data['canteen_name'] as String? ?? 'Stan Kantin';
          final isDeliveryEnabled = data['is_delivery_enabled'] as bool? ?? true;
          final deliveryFee = (data['delivery_fee'] as num?)?.toInt() ?? 2000;
          return ProductWithCanteen(
            product: Product.fromJson(data),
            canteenName: canteenName,
            isDeliveryEnabled: isDeliveryEnabled,
            deliveryFee: deliveryFee,
          );
        }).toList();

        state = PaginatedProductsState(
          items: items,
          isLoading: false,
          hasReachedMax: true,
        );
      } else {
        state = PaginatedProductsState(items: [], isLoading: false, hasReachedMax: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    // Single page response from Go in-memory high-speed cache
  }
}

// ─── Provider keluarga untuk pagination ───
final paginatedProductsProvider = StateNotifierProvider.family<
    PaginatedProductsNotifier, PaginatedProductsState, PaginatedProductsFilter>((ref, filter) {
  return PaginatedProductsNotifier(ref, filter);
});
