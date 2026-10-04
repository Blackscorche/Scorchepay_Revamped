import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class BarDatum {
  const BarDatum(this.label, this.value, this.color);
  final String label;
  final double value; // 0-100
  final Color color;
}

/// Small categorical bar chart (spending-by-category style). Each
/// category keeps a fixed hue from the shared categorical palette, with
/// a direct value label above every bar since there are only a handful
/// of categories — the "never label every point" rule applies to dense
/// line/scatter series, not a 5-6 bar categorical chart like this one.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.data, this.height = 120});

  final List<BarDatum> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data
            .map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${d.value.toInt()}%',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Expanded(
                          child: FractionallySizedBox(
                            heightFactor: (d.value / 100).clamp(0.02, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 24),
                              decoration: BoxDecoration(
                                color: d.color,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(5),
                                  bottomLeft: Radius.circular(2),
                                  bottomRight: Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(d.label,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
