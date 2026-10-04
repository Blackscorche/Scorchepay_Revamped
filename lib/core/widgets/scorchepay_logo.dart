import 'package:flutter/material.dart';

/// Official brand mark. The source PNG includes generous transparent padding.
class ScorchePayLogo extends StatelessWidget {
  const ScorchePayLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'ScorchePay logo',
        image: true,
        child: SizedBox.square(
          dimension: size,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: size * 2.4,
              maxHeight: size * 2.4,
              child: Image.asset('assets/logo_red.png',
                  width: size * 2.4,
                  height: size * 2.4,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true),
            ),
          ),
        ),
      );
}
