import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../app_icons.dart';

enum RowIconTint { neutral, accent, warn, good, loss }

/// The workhorse row used throughout the app: leading icon in a tinted
/// circle, title + optional subtitle, trailing widget (defaults to a
/// chevron). Rows are separated by spacing/hairlines rather than heavy
/// borders — stack several inside one [AppCard] to form a list group.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tint = RowIconTint.neutral,
    this.showChevron = true,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final RowIconTint tint;
  final bool showChevron;
  final bool showDivider;

  Color get _bg {
    switch (tint) {
      case RowIconTint.accent:
        return AppColors.accentSoft;
      case RowIconTint.warn:
        return AppColors.statusSoft(AppColors.warn);
      case RowIconTint.good:
        return AppColors.statusSoft(AppColors.gain);
      case RowIconTint.loss:
        return AppColors.statusSoft(AppColors.loss);
      case RowIconTint.neutral:
        return AppColors.surface2;
    }
  }

  Color get _fg {
    switch (tint) {
      case RowIconTint.accent:
        return AppColors.accent;
      case RowIconTint.warn:
        return AppColors.warn;
      case RowIconTint.good:
        return AppColors.gain;
      case RowIconTint.loss:
        return AppColors.loss;
      case RowIconTint.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.hairline))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: _fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppText.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron && onTap != null)
              const Icon(AppIcons.chevronRight, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
