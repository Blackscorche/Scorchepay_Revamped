import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// "Section title" heading used above card groups (e.g. "Portfolio
/// allocation"), with an optional trailing action link (e.g. "See all").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.topPad = 22});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: 10, left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.sectionTitle),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

/// Uppercase muted eyebrow label ("TOTAL BALANCE", "YOU'RE PAYING").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.eyebrow);
}
