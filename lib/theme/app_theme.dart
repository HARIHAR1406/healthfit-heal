import 'package:flutter/material.dart';

import '../design_system/colors/app_colors.dart';
import '../design_system/typography/app_typography.dart';
import '../design_system/spacing/app_spacing.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

/// Central theme configuration for HealthFit Heal.
///
/// Provides [lightTheme] and [darkTheme] built on Material Design 3.
/// Both themes share the same [ColorScheme] seed but diverge in
/// surface, background, and component-level overrides.
abstract final class AppTheme {
  // ── Color Seeds ───────────────────────────────────────────────────────────
  static const Color _seedColor = AppColors.primary;

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme => LightTheme.build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          error: AppColors.error,
          onError: AppColors.onError,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimaryLight,
          surfaceContainerHighest: AppColors.cardLight,
        ),
      );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => DarkTheme.build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          error: AppColors.error,
          onError: AppColors.onError,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          surfaceContainerHighest: AppColors.cardDark,
        ),
      );

  // ── Shared Component Theming ──────────────────────────────────────────────

  /// Builds shared [AppBarTheme] for a given [ColorScheme].
  static AppBarTheme buildAppBarTheme(ColorScheme cs) => AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
        centerTitle: false,
      );

  /// Builds shared [CardTheme] for a given [ColorScheme].
  static CardTheme buildCardTheme(ColorScheme cs) => CardTheme(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      );

  /// Builds shared [ElevatedButtonThemeData] for a given [ColorScheme].
  static ElevatedButtonThemeData buildElevatedButtonTheme(
    ColorScheme cs,
  ) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.buttonText,
          elevation: 0,
        ),
      );

  /// Builds shared [OutlinedButtonThemeData] for a given [ColorScheme].
  static OutlinedButtonThemeData buildOutlinedButtonTheme(
    ColorScheme cs,
  ) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: cs.primary, width: AppSpacing.borderNormal),
          textStyle: AppTypography.buttonText,
        ),
      );

  /// Builds shared [TextButtonThemeData] for a given [ColorScheme].
  static TextButtonThemeData buildTextButtonTheme(ColorScheme cs) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: AppTypography.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );

  /// Builds shared [InputDecorationTheme] for a given [ColorScheme].
  static InputDecorationTheme buildInputDecorationTheme(
    ColorScheme cs,
  ) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: cs.onSurface.withValues(alpha: 0.4),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
        floatingLabelStyle: AppTypography.bodySmall.copyWith(
          color: cs.primary,
        ),
      );

  /// Builds shared [BottomNavigationBarThemeData] for a given [ColorScheme].
  static NavigationBarThemeData buildNavigationBarTheme(
    ColorScheme cs,
  ) =>
      NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: AppSpacing.iconMd);
          }
          return IconThemeData(
            color: cs.onSurface.withValues(alpha: 0.6),
            size: AppSpacing.iconMd,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          );
        }),
        elevation: 0,
      );

  /// Builds shared [SnackBarThemeData] for a given [ColorScheme].
  static SnackBarThemeData buildSnackBarTheme(ColorScheme cs) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

  /// Builds shared [DialogTheme] for a given [ColorScheme].
  static DialogTheme buildDialogTheme(ColorScheme cs) => DialogTheme(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: cs.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: cs.onSurface.withValues(alpha: 0.8),
        ),
      );

  /// Builds shared [DividerThemeData] for a given [ColorScheme].
  static DividerThemeData buildDividerTheme(ColorScheme cs) =>
      const DividerThemeData(
        space: 1,
        thickness: 1,
      );

  /// Builds shared [ChipThemeData] for a given [ColorScheme].
  static ChipThemeData buildChipTheme(ColorScheme cs) => ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        labelStyle: AppTypography.labelMedium,
      );
}
