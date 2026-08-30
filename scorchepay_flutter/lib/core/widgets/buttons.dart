import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Solid ember-gradient CTA. Use for exactly one action per screen —
/// Confirm & Pay, Continue, Create account. Never for secondary actions.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 52,
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.accentGradient,
        color: onPressed == null ? AppColors.surface3 : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: AppText.button.copyWith(
                  color: onPressed == null ? AppColors.muted : Colors.white,
                )),
          ],
        ],
      ),
    );
    return GestureDetector(onTap: loading ? null : onPressed, child: child);
  }
}

/// Neutral outline button for secondary actions sitting beside a
/// PrimaryButton, or standalone low-emphasis actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.textPrimary),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.button.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Small circular icon-only button (back arrow, bell, avatar slot).
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 36,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: size * 0.46, color: AppColors.textSecondary),
          ),
          if (badge)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.page, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
