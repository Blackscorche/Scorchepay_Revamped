import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CountryFlag { ng, us, gh, eu, gb }

/// Small hand-drawn flag swatch (simplified geometry, not an image
/// asset) used next to currency balances — avoids pulling in an emoji
/// flag (inconsistent across platforms/fonts) or bundling real flag PNGs.
class FlagChip extends StatelessWidget {
  const FlagChip({super.key, required this.flag, this.width = 26, this.height = 18});

  final CountryFlag flag;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _FlagPainter(flag)),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.flag);
  final CountryFlag flag;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint();

    switch (flag) {
      case CountryFlag.ng:
        paint.color = const Color(0xFF0B8F3A);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(w / 3, 0, w / 3, h), paint);
        break;
      case CountryFlag.us:
        paint.color = const Color(0xFFB22234);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint.color = Colors.white;
        for (final i in [1, 3, 5]) {
          canvas.drawRect(Rect.fromLTWH(0, i * h / 7, w, h / 7), paint);
        }
        paint.color = const Color(0xFF3C3B6E);
        canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.42, h * 0.55), paint);
        break;
      case CountryFlag.gh:
        paint.color = const Color(0xFFCE1126);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 3), paint);
        paint.color = const Color(0xFFFCD116);
        canvas.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3), paint);
        paint.color = const Color(0xFF006B3F);
        canvas.drawRect(Rect.fromLTWH(0, 2 * h / 3, w, h / 3), paint);
        paint.color = Colors.black;
        canvas.drawCircle(Offset(w / 2, h / 2), h * 0.14, paint);
        break;
      case CountryFlag.eu:
        paint.color = const Color(0xFF003399);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint.color = const Color(0xFFFFCC00);
        for (int i = 0; i < 8; i++) {
          final a = (i / 8) * 2 * math.pi;
          final cx = w / 2 + (w * 0.24) * math.sin(a);
          final cy = h / 2 - (h * 0.34) * math.cos(a);
          canvas.drawCircle(Offset(cx, cy), 1.0, paint);
        }
        break;
      case CountryFlag.gb:
        paint.color = const Color(0xFF00247D);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint
          ..color = Colors.white
          ..strokeWidth = 3;
        canvas.drawLine(Offset(0, 0), Offset(w, h), paint);
        canvas.drawLine(Offset(w, 0), Offset(0, h), paint);
        paint
          ..color = const Color(0xFFCF142B)
          ..strokeWidth = 1.3;
        canvas.drawLine(Offset(0, 0), Offset(w, h), paint);
        canvas.drawLine(Offset(w, 0), Offset(0, h), paint);
        paint
          ..color = Colors.white
          ..strokeWidth = 5;
        canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), paint);
        canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
        paint
          ..color = const Color(0xFFCF142B)
          ..strokeWidth = 2.2;
        canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), paint);
        canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) => oldDelegate.flag != flag;
}
