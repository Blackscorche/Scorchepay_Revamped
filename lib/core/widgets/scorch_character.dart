import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'scorch_activity.dart';

/// Animates the original shaded artwork using a continuous textured mesh.
/// This is a 2.5D puppet, not a replacement illustration or a sprite sequence.
class ScorchCharacter extends StatefulWidget {
  const ScorchCharacter(
      {super.key,
      required this.asset,
      required this.activity,
      required this.progress,
      required this.size});
  final String asset;
  final ScorchActivity activity;
  final Animation<double> progress;
  final double size;

  @override
  State<ScorchCharacter> createState() => _ScorchCharacterState();
}

class _ScorchCharacterState extends State<ScorchCharacter> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((image, _) {
    if (!mounted) {
      image.dispose();
      return;
    }
    final previous = _image;
    setState(() => _image = image);
    previous?.dispose();
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ScorchCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _image?.dispose();
    _image = null;
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        child: _image == null
            ? const SizedBox.shrink()
            : CustomPaint(
                painter: ScorchCharacterPainter(
                    _image!.image, widget.progress, widget.activity),
              ),
      );
}

/// Normalized deformation field. Every motion returns to its original position
/// and velocity at the loop seam. Limb weights taper into their shoulders.
Offset scorchVertex(Offset point, double progress, ScorchActivity activity) {
  if (activity == ScorchActivity.rest) return point;
  final phase = progress * math.pi * 2;
  final breath = math.sin(phase);
  final x = point.dx, y = point.dy;
  double smooth(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  double region(double cx, double cy, double rx, double ry) =>
      math.exp(-2 * (math.pow((x - cx) / rx, 2) + math.pow((y - cy) / ry, 2)));
  var dx = (x - .5) * .03 * breath * smooth((.94 - y) / .3);
  var dy = -(y - .91) * .022 * breath;
  // The flame follows the body with a delayed, flexible sweep.
  dx += .054 * math.sin(phase) * math.pow(smooth((.48 - y) / .45), 2);
  dy += .015 * math.sin(phase * 2) * smooth((.4 - y) / .4);

  void turn(Offset pivot, double angle, double weight) {
    final relative = point - pivot;
    dx +=
        (relative.dx * (math.cos(angle) - 1) - relative.dy * math.sin(angle)) *
            weight;
    dy +=
        (relative.dx * math.sin(angle) + relative.dy * (math.cos(angle) - 1)) *
            weight;
  }

  switch (activity) {
    case ScorchActivity.welcome:
    case ScorchActivity.explore:
      // Two gentle waves from the shoulder; the torso and face stay stable.
      turn(
          const Offset(.73, .66),
          .38 * math.sin(phase * 2),
          smooth((x - .72) / .1) *
              smooth((.76 - y) / .15) *
              smooth((y - .35) / .15));
      turn(const Offset(.34, .73), .12 * breath,
          smooth((.35 - x) / .14) * smooth((y - .66) / .12));
    case ScorchActivity.celebrate:
      turn(
          const Offset(.31, .64),
          -.3 * breath,
          smooth((.34 - x) / .14) *
              smooth((.8 - y) / .25) *
              smooth((y - .35) / .15));
      turn(
          const Offset(.74, .63),
          .3 * breath,
          smooth((x - .71) / .14) *
              smooth((.78 - y) / .25) *
              smooth((y - .3) / .15));
      dx += .025 *
          breath *
          (region(.39, .84, .17, .15) - region(.62, .83, .17, .15));
      dy += .02 * math.sin(phase * 2) * smooth((y - .73) / .18);
    case ScorchActivity.protect:
      // Shield and gripping hands rise together, preserving their contact.
      dy -= .027 * (1 - math.cos(phase)) * region(.59, .75, .38, .23);
      dx += .014 * breath * region(.49, .51, .27, .19);
    case ScorchActivity.wallet:
    case ScorchActivity.pay:
    case ScorchActivity.crypto:
    case ScorchActivity.save:
    case ScorchActivity.processing:
      // Small coin-hand gesture, with a quieter counter-motion in the wallet.
      dy -= .037 * (1 - math.cos(phase)) * region(.7, .64, .14, .12);
      dx += .017 * breath * region(.7, .64, .14, .12);
      dy += .009 * breath * region(.57, .77, .25, .14);
    case ScorchActivity.rest:
      break;
  }
  return Offset(x + dx, y + dy);
}

class ScorchCharacterPainter extends CustomPainter {
  ScorchCharacterPainter(this.image, this.progress, this.activity)
      : super(repaint: progress) {
    _paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..shader = ui.ImageShader(
          image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage,
          filterQuality: FilterQuality.medium);
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final index = (row * (columns + 1) + column) * 2;
        _texture[index] = column / columns * image.width;
        _texture[index + 1] = row / rows * image.height;
      }
    }
  }
  final ui.Image image;
  final Animation<double> progress;
  final ScorchActivity activity;
  static const columns = 32, rows = 40;
  final _positions = Float32List((columns + 1) * (rows + 1) * 2);
  final _texture = Float32List((columns + 1) * (rows + 1) * 2);
  late final Paint _paint;
  static final _indices = Uint16List.fromList([
    for (var row = 0; row < rows; row++)
      for (var column = 0; column < columns; column++) ...[
        row * (columns + 1) + column,
        row * (columns + 1) + column + 1,
        (row + 1) * (columns + 1) + column,
        row * (columns + 1) + column + 1,
        (row + 1) * (columns + 1) + column + 1,
        (row + 1) * (columns + 1) + column,
      ],
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final fit = applyBoxFit(BoxFit.contain,
        Size(image.width.toDouble(), image.height.toDouble()), size);
    final origin = Offset((size.width - fit.destination.width) / 2,
        (size.height - fit.destination.height) / 2);
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final point = scorchVertex(
            Offset(column / columns, row / rows), progress.value, activity);
        final index = (row * (columns + 1) + column) * 2;
        _positions[index] = origin.dx + point.dx * fit.destination.width;
        _positions[index + 1] = origin.dy + point.dy * fit.destination.height;
      }
    }
    final vertices = ui.Vertices.raw(ui.VertexMode.triangles, _positions,
        textureCoordinates: _texture, indices: _indices);
    canvas.drawVertices(vertices, BlendMode.srcOver, _paint);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(ScorchCharacterPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.activity != activity ||
      oldDelegate.progress != progress;
}
