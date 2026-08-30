import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Thin rounded progress track used for savings goals, loyalty tiers and
/// group-savings contributions.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar(
      {super.key, required this.value, this.color, this.height = 6});

  /// 0.0 – 1.0
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        color: AppColors.surface3,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: color == null ? AppColors.accentGradient : null,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
