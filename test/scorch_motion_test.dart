import 'package:flutter_test/flutter_test.dart';
import 'package:scorchepay/core/widgets/scorch_activity.dart';
import 'package:scorchepay/core/widgets/scorch_character.dart';

void main() {
  test('character loops have no position or velocity jump', () {
    for (final activity in ScorchActivity.values) {
      for (final point in [
        const Offset(.82, .54),
        const Offset(.45, .08),
        const Offset(.7, .64)
      ]) {
        final start = scorchVertex(point, 0, activity);
        final end = scorchVertex(point, 1, activity);
        expect((end - start).distance, lessThan(1e-8));
        const step = .0001;
        final incoming = (end - scorchVertex(point, 1 - step, activity)) / step;
        final outgoing = (scorchVertex(point, step, activity) - start) / step;
        expect((incoming - outgoing).distance, lessThan(.005));
      }
    }
  });

  test('mesh stays unfolded across every pose and animation phase', () {
    for (final activity in ScorchActivity.values) {
      for (var frame = 0; frame < 36; frame++) {
        for (var row = 0; row < 40; row++) {
          for (var col = 0; col < 32; col++) {
            final a =
                scorchVertex(Offset(col / 32, row / 40), frame / 36, activity);
            final b = scorchVertex(
                Offset((col + 1) / 32, row / 40), frame / 36, activity);
            final c = scorchVertex(
                Offset(col / 32, (row + 1) / 40), frame / 36, activity);
            final d = scorchVertex(
                Offset((col + 1) / 32, (row + 1) / 40), frame / 36, activity);
            double cross(Offset u, Offset v) => u.dx * v.dy - u.dy * v.dx;
            expect(cross(b - a, c - a), greaterThan(0),
                reason: '$activity frame=$frame row=$row col=$col');
            expect(cross(d - b, c - b), greaterThan(0),
                reason: '$activity frame=$frame row=$row col=$col');
          }
        }
      }
    }
  });

  test('hands and flame move independently; rest leaves artwork intact', () {
    const hand = Offset(.83, .54),
        flame = Offset(.45, .08),
        face = Offset(.5, .58);
    final handDelta = scorchVertex(hand, .125, ScorchActivity.welcome) - hand;
    final faceDelta = scorchVertex(face, .125, ScorchActivity.welcome) - face;
    expect((handDelta - faceDelta).distance, greaterThan(.02));
    expect((scorchVertex(flame, .25, ScorchActivity.welcome) - flame).distance,
        greaterThan(.015));
    expect(scorchVertex(hand, .25, ScorchActivity.rest), hand);
  });
}
