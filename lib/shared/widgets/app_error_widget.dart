import 'package:flutter/material.dart';

import '../../design_system/icons/app_icons.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_typography.dart';
import 'app_button.dart';

/// A reusable error display widget for HealthFit Heal.
///
/// Used to show error states in lists, pages, or dialogs.
/// Supports an optional retry callback and custom icon.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon,
    this.title,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Error icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? AppIcons.error,
              size: AppSpacing.iconXxl,
              color: cs.error,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title (optional)
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.titleMedium.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Message
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          // Retry button
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: retryLabel,
              onPressed: onRetry,
              width: 160,
              height: AppSpacing.buttonHeightSm,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact inline error text for form field errors or small containers.
class AppInlineError extends StatelessWidget {
  const AppInlineError({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.error, size: AppSpacing.iconXs, color: cs.error),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: cs.error),
          ),
        ),
      ],
    );
  }
}
