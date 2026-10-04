import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'buttons.dart';
import 'scorch_mascot.dart';
import 'detail_header.dart';

/// A full real page (header + empty state, optionally a CTA) for
/// features whose flow/logic isn't built out yet — used instead of a
/// modal/toast standing in for a page. Every icon-grid shortcut in the
/// app that doesn't yet have real content routes here rather than to a
/// dead end.
class EmptyStatePage extends StatelessWidget {
  const EmptyStatePage({
    super.key,
    required this.headerIcon,
    required this.title,
    required this.subtitle,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.ctaLabel,
    this.onCta,
  });

  final IconData headerIcon;
  final String title;
  final String subtitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailHeader(icon: headerIcon, title: title, subtitle: subtitle),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ScorchMascot(activity: ScorchActivity.explore, size: 140),
                      const SizedBox(height: 18),
                      Text(emptyTitle,
                          style: AppText.cardTitle,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(emptyMessage,
                            style: AppText.bodyMuted,
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
              if (ctaLabel != null)
                PrimaryButton(label: ctaLabel!, onPressed: onCta),
            ],
          ),
        ),
      ),
    );
  }
}
