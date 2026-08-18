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
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_profile_header.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_stats_card.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_product_list_item.dart';
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
                        child: const Icon(Icons.lock_reset_rounded, color: Nebula.teal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppStrings.adminChangePassword,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: ctx.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: obscure,
                    style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Masukkan sandi baru',
                      hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 14),
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
          icon: Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${AppStrings.titleDetail} Operator',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
          ),
        ),
        actions: [
          detailAsync.maybeWhen(
            data: (data) => IconButton(
              icon: Icon(CupertinoIcons.pencil, color: Nebula.teal),
              onPressed: () => showEditMerchantSheet(
                context,
                ref,
                data.profile,
                CanteenOperator.fromJson(data.operator),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
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

          final double dailySales = data.dailySales;
          final double monthlySales = data.monthlySales;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MerchantProfileHeader(
                  fullName: fullName,
                  canteenName: canteenName,
                  username: username,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(profile.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield, size: 18),
                  label: const Text(
                    AppStrings.adminChangePassword,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const GradientLine(margin: EdgeInsets.symmetric(vertical: 16)),
                Row(
                  children: [
                    Expanded(child: MerchantDailySalesCard(dailySales: dailySales)),
                    const SizedBox(width: 12),
                    Expanded(child: MerchantMonthlySalesCard(monthlySales: monthlySales)),
                  ],
                ),
                const SizedBox(height: 20),
                if (MediaQuery.of(context).size.width >= 640)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildProductCatalog(products),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRecentSales(txs, canteenName),
                      ),
                    ],
                  )
                else ...[
                  _buildProductCatalog(products),
                  const SizedBox(height: 16),
                  _buildRecentSales(txs, canteenName),
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
                const SizedBox(height: 20),
                ...List.generate(3, (i) => const SkeletonListTile()),
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
              Text('${AppStrings.labelFailed} memuat data'),
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

  Widget _buildProductCatalog(List<Product> products) {
    return NebulaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Product Catalog',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Read-Only',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: EmptyStateWidget(message: AppStrings.adminNoProductsLabel),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, i) => Divider(height: 16, color: context.dividerCol),
              itemBuilder: (context, i) {
                final p = products[i];
                return MerchantProductListItem(
                  name: p.name,
                  price: p.price,
                  isAvailable: p.isAvailable,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSales(List<OperatorTransaction> txs, String canteenName) {
    return NebulaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Riwayat Penjualan (10 Terakhir)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentTransactionsScreen(
                        operatorId: widget.merchantId,
                        title: 'Penjualan $canteenName',
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
          const SizedBox(height: 12),
          if (txs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: EmptyStateWidget(message: AppStrings.adminNoSalesLabel),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.take(10).length,
              separatorBuilder: (context, i) => Divider(height: 14, color: context.dividerCol),
              itemBuilder: (context, i) {
                final tx = txs[i];
                final bool isRefund = tx.status?.toString().toLowerCase() == 'refunded' || tx.type == 'refund';

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
                            radius: 16,
                            backgroundColor: isRefund ? Nebula.rose.withValues(alpha: 0.1) : Nebula.teal.withValues(alpha: 0.08),
                            child: Icon(
                              isRefund ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.cart,
                              size: 14,
                              color: isRefund ? Nebula.rose : Nebula.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.studentName ?? 'Siswa (NISN: ${tx.studentNisn ?? "-"})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM, HH:mm', 'id_ID').format(tx.createdAt?.toLocal() ?? DateTime.now()),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isRefund ? "-" : "+"}Rp ${NumberFormat('#,###', 'id_ID').format(tx.totalAmount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isRefund ? Nebula.rose : Nebula.teal,
                                ),
                              ),
                              if (isRefund)
                                Text(
                                  'REFUNDED',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Nebula.rose,
                                  ),
                                ),
                            ],
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
