/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/models/order_message.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref.read(supabaseClientProvider).rpc(
        'mark_order_messages_read',
        params: {
          'p_order_id': widget.order.id,
          'p_sender_role': 'student',
        },
      );
    } catch (_) {}
  }

  void _checkAndMarkRead(List<OrderMessage> messages, String myRole) {
    final hasUnreadFromOther = messages.any((m) => m.senderRole != myRole && !m.isRead);
    if (hasUnreadFromOther && !_isMarkingRead) {
      _isMarkingRead = true;
      ref.read(supabaseClientProvider).rpc(
        'mark_order_messages_read',
        params: {
          'p_order_id': widget.order.id,
          'p_sender_role': myRole,
        },
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
    HapticFeedback.lightImpact();

    try {
      final sendFn = ref.read(sendOrderMessageProvider);
      sendFn(
        widget.order.id,
        text,
        senderRole: 'student',
        senderName: 'Siswa',
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isPedagangOnline ? colors.statusSuccess : colors.textMuted.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.chat_bubble_2, color: colors.brandPrimary.withValues(alpha: 0.4), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada pesan.\nMulai obrolan langsung dengan pedagang kantin!',
                            textAlign: TextAlign.center,
                            style: HallmarkTypography.bodyMain(colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderRole == 'student';
                    final timeStr = msg.createdAt != null
                        ? DateFormat('HH:mm').format(msg.createdAt!)
                        : '';

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
