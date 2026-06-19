/// Data model untuk tabel `products`.
///
/// Merepresentasikan katalog jajanan/produk di stan kantin.
class Product {
  final String id;
  final String operatorId;
  final String name;
  final double price;
  final String category;
  final bool isAvailable;
  final String? imageUrl;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.imageUrl,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      operatorId: json['operator_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Produk',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      category: json['category']?.toString() ?? 'makanan',
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
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
  };

  Product copyWith({
    String? id,
    String? operatorId,
    String? name,
    double? price,
    String? category,
    bool? isAvailable,
    String? imageUrl,
    DateTime? createdAt,
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
    );
  }

  bool get isMakanan => category == 'makanan';
  bool get isMinuman => category == 'minuman';

  @override
  String toString() =>
      'Product(id: $id, name: $name, price: $price, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
