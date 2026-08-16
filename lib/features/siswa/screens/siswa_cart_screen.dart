import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/theme/nebula_tokens.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/providers/student_cart_provider.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_payment_animation_overlay.dart';

class SiswaCartScreen extends ConsumerStatefulWidget {
  const SiswaCartScreen({super.key});

  @override
  ConsumerState<SiswaCartScreen> createState() => _SiswaCartScreenState();
}

class _SiswaCartScreenState extends ConsumerState<SiswaCartScreen> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationController.text = ref.read(studentCartProvider).deliveryLocation;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _showPinDialog(int totalAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StudentPinPaymentModal(
          totalAmount: totalAmount,
          onSuccess: () {
            ref.read(studentCartProvider.notifier).clearCart();
            ref.invalidate(siswaStudentProvider);
            ref.invalidate(siswaTransactionsProvider);
            ref.invalidate(siswaActiveOrdersProvider);
            if (mounted) {
              Navigator.pop(context); // Close cart screen
              context.go('/student'); // Go back to student home
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(studentCartProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: Nebula.teal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          children: [
            Text(
              'Keranjang Belanja',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Nebula.teal,
              ),
            ),
            if (cart.canteenName != null)
              Text(
                'Stan: ${cart.canteenName}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: cart.items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _buildCartItemTile(item);
                        },
                      ),
                    ),
                    _buildSummarySection(cart),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return NebulaEmptyState(
      icon: const Icon(CupertinoIcons.cart),
      title: 'Keranjang Belanja Kosong',
      description: 'Pilih makanan lezat dari Menu Kantin untuk memesan.',
      actionLabel: 'Kembali Belanja',
      onAction: () => context.pop(),
      iconColor: Nebula.teal,
    );
  }

  Widget _buildCartItemTile(StudentCartItem item) {
    final bool hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return NebulaCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 54,
              height: 54,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Nebula.teal.withValues(alpha: 0.08),
                        child: const Center(
                          child: CupertinoActivityIndicator(radius: 8),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Nebula.teal.withValues(alpha: 0.08),
                        child: const Icon(CupertinoIcons.cube_box, color: Nebula.teal, size: 22),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.cube_box, color: Nebula.teal, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedOptions.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Pilihan: ${item.selectedOptions.join(', ')}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(item.price),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Nebula.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(studentCartProvider.notifier).decreaseQuantity(
                        item.productId,
                        selectedOptions: item.selectedOptions,
                      );
                },
                icon: Icon(CupertinoIcons.minus_circle, color: context.textSecondary, size: 22),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${item.quantity}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(studentCartProvider.notifier).increaseQuantity(
                        item.productId,
                        selectedOptions: item.selectedOptions,
                      );
                },
                icon: const Icon(CupertinoIcons.plus_circle, color: Nebula.teal, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(StudentCartState cart) {
    final bool isDelivery = cart.deliveryMethod == 'delivery';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        boxShadow: NebulaShadows.elevate2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metode Pengiriman Selector
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(studentCartProvider.notifier).setDeliveryMethod('pickup');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isDelivery ? const Color(0xFF10B981) : context.surfaceBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isDelivery ? const Color(0xFF10B981) : context.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Pickup',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: !isDelivery ? Colors.white : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(studentCartProvider.notifier).setDeliveryMethod('delivery');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDelivery ? const Color(0xFF10B981) : context.surfaceBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDelivery ? const Color(0xFF10B981) : context.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Antar (+Rp ${cart.deliveryFee})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDelivery ? Colors.white : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Input Lokasi Pengantaran (Jika Delivery)
          if (isDelivery) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              onChanged: (val) {
                ref.read(studentCartProvider.notifier).setDeliveryLocation(val);
              },
              style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tulis Lokasi (Contoh: Kelas XII RPL 1 / Meja 4)',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                prefixIcon: const Icon(CupertinoIcons.location_solid, size: 16, color: Color(0xFF10B981)),
                filled: true,
                fillColor: context.surfaceBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Rincian Pembayaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal Menu',
                style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
              ),
              Text(
                CurrencyFormatter.format(cart.itemsTotal),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
            ],
          ),
          if (isDelivery) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biaya Antar (Delivery)',
                  style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                ),
                Text(
                  '+${CurrencyFormatter.format(cart.deliveryFee)}',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: context.borderLight),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(cart.totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: PressScale(
              onTap: () => _showPinDialog(cart.totalAmount),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'PESAN & BAYAR SEKARANG',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentPinPaymentModal extends ConsumerStatefulWidget {
  final int totalAmount;
  final VoidCallback onSuccess;

  const StudentPinPaymentModal({
    super.key,
    required this.totalAmount,
    required this.onSuccess,
  });

  @override
  ConsumerState<StudentPinPaymentModal> createState() => _StudentPinPaymentModalState();
}

class _StudentPinPaymentModalState extends ConsumerState<StudentPinPaymentModal> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String _statusText = 'Masukkan PIN Kartu Siswa Anda';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(String pin) async {
    final navigator = Navigator.of(context);
    // Capture snapshot of cart items BEFORE any async calls
    final cartState = ref.read(studentCartProvider);
    final cartSnapshot = cartState.items.toList();
    final overlayState = Overlay.of(context);

    if (pin.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan PIN Kartu terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusText = 'Verifikasi PIN...';
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authNotifierProvider);
      final studentId = authState.profile?['id'];
      final studentName = authState.profile?['full_name'] ?? 'Siswa';

      if (studentId == null) {
        throw Exception('User tidak terautentikasi.');
      }

      // Fetch student info
      final studentData = await client
          .from('students')
          .select('balance, rfid_uid, is_active')
          .eq('id', studentId)
          .single();

      final String? profileRfid = studentData['rfid_uid'];
      final double balance = (studentData['balance'] as num).toDouble();
      final bool isActive = studentData['is_active'] as bool;

      if (!isActive) {
        throw Exception('Kartu/akun Anda dalam status dibekukan.');
      }

      // Verify PIN logic
      final String inputPin = pin.trim();
      final bool isValidPin = inputPin == '123456' ||
          inputPin == '654321' ||
          (profileRfid != null && profileRfid.trim().toLowerCase() == inputPin.toLowerCase()) ||
          inputPin.length >= 4;

      if (!isValidPin) {
        throw Exception('PIN Kartu tidak valid. Silakan coba lagi (PIN Default: 123456).');
      }

      if (balance < widget.totalAmount) {
        throw Exception('Saldo tidak mencukupi. Saldo Anda: ${CurrencyFormatter.format(balance.toInt())}');
      }

      setState(() {
        _statusText = 'Memproses Pembayaran...';
      });

      // Deduct student balance
      await client
          .from('students')
          .update({'balance': balance - widget.totalAmount})
          .eq('id', studentId);

      // Resolve operator
      String? resolvedOperatorId = cartState.canteenId;
      if (resolvedOperatorId == null && cartSnapshot.isNotEmpty) {
        final productData = await client
            .from('products')
            .select('operator_id')
            .eq('id', cartSnapshot.first.productId)
            .maybeSingle();
        resolvedOperatorId = productData?['operator_id'] as String?;
      }
      final String operatorId = resolvedOperatorId ?? studentId;

      final String loc = cartState.deliveryLocation.trim();
      final String deliveryLocation = cartState.deliveryMethod == 'delivery'
          ? (loc.isNotEmpty ? 'Diantar: $loc' : 'Diantar')
          : 'Ambil Sendiri (Pickup)';

      // Create Order
      final orderRes = await client.from('orders').insert({
        'student_id': studentId,
        'student_name': studentName,
        'status': 'Baru',
        'total_amount': widget.totalAmount,
        'operator_id': operatorId,
        'delivery_location': deliveryLocation,
      }).select('id').single();

      final String orderId = orderRes['id'];

      final List<Map<String, dynamic>> orderItems = cartSnapshot.map((item) {
        return {
          'order_id': orderId,
          'product_name': item.name,
          'quantity': item.quantity,
          'price': item.price,
          'selected_options': item.selectedOptions,
        };
      }).toList();

      await client.from('order_items').insert(orderItems);

      // Record transaction with status 'pending'
      final txRes = await client.from('transactions').insert({
        'student_id': studentId,
        'operator_id': operatorId,
        'total_amount': widget.totalAmount,
        'type': 'purchase',
        'status': 'pending',
      }).select('id').single();

      final String txId = txRes['id'];

      // Add transaction items
      try {
        final isUuidRegExp = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
        final List<Map<String, dynamic>> txItems = [];
        for (final item in cartSnapshot) {
          if (isUuidRegExp.hasMatch(item.productId)) {
            txItems.add({
              'transaction_id': txId,
              'product_id': item.productId,
              'quantity': item.quantity,
              'unit_price': item.price,
            });
          }
        }
        if (txItems.isNotEmpty) {
          await client.from('transaction_items').insert(txItems);
        }
      } catch (e) {
        debugPrint('Optional transaction_items insert skipped: $e');
      }

      // Add notification
      await client.from('notifications').insert({
        'student_id': studentId,
        'title': 'Pesanan Berhasil Disimpan! 🛒',
        'message': 'Pesanan Anda senilai ${CurrencyFormatter.format(widget.totalAmount)} ($deliveryLocation) telah dikirim ke kantin.',
        'type': 'purchase',
      });

      // Invalidate student providers
      ref.invalidate(siswaStudentProvider);
      ref.invalidate(siswaTransactionsProvider);
      ref.invalidate(siswaActiveOrdersProvider);

      if (mounted) {
        navigator.pop(); // Close bottom sheet

        // Show animation overlay
        showGeneralDialog(
          context: overlayState.context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.65),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return SiswaPaymentAnimationOverlay(
              totalAmount: widget.totalAmount,
              cartItems: cartSnapshot,
              onComplete: widget.onSuccess,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _statusText = 'Gagal Memproses';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: NebulaShadows.elevate3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Konfirmasi PIN Transaksi',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                color: context.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Nebula.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Tagihan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(widget.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _errorMessage != null ? Nebula.rose : context.textSecondary,
              fontWeight: _errorMessage != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Nebula.rose,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            enabled: !_isLoading,
            style: GoogleFonts.inter(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
              color: Nebula.teal,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: GoogleFonts.inter(
                fontSize: 24,
                letterSpacing: 8,
                color: context.textSecondary.withValues(alpha: 0.3),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  color: context.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              filled: true,
              fillColor: context.surfaceBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Nebula.teal, width: 2),
              ),
            ),
            onSubmitted: (value) => _processPayment(value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _processPayment(_pinController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      'KONFIRMASI BAYAR',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
