import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class DonutSlice {
  const DonutSlice(this.label, this.pct, this.color);
  final String label;
  final double pct; // 0-100
  final Color color;
}

/// Portfolio-allocation donut: fixed categorical hues (never reassigned
/// by sort order), a 2px surface gap between segments per mark spec, and
/// a center total. Always paired with a legend by the caller — identity
/// here is never color-alone.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, required this.centerLabel, required this.centerValue, this.size = 112});

  final List<DonutSlice> slices;
  final String centerLabel;
  final String centerValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(slices)),
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerValue, style: AppText.detailTitle.copyWith(fontSize: 14)),
                Text(centerLabel.toUpperCase(),
                    style: AppText.eyebrow.copyWith(fontSize: 8.5, letterSpacing: 0.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices);
  final List<DonutSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.115;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const gapRad = 0.045; // ~2px visual gap between segments

    double start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.pct / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final drawSweep = (sweep - gapRad).clamp(0.0, sweep);
      canvas.drawArc(rect, start + gapRad / 2, drawSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.slices != slices;
}
