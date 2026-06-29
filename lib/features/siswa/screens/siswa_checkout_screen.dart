import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/cart_provider.dart';
import 'package:kantin_digital/features/siswa/providers/order_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaCheckoutScreen extends ConsumerStatefulWidget {
  const SiswaCheckoutScreen({super.key});

  @override
  ConsumerState<SiswaCheckoutScreen> createState() =>
      _SiswaCheckoutScreenState();
}

class _SiswaCheckoutScreenState extends ConsumerState<SiswaCheckoutScreen> {
  bool _isProcessing = false;
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, TextEditingController> _locationControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    for (final c in _phoneControllers.values) {
      c.dispose();
    }
    for (final c in _locationControllers.values) {
      c.dispose();
    }
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _phoneCtrl(String operatorId) {
    _phoneControllers[operatorId] ??= TextEditingController();
    return _phoneControllers[operatorId]!;
  }

  TextEditingController _locationCtrl(String operatorId) {
    _locationControllers[operatorId] ??= TextEditingController();
    return _locationControllers[operatorId]!;
  }

  TextEditingController _noteCtrl(String operatorId) {
    _noteControllers[operatorId] ??= TextEditingController();
    return _noteControllers[operatorId]!;
  }

  Future<void> _placeOrder(CartState cart, int studentBalance) async {
    // Sync manual text fields ke provider
    final notifier = ref.read(cartProvider.notifier);
    for (final entry in cart.canteenList) {
      notifier.setStudentPhone(
          entry.operatorId, _phoneCtrl(entry.operatorId).text.trim());
      notifier.setDeliveryLocation(
          entry.operatorId, _locationCtrl(entry.operatorId).text.trim());
      notifier.setCanteenNote(
          entry.operatorId, _noteCtrl(entry.operatorId).text.trim());
    }

    // Re-read updated state
    final updatedCart = ref.read(cartProvider);

    // Validasi
    final errs = notifier.validate();
    setState(() => _errors
      ..clear()
      ..addAll(errs));
    if (errs.isNotEmpty) return;

    // Cek saldo
    if (studentBalance < updatedCart.grandTotal) {
      _showSnack('Saldo tidak mencukupi', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final authState = ref.read(authNotifierProvider);
      final studentId = authState.profile?['id'] as String?;
      if (studentId == null) throw Exception('Not authenticated');

      // Build payload untuk RPC place_order
      final orders = updatedCart.canteenList.map((c) {
        return {
          'operator_id': c.operatorId,
          'delivery_type': c.deliveryType,
          'delivery_location': c.deliveryType == 'delivery'
              ? c.deliveryLocation
              : null,
          'delivery_fee': c.deliveryType == 'delivery' ? c.deliveryFee : 0,
          'student_phone': c.deliveryType == 'delivery'
              ? c.studentPhone
              : null,
          'subtotal': c.subtotal,
          'total_amount': c.totalAmount,
          'note': c.note,
          'items': c.items
              .map((i) => {
                    'product_id': i.productId,
                    'quantity': i.quantity,
                    'unit_price': i.unitPrice,
                    'note': i.note,
                  })
              .toList(),
        };
      }).toList();

      final client = ref.read(supabaseClientProvider);
      await client.rpc('place_order', params: {
        'p_student_id': studentId,
        'p_orders': orders,
      });

      // Berhasil — bersihkan keranjang, invalidate providers
      ref.read(cartProvider.notifier).clearAll();
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaActiveOrdersProvider);

      if (mounted) {
        context.go(AppRouter.studentOrders);
        _showSnack('Pesanan berhasil dikirim! 🎉');
      }
    } catch (e) {
      String msg = 'Gagal mengirim pesanan';
      if (e.toString().contains('insufficient_balance')) {
        msg = 'Saldo tidak mencukupi';
      } else if (e.toString().contains('phone_required')) {
        msg = 'Nomor WA wajib untuk pengiriman';
      } else if (e.toString().contains('delivery_location_required')) {
        msg = 'Lokasi antar wajib diisi';
      }
      _showSnack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final studentAsync = ref.watch(siswaStudentProvider);
    final locationsAsync = ref.watch(deliveryLocationsProvider);

    final balance = studentAsync.when(
      data: (s) => s?.balance ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final locations = locationsAsync.when(
      data: (l) => l,
      loading: () => <DeliveryLocation>[],
      error: (_, __) => <DeliveryLocation>[],
    );

    if (cartState.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.left_chevron),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Checkout',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Text('Keranjang kosong',
              style: GoogleFonts.inter(color: AppColors.mutedGray)),
        ),
      );
    }

    final canteens = cartState.canteenList;
    final grandTotal = cartState.grandTotal;
    final afterBalance = balance - grandTotal;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Konfirmasi Pesanan',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.teal),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo info card
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.teal, AppColors.darkTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo kamu',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white70)),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(balance)}',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.arrow_right,
                      color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Setelah bayar',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white70)),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(afterBalance)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: afterBalance < 0
                                ? AppColors.error
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Per kantin sections
            ...canteens.map((c) => _CanteenSection(
                  entry: c,
                  locations: locations,
                  error: _errors[c.operatorId],
                  phoneCtrl: _phoneCtrl(c.operatorId),
                  locationCtrl: _locationCtrl(c.operatorId),
                  noteCtrl: _noteCtrl(c.operatorId),
                )),

            // Grand total
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total ${canteens.length} kantin',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.mutedGray)),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(grandTotal)}',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal),
                      ),
                    ],
                  ),
                  if (afterBalance < 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo tidak mencukupi. Kekurangan Rp ${NumberFormat('#,###', 'id_ID').format(afterBalance.abs())}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom action
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: (_isProcessing || afterBalance < 0)
              ? null
              : () => _placeOrder(cartState, balance),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            disabledBackgroundColor: AppColors.gray400,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isProcessing
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
                  'Pesan Sekarang  •  Rp ${NumberFormat('#,###', 'id_ID').format(grandTotal)}',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _CanteenSection extends ConsumerStatefulWidget {
  final CartCanteenEntry entry;
  final List<DeliveryLocation> locations;
  final String? error;
  final TextEditingController phoneCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController noteCtrl;

  const _CanteenSection({
    required this.entry,
    required this.locations,
    this.error,
    required this.phoneCtrl,
    required this.locationCtrl,
    required this.noteCtrl,
  });

  @override
  ConsumerState<_CanteenSection> createState() => _CanteenSectionState();
}

class _CanteenSectionState extends ConsumerState<_CanteenSection> {
  String? _selectedLocationId; // null = custom (ketik sendiri)

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(cartProvider.notifier);
    final entry = widget.entry;
    final deliveryFee = entry.deliveryType == 'delivery' ? entry.deliveryFee : 0;
    final total = entry.subtotal + deliveryFee;
    final isDelivery = entry.deliveryType == 'delivery';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kantin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.bag_fill,
                    color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.canteenName,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal),
                  ),
                ),
              ],
            ),
          ),

          // Items
          ...entry.items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Text('${item.quantity}x',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedGray)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.productName,
                          style: GoogleFonts.inter(fontSize: 13)),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(item.lineTotal)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // Delivery type selector
          if (entry.deliveryEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Cara penerimaan',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DeliveryOption(
                    label: 'Ambil Sendiri',
                    icon: CupertinoIcons.bag,
                    selected: !isDelivery,
                    onTap: () =>
                        notifier.setDeliveryType(entry.operatorId, 'takeaway'),
                  ),
                ),
                Expanded(
                  child: _DeliveryOption(
                    label: 'Diantarkan',
                    icon: CupertinoIcons.location_fill,
                    selected: isDelivery,
                    onTap: () =>
                        notifier.setDeliveryType(entry.operatorId, 'delivery'),
                    badge: entry.deliveryFee > 0
                        ? '+Rp ${NumberFormat('#,###', 'id_ID').format(entry.deliveryFee)}'
                        : 'Gratis',
                  ),
                ),
              ],
            ),
          ],

          // Delivery location (jika delivery)
          if (isDelivery) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Lokasi antar *',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray)),
            ),
            const SizedBox(height: 8),

            // Pilih dari daftar
            if (widget.locations.isNotEmpty) ...[
              SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...widget.locations.map((loc) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(loc.name,
                                style: GoogleFonts.inter(fontSize: 12)),
                            selected: _selectedLocationId == loc.id,
                            selectedColor: AppColors.primaryLight,
                            checkmarkColor: AppColors.teal,
                            onSelected: (_) {
                              setState(
                                  () => _selectedLocationId = loc.id);
                              notifier.setDeliveryLocation(
                                  entry.operatorId, loc.name);
                              widget.locationCtrl.text = loc.name;
                            },
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Ketik sendiri',
                            style: GoogleFonts.inter(fontSize: 12)),
                        selected: _selectedLocationId == '__custom',
                        selectedColor: AppColors.softOrange,
                        onSelected: (_) =>
                            setState(() => _selectedLocationId = '__custom'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Input manual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: widget.locationCtrl,
                onChanged: (v) {
                  notifier.setDeliveryLocation(entry.operatorId, v);
                  setState(() => _selectedLocationId = '__custom');
                },
                decoration: InputDecoration(
                  hintText: 'Contoh: Kelas 7A, Ruang Guru…',
                  hintStyle:
                      GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
                  prefixIcon: const Icon(CupertinoIcons.location,
                      size: 18, color: AppColors.mutedGray),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),

            // Nomor WA
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nomor WA / HP *',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: widget.phoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (v) =>
                    notifier.setStudentPhone(entry.operatorId, v),
                decoration: InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  hintStyle:
                      GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
                  prefixIcon: const Icon(CupertinoIcons.phone,
                      size: 18, color: AppColors.mutedGray),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),

            if (widget.error != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.error!,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ],

          // Catatan order
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: widget.noteCtrl,
              onChanged: (v) =>
                  notifier.setCanteenNote(entry.operatorId, v),
              decoration: InputDecoration(
                hintText: 'Catatan untuk kantin (opsional)…',
                hintStyle:
                    GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 13),
                prefixIcon: const Icon(CupertinoIcons.pencil,
                    size: 18, color: AppColors.mutedGray),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),

          // Subtotal kantin ini
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.mutedGray)),
                    Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(entry.subtotal)}',
                        style: GoogleFonts.inter(fontSize: 13)),
                  ],
                ),
                if (isDelivery && entry.deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ongkir 🛵',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.mutedGray)),
                      Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(entry.deliveryFee)}',
                          style: GoogleFonts.inter(fontSize: 13)),
                    ],
                  ),
                ],
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total kantin ini',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  const _DeliveryOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.teal : AppColors.mutedGray, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.teal : AppColors.mutedGray,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Text(badge!,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.accentOrange)),
            ],
          ],
        ),
      ),
    );
  }
}
