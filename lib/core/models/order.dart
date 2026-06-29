/// Model untuk Order (pesanan makanan ala GoFood).
///
/// Merepresentasikan tabel `orders` dan `order_items`.

// ─────────────────────────────────────────────────────────────
// DeliveryLocation — pilihan lokasi antar dari DB
// ─────────────────────────────────────────────────────────────

class DeliveryLocation {
  final String id;
  final String name;
  final String type; // 'class', 'room', 'other'
  final bool isActive;
  final int sortOrder;

  const DeliveryLocation({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'DeliveryLocation($name)';
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeliveryLocation && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────
// CanteenInfo — data kantin untuk halaman list & menu siswa
// ─────────────────────────────────────────────────────────────

class CanteenInfo {
  final String id;
  final String canteenName;
  final String fullName;
  final String? avatarUrl;
  final bool deliveryEnabled;
  final int deliveryFee;
  final int productCount;

  const CanteenInfo({
    required this.id,
    required this.canteenName,
    required this.fullName,
    this.avatarUrl,
    this.deliveryEnabled = false,
    this.deliveryFee = 0,
    this.productCount = 0,
  });

  factory CanteenInfo.fromJson(Map<String, dynamic> json) {
    return CanteenInfo(
      id: json['id']?.toString() ?? '',
      canteenName: json['canteen_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      deliveryEnabled: json['delivery_enabled'] as bool? ?? false,
      deliveryFee:
          (double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0)
              .toInt(),
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CanteenInfo && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────
// OrderItemLine — item dalam sebuah pesanan
// ─────────────────────────────────────────────────────────────

class OrderItemLine {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final String? note;

  const OrderItemLine({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.note,
  });

  int get lineTotal => quantity * unitPrice;

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    return OrderItemLine(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: product?['name']?.toString() ?? 'Produk',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice:
          (double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0).toInt(),
      note: json['note']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Order — pesanan utama
// ─────────────────────────────────────────────────────────────

class Order {
  final String id;
  final String studentId;
  final String operatorId;
  final String? transactionId;
  final String status;
  // status: 'pending','accepted','preparing','ready','completed','cancelled'
  final String deliveryType; // 'takeaway' | 'delivery'
  final String? deliveryLocation;
  final int deliveryFee;
  final String? studentPhone;
  final int subtotal;
  final int totalAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (opsional)
  final String? studentName;
  final String? canteenName;
  final List<OrderItemLine> items;

  const Order({
    required this.id,
    required this.studentId,
    required this.operatorId,
    this.transactionId,
    required this.status,
    required this.deliveryType,
    this.deliveryLocation,
    this.deliveryFee = 0,
    this.studentPhone,
    required this.subtotal,
    required this.totalAmount,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.canteenName,
    this.items = const [],
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive =>
      status == 'pending' ||
      status == 'accepted' ||
      status == 'preparing' ||
      status == 'ready';
  bool get isDelivery => deliveryType == 'delivery';
  bool get canCancel => status == 'pending';

  /// Label status dalam bahasa Indonesia
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Diterima';
      case 'preparing':
        return 'Sedang Dimasak';
      case 'ready':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Step index untuk progress indicator (0–4)
  int get statusStep {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // Joined student name
    String? sName;
    final student = json['students'] as Map<String, dynamic>?;
    if (student != null) {
      final profiles = student['profiles'] as Map<String, dynamic>?;
      sName = profiles?['full_name']?.toString() ??
          student['full_name']?.toString();
    }

    // Joined canteen name
    String? cName;
    final canteen = json['canteen_operators'] as Map<String, dynamic>?;
    cName = canteen?['canteen_name']?.toString();

    // Items
    List<OrderItemLine> items = [];
    final rawItems = json['order_items'];
    if (rawItems is List) {
      items = rawItems
          .map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      operatorId: json['operator_id']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      deliveryType: json['delivery_type']?.toString() ?? 'takeaway',
      deliveryLocation: json['delivery_location']?.toString(),
      deliveryFee:
          (double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0)
              .toInt(),
      studentPhone: json['student_phone']?.toString(),
      subtotal:
          (double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0).toInt(),
      totalAmount:
          (double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0)
              .toInt(),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      studentName: sName,
      canteenName: cName,
      items: items,
    );
  }

  Order copyWith({String? status, List<OrderItemLine>? items}) {
    return Order(
      id: id,
      studentId: studentId,
      operatorId: operatorId,
      transactionId: transactionId,
      status: status ?? this.status,
      deliveryType: deliveryType,
      deliveryLocation: deliveryLocation,
      deliveryFee: deliveryFee,
      studentPhone: studentPhone,
      subtotal: subtotal,
      totalAmount: totalAmount,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      studentName: studentName,
      canteenName: canteenName,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────
// CartItemEntry — item di keranjang (belum jadi order)
// ─────────────────────────────────────────────────────────────

class CartItemEntry {
  final String productId;
  final String productName;
  final int unitPrice;
  final String? imageUrl;
  final int quantity;
  final String? note;

  const CartItemEntry({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.imageUrl,
    this.quantity = 1,
    this.note,
  });

  int get lineTotal => quantity * unitPrice;

  CartItemEntry copyWith({int? quantity, String? note}) {
    return CartItemEntry(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CartCanteenEntry — semua item dari 1 kantin dalam keranjang
// ─────────────────────────────────────────────────────────────

class CartCanteenEntry {
  final String operatorId;
  final String canteenName;
  final bool deliveryEnabled;
  final int deliveryFee;
  final List<CartItemEntry> items;
  final String deliveryType; // 'takeaway' | 'delivery'
  final String? deliveryLocation;
  final String? studentPhone;
  final String? note;

  const CartCanteenEntry({
    required this.operatorId,
    required this.canteenName,
    this.deliveryEnabled = false,
    this.deliveryFee = 0,
    this.items = const [],
    this.deliveryType = 'takeaway',
    this.deliveryLocation,
    this.studentPhone,
    this.note,
  });

  int get subtotal => items.fold(0, (s, e) => s + e.lineTotal);
  int get totalAmount =>
      subtotal + (deliveryType == 'delivery' ? deliveryFee : 0);
  int get itemCount => items.fold(0, (s, e) => s + e.quantity);

  CartCanteenEntry copyWith({
    List<CartItemEntry>? items,
    String? deliveryType,
    String? deliveryLocation,
    String? studentPhone,
    String? note,
  }) {
    return CartCanteenEntry(
      operatorId: operatorId,
      canteenName: canteenName,
      deliveryEnabled: deliveryEnabled,
      deliveryFee: deliveryFee,
      items: items ?? this.items,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      studentPhone: studentPhone ?? this.studentPhone,
      note: note ?? this.note,
    );
  }
}
