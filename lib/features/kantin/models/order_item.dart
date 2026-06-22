class OrderSubItem {
  final String name;
  final int qty;
  final int price; // fixed: changed from double to int

  const OrderSubItem({
    required this.name,
    required this.qty,
    required this.price,
  });
}

class OrderItem {
  final String id;
  final String studentName;
  final String time;
  final String status; // 'Baru', 'Sedang Dimasak', 'Siap Diambil', 'Siap Diantar'
  final String? deliveryLocation;
  final List<OrderSubItem> items;
  final int totalAmount; // fixed: changed from double to int

  const OrderItem({
    required this.id,
    required this.studentName,
    required this.time,
    required this.status,
    this.deliveryLocation,
    required this.items,
    required this.totalAmount,
  });

  OrderItem copyWith({
    String? status,
    String? deliveryLocation,
  }) {
    return OrderItem(
      id: id,
      studentName: studentName,
      time: time,
      status: status ?? this.status,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      items: items,
      totalAmount: totalAmount,
    );
  }
}
