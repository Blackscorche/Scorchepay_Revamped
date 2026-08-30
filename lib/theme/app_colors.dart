import 'package:flutter/material.dart';

/// Central color system for ScorchePay.
///
/// Design intent: a near-black neutral surface system (like Coinbase /
/// Phantom / Backpack) with the brand ember-red accent used SPARINGLY —
/// primary CTAs, the active tab, and a handful of key highlights only.
/// Gains/losses use their own semantic greens/reds, deliberately a
/// different hue from the brand accent so "brand" and "price is down"
/// never read as the same signal.
class AppColors {
  AppColors._();

  // Surfaces
  static const Color bg = Color(0xFF000000);
  static const Color page = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF111113);
  static const Color surface2 = Color(0xFF18181B);
  static const Color surface3 = Color(0xFF212126);

  // Borders
  static const Color border = Color(0x12FFFFFF); // ~7% white
  static const Color borderStrong = Color(0x21FFFFFF); // ~13% white
  static const Color hairline = Color(0x0EFFFFFF); // ~5.5% white

  // Text
  static const Color textPrimary = Color(0xFFF5F5F6);
  static const Color textSecondary = Color(0xFF9A9AA3);
  static const Color muted = Color(0xFF68686F);

  // Brand accent (ember)
  static const Color accent = Color(0xFFFF4B1F);
  static const Color accentGradStart = Color(0xFFFF5B2E);
  static const Color accentGradEnd = Color(0xFFFF3618);
  static const Color accentSoft = Color(0x21FF4B1F); // ~13% accent

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGradStart, accentGradEnd],
  );

  // Semantic status
  static const Color gain = Color(0xFF2ED573);
  static const Color loss = Color(0xFFFF4D6D);
  static const Color warn = Color(0xFFFFB020);
  static const Color info = Color(0xFF4A9EFF);

  // Categorical data palette (charts / allocation / legends)
  static const Color catBlue = Color(0xFF4A9EFF);
  static const Color catOrange = Color(0xFFFF9F43);
  static const Color catAqua = Color(0xFF20C9A6);
  static const Color catYellow = Color(0xFFFFCD3C);
  static const Color catMagenta = Color(0xFFFF6FA3);
  static const Color catGreen = Color(0xFF2ED573);
  static const Color catViolet = Color(0xFF9C8CFF);

  static const List<Color> categorical = [
    catBlue,
    catOrange,
    catAqua,
    catYellow,
    catMagenta,
    catGreen,
    catViolet,
  ];

  // Single-hue ember ramp — for charts/legends that should read as "on
  // brand" (e.g. portfolio allocation) instead of a multi-hue rainbow.
  // Lightness steps down the family rather than switching hue, so slices
  // stay distinguishable while never competing with the brand accent.
  static const Color accentTint1 = Color(0xFFFFB08A);
  static const Color accentTint2 = Color(0xFFFF8659);
  static const Color accentShade1 = Color(0xFFD93A16);
  static const Color accentShade2 = Color(0xFF8F260D);

  static const List<Color> accentRamp = [
    accent,
    accentTint1,
    accentShade1,
    accentTint2,
    accentShade2,
  ];

  static Color statusSoft(Color c) => c.withOpacity(0.13);
}
