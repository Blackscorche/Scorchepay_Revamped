import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type ramp for ScorchePay. Uses the platform default font (San Francisco
/// on iOS, Roboto on Android) with deliberate weight/tracking choices
/// instead of a display face — this mirrors how most top-tier fintech
/// apps actually ship (Cash App, Robinhood): the font itself stays
/// invisible, hierarchy comes from weight, size and spacing.
class AppText {
  AppText._();

  static const TextStyle heroNumber = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static const TextStyle heroNumberMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle detailTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.muted,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  static TextStyle get tabular => body.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
