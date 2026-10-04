import 'package:flutter/material.dart';
import '../../core/widgets/scorch_mascot.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Debug-only preview of the same character player used by app screens.
class ScorchPreviewScreen extends StatelessWidget {
  const ScorchPreviewScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meet Scorch',
                            style: AppText.pageTitle.copyWith(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text('A little spark. A lot of personality.',
                            style: AppText.bodyMuted),
                        const SizedBox(height: 28),
                        LayoutBuilder(
                            builder: (context, constraints) =>
                                Wrap(spacing: 16, runSpacing: 16, children: [
                                  for (final scene in const [
                                    (
                                      ScorchActivity.welcome,
                                      'Hello, you.',
                                      'A little spark to welcome you.'
                                    ),
                                    (
                                      ScorchActivity.wallet,
                                      'Money, in motion.',
                                      'Your wallet’s little companion.'
                                    ),
                                    (
                                      ScorchActivity.crypto,
                                      'Find your crypto rhythm.',
                                      'BTC, ETH and USDT in Scorch’s orbit.'
                                    ),
                                    (
                                      ScorchActivity.save,
                                      'Small steps. Bigger plans.',
                                      'A little progress toward your next goal.'
                                    ),
                                    (
                                      ScorchActivity.protect,
                                      'Looking out for you.',
                                      'A reassuring shield by your side.'
                                    ),
                                    (
                                      ScorchActivity.celebrate,
                                      'That’s a win.',
                                      'A happy hop for a job well done.'
                                    ),
                                  ])
                                    Container(
                                        width: constraints.maxWidth < 600
                                            ? constraints.maxWidth
                                            : (constraints.maxWidth - 16) / 2,
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                            color: AppColors.surface2,
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            border: Border.all(
                                                color: AppColors.hairline)),
                                        child: Column(children: [
                                          ScorchMascot(
                                              activity: scene.$1, size: 220),
                                          const SizedBox(height: 12),
                                          Text(scene.$2,
                                              style: AppText.cardTitle),
                                          const SizedBox(height: 8),
                                          Text(scene.$3,
                                              style: AppText.bodyMuted,
                                              textAlign: TextAlign.center)
                                        ])),
                                ])),
                      ]),
                )))),
      );
}
