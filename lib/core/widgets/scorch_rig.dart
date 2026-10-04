import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'scorch_activity.dart';

/// Continuous joint motion, evaluated at the display's refresh rate.
/// Every channel is periodic, including its velocity at the loop boundary.
class ScorchPose {
  ScorchPose(double progress, this.activity) : phase = progress * math.pi * 2;
  final double phase;
  final ScorchActivity activity;
  double get breath => math.sin(phase);
  double get lift => (1 - math.cos(phase)) / 2;
  double get blink => 1 - .96 * math.pow((1 + math.cos(phase - 4.5)) / 2, 80);
  double get wave => math.sin(phase * 3) * .3;
  double get flame => math.sin(phase + .4) * 5;
  bool get holdsWallet => const {
        ScorchActivity.wallet,
        ScorchActivity.pay,
        ScorchActivity.crypto,
        ScorchActivity.save,
        ScorchActivity.processing
      }.contains(activity);
  Offset get rightHand => holdsWallet
      ? Offset(128 + lift * 14, 144 - lift * 40)
      : activity == ScorchActivity.protect
          ? Offset(137, 140 - lift * 7)
          : activity == ScorchActivity.celebrate
              ? Offset(155, 114 - lift * 40)
              : Offset(
                  158 + math.sin(phase * 3) * 5, 89 + math.cos(phase * 3) * 4);
}

class ScorchRig extends StatelessWidget {
  const ScorchRig(
      {super.key,
      required this.progress,
      required this.activity,
      required this.size});
  final Animation<double> progress;
  final ScorchActivity activity;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: ScorchRigPainter(progress, activity)));
}

class ScorchRigPainter extends CustomPainter {
  ScorchRigPainter(this.progress, this.activity) : super(repaint: progress);
  final Animation<double> progress;
  final ScorchActivity activity;
  static const orange = Color(0xFFFF731C);
  static const gold = Color(0xFFFFD76A);
  static const red = Color(0xFFF1481F);
  static const ink = Color(0xFF342025);

  Paint gradient(Rect rect, List<Color> colors,
          {Alignment begin = Alignment.topLeft,
          Alignment end = Alignment.bottomRight}) =>
      Paint()
        ..shader = LinearGradient(begin: begin, end: end, colors: colors)
            .createShader(rect);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    final pose = ScorchPose(progress.value, activity);
    final jump = activity == ScorchActivity.celebrate ? pose.lift * 18 : 0.0;
    canvas.translate(0, -jump + pose.breath * 1.4);
    // Separate ankle and shoulder joints move independently of the torso.
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(100 + side * 21, 169);
      canvas.rotate(side *
          (.09 +
              (activity == ScorchActivity.celebrate
                  ? pose.lift * .42
                  : pose.breath * .025)));
      final foot =
          Rect.fromCenter(center: Offset(side * 3, 6), width: 29, height: 20);
      canvas.drawOval(foot, gradient(foot, [gold, orange, red]));
      canvas.restore();
    }
    final leftHand = pose.holdsWallet
        ? const Offset(81, 147)
        : activity == ScorchActivity.protect
            ? Offset(71, 140 - pose.lift * 7)
            : activity == ScorchActivity.celebrate
                ? Offset(43, 114 - pose.lift * 40)
                : Offset(46, 140 + pose.breath * 2);
    _arm(canvas, const Offset(66, 119), leftHand, -1);
    _arm(canvas, const Offset(136, 117), pose.rightHand, 1);

    // Stable silhouette: only the flame control points flex, never swap images.
    final body = Path()
      ..moveTo(101, 169)
      ..cubicTo(60, 173, 43, 149, 48, 118)
      ..cubicTo(50, 103, 57, 95, 53, 78)
      ..cubicTo(65, 81, 69, 89, 69, 93)
      ..cubicTo(60, 60, 112 + pose.flame, 45, 85 + pose.flame, 16)
      ..cubicTo(119 + pose.flame, 22, 142, 57, 130, 85)
      ..cubicTo(141, 78, 143, 70, 141, 65)
      ..cubicTo(162, 85, 156, 108, 151, 119)
      ..cubicTo(158, 149, 139, 171, 101, 169)
      ..close();
    const bounds = Rect.fromLTWH(44, 16, 117, 156);
    canvas.drawPath(
        body, gradient(bounds, [gold, const Color(0xFFFFA937), orange, red]));
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
        const Rect.fromLTWH(49, 46, 99, 99),
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: .35),
            Colors.white.withValues(alpha: 0)
          ]).createShader(const Rect.fromLTWH(49, 46, 99, 99)));
    final flameLight = Path()
      ..moveTo(96 + pose.flame, 25)
      ..cubicTo(134, 60, 95, 69, 89, 93)
      ..cubicTo(108, 77, 127, 71, 127, 57)
      ..cubicTo(123, 42, 111, 32, 96 + pose.flame, 25);
    canvas.drawPath(flameLight,
        Paint()..color = const Color(0xFFFFEBA2).withValues(alpha: .45));
    canvas.restore();

    final gaze = activity == ScorchActivity.protect
        ? math.sin(pose.phase) * 2
        : pose.holdsWallet
            ? pose.lift * 1.5
            : 0.0;
    _eye(canvas, Offset(80, 111), pose.blink, gaze);
    _eye(canvas, Offset(121, 108), pose.blink, gaze);
    final brow = Paint()
      ..color = ink.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(72, 95)
          ..quadraticBezierTo(79, 90, 86, 94),
        brow);
    canvas.drawPath(
        Path()
          ..moveTo(115, 91)
          ..quadraticBezierTo(122, 87, 129, 92),
        brow);
    for (final cheek in [const Offset(67, 128), const Offset(137, 125)]) {
      final rect = Rect.fromCenter(center: cheek, width: 23, height: 13);
      canvas.drawOval(
          rect,
          Paint()
            ..shader = RadialGradient(colors: [
              red.withValues(alpha: .65),
              red.withValues(alpha: 0)
            ]).createShader(rect));
    }
    final smile = Path()
      ..moveTo(86, 130)
      ..quadraticBezierTo(102, 138, 117, 125)
      ..cubicTo(115, 151, 92, 150, 86, 130)
      ..close();
    canvas.drawPath(smile, Paint()..color = ink);
    canvas.save();
    canvas.clipPath(smile);
    canvas.drawOval(const Rect.fromLTWH(94, 139, 20, 12),
        Paint()..color = const Color(0xFFFF8874));
    canvas.restore();

    if (pose.holdsWallet) {
      _coin(canvas, pose.rightHand + const Offset(-3, 9), pose.phase);
      _wallet(canvas);
      _hand(canvas, leftHand, -.2);
      _hand(canvas, pose.rightHand, .25 - pose.lift * .2);
    } else if (activity == ScorchActivity.protect) {
      canvas.save();
      canvas.translate(0, -pose.lift * 7);
      _shield(canvas);
      canvas.restore();
      _hand(canvas, leftHand, -.2);
      _hand(canvas, pose.rightHand, .2);
    } else {
      _hand(canvas, leftHand, -pose.wave * .4);
      _hand(canvas, pose.rightHand, pose.wave);
    }
    canvas.restore();
  }

  void _arm(Canvas c, Offset shoulder, Offset hand, double side) {
    final bend = Offset((shoulder.dx + hand.dx) / 2 + side * 5,
        (shoulder.dy + hand.dy) / 2 + 7);
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(bend.dx, bend.dy, hand.dx, hand.dy);
    c.drawPath(
        path,
        Paint()
          ..color = red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round);
    c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(colors: [gold, orange])
              .createShader(Rect.fromPoints(shoulder, hand).inflate(10))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round);
  }

  void _hand(Canvas c, Offset point, double angle) {
    c.save();
    c.translate(point.dx, point.dy);
    c.rotate(angle);
    const rect = Rect.fromLTWH(-10, -10, 20, 20);
    c.drawOval(rect, gradient(rect, [gold, orange, red]));
    for (var i = 0; i < 3; i++) {
      final finger = Rect.fromLTWH(-8 + i * 5, -13 - (i == 1 ? 2 : 0), 7, 13);
      c.drawRRect(RRect.fromRectAndRadius(finger, const Radius.circular(4)),
          gradient(finger, [gold, orange]));
    }
    c.restore();
  }

  void _eye(Canvas c, Offset center, double openness, double gaze) {
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(1, openness);
    const rect = Rect.fromLTWH(-9, -12, 18, 24);
    c.drawOval(
        rect,
        gradient(
            rect, [const Color(0xFF653329), ink, const Color(0xFF171216)]));
    c.drawOval(
        Rect.fromCenter(center: Offset(-2 + gaze, -5), width: 6, height: 8),
        Paint()..color = const Color(0xFFFFFAE8));
    c.drawCircle(Offset(4 + gaze, 5), 1.7,
        Paint()..color = Colors.white.withValues(alpha: .35));
    c.restore();
  }

  void _coin(Canvas c, Offset point, double phase) {
    c.save();
    c.translate(point.dx, point.dy);
    c.rotate(math.sin(phase) * .13);
    const rect = Rect.fromLTWH(-10, -12, 20, 24);
    c.drawOval(rect, gradient(rect, [const Color(0xFFFFF5B2), gold, orange]));
    c.drawOval(
        rect.deflate(3),
        Paint()
          ..color = const Color(0xFFFFF2A2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    c.drawLine(
        const Offset(0, -5),
        const Offset(0, 5),
        Paint()
          ..color = orange
          ..strokeWidth = 2);
    c.restore();
  }

  void _wallet(Canvas c) {
    const rect = Rect.fromLTWH(86, 142, 53, 30);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        gradient(rect, [const Color(0xFF514044), const Color(0xFF231F25)]));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(89, 139, 48, 8), const Radius.circular(4)),
        Paint()..color = const Color(0xFF18141B));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(121, 151, 21, 13), const Radius.circular(5)),
        Paint()..color = const Color(0xFF68504D));
    c.drawCircle(const Offset(132, 157), 3, Paint()..color = gold);
  }

  void _shield(Canvas c) {
    final path = Path()
      ..moveTo(101, 126)
      ..lineTo(134, 137)
      ..quadraticBezierTo(134, 164, 101, 182)
      ..quadraticBezierTo(68, 164, 68, 137)
      ..close();
    c.drawPath(
        path, gradient(const Rect.fromLTWH(68, 126, 66, 56), [gold, orange]));
    c.save();
    c.translate(101, 154);
    c.scale(.86);
    c.translate(-101, -154);
    c.drawPath(
        path,
        gradient(const Rect.fromLTWH(68, 126, 66, 56),
            [const Color(0xFF594044), const Color(0xFF28212B)]));
    c.restore();
    c.drawPath(
        Path()
          ..moveTo(87, 152)
          ..lineTo(97, 162)
          ..lineTo(116, 143),
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(ScorchRigPainter oldDelegate) =>
      activity != oldDelegate.activity || progress != oldDelegate.progress;
}
