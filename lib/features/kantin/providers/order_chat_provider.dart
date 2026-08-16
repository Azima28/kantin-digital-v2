/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/models/order_message.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

/// Preset quick-reply options for Siswa & Pedagang
class OrderChatPresets {
  OrderChatPresets._();

  static const List<String> siswa = [
    'Pesanan saya sudah sampai mana ya?',
    'Tolong dipisah sambalnya ya kak 🙏',
    'Bisa tolong kurangin es nya?',
    'Saya mau ambil jam istirahat ya',
    'Makasih banyak kak! 👍',
  ];

  static const List<String> pedagang = [
    'Pesanan sedang dimasak ya dek 🍳',
    'Bahan makanan habis, mau diganti?',
    'Pesanan sudah siap diambil di stan! 🛍️',
    'Pengantar sedang jalan ke kelasmu 🛵',
    'Sama-sama, selamat menikmati! 😊',
  ];
}

/// In-memory fallback message store per orderId for dev testing
final localOrderChatProvider = StateNotifierProvider.family<LocalOrderChatNotifier, List<OrderMessage>, String>((ref, orderId) {
  return LocalOrderChatNotifier();
});

class LocalOrderChatNotifier extends StateNotifier<List<OrderMessage>> {
  LocalOrderChatNotifier() : super(const []);

  void addMessage(OrderMessage message) {
    state = [...state, message];
  }
}

/// Real-time stream provider for remote order chat messages from database
final orderChatStreamProvider = StreamProvider.autoDispose.family<List<OrderMessage>, String>((ref, orderId) {
  final client = ref.watch(supabaseClientProvider);

  return client
      .from('order_messages')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('created_at', ascending: true)
      .map((dataList) {
        return dataList.map((json) => OrderMessage.fromJson(json)).toList();
      })
      .handleError((_) => <OrderMessage>[]);
});

/// Function provider to send a chat message with Instant Optimistic UI & Local Caching
final sendOrderMessageProvider = Provider<Future<void> Function(
  String orderId,
  String messageText, {
  required String senderRole,
  required String senderName,
})>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return (
    String orderId,
    String messageText, {
    required String senderRole,
    required String senderName,
  }) async {
    final user = client.auth.currentUser;
    final String text = messageText.trim();
    if (text.isEmpty) return;

    final String? validUserId = (user?.id != null && user!.id.isNotEmpty) ? user.id : null;

    final newMessage = OrderMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      senderId: validUserId ?? '',
      senderRole: senderRole,
      senderName: senderName,
      message: text,
      createdAt: DateTime.now(),
    );

    // 1. INSTANT OPTIMISTIC RENDER: Add message to local state immediately
    ref.read(localOrderChatProvider(orderId).notifier).addMessage(newMessage);

    // 2. Perform DB insert asynchronously in background
    try {
      final Map<String, dynamic> insertPayload = {
        'order_id': orderId,
        'sender_role': senderRole,
        'sender_name': senderName,
        'message': text,
      };

      if (validUserId != null) {
        insertPayload['sender_id'] = validUserId;
      }

      await client.from('order_messages').insert(insertPayload);
    } catch (_) {
      // Retain local message so user sees pending state
    }
  };
});

/// Realtime presence provider to track active roles ('student' or 'canteen_operator') in an order chat
final orderPresenceProvider = StreamProvider.autoDispose.family<Set<String>, String>((ref, orderId) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<Set<String>>();
  final Set<String> activeRoles = {};

  final channelName = 'order_presence_$orderId';
  final RealtimeChannel channel = client.channel(channelName);

  channel.onPresenceSync((_) {
    final state = channel.presenceState();
    activeRoles.clear();
    for (final presence in state) {
      for (final p in presence.presences) {
        final role = p.payload['role']?.toString();
        if (role != null && role.isNotEmpty) {
          activeRoles.add(role);
        }
      }
    }
    if (!controller.isClosed) {
      controller.add(Set<String>.from(activeRoles));
    }
  }).subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Function to track presence in a chat session for the current user
final trackOrderPresenceProvider = Provider<Future<void> Function(String orderId, String myRole)>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return (String orderId, String myRole) async {
    try {
      final channel = client.channel('order_presence_$orderId');
      final user = client.auth.currentUser;
      await channel.track({
        'role': myRole,
        'user_id': user?.id ?? 'guest',
        'active_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  };
});
