/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/notification_bell.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/kantin/widgets/order_detail_sheet.dart';
import 'package:kantin_digital/features/kantin/widgets/daily_sales_volume_widget.dart';
import 'package:kantin_digital/features/kantin/widgets/top_selling_food_widget.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';

/// Hallmark POS Kasir Workbench Master Screen
class PosHomeScreen extends ConsumerStatefulWidget {
  const PosHomeScreen({super.key});

  @override
  ConsumerState<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends ConsumerState<PosHomeScreen> {
  Future<void> _toggleDelivery(bool enabled, int currentFee) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/pos/delivery-settings', body: {
        'is_delivery_enabled': enabled,
        'delivery_fee': currentFee,
      });

      ref.invalidate(canteenOperatorProvider);
      ref.invalidate(publicCanteensProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Layanan Antar Aktif (${CurrencyFormatter.format(currentFee)})'
                  : 'Layanan Antar Dinonaktifkan (Hanya Pickup)',
            ),
            backgroundColor: enabled ? const Color(0xFF10B981) : const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui layanan antar: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showQuickDeliveryModal(BuildContext context, bool currentEnabled, int currentFee) {
    bool tempEnabled = currentEnabled;
    int tempFee = currentFee;
    final feeController = TextEditingController(text: currentFee.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: context.surfaceBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: context.dividerCol, width: 0.5),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.dividerCol,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: Nebula.teal, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengaturan Layanan Antar',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                'Atur penerimaan delivery & ongkir stan',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Toggle Switch Tile
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: tempEnabled
                            ? const Color(0xFF10B981).withValues(alpha: 0.08)
                            : context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tempEnabled
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : context.dividerCol,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Terima Pesanan Delivery',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tempEnabled
                                      ? 'Siswa dapat memesan antar ke kelas/meja'
                                      : 'Stan hanya menerima pesanan ambil sendiri (Pickup)',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: tempEnabled,
                            activeTrackColor: const Color(0xFF10B981),
                            onChanged: (val) {
                              setModalState(() => tempEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (tempEnabled) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Tarif Ongkos Kirim (Biaya Antar)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: feeController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Rp',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '2000',
                          filled: true,
                          fillColor: context.cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.dividerCol),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.dividerCol),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                          ),
                        ),
                        onChanged: (v) {
                          tempFee = int.tryParse(v.replaceAll('.', '').trim()) ?? 0;
                        },
                      ),
                      const SizedBox(height: 10),
                      // Quick Chips
                      Wrap(
                        spacing: 8,
                        children: [1000, 2000, 3000, 5000].map((chipFee) {
                          final isSelected = (int.tryParse(feeController.text.replaceAll('.', '').trim()) ?? 0) == chipFee;
                          return ChoiceChip(
                            label: Text(
                              CurrencyFormatter.format(chipFee),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : context.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Nebula.teal,
                            backgroundColor: context.cardBg,
                            onSelected: (_) {
                              setModalState(() {
                                feeController.text = chipFee.toString();
                                tempFee = chipFee;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final fee = int.tryParse(feeController.text.replaceAll('.', '').trim()) ?? tempFee;
                          Navigator.pop(ctx);
                          _toggleDelivery(tempEnabled, fee);
                        },
                        child: Text(
                          'Simpan Pengaturan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String id, String newStatus, String studentId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/orders/$id/status', body: {'status': newStatus});

      ref.invalidate(canteenOrdersProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(operatorTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan berhasil diubah menjadi "$newStatus"'),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status pesanan: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final String canteenName = authState.profile?['canteen_name'] ?? 'Stan Kantin';
    final String? profilePhotoUrl = authState.profile?['avatar_url'];

    final revenueAsync = ref.watch(todayRevenueProvider);
    final ordersAsync = ref.watch(canteenOrdersProvider);
    final canteenSettingsAsync = ref.watch(canteenOperatorProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Nebula.teal.withValues(alpha: 0.1),
              backgroundImage: profilePhotoUrl != null
                  ? CachedNetworkImageProvider(profilePhotoUrl)
                  : null,
              child: profilePhotoUrl == null
                  ? const Icon(Icons.storefront_rounded, color: Nebula.teal, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $canteenName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                  Text(
                    'Kasir Workbench',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Nebula.teal,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBell(color: Nebula.teal),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayRevenueProvider);
          ref.invalidate(canteenOrdersProvider);
          ref.invalidate(canteenOperatorProvider);
          ref.invalidate(operatorTransactionsProvider);
          ref.invalidate(topSellingFoodProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // 1. Status Stan & Delivery Banner Pill
                canteenSettingsAsync.maybeWhen(
                  data: (operatorData) {
                    final bool isDeliveryOn = operatorData?.isDeliveryEnabled ?? true;
                    final int fee = operatorData?.deliveryFee ?? 2000;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDeliveryOn
                            ? const Color(0xFF10B981).withValues(alpha: 0.08)
                            : context.surfaceBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDeliveryOn
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : context.dividerCol,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDeliveryOn ? const Color(0xFF10B981) : Colors.amber.shade700,
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showQuickDeliveryModal(context, isDeliveryOn, fee),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Stan Buka • ',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            isDeliveryOn ? 'Terima Antar' : 'Hanya Pickup',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDeliveryOn ? const Color(0xFF10B981) : context.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      isDeliveryOn
                                          ? 'Ongkir: ${CurrencyFormatter.format(fee)} • Ketuk atur'
                                          : 'Delivery mati • Ketuk aktifkan',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.75,
                            child: CupertinoSwitch(
                              value: isDeliveryOn,
                              activeTrackColor: const Color(0xFF10B981),
                              onChanged: (val) => _toggleDelivery(val, fee),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                // 2. Ringkasan Aktivitas & Penjualan Hari Ini (2x2 Metrics Grid)
                ordersAsync.when(
                  skipLoadingOnRefresh: true,
                  skipLoadingOnReload: true,
                  data: (orders) {
                    final int countBaru = orders.where((o) => o.status.trim() == 'Baru').length;
                    final int countProses = orders.where((o) {
                      final s = o.status.trim();
                      return s == 'Sedang Dimasak' ||
                          s == 'Siap Diambil' ||
                          s == 'Siap Diantar' ||
                          s == 'Menunggu Pembatalan' ||
                          s == 'Menunggu Persetujuan Murid';
                    }).length;
                    final int countSelesai = orders.where((o) => o.status.trim() == 'Selesai').length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metric 2x2 Grid
                        Row(
                          children: [
                            // Card 1: Total Pendapatan Hari Ini
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pendapatan Hari Ini',
                                valueWidget: revenueAsync.maybeWhen(
                                  data: (rev) => Text(
                                    CurrencyFormatter.format(rev),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Nebula.teal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  orElse: () => const Text('Rp 0'),
                                ),
                                icon: CupertinoIcons.creditcard_fill,
                                iconColor: Nebula.teal,
                                iconBgColor: Nebula.teal.withValues(alpha: 0.12),
                                onTap: () => context.go('/pos/sales'),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Card 2: Pesanan Baru Masuk
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pesanan Baru',
                                valueText: '$countBaru Masuk',
                                icon: Icons.receipt_long_rounded,
                                iconColor: Nebula.amber,
                                iconBgColor: Nebula.amber.withValues(alpha: 0.12),
                                onTap: () => context.go('/pos/orders'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Card 3: Sedang Diproses
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Sedang Diproses',
                                valueText: '$countProses Antrean',
                                icon: Icons.soup_kitchen_rounded,
                                iconColor: const Color(0xFF0284C7),
                                iconBgColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                onTap: () => context.go('/pos/orders'),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Card 4: Pesanan Selesai
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pesanan Selesai',
                                valueText: '$countSelesai Pesanan',
                                icon: Icons.check_circle_rounded,
                                iconColor: const Color(0xFF10B981),
                                iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                                onTap: () => context.go('/pos/orders'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Shimmer(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
                            SizedBox(width: 10),
                            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
                            SizedBox(width: 10),
                            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // 3. Quick Action Buttons Grid (4 Aksi Utama Kasir)
                Text(
                  'Aksi Cepat Kasir',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Kasir POS',
                        subtitle: 'Scan & Kasir',
                        icon: CupertinoIcons.square_grid_2x2_fill,
                        color: Nebula.teal,
                        onTap: () => context.push('/pos/terminal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Cek Saldo',
                        subtitle: 'Scan Kartu RFID',
                        icon: CupertinoIcons.creditcard_fill,
                        color: const Color(0xFF3B82F6),
                        onTap: () => context.push('/pos/check-card'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Kelola Menu',
                        subtitle: 'Produk & Stok',
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => context.go('/pos/products'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Riwayat',
                        subtitle: 'Histori Penjualan',
                        icon: Icons.history_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.go('/pos/sales'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. Live Antrean Pesanan Masuk (Live Orders Feed)
                ordersAsync.when(
                  data: (orders) {
                    final activeOrders = orders.where((o) =>
                        o.status == 'Baru' ||
                        o.status == 'Sedang Dimasak' ||
                        o.status == 'Siap Diambil' ||
                        o.status == 'Siap Diantar').take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Antrean Pesanan',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (activeOrders.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Nebula.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${activeOrders.length} Aktif',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Nebula.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => context.go('/pos/orders'),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat Semua',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Nebula.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(CupertinoIcons.chevron_right, size: 11, color: Nebula.teal),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (activeOrders.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.dividerCol, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.check_circle_outline_rounded, color: Nebula.teal, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dapur Siap & Bersih!',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Semua pesanan telah diproses. Siap melayani pembeli berikutnya.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...activeOrders.map((order) => _buildLiveOrderCard(context, order)),
                      ],
                    );
                  },
                  loading: () => const SkeletonBox(height: 120, borderRadius: 16),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // 5. Analisis Performa & Grafik Volume (Optional Collapsible / Clean Card)
                const DailySalesVolumeWidget(),
                const SizedBox(height: 16),
                const TopSellingFoodWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    String? valueText,
    Widget? valueWidget,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerCol, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                Icon(CupertinoIcons.chevron_right, size: 12, color: context.textSecondary.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            valueWidget ??
                Text(
                  valueText ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerCol, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveOrderCard(BuildContext context, OrderItem order) {
    final topItem = order.mostExpensiveItem;
    final String? imgUrl = topItem?.imageUrl;

    Color badgeColor = Nebula.amber;
    if (order.status == 'Siap Diantar' || order.status == 'Siap Diambil') {
      badgeColor = const Color(0xFF0284C7);
    }

    final String itemsSummary = order.items.isNotEmpty
        ? order.items.map((i) => '${i.qty}x ${i.name}').join(', ')
        : 'Pesanan Kantin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerCol, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          OrderDetailSheet.show(
            context,
            order: order,
            onStatusChanged: _updateOrderStatus,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Photo Thumbnail
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.dividerCol, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (imgUrl != null && imgUrl.isNotEmpty)
                      ? Image.network(
                          imgUrl,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackFoodIcon(),
                        )
                      : _fallbackFoodIcon(),
                ),
              ),
              const SizedBox(width: 10),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            order.studentName,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.status,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemsSummary,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.format(order.totalAmount),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Nebula.teal,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Proses',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(CupertinoIcons.chevron_right, size: 11, color: Nebula.teal),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackFoodIcon() {
    return Container(
      color: Nebula.teal.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.restaurant_menu_rounded, color: Nebula.teal, size: 20),
      ),
    );
  }
}
