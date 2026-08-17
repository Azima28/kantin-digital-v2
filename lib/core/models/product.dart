/// Data model untuk tabel `products`.
///
/// Merepresentasikan katalog jajanan/produk di stan kantin.
class Product {
  final String id;
  final String operatorId;
  final String name;
  final int price;
  final String category;
  final bool isAvailable;
  final String? imageUrl;
  final DateTime? createdAt;
  final List<String> customizableOptions;
  final String? canteenName;
  final bool isDeliveryEnabled;
  final int deliveryFee;
  final double rating;
  final int totalReviews;
  final int totalSold;

  const Product({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.imageUrl,
    this.createdAt,
    this.customizableOptions = const <String>[],
    this.canteenName,
    this.isDeliveryEnabled = true,
    this.deliveryFee = 2000,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalSold = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      operatorId: json['operator_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Produk',
      price: (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0).toInt(),
      category: json['category']?.toString() ?? 'makanan',
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      customizableOptions: (json['customizable_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      canteenName: json['canteen_name']?.toString(),
      isDeliveryEnabled: json['is_delivery_enabled'] as bool? ?? true,
      deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 2000,
      rating: (double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0),
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      totalSold: (json['total_sold'] as num?)?.toInt() ??
          (json['sold_count'] as num?)?.toInt() ??
          (json['terjual'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'operator_id': operatorId,
    'name': name,
    'price': price,
    'category': category,
    'is_available': isAvailable,
    'image_url': imageUrl,
    'created_at': createdAt?.toIso8601String(),
    'customizable_options': customizableOptions,
    'canteen_name': canteenName,
    'is_delivery_enabled': isDeliveryEnabled,
    'delivery_fee': deliveryFee,
    'rating': rating,
    'total_reviews': totalReviews,
    'total_sold': totalSold,
  };

  Product copyWith({
    String? id,
    String? operatorId,
    String? name,
    int? price,
    String? category,
    bool? isAvailable,
    String? imageUrl,
    DateTime? createdAt,
    List<String>? customizableOptions,
    String? canteenName,
    bool? isDeliveryEnabled,
    int? deliveryFee,
    double? rating,
    int? totalReviews,
    int? totalSold,
  }) {
    return Product(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      customizableOptions: customizableOptions ?? this.customizableOptions,
      canteenName: canteenName ?? this.canteenName,
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalSold: totalSold ?? this.totalSold,
    );
  }

  bool get isMakanan => category == 'makanan';
  bool get isMinuman => category == 'minuman';
  bool get hasRating => totalReviews > 0 && rating > 0;

  @override
  String toString() =>
      'Product(id: $id, name: $name, price: $price, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
