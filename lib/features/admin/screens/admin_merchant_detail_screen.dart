import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/empty_state_widget.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_profile_header.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_stats_card.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_product_list_item.dart';
import 'package:kantin_digital/features/admin/widgets/merchant_transaction_list_item.dart';
import 'package:kantin_digital/features/admin/widgets/admin_edit_merchant_sheet.dart';

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

    final client = ref.read(supabaseClientProvider);
    try {
      final currentUserRole = ref.read(authNotifierProvider).profile?['role'];
      if (currentUserRole != 'super_admin' && currentUserRole != 'admin' && currentUserRole != 'petugas_keuangan') {
        throw Exception('Tidak memiliki izin untuk mengubah password');
      }

      final currentUserId = ref.read(authNotifierProvider).profile?['id'];
      await client.rpc('update_auth_user_password', params: {
        'p_user_id': profileId,
        'p_new_password': password,
        'p_caller_id': currentUserId,
      });

      if (mounted) {
        Navigator.pop(context);
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPasswordUpdated),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengubah kata sandi'),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(String profileId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(AppStrings.adminChangePassword),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: _passwordController,
            placeholder: 'Masukkan sandi baru',
            obscureText: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _changePassword(profileId),
            child: const Text(AppStrings.buttonSave),
          ),
        ],
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
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.darkTeal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${AppStrings.titleDetail} Operator',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
        actions: [
          detailAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(CupertinoIcons.pencil, color: AppColors.darkTeal),
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
                    backgroundColor: AppColors.darkTeal,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield),
                  label: const Text(
                    AppStrings.adminChangePassword,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: MerchantDailySalesCard(dailySales: dailySales)),
                    const SizedBox(width: 12),
                    Expanded(child: MerchantMonthlySalesCard(monthlySales: monthlySales)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildProductCatalog(products),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRecentSales(txs),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    color: AppColors.darkTeal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
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
              separatorBuilder: (context, i) => const Divider(height: 16, color: AppColors.borderGray),
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

  Widget _buildRecentSales(List<OperatorTransaction> txs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Sales',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkTeal,
            ),
          ),
          const SizedBox(height: 16),
          if (txs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: EmptyStateWidget(message: AppStrings.adminNoSalesLabel),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (context, i) => const Divider(height: 16, color: AppColors.borderGray),
              itemBuilder: (context, i) {
                final tx = txs[i];
                return MerchantTransactionListItem(
                  nisn: tx.studentNisn ?? '-',
                  date: tx.createdAt?.toLocal() ?? DateTime.now(),
                  amount: tx.totalAmount,
                );
              },
            ),
        ],
      ),
    );
  }
}
