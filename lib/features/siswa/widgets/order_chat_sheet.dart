/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/models/order_message.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/order_chat_product_card.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';

/// Hallmark Student <-> Canteen Merchant In-App Order Chat Sheet
/// Features WhatsApp-style Green Bubbles, Non-Blocking Instant Sending, and WhatsApp Ticks (✓, ✓✓, ✓✓ blue).
class OrderChatSheet extends ConsumerStatefulWidget {
  final OrderItem order;

  const OrderChatSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, {required OrderItem order}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatSheet(order: order),
    );
  }

  @override
  ConsumerState<OrderChatSheet> createState() => _OrderChatSheetState();
}

class _OrderChatSheetState extends ConsumerState<OrderChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isMarkingRead = false;
  int _lastMessageCount = 0;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _markRead();
    ref.read(trackOrderPresenceProvider)(widget.order.id, 'student');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref.read(apiClientProvider).patch('/orders/${widget.order.id}/messages/read');
    } catch (_) {}
  }

  void _checkAndMarkRead(List<OrderMessage> messages, String myRole) {
    final hasUnreadFromOther = messages.any((m) => m.senderRole != myRole && !m.isRead);
    if (hasUnreadFromOther && !_isMarkingRead) {
      _isMarkingRead = true;
      ref.read(apiClientProvider).patch(
        '/orders/${widget.order.id}/messages/read',
      ).then((_) {
        _isMarkingRead = false;
      }).catchError((_) {
        _isMarkingRead = false;
      });
    }
  }

  void _sendMessage([String? customText]) {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    if (customText == null) _messageController.clear();
    if (!kIsWeb) {
      HapticFeedback.lightImpact();
    }

    final authProfile = ref.read(authNotifierProvider).profile;
    final userRole = authProfile?['role']?.toString();
    String myRole = 'student';
    String myName = authProfile?['full_name']?.toString() ?? 'Siswa';

    if (userRole == 'petugas_kantin') {
      myRole = 'canteen_operator';
      myName = authProfile?['canteen_name']?.toString() ?? authProfile?['full_name']?.toString() ?? 'Petugas Kantin';
    } else if (userRole == 'petugas_keuangan' || userRole == 'admin' || userRole == 'super_admin') {
      myRole = 'admin';
      myName = '${authProfile?['full_name'] ?? "Petugas Keuangan"} (Admin)';
    }

    try {
      final sendFn = ref.read(sendOrderMessageProvider);
      sendFn(
        widget.order.id,
        text,
        senderRole: myRole,
        senderName: myName,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOrderDetails(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.borderTactile, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rincian Menu Pesanan',
                    style: HallmarkTypography.titleL3(colors.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...widget.order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.qty}x ${item.name}',
                          style: HallmarkTypography.bodyMain(colors.textPrimary).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.price * item.qty),
                        style: HallmarkTypography.bodyMain(colors.brandPrimary).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.borderTactile),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Tagihan',
                    style: HallmarkTypography.titleSmall(colors.textPrimary),
                  ),
                  Text(
                    CurrencyFormatter.format(widget.order.totalAmount),
                    style: HallmarkTypography.titleSmall(colors.brandPrimary).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleAutoScroll(int currentCount) {
    if (!_initialScrollDone) {
      _initialScrollDone = true;
      _lastMessageCount = currentCount;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(immediate: true));
      return;
    }

    if (currentCount > _lastMessageCount) {
      _lastMessageCount = currentCount;
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.maxScrollExtent - pos.pixels < 160) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Widget _buildWhatsAppTick(OrderMessage msg, bool isDark, bool isRecipientActive) {
    final isLocal = msg.id.startsWith('local_');
    final isRead = msg.isRead;

    if (isLocal) {
      // Ikon Jam WhatsApp (Clock Icon): Pesan sedang dikirim / pending di jaringan
      return Icon(
        Icons.access_time_rounded,
        size: 13,
        color: isDark ? Colors.white60 : Colors.grey,
      );
    } else if (isRead) {
      // Centang 2 Biru (Double Blue Ticks): Sudah dibaca oleh lawan bicara!
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Color(0xFF38BDF8), // WhatsApp blue tick
      );
    } else if (isRecipientActive) {
      // Centang 2 Abu-abu (Double Grey Ticks): Terkirim & diterima lawan bicara yang sedang aktif
      return Icon(
        Icons.done_all_rounded,
        size: 14,
        color: isDark ? Colors.white60 : Colors.grey,
      );
    } else {
      // Centang 1 Abu-abu (Single Grey Tick): Terkirim ke server, lawan bicara sedang offline / tidak aktif
      return Icon(
        Icons.check,
        size: 14,
        color: isDark ? Colors.white60 : Colors.grey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final chatAsync = ref.watch(orderChatStreamProvider(widget.order.id));
    final localMessages = ref.watch(localOrderChatProvider(widget.order.id));

    final presenceAsync = ref.watch(orderPresenceProvider(widget.order.id));
    final Set<String> activeRoles = presenceAsync.maybeWhen(
      data: (roles) => roles,
      orElse: () => <String>{},
    );
    final bool isPedagangOnline = activeRoles.contains('canteen_operator');

    // Register presence active status
    ref.read(trackOrderPresenceProvider)(widget.order.id, 'student');

    // WhatsApp Green colors for student
    final Color whatsappGreenBg = isDark
        ? const Color(0xFF005C4B) // WhatsApp Dark Green
        : const Color(0xFFE7FFDB); // WhatsApp Soft Light Green

    final Color whatsappTextColor = isDark
        ? Colors.white
        : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.80 + (bottomInset > 0 ? bottomInset * 0.4 : 0),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.borderTactile, width: 0.5),
      ),
      child: Column(
        children: [
          // Drag handle & Header Bar
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.borderTactile, width: 0.5)),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.brandPrimary.withValues(alpha: 0.15),
                      child: Icon(Icons.storefront_rounded, color: colors.brandPrimary, size: 20),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isPedagangOnline ? colors.statusSuccess : colors.textMuted.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surfaceContainer, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Pedagang Kantin',
                        style: HallmarkTypography.titleSmall(colors.textPrimary),
                      ),
                      Text(
                        'ID: #${widget.order.id.length > 8 ? widget.order.id.substring(0, 8) : widget.order.id} • ${widget.order.status} • ${isPedagangOnline ? "Online" : "Offline"}',
                        style: HallmarkTypography.bodySmall(colors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Message Stream Area
          Expanded(
            child: chatAsync.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true,
              data: (remoteMessages) {
                final remoteIds = remoteMessages.map((m) => m.id).toSet();
                final uniqueLocal = localMessages.where((m) {
                  if (remoteIds.contains(m.id)) return false;
                  final isAlreadySaved = remoteMessages.any((r) =>
                    r.senderRole == m.senderRole &&
                    r.message == m.message &&
                    r.createdAt != null &&
                    m.createdAt != null &&
                    r.createdAt!.difference(m.createdAt!).inSeconds.abs() < 10
                  );
                  return !isAlreadySaved;
                }).toList();

                final messages = [...remoteMessages, ...uniqueLocal];
                _checkAndMarkRead(messages, 'student');
                if (messages.isEmpty) {
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      OrderChatProductCard(
                        order: widget.order,
                        onTap: () => _showOrderDetails(context),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.chat_bubble_2, color: colors.brandPrimary.withValues(alpha: 0.4), size: 44),
                            const SizedBox(height: 10),
                            Text(
                              'Belum ada pesan.\nMulai obrolan langsung dengan pedagang kantin!',
                              textAlign: TextAlign.center,
                              style: HallmarkTypography.bodyMain(colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                _handleAutoScroll(messages.length);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return OrderChatProductCard(
                        order: widget.order,
                        onTap: () => _showOrderDetails(context),
                      );
                    }

                    final msg = messages[index - 1];
                    final currentUserId = ref.read(authNotifierProvider).profile?['id']?.toString();
                    final isMe = msg.isFromCurrentSession ||
                        (currentUserId != null && currentUserId.isNotEmpty && msg.senderId == currentUserId);
                    final bool isAdminSender = msg.isAdmin || msg.senderRole == 'admin' || msg.senderRole == 'petugas_keuangan';
                    final timeStr = AppDateFormatter.formatTime(msg.createdAt);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          top: 4,
                          bottom: 4,
                          left: isMe ? 48 : 0,
                          right: isMe ? 0 : 48,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? whatsappGreenBg : colors.surfaceSubtle,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: isMe
                              ? Border.all(color: colors.statusSuccess.withValues(alpha: 0.2), width: 0.5)
                              : Border.all(color: colors.borderTactile, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (isAdminSender) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded, size: 10, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      'PETUGAS KEUANGAN / ADMIN',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[900] ?? Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Text(
                              msg.message,
                              style: HallmarkTypography.bodyMain(
                                isMe ? whatsappTextColor : colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeStr,
                                  style: HallmarkTypography.bodySmall(
                                    isMe
                                        ? (isDark ? Colors.white70 : colors.textMuted)
                                        : colors.textMuted,
                                  ).copyWith(fontSize: 10),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  _buildWhatsAppTick(msg, isDark, isPedagangOnline),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => Center(
                child: Text('Gagal memuat pesan: $err', style: HallmarkTypography.bodyMain(colors.statusError)),
              ),
            ),
          ),

          // Preset Quick Reply Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: OrderChatPresets.siswa.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = OrderChatPresets.siswa[index];
                return ActionChip(
                  label: Text(
                    preset,
                    style: HallmarkTypography.bodySmall(colors.textPrimary),
                  ),
                  backgroundColor: colors.surfaceSubtle,
                  side: BorderSide(color: colors.borderTactile, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _sendMessage(preset),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 12 + bottomInset,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border(top: BorderSide(color: colors.borderTactile, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: HallmarkTypography.bodyMain(colors.textPrimary),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan untuk kantin...',
                      hintStyle: HallmarkTypography.bodyMain(colors.textMuted),
                      filled: true,
                      fillColor: colors.surfaceSubtle,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.borderTactile, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.borderTactile, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.brandPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: colors.brandPrimary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
