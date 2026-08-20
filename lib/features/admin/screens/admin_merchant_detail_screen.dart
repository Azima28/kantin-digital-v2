import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_profile_header.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_stats_card.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_product_list_item.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_all_products_sheet.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_merchant_sheet.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_transaction_detail_sheet.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class AdminMerchantDetailScreen extends ConsumerStatefulWidget {
  final String merchantId;
  const AdminMerchantDetailScreen({super.key, required this.merchantId});

  @override
  ConsumerState<AdminMerchantDetailScreen> createState() => _AdminMerchantDetailScreenState();
}

class _AdminMerchantDetailScreenState extends ConsumerState<AdminMerchantDetailScreen> {
  final _passwordController = TextEditingController();
  int _selectedHistoryTab = 0; // 0: Penjualan, 1: Pencairan & Mutasi

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(String profileId) async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/users/password',
        body: {
          'user_id': profileId,
          'new_password': password,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal mengubah kata sandi');
      }

      if (mounted) {
        Navigator.pop(context);
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPasswordUpdated),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah kata sandi: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(String profileId) {
    bool obscure = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: ctx.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ctx.dividerCol, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: ctx.shadowColor,
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.lock_rotation, color: Nebula.teal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppStrings.adminChangePassword,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ctx.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: obscure,
                    style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi baru...',
                      hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: ctx.surfaceBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ctx.dividerCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ctx.dividerCol),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setLocal(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _passwordController.clear();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: ctx.dividerCol),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.buttonCancel,
                            style: GoogleFonts.inter(
                              color: ctx.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _changePassword(profileId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.buttonSave,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog: Tarik Saldo / Cairkan Kas Stan ──────────────────────────────────
  void _showWithdrawalDialog(String operatorId, String canteenName, int currentBalance) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedMethod = 'Tunai (Cash)';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                color: ctx.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ctx.dividerCol, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: ctx.shadowColor,
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.arrow_up_right_circle_fill, color: Nebula.rose, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pencairan Kas Stan (Tarik Saldo)',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: ctx.textPrimary,
                                  ),
                                ),
                                Text(
                                  canteenName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Nebula.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Info Saldo Tersedia
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Nebula.teal.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saldo Tersedia untuk Ditarik:',
                              style: GoogleFonts.inter(fontSize: 12, color: ctx.textSecondary),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(currentBalance)}',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Nebula.teal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input Nominal Penarikan
                      Text(
                        'Nominal Penarikan Dana (Rp)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary, fontWeight: FontWeight.bold),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Nominal penarikan wajib diisi';
                          final val = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (val <= 0) return 'Nominal harus lebih dari 0';
                          if (val > currentBalance) {
                            return 'Melebihi saldo tersedia (Maks Rp ${NumberFormat("#,###", "id_ID").format(currentBalance)})';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Contoh: 50000',
                          hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 13),
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
                          filled: true,
                          fillColor: ctx.surfaceBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick presets
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (currentBalance > 0)
                            InkWell(
                              onTap: () => setLocal(() => amountCtrl.text = currentBalance.toString()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Nebula.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Tarik Semua', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Nebula.teal)),
                              ),
                            ),
                          ...[50000, 100000, 200000, 500000].where((amt) => amt <= currentBalance).map((amt) {
                            return InkWell(
                              onTap: () => setLocal(() => amountCtrl.text = amt.toString()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ctx.surfaceBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: ctx.dividerCol),
                                ),
                                child: Text('Rp ${NumberFormat("#,###", "id_ID").format(amt)}', style: GoogleFonts.inter(fontSize: 11, color: ctx.textPrimary)),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Metode Penyerahan Kas: Tunai
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: ctx.surfaceBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ctx.dividerCol, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.arrow_up_right_circle_fill, size: 18, color: Nebula.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Metode Penyerahan:',
                                    style: GoogleFonts.inter(fontSize: 10.5, color: ctx.textSecondary),
                                  ),
                                  Text(
                                    'Tunai (Serah Terima Kas Langsung)',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Catatan Pembukuan
                      Text(
                        'Catatan / Keterangan Pembukuan',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: notesCtrl,
                        style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Pencairan hasil penjualan minggu ke-1',
                          hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: ctx.surfaceBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                        ),
                      ),
                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: ctx.dividerCol),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                AppStrings.buttonCancel,
                                style: GoogleFonts.inter(color: ctx.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      final rawAmt = int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                      if (rawAmt <= 0) return;

                                      setLocal(() => isSaving = true);
                                      try {
                                        final apiClient = ref.read(apiClientProvider);
                                        final res = await apiClient.post(
                                          '/finance/merchant/withdraw',
                                          body: {
                                            'operator_id': operatorId,
                                            'amount': rawAmt,
                                            'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Pencairan kas stan',
                                            'method': selectedMethod,
                                          },
                                        );

                                        if (!res.success) {
                                          throw Exception(res.message ?? 'Gagal mencairkan dana stan');
                                        }

                                        ref.invalidate(adminMerchantDetailProvider(widget.merchantId));
                                        ref.invalidate(keuanganDashboardProvider);

                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Pencairan dana Rp ${NumberFormat("#,###", "id_ID").format(rawAmt)} untuk $canteenName berhasil dicatat.'),
                                              backgroundColor: Nebula.teal,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setLocal(() => isSaving = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Gagal mencairkan dana: $e'),
                                              backgroundColor: Nebula.rose,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Nebula.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      'Cairkan Kas',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminMerchantDetailProvider(widget.merchantId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Operator Stan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          detailAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(CupertinoIcons.pencil, color: Nebula.teal),
              tooltip: 'Edit Data Stan',
              onPressed: () => showEditMerchantSheet(
                context,
                ref,
                data.profile,
                CanteenOperator.fromJson(data.operator),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: detailAsync.when(
        data: (data) {
          final profile = data.profile;
          final operator = data.operator;
          final List<Product> products = data.products;
          final List<OperatorTransaction> txs = data.recentTransactions;

          final String fullName = profile.fullName ?? '';
          final String username = profile.username ?? '';
          final String canteenName = operator['canteen_name'] ?? 'Stan Kantin';
          final int balanceEarned = (operator['balance_earned'] as num?)?.toInt() ?? 0;

          final double dailySales = data.dailySales;
          final double monthlySales = data.monthlySales;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Header
                MerchantProfileHeader(
                  fullName: fullName,
                  canteenName: canteenName,
                  username: username,
                ),
                const SizedBox(height: 14),

                // 2. KARTU SALDO PENDAPATAN & AKSI KEUANGAN (Pembukuan Stan)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Nebula.teal.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(CupertinoIcons.creditcard_fill, color: Nebula.teal, size: 16),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Saldo Pendapatan Stan',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Siap Dicairkan',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(balanceEarned)}',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tombol Aksi Finansial: Tarik Saldo
                      PressScale(
                        onTap: () => _showWithdrawalDialog(profile.id, canteenName, balanceEarned),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Nebula.teal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.arrow_up_right_circle_fill, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Cairkan Kas Stan (Tarik Saldo)',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Ubah Sandi Button
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(profile.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.cardBg,
                    foregroundColor: context.textPrimary,
                    elevation: 0,
                    side: BorderSide(color: context.dividerCol, width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield, size: 16, color: Nebula.teal),
                  label: Text(
                    AppStrings.adminChangePassword,
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Sales Stats Cards
                Row(
                  children: [
                    Expanded(child: MerchantDailySalesCard(dailySales: dailySales)),
                    const SizedBox(width: 10),
                    Expanded(child: MerchantMonthlySalesCard(monthlySales: monthlySales)),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Product Catalog & Transaction History
                if (MediaQuery.of(context).size.width >= 640)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildProductCatalog(products, canteenName),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRecentSales(txs, canteenName, profile.id),
                      ),
                    ],
                  )
                else ...[
                  _buildProductCatalog(products, canteenName),
                  const SizedBox(height: 14),
                  _buildRecentSales(txs, canteenName, profile.id),
                ],
              ],
            ),
          );
        },
        loading: () => Shimmer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminMerchantDetailProvider(widget.merchantId)),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCatalog(List<Product> products, String canteenName) {
    return NebulaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Katalog Produk (${products.length})',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  MerchantAllProductsSheet.show(
                    context,
                    products: products,
                    canteenName: canteenName,
                  );
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Nebula.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: EmptyStateWidget(message: AppStrings.adminNoProductsLabel),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.take(5).length,
              separatorBuilder: (context, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = products[i];
                return MerchantProductListItem.fromProduct(p);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSales(List<OperatorTransaction> txs, String canteenName, String operatorId) {
    // Filter by Tab
    final salesTxs = txs.where((t) => t.type == 'purchase').toList();
    final payoutTxs = txs.where((t) => t.type == 'withdrawal' || t.type == 'merchant_adjustment').toList();
    final displayTxs = _selectedHistoryTab == 0 ? salesTxs : payoutTxs;

    return NebulaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pembukuan Mutasi Stan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentTransactionsScreen(
                        operatorId: widget.merchantId,
                        title: 'Mutasi $canteenName',
                        primaryColor: Nebula.teal,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Nebula.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tab Selector: Penjualan vs Pencairan Kas
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedHistoryTab = 0),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedHistoryTab == 0 ? Nebula.teal : context.surfaceBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Penjualan (${salesTxs.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedHistoryTab == 0 ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedHistoryTab = 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedHistoryTab == 1 ? Nebula.teal : context.surfaceBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pencairan Kas (${payoutTxs.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedHistoryTab == 1 ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (displayTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: EmptyStateWidget(
                message: _selectedHistoryTab == 0 ? 'Belum ada riwayat penjualan produk.' : 'Belum ada riwayat pencairan kas stan.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayTxs.take(5).length,
              separatorBuilder: (context, i) => Divider(height: 14, color: context.dividerCol),
              itemBuilder: (context, i) {
                final tx = displayTxs[i];
                final bool isWithdrawal = tx.type == 'withdrawal';
                final bool isAdjustment = tx.type == 'merchant_adjustment';
                final bool isRefund = tx.status?.toString().toLowerCase() == 'refunded' || tx.type == 'refund';

                String title = tx.studentName ?? 'Siswa';
                if (isWithdrawal) {
                  title = 'Pencairan Kas (Tarik Saldo)';
                } else if (isAdjustment) {
                  title = 'Koreksi Saldo Stan';
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showTransactionDetailSheet(context, ref, tx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isWithdrawal
                                ? Nebula.rose.withValues(alpha: 0.12)
                                : (isAdjustment ? Nebula.amber.withValues(alpha: 0.15) : Nebula.teal.withValues(alpha: 0.12)),
                            child: Icon(
                              isWithdrawal
                                  ? CupertinoIcons.arrow_up_right_circle
                                  : (isAdjustment ? CupertinoIcons.arrow_right_arrow_left : (isRefund ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.cart)),
                              size: 16,
                              color: isWithdrawal ? Nebula.rose : (isAdjustment ? Nebula.amber : Nebula.teal),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(
                                    tx.createdAt?.toLocal() ?? DateTime.now(),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isWithdrawal ? "-" : "+"}Rp ${NumberFormat('#,###', 'id_ID').format(tx.totalAmount)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isWithdrawal ? Nebula.rose : Nebula.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
