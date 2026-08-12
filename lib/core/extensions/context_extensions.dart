import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_typography.dart';

/// Convenience extensions on [BuildContext] for cleaner widget code.
extension ContextExtensions on BuildContext {
  // ── Theme ─────────────────────────────────────────────────────────────────

  /// The current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// The current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Whether the app is currently in dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Media ─────────────────────────────────────────────────────────────────

  /// The current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Bottom safe area inset (home indicator / navigation bar).
  double get bottomInset => MediaQuery.paddingOf(this).bottom;

  /// Top safe area inset (status bar / notch).
  double get topInset => MediaQuery.paddingOf(this).top;

  /// Whether the keyboard is currently visible.
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// The keyboard height when visible, or 0.
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// Screen size category helpers.
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 480;
  bool get isLargeScreen => screenWidth >= 480;

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Pops the current route.
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Whether the navigator can pop.
  bool get canPop => Navigator.of(this).canPop();

  // ── Snack Bar ─────────────────────────────────────────────────────────────

  void showSnackBar(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodyMedium),
          action: action,
          duration: duration,
        ),
      );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodyMedium),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodyMedium),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Focus ─────────────────────────────────────────────────────────────────

  /// Dismisses the keyboard by unfocusing the current focus node.
  void dismissKeyboard() => FocusScope.of(this).unfocus();

  // ── Responsive Padding ────────────────────────────────────────────────────

  /// Standard page edge padding.
  EdgeInsets get pagePadding => const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.pageVertical,
      );

  /// Horizontal-only page edge padding.
  EdgeInsets get pageHorizontalPadding => const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      );

  // ── Color Helpers ─────────────────────────────────────────────────────────

  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get errorColor => colorScheme.error;
  Color get surfaceColor => colorScheme.surface;
  Color get onSurfaceColor => colorScheme.onSurface;
}

