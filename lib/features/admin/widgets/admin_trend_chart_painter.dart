import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Trend line chart painter for daily volume data.
class TrendChartPainter extends CustomPainter {
  final Color primaryColor;
  final List<num> data;

  TrendChartPainter(this.primaryColor, this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.15),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (data.isEmpty) {
      final path = Path();
      path.moveTo(0, size.height * 0.8);
      path.lineTo(size.width, size.height * 0.8);
      canvas.drawPath(path, linePaint);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
      return;
    }

    final double maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final double minVal = data.reduce((a, b) => a < b ? a : b).toDouble();
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final double stepX = size.width / (data.length - 1 == 0 ? 1 : data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double currentVal = data[i].toDouble();
      final double normalizedY = (currentVal - minVal) / range;
      final double y = size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);
      final double x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.data != data;
  }
}
