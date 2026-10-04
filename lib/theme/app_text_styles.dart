import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type ramp for ScorchePay. Uses the platform default font (San Francisco
/// on iOS, Roboto on Android) with deliberate weight/tracking choices
/// instead of a display face — this mirrors how most top-tier fintech
/// apps actually ship (Cash App, Robinhood): the font itself stays
/// invisible, hierarchy comes from weight, size and spacing.
///
/// Every style here bakes in a text color sourced from [AppColors], which
/// is theme-aware — so these are getters (re-evaluated on every access)
/// rather than `const` fields, and flip with light/dark mode.
class AppText {
  AppText._();

  static TextStyle get heroNumber => const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.05,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get heroNumberMedium => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get pageTitle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get detailTitle => const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get cardTitle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get body => const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ).copyWith(color: AppColors.textPrimary);

  static TextStyle get bodyMuted => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ).copyWith(color: AppColors.textSecondary);

  static TextStyle get caption => const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ).copyWith(color: AppColors.muted);

  static TextStyle get eyebrow => const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ).copyWith(color: AppColors.muted);

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
