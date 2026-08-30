import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Standard surface card used across every screen: 1px hairline border,
/// rounded corners, flat neutral fill. Kept deliberately quiet so the
/// hero card and the accent color are the only things that pop.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: card,
    );
  }
}

/// The "hero" balance/portfolio card — a subtle glass treatment (soft
/// vertical gradient + a 1px light seam along the top edge) instead of a
/// loud glowing blob. This is the one card per screen allowed a bit of
/// visual weight; everything else stays flat.
class GlassHeroCard extends StatelessWidget {
  const GlassHeroCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderStrong),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141416), Color(0xFF101012)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0),
                ]),
              ),
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}
