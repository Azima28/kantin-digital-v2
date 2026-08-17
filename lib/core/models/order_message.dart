/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */

/// Model representing an order chat message between Student and Canteen Merchant.
class OrderMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderRole; // 'student' or 'canteen_operator'
  final String senderName;
  final String message;
  final DateTime? createdAt;
  final bool isRead;
  final bool isFromCurrentSession;

  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    this.createdAt,
    this.isRead = false,
    this.isFromCurrentSession = false,
  });

  factory OrderMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['sender_id']?.toString() ?? '';
    final rawRole = json['sender_role']?.toString() ?? 'student';
    final normalizedRole = (rawRole == 'petugas_kantin' || rawRole == 'canteen_operator' || rawRole == 'merchant')
        ? 'canteen_operator'
        : 'student';

    return OrderMessage(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      senderId: senderId,
      senderRole: normalizedRole,
      senderName: json['sender_name']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isRead: json['is_read'] == true,
      isFromCurrentSession: currentUserId != null && currentUserId.isNotEmpty && senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'message': message,
      'created_at': createdAt?.toIso8601String(),
      'is_read': isRead,
    };
  }

  bool get isFromMe => isFromCurrentSession;
}
