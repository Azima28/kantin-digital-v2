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

  /// Nested object dari join Supabase (opsional).
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
    return TransactionItem(
      id: json['id']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
      productId: json['product_id'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice:
          int.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      customNotes: json['custom_notes'] as String?,
      product: (json['product'] ?? json['products']) as Map<String, dynamic>?,
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

  /// Nama produk dari join data.
  String get productName {
    if (product != null) {
      return product!['name'] as String? ?? '-';
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
