import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/colors/app_colors.dart';
import '../design_system/typography/app_typography.dart';
import 'app_theme.dart';

/// Dark theme configuration for HealthFit Heal.
///
/// Uses Material Design 3 with a teal-primary brand palette on a
/// deep dark green-tinted surface for a premium fitness-app feel.
abstract final class DarkTheme {
  static ThemeData build({required ColorScheme colorScheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,

      // ── Scaffold ────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: _buildTextTheme(colorScheme),

      // ── App Bar ─────────────────────────────────────────────────────────
      appBarTheme: AppTheme.buildAppBarTheme(colorScheme).copyWith(
        backgroundColor: AppColors.backgroundDark,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: AppTheme.buildCardTheme(colorScheme).copyWith(
        color: AppColors.cardDark,
        shadowColor: AppColors.black.withOpacity(0.3),
        surfaceTintColor: AppColors.transparent,
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: AppTheme.buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: AppTheme.buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: AppTheme.buildTextButtonTheme(colorScheme),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme:
          AppTheme.buildInputDecorationTheme(colorScheme).copyWith(
        fillColor: AppColors.cardDark,
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: AppTheme.buildNavigationBarTheme(colorScheme)
          .copyWith(
        backgroundColor: AppColors.surfaceDark,
      ),

      // ── Dialogs ───────────────────────────────────────────────────────────
      dialogTheme: AppTheme.buildDialogTheme(colorScheme).copyWith(
        backgroundColor: AppColors.cardDark,
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────────
      snackBarTheme: AppTheme.buildSnackBarTheme(colorScheme).copyWith(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: AppTheme.buildChipTheme(colorScheme).copyWith(
        backgroundColor: AppColors.cardDark,
        selectedColor: AppColors.primary.withOpacity(0.25),
        side: const BorderSide(color: AppColors.dividerDark),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: AppTheme.buildDividerTheme(colorScheme).copyWith(
        color: AppColors.dividerDark,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textDisabledDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.35);
          }
          return AppColors.dividerDark;
        }),
      ),

      // ── Progress Indicators ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.dividerDark,
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
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.dividerDark,
      ),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        iconColor: AppColors.textSecondaryDark,
        tileColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme cs) {
    final color = AppColors.textPrimaryDark;
    final secondaryColor = AppColors.textSecondaryDark;

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
