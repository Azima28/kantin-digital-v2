/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/order_message.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/core/widgets/notifications_bottom_sheet.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/parent/providers/parent_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Realtime Service connecting the Flutter App to the Go Backend WebSocket server
class RealtimeService {
  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isDisposed = false;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  RealtimeService(this._ref);

  bool get isConnected => _isConnected;

  static String _resolveDefaultWsUrl() {
    if (kIsWeb) {
      final origin = Uri.base;
      if (origin.host.isNotEmpty && !origin.scheme.startsWith('file')) {
        final wsScheme = origin.scheme == 'https' ? 'wss' : 'ws';
        final portPart = (origin.hasPort && origin.port != 80 && origin.port != 443) ? ':${origin.port}' : '';
        return '$wsScheme://${origin.host}$portPart/ws';
      }
    }
    return const String.fromEnvironment(
      'BACKEND_WS_URL',
      defaultValue: 'wss://sekantin.zitech.web.id/ws',
    );
  }

  void connect() {
    if (_isDisposed) return;
    _subscription?.cancel();
    _channel?.sink.close();

    final authState = _ref.read(authNotifierProvider);
    final String? token = authState.sessionToken;

    final String wsUrl = _resolveDefaultWsUrl();

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

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendHeartbeat();
      });

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
    _heartbeatTimer?.cancel();
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

  void _sendHeartbeat() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode({'event': 'ping'}));
      } catch (_) {}
    }
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
              // Add or seamlessly replace pending optimistic message in-place
              _ref.read(localOrderChatProvider(orderId).notifier).addMessage(msg);
              _ref.invalidate(orderChatStreamProvider(orderId));
            }
          }
          break;

        case 'order:presence':
          if (payloadMap != null) {
            final String orderId = (payloadMap['order_id'] ?? payloadMap['id'])?.toString() ?? '';
            if (orderId.isNotEmpty) {
              _ref.invalidate(orderPresenceProvider(orderId));
            }
          }
          break;

        case 'user:presence':
          _ref.invalidate(orderPresenceProvider);
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
            final String orderId = (payloadMap['order_id'] ?? payloadMap['id'])?.toString() ?? '';
            if (orderId.isNotEmpty) {
              _ref.invalidate(orderChatStreamProvider(orderId));
            }
          }
          break;

        case 'notification':
        case 'notification:new':
        case 'broadcast':
          _ref.invalidate(userNotificationsProvider);
          if (isStudent) {
            _ref.invalidate(siswaNotificationsProvider);
          }
          _showBroadcastBanner(event, payloadMap);
          break;

        case 'balance:updated':
          if (isStudent) {
            _ref.invalidate(siswaStudentProvider);
            _ref.invalidate(siswaNotificationsProvider);
          }
          _ref.invalidate(parentDashboardProvider);
          _ref.invalidate(userNotificationsProvider);
          break;

        case 'account:status_changed':
        case 'account_status_changed':
          if (payloadMap != null) {
            final String targetUserId = (payloadMap['user_id'] ?? payloadMap['id'])?.toString() ?? '';
            final bool newIsActive = payloadMap['is_active'] == true;
            final currentUserId = profile?['id']?.toString();
            if (currentUserId != null && currentUserId == targetUserId) {
              debugPrint('[RealtimeService] Current account status changed to: $newIsActive');
              _ref.read(authNotifierProvider.notifier).updateAccountActiveStatus(newIsActive);
            }
          }
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[RealtimeService] Message parsing error: $e');
    }
  }

  void _showBroadcastBanner(String event, Map<String, dynamic>? payloadMap) {
    if (payloadMap == null) return;
    final String title = (payloadMap['title'] ?? 'Pengumuman Baru').toString().trim();
    final String message = (payloadMap['message'] ?? '').toString().trim();

    if (title.isEmpty && message.isEmpty) return;

    final messenger = AppRouter.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final navContext = AppRouter.navigatorKey.currentContext;
    final themeMode = _ref.read(themeProvider);
    final bool isDark = navContext != null
        ? (Theme.of(navContext).brightness == Brightness.dark)
        : (themeMode == ThemeMode.dark);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: isDark ? 6 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 6),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF14B8A6).withValues(alpha: 0.18)
                    : const Color(0xFF0D9488).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.speaker_2_fill,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Buka',
          textColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0D9488),
          onPressed: () {
            final ctx = AppRouter.navigatorKey.currentContext;
            if (ctx != null) {
              NotificationsBottomSheet.show(ctx);
            }
          },
        ),
      ),
    );
  }

  void dispose() {
    _isDisposed = true;
    _isConnected = false;
    _heartbeatTimer?.cancel();
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
