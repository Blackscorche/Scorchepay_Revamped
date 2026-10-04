import 'package:flutter/material.dart';
import '../../../core/widgets/scorch_mascot.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ResultLine {
  const ResultLine(this.label, this.value);
  final String label;
  final String value;
}

/// Shared success/failure terminal screen for every money-moving flow.
/// [onPrimary] typically pops back to wherever the flow was entered
/// from (`Navigator.popUntil`); [onSecondary] is a lighter action like
/// "Send another" or "Retry".
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.success,
    required this.headline,
    required this.lines,
    this.detailMessage,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final bool success;
  final String headline;
  final List<ResultLine> lines;
  final String? detailMessage;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.gain : AppColors.loss;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                if (success)
                  const ScorchMascot(activity: ScorchActivity.celebrate, size: 150)
                else Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.14), shape: BoxShape.circle),
                  child: Icon(success ? AppIcons.check : AppIcons.close,
                      size: 36, color: color),
                ),
                const SizedBox(height: 20),
                Text(headline,
                    style: AppText.pageTitle.copyWith(fontSize: 21),
                    textAlign: TextAlign.center),
                if (detailMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(detailMessage!,
                      style: AppText.bodyMuted, textAlign: TextAlign.center),
                ],
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        for (int i = 0; i < lines.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: i == lines.length - 1 ? 0 : 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lines[i].label,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary)),
                                Flexible(
                                  child: Text(
                                    lines[i].value,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                PrimaryButton(label: primaryLabel, onPressed: onPrimary),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: 10),
                  SecondaryButton(
                      label: secondaryLabel!, onPressed: onSecondary ?? () {}),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
