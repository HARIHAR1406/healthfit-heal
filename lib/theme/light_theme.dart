import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/colors/app_colors.dart';
import '../design_system/typography/app_typography.dart';
import 'app_theme.dart';

/// Light theme configuration for HealthFit Heal.
///
/// Uses Material Design 3 with a teal-primary brand palette on a
/// clean white/off-white surface for maximum readability.
abstract final class LightTheme {
  static ThemeData build({required ColorScheme colorScheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,

      // ── Scaffold ────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: _buildTextTheme(colorScheme),

      // ── App Bar ─────────────────────────────────────────────────────────
      appBarTheme: AppTheme.buildAppBarTheme(colorScheme).copyWith(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.backgroundLight,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: AppTheme.buildCardTheme(colorScheme).copyWith(
        shadowColor: AppColors.black.withOpacity(0.06),
        surfaceTintColor: AppColors.transparent,
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: AppTheme.buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: AppTheme.buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: AppTheme.buildTextButtonTheme(colorScheme),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: AppTheme.buildInputDecorationTheme(colorScheme)
          .copyWith(
        fillColor: AppColors.surfaceLight,
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: AppTheme.buildNavigationBarTheme(colorScheme),

      // ── Dialogs ───────────────────────────────────────────────────────────
      dialogTheme: AppTheme.buildDialogTheme(colorScheme),

      // ── Snack Bar ─────────────────────────────────────────────────────────
      snackBarTheme: AppTheme.buildSnackBarTheme(colorScheme).copyWith(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: AppTheme.buildChipTheme(colorScheme).copyWith(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withOpacity(0.15),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: AppTheme.buildDividerTheme(colorScheme).copyWith(
        color: AppColors.dividerLight,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textDisabledLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.dividerLight;
        }),
      ),

      // ── Progress Indicators ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.dividerLight,
      ),

      // ── Floating Action Button ────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundLight,
        modalBackgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.dividerLight,
      ),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        iconColor: AppColors.textSecondaryLight,
        tileColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme cs) {
    final color = AppColors.textPrimaryLight;
    final secondaryColor = AppColors.textSecondaryLight;

    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: color),
      displayMedium: AppTypography.displayMedium.copyWith(color: color),
      displaySmall: AppTypography.displaySmall.copyWith(color: color),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: color),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: color),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: color),
      titleLarge: AppTypography.titleLarge.copyWith(color: color),
      titleMedium: AppTypography.titleMedium.copyWith(color: color),
      titleSmall: AppTypography.titleSmall.copyWith(color: color),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: secondaryColor),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondaryColor),
      labelLarge: AppTypography.labelLarge.copyWith(color: color),
      labelMedium: AppTypography.labelMedium.copyWith(color: secondaryColor),
      labelSmall: AppTypography.labelSmall.copyWith(color: secondaryColor),
    );
  }
}

