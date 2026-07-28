import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import 'circular_progress_ring.dart';

/// Premium hero banner at the top of the home dashboard.
///
/// Displays:
///   - Personalized welcome message + motivational quote
///   - Circular wellness score ring
///   - Wellness label
///   - "Log Activity" CTA button
class HeroBanner extends ConsumerWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final data = ref.watch(dashboardDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final score = data?.wellnessScore ?? 0;
    final label = data?.wellnessLabel ?? '';
    final quote = data?.motivationalQuote ?? '';

    return Semantics(
      label: 'Wellness overview. Score: $score out of 100. $label',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF00B4D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          child: Stack(
            children: [
              // ── Decorative Circles ──────────────────────────────────────────
              Positioned(
                top: -30,
                right: -20,
                child: _DecoCircle(
                  size: 150,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                bottom: -40,
                right: 60,
                child: _DecoCircle(
                  size: 120,
                  color: AppColors.white.withValues(alpha: 0.04),
                ),
              ),
              Positioned(
                top: 20,
                right: 100,
                child: _DecoCircle(
                  size: 60,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),

              // ── Content Row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              '✦  Today\'s Wellness',
                              style: AppTypography.overline.copyWith(
                                color: AppColors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Greeting
                          Text(
                            'Hello, ${user?.firstName ?? 'there'}!',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          // Motivational quote
                          Text(
                            quote,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // CTA Button
                          _LogActivityButton(),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Right: wellness ring
                    _WellnessRing(score: score, label: label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CTA Button ────────────────────────────────────────────────────────────────

class _LogActivityButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Log Today\'s Activity',
      button: true,
      child: OutlinedButton.icon(
        onPressed: () => context.go(RouteNames.workouts),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(
            color: AppColors.white,
            width: AppSpacing.borderNormal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: AppSpacing.iconSm),
        label: Text(
          'Log Activity',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Wellness Ring ─────────────────────────────────────────────────────────────

class _WellnessRing extends StatelessWidget {
  const _WellnessRing({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressRing(
          fraction: score / 100.0,
          size: 92,
          strokeWidth: 7,
          color: AppColors.white,
          trackColor: AppColors.white.withValues(alpha: 0.2),
          centerWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              Text(
                '/100',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Decorative Circle ─────────────────────────────────────────────────────────

class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
