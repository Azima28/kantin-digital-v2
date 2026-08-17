/// Data model untuk tabel `transaction_items`.
///
/// Mencatat detail item per transaksi belanja di kasir kantin.
class TransactionItem {
  final String id;
  final String transactionId;
  final String? productId;
  final int quantity;
  final int unitPrice;
  final String? customNotes;

  /// Nested object produk (opsional).
  final Map<String, dynamic>? product;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    this.productId,
    required this.quantity,
    required this.unitPrice,
    this.customNotes,
    this.product,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? prod = (json['product'] ?? json['products']) as Map<String, dynamic>?;
    if (prod == null && (json['product_name'] != null || json['image_url'] != null || json['name'] != null)) {
      prod = {
        'name': json['product_name'] ?? json['name'],
        'image_url': json['image_url'],
      };
    }
    return TransactionItem(
      id: json['id']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
      productId: json['product_id'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice:
          (double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0).toInt(),
      customNotes: json['custom_notes'] as String?,
      product: prod,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'custom_notes': customNotes,
      };

  /// Total harga item = quantity × unitPrice
  int get totalPrice => quantity * unitPrice;

  /// URL Gambar thumbnail produk
  String? get imageUrl {
    if (product != null && product!['image_url'] != null) {
      return product!['image_url']?.toString();
    }
    return null;
  }

  /// Nama produk dari join data.
  String get productName {
    if (product != null) {
      return product!['name'] as String? ?? product!['product_name'] as String? ?? '-';
    }
    return '-';
  }

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? productId,
    int? quantity,
    int? unitPrice,
    String? customNotes,
    Map<String, dynamic>? product,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      customNotes: customNotes ?? this.customNotes,
      product: product ?? this.product,
    );
  }

  @override
  String toString() =>
      'TransactionItem(id: $id, product: $productId, qty: $quantity, price: $unitPrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransactionItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
