import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'scorch_activity.dart';
import 'scorch_character.dart';
export 'scorch_activity.dart';

/// Scorch's small motion scenes share a single clock and never capture input.
/// Props communicate the task; motion stops for accessibility and hidden routes.
class ScorchMascot extends StatefulWidget {
  const ScorchMascot(
      {super.key,
      this.activity = ScorchActivity.welcome,
      this.size = 160,
      this.animate = true, this.grounded = false});
  final ScorchActivity activity;
  final double size;
  final bool animate;
  final bool grounded;

  static String assetFor(ScorchActivity activity) => switch (activity) {
        ScorchActivity.protect => 'assets/scorch_protect.png',
        ScorchActivity.celebrate => 'assets/scorch_celebrate.png',
        ScorchActivity.wallet ||
        ScorchActivity.pay ||
        ScorchActivity.crypto ||
        ScorchActivity.save ||
        ScorchActivity.processing =>
          'assets/scorch_wallet.png',
        _ => 'assets/scorch_mascot.png',
      };

  static ScorchActivity activityFor(String title) {
    final value = title.toLowerCase();
    if (RegExp('escrow|pin|security|verif|dispute').hasMatch(value)) {
      return ScorchActivity.protect;
    }
    if (RegExp('sav|goal|group').hasMatch(value)) {
      return ScorchActivity.save;
    }
    if (RegExp('crypto|coin|swap|trade|p2p').hasMatch(value)) {
      return ScorchActivity.crypto;
    }
    if (RegExp('pay|send|bill|airtime|data|transfer|gift').hasMatch(value)) {
      return ScorchActivity.pay;
    }
    if (RegExp('wallet|deposit|balance|receive').hasMatch(value)) {
      return ScorchActivity.wallet;
    }
    return ScorchActivity.explore;
  }

  @override
  State<ScorchMascot> createState() => _ScorchMascotState();
}

class _ScorchMascotState extends State<ScorchMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(ScorchMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity != widget.activity) _clock.value = 0;
    _syncMotion();
  }

  void _syncMotion() {
    final enabled = widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        widget.activity != ScorchActivity.rest;
    if (enabled && !_clock.isAnimating) {
      _clock.repeat();
    }
    if (!enabled) {
      _clock.stop();
      _clock.value = 0;
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: SizedBox.square(
                dimension: widget.size,
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, child) {
                    final t = _clock.value;
                    final wave = math.sin(t * math.pi * 2);
                    return Stack(alignment: Alignment.center, children: [
                      if (!widget.grounded) Positioned.fill(
                          child: CustomPaint(
                              painter: _ScorchScene(
                                  widget.activity, t, AppColors.accent))),
                      if (!widget.grounded) Positioned(
                          bottom: widget.size * .08,
                          child: Transform.scale(
                            scaleX: 1 - wave * .08,
                            child: Container(
                                width: widget.size * .4,
                                height: widget.size * .035,
                                decoration: BoxDecoration(
                                    color:
                                        AppColors.accent.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(100))),
                          )),
                      Transform.translate(
                        key: const ValueKey('scorch-motion'),
                        offset: Offset(
                            0,
                            -(widget.grounded ? 0 : widget.size) *
                                (widget.activity == ScorchActivity.celebrate
                                    ? .045
                                    : .018) *
                                (1 - math.cos(t * math.pi * 2))),
                        child: Transform.rotate(
                          angle: wave * .04,
                          child: Transform.scale(
                              scale: 1 + wave * .035, child: child),
                        ),
                      ),
                    ]);
                  },
                  child: ScorchCharacter(
                    asset: ScorchMascot.assetFor(widget.activity),
                    activity: widget.activity,
                    progress: _clock,
                    size: widget.size * .94,
                  ),
                )),
          ),
        ),
      );
}

class _ScorchScene extends CustomPainter {
  _ScorchScene(this.activity, this.t, this.color);
  final ScorchActivity activity;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s * .5, s * .5);
    canvas.drawCircle(
        center,
        s * .43,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: .13),
            color.withValues(alpha: 0)
          ]).createShader(Offset.zero & size));
    final line = Paint()
      ..color = color.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final orbit =
        Rect.fromCenter(center: center, width: s * .88, height: s * .48);
    if (activity == ScorchActivity.crypto) {
      // Separate crypto scene: recognizable asset tokens travel around Scorch.
      // The ellipse stays outside the face and the original coin-hand gesture.
      canvas.drawOval(
          Rect.fromCenter(center: center, width: s * .88, height: s * .7),
          line);
      const symbols = ['BTC', 'ETH', 'USDT'];
      const colors = [Color(0xFFF7931A), Color(0xFF7786D8), Color(0xFF269D82)];
      for (var i = 0; i < 3; i++) {
        final angle = (t + i / 3) * math.pi * 2;
        final point = center +
            Offset(math.cos(angle) * s * .43, math.sin(angle) * s * .34);
        final radius = s * .067;
        final bounds = Rect.fromCircle(center: point, radius: radius);
        canvas.drawCircle(point + Offset(0, s * .012), radius,
            Paint()..color = colors[i].withValues(alpha: .15));
        canvas.drawCircle(
            point,
            radius,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-.4, -.5),
                colors: [Color.lerp(colors[i], Colors.white, .3)!, colors[i]],
              ).createShader(bounds));
        canvas.drawCircle(
            point,
            radius * .85,
            Paint()
              ..color = Colors.white.withValues(alpha: .5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * .004);
        final label = TextPainter(
            text: TextSpan(
                text: symbols[i],
                style: TextStyle(
                    fontSize: s * (i == 2 ? .032 : .038),
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            textDirection: TextDirection.ltr)
          ..layout();
        label.paint(canvas, point - Offset(label.width / 2, label.height / 2));
        label.dispose();
      }
    } else if (activity == ScorchActivity.wallet) {
      canvas.drawOval(orbit, line);
      for (var i = 0; i < 3; i++) {
        final angle = (t + i / 3) * math.pi * 2;
        final point = center +
            Offset(math.cos(angle) * s * .44, math.sin(angle) * s * .24);
        canvas.drawCircle(
            point, s * .036, Paint()..color = color.withValues(alpha: .8));
        canvas.drawCircle(
            point,
            s * .023,
            Paint()
              ..color = Colors.white.withValues(alpha: .7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    } else if (activity == ScorchActivity.pay ||
        activity == ScorchActivity.processing) {
      final path = Path()
        ..moveTo(s * .07, s * .68)
        ..cubicTo(s * .2, s * .07, s * .8, s * .95, s * .94, s * .28);
      canvas.drawPath(path, line..strokeWidth = 2);
      final metric = path.computeMetrics().first;
      for (var i = 0; i < 3; i++) {
        final point = metric
            .getTangentForOffset(((t + i / 3) % 1) * metric.length)!
            .position;
        canvas.drawCircle(
            point, s * .023, Paint()..color = color.withValues(alpha: .7));
      }
    } else if (activity == ScorchActivity.protect) {
      final shield = Path()
        ..moveTo(s * .5, s * .06)
        ..lineTo(s * .86, s * .2)
        ..lineTo(s * .82, s * .61)
        ..quadraticBezierTo(s * .76, s * .8, s * .5, s * .94)
        ..quadraticBezierTo(s * .24, s * .8, s * .18, s * .61)
        ..lineTo(s * .14, s * .2)
        ..close();
      canvas.drawPath(
          shield,
          line
            ..strokeWidth = 2
            ..color =
                color.withValues(alpha: .16 + .08 * math.sin(t * math.pi * 2)));
    } else if (activity == ScorchActivity.save) {
      for (var i = 0; i < 4; i++) {
        final height = s * (.07 + .04 * i);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(
                    s * (.1 + .065 * i), s * .85 - height, s * .045, height),
                Radius.circular(s * .015)),
            Paint()
              ..color = color.withValues(
                  alpha: .2 + .1 * math.sin((t + i / 4) * math.pi * 2)));
      }
    } else if (activity != ScorchActivity.rest) {
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2;
        final radius = s * (.38 + .025 * math.sin((t + i / 5) * math.pi * 2));
        final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final r = s * (activity == ScorchActivity.celebrate ? .02 : .012);
        canvas.drawLine(
            p - Offset(r, 0),
            p + Offset(r, 0),
            line
              ..strokeWidth = 2
              ..color = color.withValues(alpha: .5));
        canvas.drawLine(p - Offset(0, r), p + Offset(0, r), line);
      }
    }
  }

  @override
  bool shouldRepaint(_ScorchScene oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.activity != activity ||
      oldDelegate.color != color;
}

/// A quiet, contextual companion card; never overlays financial controls.
class ScorchCompanion extends StatelessWidget {
  const ScorchCompanion(
      {super.key,
      required this.activity,
      required this.title,
      required this.message});
  final ScorchActivity activity;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.accent.withValues(alpha: .08),
              AppColors.surface2
            ]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.accent.withValues(alpha: .12))),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 5),
                Text(message,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45)),
              ])),
          const SizedBox(width: 8),
          ScorchMascot(activity: activity, size: 88)
        ]),
      );
}
