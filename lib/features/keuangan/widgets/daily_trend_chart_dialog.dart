import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

/// Dialog Modal Grafik Tren Transaksi Realtime Sesuai Periode Yang Dipilih
class DailyTrendChartDialog extends ConsumerStatefulWidget {
  final ReportFilterParam? filterParam;

  const DailyTrendChartDialog({super.key, this.filterParam});

  @override
  ConsumerState<DailyTrendChartDialog> createState() => _DailyTrendChartDialogState();
}

class _DailyTrendChartDialogState extends ConsumerState<DailyTrendChartDialog> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final trendAsync = ref.watch(dailyTrendChartProvider);

    final periodTitle = widget.filterParam != null ? widget.filterParam!.formattedPeriodLabel : 'Harian';

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title, Subtitle, Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Tren Transaksi',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Nebula.teal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Nebula.teal.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Nebula.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'REALTIME',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Nebula.teal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visualisasi tren transaksi periode $periodTitle.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: context.textSecondary, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Realtime Interactive Chart Box
            trendAsync.when(
              loading: () => SizedBox(
                height: 240,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Nebula.teal, strokeWidth: 2.5),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat data grafik periode $periodTitle...',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, _) => SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    'Gagal memuat tren transaksi realtime.',
                    style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                  ),
                ),
              ),
              data: (chartData) {
                final points = chartData.points;
                final defaultIdx = (points.length - 1).clamp(0, points.length - 1);
                final selectedIdx = _selectedIndex ?? defaultIdx;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 240,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              GestureDetector(
                                onTapDown: (details) {
                                  final width = constraints.maxWidth;
                                  const leftPadding = 44.0;
                                  const rightPadding = 16.0;
                                  final chartWidth = width - leftPadding - rightPadding;
                                  final stepX = points.length > 1 ? chartWidth / (points.length - 1) : 0.0;

                                  final touchX = details.localPosition.dx - leftPadding;
                                  int closestIdx = stepX > 0 ? (touchX / stepX).round().clamp(0, points.length - 1).toInt() : 0;
                                  setState(() {
                                    _selectedIndex = closestIdx;
                                  });
                                },
                                child: CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: _DailyTrendChartPainter(
                                    data: points,
                                    selectedIndex: selectedIdx,
                                    gridColor: context.dividerCol,
                                    textColor: context.textSecondary,
                                    activeColor: Nebula.teal,
                                    maxAmount: chartData.maxAmount,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bottom Summary Text (Matching Realtime stats for selected period)
                    Text(
                      'Rata-rata transaksi harian: ${currencyFmt.format(chartData.averageAmount.round())}. '
                      '${chartData.percentageChange >= 0 ? "Tren meningkat ${chartData.percentageChange.toStringAsFixed(0)}% dari periode sebelumnya." : "Tren menurun ${chartData.percentageChange.abs().toStringAsFixed(0)}% dari periode sebelumnya."}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar Grafik Kurva Smooth Bezier Realtime Periode Terpilih
class _DailyTrendChartPainter extends CustomPainter {
  final List<DailyTrendPoint> data;
  final int selectedIndex;
  final Color gridColor;
  final Color textColor;
  final Color activeColor;
  final double maxAmount;

  _DailyTrendChartPainter({
    required this.data,
    required this.selectedIndex,
    required this.gridColor,
    required this.textColor,
    required this.activeColor,
    required this.maxAmount,
  });

  String _formatShortVal(double amount) {
    if (amount >= 1000000000) {
      final val = amount / 1000000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}B';
    } else if (amount >= 1000000) {
      final val = amount / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}k';
    } else if (amount == 0) {
      return '0';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 44.0;
    const double rightPadding = 16.0;
    const double topPadding = 44.0;
    const double bottomPadding = 28.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final double maxY = maxAmount > 0 ? maxAmount : 2500000.0;
    final List<double> yLevels = [maxY, maxY * 0.8, maxY * 0.6, maxY * 0.4, maxY * 0.2, 0.0];
    final List<String> yLabels = yLevels.map((v) => _formatShortVal(v)).toList();

    // 1. Draw Gridlines & Y-Axis Labels
    final textStyleY = GoogleFonts.inter(
      fontSize: 10,
      color: textColor.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
    );

    final linePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (int i = 0; i < yLevels.length; i++) {
      final yRatio = (yLevels[i] / maxY).clamp(0.0, 1.0);
      final yPos = topPadding + (1 - yRatio) * chartHeight;

      // Draw horizontal line
      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        linePaint,
      );

      // Draw Y label
      final textSpan = TextSpan(text: yLabels[i], style: textStyleY);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, yPos - textPainter.height / 2),
      );
    }

    // Compute X and Y positions for data points
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;
    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final xPos = leftPadding + i * stepX;
      final yRatio = (data[i].amount / maxY).clamp(0.0, 1.0);
      final yPos = topPadding + (1 - yRatio) * chartHeight;
      points.add(Offset(xPos, yPos));
    }

    // 2. Build Smooth Cubic Bezier Path
    final Path linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);

    if (points.length == 1) {
      linePath.lineTo(points[0].dx, points[0].dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }
    }

    // 3. Draw Gradient Fill under line
    final Path fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, topPadding + chartHeight);
    fillPath.lineTo(points.first.dx, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topPadding),
        Offset(0, topPadding + chartHeight),
        [
          activeColor.withValues(alpha: 0.28),
          activeColor.withValues(alpha: 0.02),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Line Stroke
    final pathPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, pathPaint);

    // 5. Draw X-Axis Day Labels (Intelligently skip overlap for long ranges)
    final textStyleX = GoogleFonts.inter(
      fontSize: 10.5,
      color: textColor,
      fontWeight: FontWeight.w500,
    );

    int labelStep = 1;
    if (data.length > 20) {
      labelStep = 4;
    } else if (data.length > 10) {
      labelStep = 2;
    }

    for (int i = 0; i < data.length; i++) {
      if (i % labelStep != 0 && i != data.length - 1) continue;

      final textSpan = TextSpan(text: data[i].dayLabel, style: textStyleX);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    // 6. Draw Dots and Data Value Text Above Dots
    final dotOuterPaint = Paint()..color = activeColor;
    final dotInnerPaint = Paint()..color = Colors.white;

    final valueStyle = GoogleFonts.inter(
      fontSize: 10.5,
      color: textColor,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = i == selectedIndex;

      if (isSelected) {
        // Selected Dot glow & ring
        canvas.drawCircle(pt, 7.5, dotOuterPaint);
        canvas.drawCircle(pt, 4.0, dotInnerPaint);
      } else {
        // Normal Dot
        canvas.drawCircle(pt, 4.5, dotOuterPaint);
        canvas.drawCircle(pt, 2.0, dotInnerPaint);

        // Draw short text above dot if points <= 15
        if (data.length <= 15) {
          final textSpan = TextSpan(text: data[i].displayShort, style: valueStyle);
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: ui.TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(pt.dx - textPainter.width / 2, pt.dy - 18),
          );
        }
      }
    }

    // 7. Draw Active Floating Tooltip Pill
    if (selectedIndex >= 0 && selectedIndex < data.length) {
      final pt = points[selectedIndex];
      final item = data[selectedIndex];
      final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final tooltipText = '${item.fullDayName}: ${currencyFmt.format(item.amount.round())}';

      final tooltipStyle = GoogleFonts.inter(
        fontSize: 11.5,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(text: tooltipText, style: tooltipStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      const horizontalPadding = 12.0;
      const verticalPadding = 6.0;
      final tooltipWidth = textPainter.width + horizontalPadding * 2;
      final tooltipHeight = textPainter.height + verticalPadding * 2;

      final tooltipCenter = pt.dx.clamp(leftPadding + tooltipWidth / 2, size.width - rightPadding - tooltipWidth / 2);
      final tooltipTop = (pt.dy - tooltipHeight - 10).clamp(0.0, size.height);
      final RRect tooltipRRect = RRect.fromLTRBR(
        tooltipCenter - tooltipWidth / 2,
        tooltipTop,
        tooltipCenter + tooltipWidth / 2,
        tooltipTop + tooltipHeight,
        const Radius.circular(8),
      );

      final tooltipBgPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(tooltipRRect, tooltipBgPaint);

      final trianglePath = Path()
        ..moveTo(pt.dx - 5, tooltipTop + tooltipHeight)
        ..lineTo(pt.dx + 5, tooltipTop + tooltipHeight)
        ..lineTo(pt.dx, tooltipTop + tooltipHeight + 5)
        ..close();
      canvas.drawPath(trianglePath, tooltipBgPaint);

      textPainter.paint(
        canvas,
        Offset(tooltipCenter - textPainter.width / 2, tooltipTop + verticalPadding),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DailyTrendChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.data != data;
  }
}
