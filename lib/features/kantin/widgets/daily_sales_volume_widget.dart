import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';

/// DailySalesVolumeWidget — Kartu Grafik Volume Penjualan Harian Interaktif & Bahasa Indonesia
class DailySalesVolumeWidget extends ConsumerStatefulWidget {
  const DailySalesVolumeWidget({super.key});

  @override
  ConsumerState<DailySalesVolumeWidget> createState() => _DailySalesVolumeWidgetState();
}

class _DailySalesVolumeWidgetState extends ConsumerState<DailySalesVolumeWidget> {
  CanteenSalesFilterParam? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final salesVolumeAsync = ref.watch(canteenSalesVolumeProvider(_activeFilter));

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
        children: [
          // Top Row: Title Section & Interactive Date Range Selector Button
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

          // Second Row: Legend Indicators (Periode Saat Ini vs Periode Sebelumnya)
          _buildLegendSection(context),
          const SizedBox(height: 20),

          // Chart Canvas / Content Section
          salesVolumeAsync.when(
            data: (data) {
              if (data.points.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildChartContent(context, data);
            },
            loading: () => SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.isDark ? Nebula.teal : const Color(0xFF2563EB),
                ),
              ),
            ),
            error: (err, stack) => SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Gagal memuat grafik penjualan: $err',
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
          'Volume Penjualan Harian',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Volume penjualan harian stan kantin Anda',
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
    final String label = _activeFilter?.periodLabel ?? 'Bulan Ini';

    return GestureDetector(
      onTap: _showPeriodFilterModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
              Icons.calendar_month_rounded,
              size: 15,
              color: context.isDark ? Nebula.teal : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
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

  Widget _buildLegendSection(BuildContext context) {
    final primaryColor = context.isDark ? Nebula.teal : const Color(0xFF2563EB);
    final secondaryColor = context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Row(
      children: [
        // Current Period Dot & Label
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Periode Saat Ini',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 16),

        // Previous Period Dot & Label
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: secondaryColor.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Periode Sebelumnya',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          'Belum ada transaksi pada periode terpilih.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildChartContent(BuildContext context, DailySalesVolumeData data) {
    final primaryColor = context.isDark ? Nebula.teal : const Color(0xFF2563EB);
    final secondaryColor = context.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final gridLineColor = context.isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0);

    String formatYLabel(double val) {
      if (val >= 1000000) {
        final m = val / 1000000;
        return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
      }
      if (val >= 1000) {
        final k = val / 1000;
        return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 0)}k';
      }
      return val.toInt().toString();
    }

    final double maxVal = data.maxAmount <= 0 ? 100 : data.maxAmount * 1.15;
    final yLabels = [
      formatYLabel(maxVal),
      formatYLabel(maxVal * 0.75),
      formatYLabel(maxVal * 0.50),
      formatYLabel(maxVal * 0.25),
      '0',
    ];

    // Pick dynamic sample labels for X-axis
    final List<String> xLabels = [];
    final int count = data.points.length;
    if (count <= 7) {
      xLabels.addAll(data.points.map((p) => p.label));
    } else {
      // Pick evenly spaced ticks
      final int step = (count / 6).ceil();
      for (int i = 0; i < count; i += step) {
        xLabels.add(data.points[i].label);
      }
      if (xLabels.length < 6 && data.points.isNotEmpty) {
        xLabels.add(data.points.last.label);
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Row(
            children: [
              // Y-Axis Labels
              SizedBox(
                width: 38,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: yLabels
                      .map(
                        (lbl) => Text(
                          lbl,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),

              // Custom Painter Bezier Canvas
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SalesVolumePainter(
                    data: data,
                    maxVal: maxVal,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    gridLineColor: gridLineColor,
                    isDark: context.isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // X-Axis Day/Month Labels Row
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: xLabels
                .map(
                  (lbl) => Text(
                    lbl,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
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
                'Pilih Rentang Periode Grafik',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sesuaikan tanggal, bulan, atau tahun untuk melihat grafik penjualan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              _buildFilterOptionTile(
                title: 'Bulan Ini',
                subtitle: DateFormat('MMMM yyyy', 'id_ID').format(now),
                isSelected: _activeFilter == null || _activeFilter?.periodLabel == 'Bulan Ini',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeFilter = null; // Default to Bulan Ini
                  });
                },
              ),
              _buildFilterOptionTile(
                title: 'Bulan Lalu',
                subtitle: DateFormat('MMMM yyyy', 'id_ID').format(DateTime(now.year, now.month - 1, 1)),
                isSelected: _activeFilter?.periodLabel == 'Bulan Lalu',
                onTap: () {
                  Navigator.pop(ctx);
                  final prevStart = DateTime(now.year, now.month - 1, 1);
                  final prevEnd = DateTime(now.year, now.month, 0);
                  setState(() {
                    _activeFilter = CanteenSalesFilterParam(
                      startDate: prevStart,
                      endDate: prevEnd,
                      periodLabel: 'Bulan Lalu',
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
                title: '30 Hari Terakhir',
                subtitle: '${DateFormat('dd MMM', 'id_ID').format(now.subtract(const Duration(days: 29)))} - ${DateFormat('dd MMM yyyy', 'id_ID').format(now)}',
                isSelected: _activeFilter?.periodLabel == '30 Hari Terakhir',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeFilter = CanteenSalesFilterParam(
                      startDate: now.subtract(const Duration(days: 29)),
                      endDate: now,
                      periodLabel: '30 Hari Terakhir',
                    );
                  });
                },
              ),
              _buildFilterOptionTile(
                title: 'Tahun Ini (${now.year})',
                subtitle: '01 Jan ${now.year} - 31 Des ${now.year}',
                isSelected: _activeFilter?.periodLabel == 'Tahun Ini',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeFilter = CanteenSalesFilterParam(
                      startDate: DateTime(now.year, 1, 1),
                      endDate: DateTime(now.year, 12, 31),
                      periodLabel: 'Tahun Ini',
                    );
                  });
                },
              ),
              const Divider(height: 20),

              // Custom Date Range Picker Call
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                leading: Icon(
                  Icons.edit_calendar_rounded,
                  color: context.isDark ? Nebula.teal : const Color(0xFF2563EB),
                ),
                title: Text(
                  'Pilih Rentang Tanggal (Kustom)...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Atur tanggal, bulan, dan tahun secara bebas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: DateTimeRange(
                      start: _activeFilter?.startDate ?? DateTime(now.year, now.month, 1),
                      end: _activeFilter?.endDate ?? DateTime(now.year, now.month + 1, 0),
                    ),
                    locale: const Locale('id', 'ID'),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: context.isDark
                              ? ColorScheme.dark(
                                  primary: Nebula.teal,
                                  onPrimary: Colors.white,
                                  surface: const Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                )
                              : const ColorScheme.light(
                                  primary: Color(0xFF2563EB),
                                  onPrimary: Colors.white,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    final String fmtLabel =
                        '${DateFormat('dd MMM yy', 'id_ID').format(picked.start)} - ${DateFormat('dd MMM yy', 'id_ID').format(picked.end)}';
                    setState(() {
                      _activeFilter = CanteenSalesFilterParam(
                        startDate: picked.start,
                        endDate: picked.end,
                        periodLabel: fmtLabel,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
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
    final activeColor = context.isDark ? Nebula.teal : const Color(0xFF2563EB);

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? activeColor : context.textSecondary,
        size: 20,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: context.isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _SalesVolumePainter extends CustomPainter {
  final DailySalesVolumeData data;
  final double maxVal;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridLineColor;
  final bool isDark;

  _SalesVolumePainter({
    required this.data,
    required this.maxVal,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridLineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.points.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1.0;

    // Draw 5 Horizontal Grid lines
    final double stepY = size.height / 4;
    for (int i = 0; i <= 4; i++) {
      final y = i * stepY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final int pointCount = data.points.length;
    if (pointCount < 2) return;

    final double dx = size.width / (pointCount - 1);

    // Compute pixel offsets for current and previous series
    final List<Offset> currentOffsets = [];
    final List<Offset> prevOffsets = [];

    for (int i = 0; i < pointCount; i++) {
      final p = data.points[i];
      final double x = i * dx;

      final double currentY = size.height - ((p.currentAmount / maxVal) * size.height).clamp(0.0, size.height);
      final double prevY = size.height - ((p.previousAmount / maxVal) * size.height).clamp(0.0, size.height);

      currentOffsets.add(Offset(x, currentY));
      prevOffsets.add(Offset(x, prevY));
    }

    // Generate Smooth Bezier Paths
    final Path currentPath = _createSmoothPath(currentOffsets);
    final Path prevPath = _createSmoothPath(prevOffsets);

    // 1. Draw Previous Period Series (Dashed Line)
    final Path dashedPrevPath = _createDashedPath(prevPath);
    final prevPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(dashedPrevPath, prevPaint);

    // 2. Draw Current Period Area Fill (Gradient)
    final Path fillPath = Path.from(currentPath);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.35 : 0.28),
          primaryColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // 3. Draw Current Period Solid Line
    final currentPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(currentPath, currentPaint);
  }

  Path _createSmoothPath(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final controlX = p0.dx + (p1.dx - p0.dx) / 2;
      path.cubicTo(
        controlX, p0.dy,
        controlX, p1.dy,
        p1.dx, p1.dy,
      );
    }
    return path;
  }

  Path _createDashedPath(Path source) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      const double dashWidth = 6.0;
      const double dashSpace = 4.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : dashSpace;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, (distance + len).clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _SalesVolumePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
