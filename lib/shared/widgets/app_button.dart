import 'package:flutter/material.dart';

import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_typography.dart';

/// Button variant enum for [AppButton].
enum AppButtonVariant { primary, secondary, outlined, text, danger }

/// Reusable button component for HealthFit Heal.
///
/// Supports multiple [AppButtonVariant]s, loading state, icons,
/// and disabled state. Respects the app theme automatically.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppSpacing.buttonHeightMd,
  });

  /// Button label text.
  final String label;

  /// Callback invoked when the button is tapped.
  final VoidCallback? onPressed;

  /// Visual variant.
  final AppButtonVariant variant;

  /// Whether to show a loading indicator instead of the label.
  final bool isLoading;

  /// Whether the button is interactive.
  final bool isEnabled;

  /// Optional icon before the label.
  final IconData? leadingIcon;

  /// Optional icon after the label.
  final IconData? trailingIcon;

  /// Optional fixed width. Defaults to [double.infinity].
  final double? width;

  /// Button height. Defaults to [AppSpacing.buttonHeightMd].
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = isEnabled && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildButton(context, cs, isActive),
    );
  }

  Widget _buildButton(
    BuildContext context,
    ColorScheme cs,
    bool isActive,
  ) {
    final effectiveOnPressed = isActive ? onPressed : null;
    final child = _buildChild(cs);

    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: variant == AppButtonVariant.danger
                ? cs.error
                : cs.primary,
            foregroundColor: variant == AppButtonVariant.danger
                ? cs.onError
                : cs.onPrimary,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.secondary,
            foregroundColor: cs.onSecondary,
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
    };
  }

  Widget _buildChild(ColorScheme cs) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: _getContentColor(cs),
        ),
      );
    }

    if (leadingIcon == null && trailingIcon == null) {
      return Text(label, style: AppTypography.buttonText);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label, style: AppTypography.buttonText),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(trailingIcon, size: AppSpacing.iconSm),
        ],
      ],
    );
  }

  Color _getContentColor(ColorScheme cs) => switch (variant) {
        AppButtonVariant.primary => cs.onPrimary,
        AppButtonVariant.secondary => cs.onSecondary,
        AppButtonVariant.danger => cs.onError,
        AppButtonVariant.outlined || AppButtonVariant.text => cs.primary,
      };
}
