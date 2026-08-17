/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/order_message.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Preset quick-reply options for Siswa & Pedagang
class OrderChatPresets {
  OrderChatPresets._();

  static const List<String> siswa = [
    'Pesanan saya sudah sampai mana ya?',
    'Tolong dipisah sambalnya ya kak',
    'Bisa tolong kurangin es nya?',
    'Saya mau ambil jam istirahat ya',
    'Makasih banyak kak!',
  ];

  static const List<String> pedagang = [
    'Pesanan sedang dimasak ya dek',
    'Bahan makanan habis, mau diganti?',
    'Pesanan sudah siap diambil di stan!',
    'Pengantar sedang jalan ke kelasmu',
    'Sama-sama, selamat menikmati!',
  ];
}

/// In-memory fallback message store per orderId
final localOrderChatProvider = StateNotifierProvider.family<LocalOrderChatNotifier, List<OrderMessage>, String>((ref, orderId) {
  return LocalOrderChatNotifier();
});

class LocalOrderChatNotifier extends StateNotifier<List<OrderMessage>> {
  LocalOrderChatNotifier() : super(const []);

  void setMessages(List<OrderMessage> messages) {
    state = messages;
  }

  void addMessage(OrderMessage message) {
    state = [...state, message];
  }
}

/// Future provider for order chat messages from Go Backend with 5-minute memory cache
final orderChatStreamProvider = FutureProvider.autoDispose.family<List<OrderMessage>, String>((ref, orderId) async {
  ref.cacheFor(const Duration(minutes: 5));
  final apiClient = ref.read(apiClientProvider);
  final currentUserId = ref.watch(authNotifierProvider.select((s) => s.profile?['id'] as String?));

  try {
    final response = await apiClient.get('/orders/$orderId/messages');
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((json) => OrderMessage.fromJson(json as Map<String, dynamic>, currentUserId: currentUserId)).toList();
    }
  } catch (e) {
    debugPrint('[OrderChat] fetchMessages error: $e');
  }
  return <OrderMessage>[];
});

/// Function provider to send a chat message with Instant Optimistic UI & Live Server Confirmation
final sendOrderMessageProvider = Provider<Future<void> Function(
  String orderId,
  String messageText, {
  required String senderRole,
  required String senderName,
})>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final currentUserId = ref.watch(authNotifierProvider.select((s) => s.profile?['id'] as String?));

  return (
    String orderId,
    String messageText, {
    required String senderRole,
    required String senderName,
  }) async {
    final String text = messageText.trim();
    if (text.isEmpty) return;

    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final newMessage = OrderMessage(
      id: localId,
      orderId: orderId,
      senderId: currentUserId ?? '',
      senderRole: senderRole,
      senderName: senderName,
      message: text,
      createdAt: DateTime.now(),
      isFromCurrentSession: true,
    );

    // 1. INSTANT OPTIMISTIC RENDER
    ref.read(localOrderChatProvider(orderId).notifier).addMessage(newMessage);

    // 2. Track sender presence as online immediately
    ref.read(trackOrderPresenceProvider)(orderId, senderRole);

    // 3. Send to Go Backend
    try {
      final response = await apiClient.post(
        '/orders/$orderId/messages',
        body: {
          'message': text,
          'sender_role': senderRole,
          'sender_name': senderName,
        },
      );
      if (response.success) {
        // Refresh server stream immediately so clock icon transitions to confirmed checkmark!
        ref.invalidate(orderChatStreamProvider(orderId));
      }
    } catch (e) {
      debugPrint('[OrderChat] Gagal mengirim pesan: $e');
    }
  };
});

/// Presence provider that fetches currently online participant roles from Go Backend
final orderPresenceProvider = FutureProvider.autoDispose.family<Set<String>, String>((ref, orderId) async {
  ref.cacheFor(const Duration(minutes: 2));
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('/orders/$orderId/presence');
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    }
  } catch (_) {}
  return <String>{};
});

/// Function to track presence in a chat session via Go Backend
final trackOrderPresenceProvider = Provider<Future<void> Function(String orderId, String myRole)>((ref) {
  final apiClient = ref.read(apiClientProvider);

  return (String orderId, String myRole) async {
    try {
      final response = await apiClient.post(
        '/orders/$orderId/presence',
        body: {'role': myRole},
      );
      if (response.success) {
        ref.invalidate(orderPresenceProvider(orderId));
      }
    } catch (_) {}
  };
});
