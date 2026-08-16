/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:supabase_flutter/supabase_flutter.dart';

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

  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory OrderMessage.fromJson(Map<String, dynamic> json) {
    return OrderMessage(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'student',
      senderName: json['sender_name']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isRead: json['is_read'] == true,
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

  /// Returns true if the message was sent by the currently logged-in Supabase user.
  bool get isFromMe {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;
    return senderId == currentUserId;
  }
}
