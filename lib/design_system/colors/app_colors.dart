import 'package:flutter/material.dart';

/// Central color palette for HealthFit Heal.
///
/// All colors are defined here and referenced throughout the app.
/// Never use raw [Color] literals outside this file.
abstract final class AppColors {
  // ── Brand Primaries ──────────────────────────────────────────────────────
  /// Vibrant teal — primary brand color
  static const Color primary = Color(0xFF00C896);
  static const Color primaryLight = Color(0xFF5EFFC7);
  static const Color primaryDark = Color(0xFF009870);
  static const Color onPrimary = Color(0xFF003826);

  /// Energetic coral — secondary accent
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9E9E);
  static const Color secondaryDark = Color(0xFFCC3B3B);
  static const Color onSecondary = Color(0xFF1A0000);

  /// Deep indigo — tertiary accent (charts, highlights)
  static const Color tertiary = Color(0xFF6C63FF);
  static const Color tertiaryLight = Color(0xFF9D97FF);
  static const Color tertiaryDark = Color(0xFF3B36CC);
  static const Color onTertiary = Color(0xFF080033);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFA5D6A7);
  static const Color successDark = Color(0xFF2E7D32);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFCC80);
  static const Color warningDark = Color(0xFFE65100);

  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFEF9A9A);
  static const Color errorDark = Color(0xFFC62828);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF90CAF9);
  static const Color infoDark = Color(0xFF0D47A1);

  // ── Neutrals (Light Mode) ────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF8FAF9);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE8F0EC);

  static const Color textPrimaryLight = Color(0xFF1A2E26);
  static const Color textSecondaryLight = Color(0xFF5C7268);
  static const Color textDisabledLight = Color(0xFFABC0B8);
  static const Color textHintLight = Color(0xFFC5D5CF);

  // ── Neutrals (Dark Mode) ─────────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF0F1F1A);
  static const Color backgroundDark = Color(0xFF08130F);
  static const Color cardDark = Color(0xFF162820);
  static const Color dividerDark = Color(0xFF1F3328);

  static const Color textPrimaryDark = Color(0xFFE8F5F0);
  static const Color textSecondaryDark = Color(0xFF8BB8A8);
  static const Color textDisabledDark = Color(0xFF3D5C50);
  static const Color textHintDark = Color(0xFF2E4840);

  // ── Chart / Data Visualization ────────────────────────────────────────────
  static const Color chartTeal = Color(0xFF00C896);
  static const Color chartCoral = Color(0xFFFF6B6B);
  static const Color chartIndigo = Color(0xFF6C63FF);
  static const Color chartAmber = Color(0xFFFFBF00);
  static const Color chartSky = Color(0xFF00B4D8);
  static const Color chartPink = Color(0xFFFF6BB5);

  static const List<Color> chartPalette = [
    chartTeal,
    chartCoral,
    chartIndigo,
    chartAmber,
    chartSky,
    chartPink,
  ];

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00A87C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFF162820), Color(0xFF0F1F1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  // ── Shimmer ───────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE8F0EC);
  static const Color shimmerHighlight = Color(0xFFF8FAF9);
  static const Color shimmerBaseDark = Color(0xFF1F3328);
  static const Color shimmerHighlightDark = Color(0xFF2A4438);

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const Color overlay20 = Color(0x33000000);
  static const Color overlay40 = Color(0x66000000);
  static const Color overlay60 = Color(0x99000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}
