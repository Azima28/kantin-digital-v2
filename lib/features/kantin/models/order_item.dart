class OrderSubItem {
  final String name;
  final int qty;
  final int price; // fixed: changed from double to int
  final String? imageUrl;

  const OrderSubItem({
    required this.name,
    required this.qty,
    required this.price,
    this.imageUrl,
  });
}

class OrderItem {
  final String id;
  final String studentId;
  final String studentName;
  final String time;
  final String status; // 'Baru', 'Sedang Dimasak', 'Siap Diambil', 'Siap Diantar'
  final String? deliveryLocation;
  final List<OrderSubItem> items;
  final int totalAmount; // fixed: changed from double to int
  final String? cancelRequestReason;
  final DateTime? createdAt;

  const OrderItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.time,
    required this.status,
    this.deliveryLocation,
    required this.items,
    required this.totalAmount,
    this.cancelRequestReason,
    this.createdAt,
  });

  /// Returns the item with the highest unit price (termahal) in this order
  OrderSubItem? get mostExpensiveItem {
    if (items.isEmpty) return null;
    OrderSubItem top = items.first;
    for (final item in items) {
      if (item.price > top.price) {
        top = item;
      }
    }
    return top;
  }

  OrderItem copyWith({
    String? status,
    String? deliveryLocation,
    String? studentId,
    String? cancelRequestReason,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id,
      studentId: studentId ?? this.studentId,
      studentName: studentName,
      time: time,
      status: status ?? this.status,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      items: items,
      totalAmount: totalAmount,
      cancelRequestReason: cancelRequestReason ?? this.cancelRequestReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
