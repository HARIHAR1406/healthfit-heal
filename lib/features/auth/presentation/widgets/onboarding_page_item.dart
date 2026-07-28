import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Data class holding the content for one onboarding slide.
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
}

/// Predefined onboarding slides for HealthFit Heal.
const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Track Your Health',
    subtitle:
        'Monitor your vitals, steps, heart rate, and wellness metrics — all in one beautiful dashboard.',
    icon: Icons.favorite_rounded,
    gradientColors: [Color(0xFF009870), Color(0xFF00C896)],
  ),
  OnboardingPageData(
    title: 'Personalized Plans',
    subtitle:
        'Get AI-powered workout and nutrition plans crafted specifically for your goals and fitness level.',
    icon: Icons.fitness_center_rounded,
    gradientColors: [Color(0xFF3B36CC), Color(0xFF6C63FF)],
  ),
  OnboardingPageData(
    title: 'Achieve Your Goals',
    subtitle:
        'Stay on track with smart reminders, progress insights, and streak rewards to keep you motivated.',
    icon: Icons.emoji_events_rounded,
    gradientColors: [Color(0xFFCC3B3B), Color(0xFFFF6B6B)],
  ),
];

/// A single onboarding slide widget.
///
/// Renders the illustration area, title, and subtitle for one step.
class OnboardingPageItem extends StatelessWidget {
  const OnboardingPageItem({
    required this.data,
    required this.pageIndex,
    super.key,
  });

  final OnboardingPageData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Column(
      children: [
        // ── Illustration Area ────────────────────────────────────────────────
        _IllustrationSection(
          data: data,
          height: size.height * 0.45,
        ),

        // ── Text Content ─────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.subtitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IllustrationSection extends StatelessWidget {
  const _IllustrationSection({
    required this.data,
    required this.height,
  });

  final OnboardingPageData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  data.gradientColors[0].withValues(alpha: 0.15),
                  data.gradientColors[1].withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _DecorativeCircle(
              size: 200,
              color: data.gradientColors[1].withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: _DecorativeCircle(
              size: 140,
              color: data.gradientColors[0].withValues(alpha: 0.06),
            ),
          ),

          // Center icon
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.gradientColors[1].withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 8,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 72,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
