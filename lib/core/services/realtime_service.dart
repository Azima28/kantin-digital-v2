/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/order_message.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Realtime Service connecting the Flutter App to the Go Backend WebSocket server
class RealtimeService {
  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  RealtimeService(this._ref);

  bool get isConnected => _isConnected;

  void connect() {
    if (_isDisposed) return;
    _subscription?.cancel();
    _channel?.sink.close();

    final authState = _ref.read(authNotifierProvider);
    final String? token = authState.sessionToken;

    final String wsUrl = const String.fromEnvironment(
      'BACKEND_WS_URL',
      defaultValue: 'ws://127.0.0.1:8000/ws',
    );

    final Uri uri = Uri.parse(wsUrl).replace(
      queryParameters: {
        'room': 'all',
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('[RealtimeService] Connected to Go WebSocket at $wsUrl (room=all)');

      _subscription = _channel!.stream.listen(
        (dynamic rawMessage) {
          _handleIncomingMessage(rawMessage);
        },
        onError: (dynamic error) {
          debugPrint('[RealtimeService] WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[RealtimeService] WebSocket disconnected');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[RealtimeService] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _isConnected = false;
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final int delaySec = _reconnectAttempts > 4 ? 20 : (_reconnectAttempts * 4);
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  Map<String, dynamic>? _toMap(dynamic obj) {
    if (obj == null) return null;
    if (obj is Map<String, dynamic>) return obj;
    if (obj is Map) {
      return Map<String, dynamic>.from(obj);
    }
    if (obj is String) {
      try {
        final decoded = json.decode(obj);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final Map<String, dynamic> data = json.decode(rawMessage.toString()) as Map<String, dynamic>;
      final String event = data['event']?.toString() ?? '';
      final payloadMap = _toMap(data['data']);

      final profile = _ref.read(authNotifierProvider).profile;
      final role = profile?['role']?.toString();
      final isOperator = role == 'petugas_kantin';
      final isStudent = role == 'student';

      debugPrint('[RealtimeService] Received event: $event for role: $role');

      switch (event) {
        case 'order:message':
          if (payloadMap != null) {
            final String currentUserId = profile?['id']?.toString() ?? '';
            final msg = OrderMessage.fromJson(payloadMap, currentUserId: currentUserId);
            final String orderId = msg.orderId;

            if (orderId.isNotEmpty) {
              // Update in-memory message store & refresh stream for this specific order
              _ref.read(localOrderChatProvider(orderId).notifier).addMessage(msg);
              _ref.invalidate(orderChatStreamProvider(orderId));
            }
          }
          break;

        case 'order:new':
          if (isOperator) {
            _ref.invalidate(canteenOrdersProvider);
            _ref.invalidate(canteenActiveOrdersCountProvider);
            _ref.invalidate(todayRevenueProvider);
            _ref.invalidate(operatorTransactionsProvider);
          }
          if (isStudent) {
            _ref.invalidate(siswaActiveOrdersProvider);
            _ref.invalidate(siswaActiveOrdersCountProvider);
          }
          break;

        case 'order:status_updated':
        case 'order:status':
          if (isOperator) {
            _ref.invalidate(canteenOrdersProvider);
            _ref.invalidate(canteenActiveOrdersCountProvider);
            _ref.invalidate(todayRevenueProvider);
            _ref.invalidate(operatorTransactionsProvider);
          }
          if (isStudent) {
            _ref.invalidate(siswaActiveOrdersProvider);
            _ref.invalidate(siswaActiveOrdersCountProvider);
          }
          break;

        case 'order:messages_read':
          if (payloadMap != null) {
            final String orderId = payloadMap['order_id']?.toString() ?? '';
            if (orderId.isNotEmpty) {
              _ref.invalidate(orderChatStreamProvider(orderId));
            }
          }
          break;

        case 'notification:new':
          _ref.invalidate(userNotificationsProvider);
          if (isStudent) {
            _ref.invalidate(siswaNotificationsProvider);
          }
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[RealtimeService] Message parsing error: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _isConnected = false;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
  }
}

/// Global Riverpod Provider for RealtimeService
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);
  service.connect();

  // Reconnect automatically when user login state changes
  ref.listen(authNotifierProvider, (previous, next) {
    if (previous?.sessionToken != next.sessionToken) {
      service.connect();
    }
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
