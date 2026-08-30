import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../app_icons.dart';
import 'buttons.dart';

/// Standard "back + icon badge + title/subtitle" header used at the top
/// of pushed detail screens (bills sub-flows, book details, etc.) so
/// every full-screen route reads the same way.
class DetailHeader extends StatelessWidget {
  const DetailHeader(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconCircleButton(
            icon: AppIcons.chevronLeft,
            onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, size: 19, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.detailTitle),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: AppText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
