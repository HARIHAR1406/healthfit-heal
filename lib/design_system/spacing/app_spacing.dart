/// Spacing constants for HealthFit Heal.
///
/// Based on an 4-point grid system for visual rhythm and consistency.
/// Use these tokens instead of raw pixel values everywhere in the UI.
abstract final class AppSpacing {
  // ── Base Grid ─────────────────────────────────────────────────────────────
  static const double _base = 4.0;

  static const double xxs = _base;        // 4
  static const double xs = _base * 2;     // 8
  static const double sm = _base * 3;     // 12
  static const double md = _base * 4;     // 16
  static const double lg = _base * 5;     // 20
  static const double xl = _base * 6;     // 24
  static const double xxl = _base * 8;    // 32
  static const double xxxl = _base * 10;  // 40
  static const double huge = _base * 12;  // 48
  static const double massive = _base * 16; // 64

  // ── Page Padding ──────────────────────────────────────────────────────────
  static const double pageHorizontal = md;
  static const double pageVertical = xl;
  static const double pagePadding = md;

  // ── Card ──────────────────────────────────────────────────────────────────
  static const double cardPadding = md;
  static const double cardPaddingSmall = sm;
  static const double cardPaddingLarge = xl;
  static const double cardGap = sm;
  static const double cardGapLarge = md;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  // ── Icon Sizes ────────────────────────────────────────────────────────────
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 40;
  static const double iconXxl = 48;

  // ── Button ────────────────────────────────────────────────────────────────
  static const double buttonHeightSm = 36;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;
  static const double buttonHorizontalPadding = xl;

  // ── Input Fields ──────────────────────────────────────────────────────────
  static const double inputHeight = 56;
  static const double inputBorderRadius = radiusMd;
  static const double inputHorizontalPadding = md;

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  static const double bottomNavHeight = 64;

  // ── App Bar ───────────────────────────────────────────────────────────────
  static const double appBarHeight = 56;

  // ── Avatar ────────────────────────────────────────────────────────────────
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double avatarXl = 96;

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const double chartHeight = 200;
  static const double chartHeightLg = 280;

  // ── Elevation ─────────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationXs = 1;
  static const double elevationSm = 2;
  static const double elevationMd = 4;
  static const double elevationLg = 8;
  static const double elevationXl = 16;

  // ── Border Width ──────────────────────────────────────────────────────────
  static const double borderThin = 0.5;
  static const double borderNormal = 1;
  static const double borderMedium = 1.5;
  static const double borderThick = 2;
}

