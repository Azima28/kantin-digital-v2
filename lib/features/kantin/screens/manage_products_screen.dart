import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen> {
  // Local optimistic availability tracking for instant switch response with zero lag
  final Map<String, bool> _localAvailability = {};

  // Toggle availability of product in database with optimistic local UI update
  Future<void> _toggleProductAvailability(
    String productId,
    bool currentVal,
    bool newValue,
  ) async {
    setState(() {
      _localAvailability[productId] = newValue;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/pos/products/$productId/availability', body: {
        'is_available': newValue,
      });

      // Silently refresh background caches without resetting local management UI
      ref.invalidate(posProductsProvider);
      ref.invalidate(publicMenuProvider(null));
    } catch (e) {
      if (mounted) {
        setState(() {
          _localAvailability[productId] = currentVal;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memperbarui status produk'),
            backgroundColor: Nebula.rose,
          ),
        );
      }
    }
  }

  // Delete product from database with confirmation
  Future<void> _deleteProduct(
    BuildContext context,
    String productId,
    String productName,
  ) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Jajanan'),
        content: Text('Apakah Anda yakin ingin menghapus "$productName" dari katalog stan Anda?'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiClient = ref.read(apiClientProvider);
                await apiClient.delete('/pos/products/$productId');

                // Refresh providers
                if (mounted) {
                  setState(() {
                    _localAvailability.remove(productId);
                  });
                }
                ref.invalidate(posProductsProvider);
                ref.invalidate(manageProductsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.successProductDeleted),
                      backgroundColor: Nebula.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppStrings.labelFailed} menghapus jajanan'),
                      backgroundColor: Nebula.rose,
                    ),
                  );
                }
              }
            },
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );
  }

  // Preset fallback background colors for products without custom image
  Color _getFallbackBgColor(int index, String category) {
    final List<Color> colors = [
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
    ];
    return colors[index % colors.length];
  }

  // Interactive Full-Screen Product Detail & Reviews Sheet
  void _showProductDetailSheet(BuildContext context, Product product) {
    final scrollController = ScrollController();
    int selectedStarFilter = 0; // 0 = Semua, 1..5 = Bintang 1-5

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final bool isAvail = _localAvailability.containsKey(product.id)
                ? _localAvailability[product.id]!
                : product.isAvailable;

            return Container(
              height: screenHeight * 0.94,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: context.borderLight, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab Handle & Top Navigation Bar
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.dividerCol,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Menu Jajanan',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 24),
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: context.borderLight),

                  // Full-Screen Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Photo Hero Banner with Status Tag
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: Nebula.teal.withValues(alpha: 0.1),
                                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: product.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (c, i) => const ShimmerRect(
                                            width: double.infinity,
                                            height: 180,
                                            borderRadius: 16,
                                          ),
                                          errorWidget: (c, i, e) => Center(
                                            child: Icon(
                                              product.category.toLowerCase() == 'makanan'
                                                  ? Icons.restaurant_menu_rounded
                                                  : Icons.local_cafe_rounded,
                                              size: 52,
                                              color: Nebula.teal,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            product.category.toLowerCase() == 'makanan'
                                                ? Icons.restaurant_menu_rounded
                                                : Icons.local_cafe_rounded,
                                            size: 52,
                                            color: Nebula.teal,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAvail
                                        ? Nebula.teal
                                        : Nebula.rose,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isAvail ? 'Tersedia' : 'Habis',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Product Name, Category & Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.surfaceBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: context.borderLight, width: 0.8),
                                      ),
                                      child: Text(
                                        product.category.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: context.textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                CurrencyFormatter.format(product.price),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Nebula.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3. KPI Badges Row (Rating, Terjual, Status)
                          Row(
                            children: [
                              // KPI 1: Rating
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.surfaceBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderLight, width: 0.8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            product.hasRating ? Icons.star_rounded : Icons.star_border_rounded,
                                            size: 18,
                                            color: const Color(0xFFFFC107),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            product.hasRating ? product.rating.toStringAsFixed(1) : '-',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        product.hasRating ? '${product.totalReviews} Ulasan' : 'Belum Ada Rating',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // KPI 2: Terjual
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.surfaceBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderLight, width: 0.8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(CupertinoIcons.bag_fill, size: 16, color: Nebula.teal),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${product.totalSold}',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Porsi Terjual',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // KPI 3: Status Toggle
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context.surfaceBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderLight, width: 0.8),
                                  ),
                                  child: Column(
                                    children: [
                                      Transform.scale(
                                        scale: 0.65,
                                        child: CupertinoSwitch(
                                          value: isAvail,
                                          activeTrackColor: Nebula.teal,
                                          onChanged: (bool val) async {
                                            setSheetState(() {});
                                            Navigator.pop(ctx);
                                            await _toggleProductAvailability(product.id, isAvail, val);
                                          },
                                        ),
                                      ),
                                      Text(
                                        isAvail ? 'Tersedia' : 'Habis',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isAvail ? Nebula.teal : Nebula.rose,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 4. Action Buttons (Edit + Delete)
                          Row(
                            children: [
                              // Edit Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.push('/pos/products/form', extra: product);
                                  },
                                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                                  label: Text(
                                    'Edit Menu',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Nebula.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Delete Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteProduct(context, product.id, product.name);
                                },
                                icon: const Icon(CupertinoIcons.trash, size: 16),
                                label: Text(
                                  'Hapus',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Nebula.rose,
                                  side: BorderSide(color: Nebula.rose.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(height: 1, color: context.borderLight),
                          const SizedBox(height: 18),

                          // 5. Section Ulasan Pembeli & Dropdown Filter Bintang
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Ulasan Pembeli',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  if (product.hasRating) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC107).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFC107)),
                                          const SizedBox(width: 2),
                                          Text(
                                            product.rating.toStringAsFixed(1),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Sleek Compact Dropdown Filter with Yellow Stars
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: context.surfaceBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: context.borderLight, width: 0.8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedStarFilter,
                                    isDense: true,
                                    borderRadius: BorderRadius.circular(16),
                                    dropdownColor: context.cardBg,
                                    icon: const Icon(CupertinoIcons.chevron_down, size: 12),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Text(
                                          'Semua',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                                        ),
                                      ),
                                      for (int star = 5; star >= 1; star--)
                                        DropdownMenuItem(
                                          value: star,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                                              const SizedBox(width: 3),
                                              Text(
                                                '$star',
                                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                    onChanged: (int? newVal) {
                                      if (newVal != null) {
                                        setSheetState(() {
                                          selectedStarFilter = newVal;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 6. Reviews List
                          Consumer(
                            builder: (context, ref, child) {
                              final reviewsAsync = ref.watch(canteenReviewsProvider(product.operatorId));

                              return reviewsAsync.when(
                                data: (List<OrderReview> allReviews) {
                                  final reviews = allReviews.where((r) {
                                    if (selectedStarFilter > 0 && r.rating != selectedStarFilter) {
                                      return false;
                                    }
                                    return true;
                                  }).toList();

                                  if (reviews.isEmpty) {
                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                                      decoration: BoxDecoration(
                                        color: context.surfaceBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: context.borderLight, width: 0.8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.chat_bubble_2_fill,
                                            size: 40,
                                            color: context.textSecondary.withValues(alpha: 0.25),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Belum Ada Ulasan',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            selectedStarFilter > 0
                                                ? 'Belum ada ulasan pembeli untuk rating ★ $selectedStarFilter'
                                                : 'Ulasan dan penilaian dari siswa akan muncul di sini setelah pesanan selesai.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: context.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: reviews.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final review = reviews[index];
                                      final createdAt = review.createdAt?.toLocal() ?? DateTime.now();
                                      final String timeStr = AppDateFormatter.formatShortDateWithTime(createdAt);
                                      final studentInitial = review.studentName.isNotEmpty
                                          ? review.studentName[0].toUpperCase()
                                          : 'S';

                                      return Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: context.surfaceBg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: context.borderLight, width: 0.8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header: Avatar + Student Name + Rating Stars + Date
                                            Row(
                                              children: [
                                                // Student Avatar
                                                if (review.avatarUrl != null && review.avatarUrl!.isNotEmpty)
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: Nebula.teal.withValues(alpha: 0.15),
                                                    backgroundImage: CachedNetworkImageProvider(review.avatarUrl!),
                                                  )
                                                else
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: Nebula.teal.withValues(alpha: 0.15),
                                                    child: Text(
                                                      studentInitial,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Nebula.teal,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 10),

                                                // Name & Stars
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        review.studentName,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: context.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: List.generate(
                                                          5,
                                                          (i) => Icon(
                                                            i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                                            size: 13,
                                                            color: const Color(0xFFFFC107),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Time
                                                Text(
                                                  timeStr,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10.5,
                                                    color: context.textSecondary.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Quick Tags (if any)
                                            if (review.tags.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: review.tags.map((tag) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Nebula.teal.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Nebula.teal.withValues(alpha: 0.25), width: 0.5),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: Nebula.teal,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],

                                            // Review Text (if any)
                                            if (review.reviewText.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                review.reviewText,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  color: context.textPrimary,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(child: CupertinoActivityIndicator()),
                                ),
                                error: (err, stack) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Gagal memuat ulasan',
                                    style: TextStyle(color: Nebula.rose, fontSize: 12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(manageProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _localAvailability.clear();
          });
          ref.invalidate(manageProductsProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section matching user reference screenshot
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Product',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "+ TAMBAH PRODUK BARU" Button
                      PressScale(
                        onTap: () {
                          context.push('/pos/products/form');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Nebula.teal,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Nebula.teal.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+ TAMBAH PRODUK BARU',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Grid Layout
              productsAsync.when(
                data: (List<Product> products) {
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.tray_fill, size: 48, color: context.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada jajanan',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gunakan tombol di atas untuk menambahkan produk jualan stan Anda.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          final String id = product.id;
                          final String name = product.name;
                          final String category = product.category;
                          final int price = product.price;
                          final bool isAvailable = _localAvailability.containsKey(id)
                              ? _localAvailability[id]!
                              : product.isAvailable;
                          final String? imageUrl = product.imageUrl;
                          final Color fallbackBg = _getFallbackBgColor(index, category);

                          return PressScale(
                            onTap: () => _showProductDetailSheet(context, product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.borderLight.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Product Image Container
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        height: 96,
                                        width: double.infinity,
                                        color: fallbackBg.withValues(alpha: 0.15),
                                        child: imageUrl != null && imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (c, i) => const ShimmerRect(
                                                  width: double.infinity,
                                                  height: 96,
                                                  borderRadius: 12,
                                                ),
                                                errorWidget: (c, i, e) => Container(
                                                  color: fallbackBg,
                                                  child: Center(
                                                    child: Icon(
                                                      category.toLowerCase() == 'makanan' ? Icons.restaurant_menu_rounded : Icons.local_cafe_rounded,
                                                      size: 32,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: fallbackBg,
                                                child: Center(
                                                  child: Icon(
                                                    category.toLowerCase() == 'makanan' ? Icons.restaurant_menu_rounded : Icons.local_cafe_rounded,
                                                    size: 32,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  // Product Info & Controls
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Name, Category, Price, Rating & Terjual
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                category.toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: context.textSecondary,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                CurrencyFormatter.format(price),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Nebula.teal,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // Rating & Terjual Row
                                              Row(
                                                children: [
                                                  if (product.hasRating) ...[
                                                    const Icon(
                                                      Icons.star_rounded,
                                                      size: 13,
                                                      color: Color(0xFFFFC107),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      product.rating.toStringAsFixed(1),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: context.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '•',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: context.textSecondary.withValues(alpha: 0.6),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                  ],
                                                  Flexible(
                                                    child: Text(
                                                      '${product.totalSold} terjual',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w500,
                                                        color: context.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          // Footer Controls (Availability Switch & Label)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Transform.scale(
                                                scale: 0.65,
                                                alignment: Alignment.centerLeft,
                                                child: CupertinoSwitch(
                                                  value: isAvailable,
                                                  activeTrackColor: Nebula.teal,
                                                  onChanged: (bool val) =>
                                                      _toggleProductAvailability(id, isAvailable, val),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAvailable
                                                      ? Nebula.teal.withValues(alpha: 0.1)
                                                      : Nebula.rose.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isAvailable ? 'Tersedia' : 'Habis',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAvailable ? Nebula.teal : Nebula.rose,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.58,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const SkeletonProductGridCard(),
                      childCount: 6,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppStrings.labelFailed} memuat daftar produk',
                            style: GoogleFonts.inter(color: Nebula.rose, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(manageProductsProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Nebula.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}
