import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// The balance/portfolio trend chart. Single-series sequential blue line
/// (never the brand accent — keeps "our color" and "chart data" visually
/// distinct), soft area fill, faint recessive gridlines, rounded
/// data-end dot. Axis labels are rendered separately by the caller so
/// this stays a pure plot.
class WealthLineChart extends StatelessWidget {
  const WealthLineChart({super.key, required this.points, this.height = 76, this.color = AppColors.info});

  final List<double> points;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LineChartPainter(points, color)),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.points, this.color);
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final minV = points.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final stepX = size.width / (points.length - 1);
    const topInset = 4.0, bottomInset = 4.0;
    final plotH = size.height - topInset - bottomInset;

    Offset coord(int i) {
      final x = i * stepX;
      final y = size.height - bottomInset - ((points[i] - minV) / range) * plotH;
      return Offset(x, y);
    }

    // Recessive gridlines at 25/50/75%
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(coord(0).dx, coord(0).dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(coord(i).dx, coord(i).dy);
    }

    // Area fill
    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.28), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // End dot
    final end = coord(points.length - 1);
    canvas.drawCircle(end, 5, Paint()..color = const Color(0xFF101012));
    canvas.drawCircle(end, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
