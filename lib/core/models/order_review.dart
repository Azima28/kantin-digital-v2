/// Data model untuk ulasan pesanan `order_reviews`.
class OrderReview {
  final String id;
  final String orderId;
  final String studentId;
  final String studentName;
  final String? avatarUrl;
  final String? operatorId;
  final String? productId;
  final String? productName;
  final int rating;
  final String reviewText;
  final List<String> tags;
  final bool isAnonymous;
  final DateTime? createdAt;

  const OrderReview({
    required this.id,
    required this.orderId,
    required this.studentId,
    this.studentName = 'Siswa',
    this.avatarUrl,
    this.operatorId,
    this.productId,
    this.productName,
    required this.rating,
    this.reviewText = '',
    this.tags = const [],
    this.isAnonymous = false,
    this.createdAt,
  });

  factory OrderReview.fromJson(Map<String, dynamic> json) {
    return OrderReview(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? 'Siswa',
      avatarUrl: json['avatar_url']?.toString(),
      operatorId: json['operator_id']?.toString(),
      productId: json['product_id']?.toString(),
      productName: json['product_name']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      reviewText: json['review_text']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'student_id': studentId,
    'student_name': studentName,
    'avatar_url': avatarUrl,
    'operator_id': operatorId,
    'product_id': productId,
    'product_name': productName,
    'rating': rating,
    'review_text': reviewText,
    'tags': tags,
    'is_anonymous': isAnonymous,
    'created_at': createdAt?.toIso8601String(),
  };
}
