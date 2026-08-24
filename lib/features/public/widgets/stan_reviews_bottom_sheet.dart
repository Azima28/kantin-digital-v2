import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

/// Bottom sheet modal to display all customer reviews & ratings for a specific canteen stall.
class StanReviewsBottomSheet extends ConsumerStatefulWidget {
  final String canteenId;
  final String canteenName;
  final double averageRating;
  final int totalReviews;

  const StanReviewsBottomSheet({
    super.key,
    required this.canteenId,
    required this.canteenName,
    required this.averageRating,
    required this.totalReviews,
  });

  static Future<void> show(
    BuildContext context, {
    required String canteenId,
    required String canteenName,
    required double averageRating,
    required int totalReviews,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StanReviewsBottomSheet(
        canteenId: canteenId,
        canteenName: canteenName,
        averageRating: averageRating,
        totalReviews: totalReviews,
      ),
    );
  }

  @override
  ConsumerState<StanReviewsBottomSheet> createState() =>
      _StanReviewsBottomSheetState();
}

class _StanReviewsBottomSheetState
    extends ConsumerState<StanReviewsBottomSheet> {
  List<OrderReview>? _reviews;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/canteens/${widget.canteenId}/reviews');
      if (res.success && res.data != null && mounted) {
        final list = res.data as List<dynamic>;
        final parsed = list
            .map((e) => OrderReview.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _reviews = parsed;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final isDark = context.isDark;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Grab handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dividerCol,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rating & Ulasan Pembeli',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.canteenName,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Nebula.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid,
                          color: Colors.grey, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dividerCol),

          // 2. Score Highlight Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 26, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        widget.averageRating > 0
                            ? widget.averageRating.toStringAsFixed(1)
                            : '5.0',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.averageRating >= 4.0
                            ? 'Sangat Direkomendasikan!'
                            : (widget.averageRating >= 3.0
                                ? 'Cukup Memuaskan'
                                : 'Penilaian Pelanggan'),
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Berdasarkan ${widget.totalReviews > 0 ? widget.totalReviews : (_reviews?.length ?? 0)} ulasan asli dari siswa & pembeli',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dividerCol),

          // 3. Reviews List Body
          Expanded(
            child: _buildReviewsContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsContent(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Shimmer(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: context.surfaceBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  color: Nebula.rose, size: 36),
              const SizedBox(height: 10),
              Text(
                'Gagal memuat ulasan',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: context.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final reviews = _reviews ?? [];
    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_outline_rounded,
                    size: 32, color: Nebula.teal),
              ),
              const SizedBox(height: 14),
              Text(
                'Belum Ada Ulasan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jadilah yang pertama memberikan ulasan setelah memesan dari stan ini!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      separatorBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: context.dividerCol),
      ),
      itemBuilder: (context, index) {
        final review = reviews[index];
        final String formattedDate = review.createdAt != null
            ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                .format(review.createdAt!.toLocal())
            : 'Baru saja';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User name + Star rating row + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Nebula.teal.withValues(alpha: 0.12),
                      child: Text(
                        review.studentName.isNotEmpty
                            ? review.studentName[0].toUpperCase()
                            : 'S',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
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
                        Row(
                          children: List.generate(5, (starIdx) {
                            return Icon(
                              starIdx < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: const Color(0xFFFFC107),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Review text (if any)
            if (review.reviewText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderLight, width: 0.6),
                ),
                child: Text(
                  review.reviewText,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),

            // Tags (if any)
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: review.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Nebula.teal.withValues(alpha: 0.25),
                          width: 0.6),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Nebula.teal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}
