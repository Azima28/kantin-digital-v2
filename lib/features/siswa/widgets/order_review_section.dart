import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

/// 4 Preset review tags murni teks (tanpa emoji) yang dapat diklik langsung oleh siswa
const List<String> kPresetReviewTags = [
  'Sangat Enak',
  'Pelayanan Cepat',
  'Porsi Pas',
  'Bersih & Higienis',
];

/// Warna bintang kuning klasik hangat (warm yellow)
const Color kStarYellow = Color(0xFFFFC107);

/// Widget Rating Bintang & Ulasan Pesanan yang Menggantikan 4-Status Stepper saat Pesanan Selesai
class OrderReviewSection extends ConsumerStatefulWidget {
  final OrderItem order;
  final HallmarkColorScheme colors;

  const OrderReviewSection({
    super.key,
    required this.order,
    required this.colors,
  });

  @override
  ConsumerState<OrderReviewSection> createState() => _OrderReviewSectionState();
}

class _OrderReviewSectionState extends ConsumerState<OrderReviewSection> {
  int _selectedRating = 0; // Mulai dari 0 (belum ada bintang yang terisi)
  final Set<String> _selectedTags = {}; // Pilihan ulasan cepat opsional
  final TextEditingController _reviewController = TextEditingController();
  bool _isAnonymous = true; // Default anonim aktif sesuai permintaan
  bool _isSubmitting = false;
  OrderReview? _existingReview;
  bool _isLoadingReview = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingReview() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/orders/${widget.order.id}/review');
      if (res.success && res.data != null && mounted) {
        final review = OrderReview.fromJson(Map<String, dynamic>.from(res.data as Map));
        setState(() {
          _existingReview = review;
          _selectedRating = review.rating;
          _selectedTags.clear();
          _selectedTags.addAll(review.tags);
          _reviewController.text = review.reviewText;
          _isAnonymous = review.isAnonymous;
        });
      }
    } catch (_) {
      // Belum ada review
    } finally {
      if (mounted) {
        setState(() => _isLoadingReview = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    // Validasi: Wajib mengisi bintang (1 - 5 bintang)
    if (_selectedRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.star_rounded, color: kStarYellow, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Silakan sentuh bintang untuk memberi penilaian (1 - 5 bintang).',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final body = {
        'rating': _selectedRating,
        'review_text': _reviewController.text.trim(),
        'tags': _selectedTags.toList(),
        'is_anonymous': _isAnonymous,
      };

      final res = await apiClient.post('/orders/${widget.order.id}/review', body: body);
      if (!res.success) {
        throw Exception(res.message ?? 'Gagal mengirim ulasan');
      }

      final reviewData = res.data != null
          ? OrderReview.fromJson(Map<String, dynamic>.from(res.data as Map))
          : OrderReview(
              id: '',
              orderId: widget.order.id,
              studentId: widget.order.studentId,
              rating: _selectedRating,
              reviewText: _reviewController.text.trim(),
              tags: _selectedTags.toList(),
              isAnonymous: _isAnonymous,
              createdAt: DateTime.now(),
            );

      ref.invalidate(siswaActiveOrdersProvider);
      ref.invalidate(publicMenuProvider(null));

      if (mounted) {
        setState(() {
          _existingReview = reviewData;
          _isSubmitting = false;
        });
        AppToast.showSuccess(
          context,
          title: 'Ulasan Terkirim ⭐',
          message: 'Terima kasih atas ulasan dan penilaian Anda!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulasan: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;
    final String studentFullName = profile?['full_name'] ?? widget.order.studentName;
    final String? avatarUrl = profile?['avatar_url'] as String?;

    if (_isLoadingReview) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderTactile, width: 0.8),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    // ─── TAMPILAN JIKA ULASAN SUDAH PERNAH DIKIRIM ───
    if (_existingReview != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ulasan Anda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ulasan Anda',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                _existingReview?.createdAt != null
                    ? AppDateFormatter.formatDate(_existingReview!.createdAt!)
                    : 'Terkirim',
                style: GoogleFonts.inter(fontSize: 11.5, color: colors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Profile info (jika anonim atau nama asli)
          Row(
            children: [
              _buildAvatarWidget(
                isAnonymous: _existingReview!.isAnonymous,
                avatarUrl: avatarUrl,
                name: studentFullName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _existingReview!.isAnonymous ? 'Siswa (Anonim)' : studentFullName,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      _existingReview!.isAnonymous
                          ? 'Nama & foto profil disembunyikan'
                          : 'Ulasan Terverifikasi',
                      style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating Stars (Kuning Hangat)
          Row(
            children: List.generate(5, (index) {
              final bool isFilled = index < _existingReview!.rating;
              return Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? kStarYellow : colors.textMuted.withValues(alpha: 0.3),
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 10),

          // Selected Tags
          if (_existingReview!.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _existingReview!.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                );
              }).toList(),
            ),

          // Review Text
          if (_existingReview!.reviewText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceBase,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderTactile, width: 0.5),
              ),
              child: Text(
                '"${_existingReview!.reviewText}"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // ─── FORMULIR PEMBERIAN RATING & ULASAN BARU ───
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kStarYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rate_rounded, color: kStarYellow, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Beri Penilaian & Ulasan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bagikan pengalaman jajanmu untuk membantu kualitas stan kantin',
          style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
        ),
        const SizedBox(height: 16),

        // Interactive 5 Star Row (Kuning Hangat)
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final int starValue = index + 1;
              final bool isSelected = starValue <= _selectedRating;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRating = starValue);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? kStarYellow : colors.textMuted.withValues(alpha: 0.35),
                      size: 38,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Preset Review Badges / Tags (4 Pure Text Badges)
        Text(
          'Pilih Ulasan Cepat (Opsional):',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kPresetReviewTags.map((tag) {
              final bool isSelected = _selectedTags.contains(tag);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : colors.surfaceBase,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : colors.borderTactile,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF10B981) : colors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Review Text Input
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceBase,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderTactile, width: 0.8),
            ),
            child: TextField(
              controller: _reviewController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 12.5, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tulis ulasan pengalaman jajanmu di sini (opsional)...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Anonymous Mode Toggle with Avatar Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceBase,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderTactile, width: 0.6),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(
                  isAnonymous: _isAnonymous,
                  avatarUrl: avatarUrl,
                  name: studentFullName,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAnonymous ? 'Mode Anonim (Aktif)' : studentFullName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        _isAnonymous
                            ? 'Nama & foto profil akan disembunyikan'
                            : 'Nama & foto profil akan terlihat publik',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.78,
                  child: CupertinoSwitch(
                    value: _isAnonymous,
                    activeTrackColor: Nebula.teal,
                    inactiveTrackColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      setState(() => _isAnonymous = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          HallmarkButton(
            label: 'Kirim Penilaian & Ulasan',
            isLoading: _isSubmitting,
            onPressed: _submitReview,
          ),
        ],
      );
  }

  Widget _buildAvatarWidget({
    required bool isAnonymous,
    required String? avatarUrl,
    required String name,
  }) {
    if (isAnonymous) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.colors.textMuted.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.person_crop_circle_badge_xmark,
          color: widget.colors.textMuted,
          size: 20,
        ),
      );
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (_, __) => const ShimmerRect(
            width: 36,
            height: 36,
            borderRadius: 18,
          ),
          errorWidget: (_, __, ___) => _buildFallbackInitialAvatar(name),
        ),
      );
    }

    return _buildFallbackInitialAvatar(name);
  }

  Widget _buildFallbackInitialAvatar(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.colors.brandPrimary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
