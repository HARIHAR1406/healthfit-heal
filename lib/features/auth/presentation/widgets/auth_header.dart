import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Branded auth header displayed at the top of login / register screens.
///
/// Renders the app logo, app name, and an optional [subtitle].
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.subtitle,
    this.showLogo = true,
    this.compact = false,
  });

  /// Tagline or context string shown below the app name.
  final String? subtitle;

  /// Whether to display the logo icon.
  final bool showLogo;

  /// Use compact sizing for scrollable screens with many fields.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.tertiary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        compact ? AppSpacing.xxl : AppSpacing.huge,
        AppSpacing.xl,
        compact ? AppSpacing.xxl : AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            _LogoBadge(compact: compact),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          ],
          Text(
            subtitle ?? '',
            style: (compact
                    ? AppTypography.headlineSmall
                    : AppTypography.headlineMedium)
                .copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'HealthFit Heal',
              style: (compact
                      ? AppTypography.headlineSmall
                      : AppTypography.headlineMedium)
                  .copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The logo badge widget — circle with a health cross icon.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 56.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.white.withOpacity(0.4),
          width: AppSpacing.borderNormal,
        ),
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: AppColors.white,
        size: compact ? 24 : 30,
      ),
    );
  }
}

/// Centered logo for splash / onboarding.
class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.size = 80,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: AppColors.white,
        size: size * 0.5,
      ),
    );
  }
}
