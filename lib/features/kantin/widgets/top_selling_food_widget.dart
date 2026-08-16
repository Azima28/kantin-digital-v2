import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

/// TopSellingFoodWidget — Widget Kartu Donat "Distribusi Makanan Terlaris"
/// Menampilkan statistik menu makanan yang paling banyak dibeli pada hari itu atau hari sebelumnya.
class TopSellingFoodWidget extends ConsumerStatefulWidget {
  const TopSellingFoodWidget({super.key});

  @override
  ConsumerState<TopSellingFoodWidget> createState() => _TopSellingFoodWidgetState();
}

class _TopSellingFoodWidgetState extends ConsumerState<TopSellingFoodWidget> {
  CanteenSalesFilterParam? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final foodDataAsync = ref.watch(topSellingFoodProvider(_activeFilter));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Title & Interactive Date Filter Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTitleSection(context)),
              const SizedBox(width: 8),
              _buildFilterPickerButton(context),
            ],
          ),
          const SizedBox(height: 16),

          // Donut Chart & Legend Content
          SizedBox(
            height: 320,
            child: foodDataAsync.when(
              data: (data) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Center Donut Chart with Square Badge
                    _buildDonutChartSection(context, data),
                    const SizedBox(height: 16),

                    // Legend Breakdown List
                    _buildLegendListSection(context, data),
                  ],
                );
              },
              loading: () => Shimmer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SkeletonCircle(size: 130),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: const [
                              SkeletonCircle(size: 10),
                              SizedBox(width: 8),
                              SkeletonBox(width: 100, height: 12, borderRadius: 4),
                              Spacer(),
                              SkeletonBox(width: 40, height: 12, borderRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Gagal memuat grafik makanan: $err',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Makanan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Menu makanan paling banyak dibeli',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPickerButton(BuildContext context) {
    final String label = _activeFilter?.periodLabel ?? 'Hari Ini';

    return GestureDetector(
      onTap: _showPeriodFilterModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: context.isDark ? Nebula.teal : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChartSection(BuildContext context, FoodSalesDistributionData data) {
    return Center(
      child: SizedBox(
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Custom Painted Donut Ring
            CustomPaint(
              size: const Size(170, 170),
              painter: _DonutChartPainter(
                items: data.items,
                isDark: context.isDark,
              ),
            ),

            // Center Badge Box (Matches reference design)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.topCount > 0 ? '${data.topCount}' : '0',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top Makanan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendListSection(BuildContext context, FoodSalesDistributionData data) {
    if (data.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Belum ada transaksi makanan pada periode terpilih.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: context.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: data.items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              // Color indicator box
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),

              // Item Name
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Percentage & Quantity label
              Text(
                '${item.percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showPeriodFilterModal() {
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Filter Tanggal Makanan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lihat distribusi makanan terlaris pada hari itu atau hari sebelumnya',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              _buildFilterOptionTile(
                title: 'Hari Ini',
                subtitle: DateFormat('dd MMMM yyyy', 'id_ID').format(now),
                isSelected: _activeFilter == null || _activeFilter?.periodLabel == 'Hari Ini',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeFilter = null; // Default to Hari Ini
                  });
                },
              ),
              _buildFilterOptionTile(
                title: 'Kemarin',
                subtitle: DateFormat('dd MMMM yyyy', 'id_ID').format(now.subtract(const Duration(days: 1))),
                isSelected: _activeFilter?.periodLabel == 'Kemarin',
                onTap: () {
                  Navigator.pop(ctx);
                  final yesterday = now.subtract(const Duration(days: 1));
                  setState(() {
                    _activeFilter = CanteenSalesFilterParam(
                      startDate: yesterday,
                      endDate: yesterday,
                      periodLabel: 'Kemarin',
                    );
                  });
                },
              ),
              _buildFilterOptionTile(
                title: '7 Hari Terakhir',
                subtitle: '${DateFormat('dd MMM', 'id_ID').format(now.subtract(const Duration(days: 6)))} - ${DateFormat('dd MMM yyyy', 'id_ID').format(now)}',
                isSelected: _activeFilter?.periodLabel == '7 Hari Terakhir',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeFilter = CanteenSalesFilterParam(
                      startDate: now.subtract(const Duration(days: 6)),
                      endDate: now,
                      periodLabel: '7 Hari Terakhir',
                    );
                  });
                },
              ),
              _buildFilterOptionTile(
                title: 'Bulan Ini',
                subtitle: DateFormat('MMMM yyyy', 'id_ID').format(now),
                isSelected: _activeFilter?.periodLabel == 'Bulan Ini',
                onTap: () {
                  Navigator.pop(ctx);
                  final start = DateTime(now.year, now.month, 1);
                  final end = DateTime(now.year, now.month + 1, 0);
                  setState(() {
                    _activeFilter = CanteenSalesFilterParam(
                      startDate: start,
                      endDate: end,
                      periodLabel: 'Bulan Ini',
                    );
                  });
                },
              ),
              _buildFilterOptionTile(
                title: 'Pilih Tanggal Khusus...',
                subtitle: _activeFilter?.periodLabel.startsWith('Tgl:') == true
                    ? _activeFilter!.periodLabel
                    : 'Pilih tanggal hari sebelum-sebelumnya',
                isSelected: _activeFilter?.periodLabel.startsWith('Tgl:') == true,
                onTap: () async {
                  Navigator.pop(ctx);
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _activeFilter?.startDate ?? now,
                    firstDate: DateTime(2025, 1, 1),
                    lastDate: now,
                  );
                  if (pickedDate != null) {
                    final labelStr = DateFormat('dd MMM yyyy', 'id_ID').format(pickedDate);
                    setState(() {
                      _activeFilter = CanteenSalesFilterParam(
                        startDate: pickedDate,
                        endDate: pickedDate,
                        periodLabel: labelStr,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (context.isDark ? Nebula.teal.withValues(alpha: 0.15) : const Color(0xFFEFF6FF))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (context.isDark ? Nebula.teal : const Color(0xFF3B82F6))
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? (context.isDark ? Colors.white : const Color(0xFF1E40AF))
                              : (context.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.isDark ? Nebula.teal : const Color(0xFF2563EB),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// _DonutChartPainter — Custom painter for drawing rounded Donut Arcs
class _DonutChartPainter extends CustomPainter {
  final List<FoodSalesDistributionItem> items;
  final bool isDark;

  _DonutChartPainter({
    required this.items,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 26.0;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFE2E8F0);

    // If no items, draw neutral base ring
    if (items.isEmpty) {
      canvas.drawCircle(center, radius - (strokeWidth / 2), basePaint);
      return;
    }

    double startAngle = -math.pi / 2; // Start from top
    const gapAngle = 0.05; // Gap between arcs in radians

    final double totalPercentage = items.fold(0.0, (sum, item) => sum + item.percentage);

    for (var item in items) {
      final sweepPercentage = totalPercentage > 0 ? (item.percentage / totalPercentage) : 0.0;
      final sweepAngle = (sweepPercentage * 2 * math.pi) - gapAngle;

      if (sweepAngle > 0) {
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = item.color;

        final rect = Rect.fromCircle(
          center: center,
          radius: radius - (strokeWidth / 2),
        );

        canvas.drawArc(rect, startAngle + (gapAngle / 2), sweepAngle, false, arcPaint);
      }

      startAngle += (sweepPercentage * 2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.isDark != isDark;
  }
}
