import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Generic placeholder for shell tab pages not yet implemented.
///
/// Each tab uses this scaffold until the feature is built.
class TabPlaceholderPage extends StatelessWidget {
  const TabPlaceholderPage({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  'Coming soon',
                  style: AppTypography.labelMedium.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Health tab placeholder.
class HealthPlaceholderPage extends StatelessWidget {
  const HealthPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const TabPlaceholderPage(
        title: 'Health',
        icon: Icons.monitor_heart_rounded,
        color: AppColors.secondary,
        description:
            'Track your vitals, heart rate, blood pressure, and body metrics in real-time.',
      );
}

/// Fitness tab placeholder.
class FitnessPlaceholderPage extends StatelessWidget {
  const FitnessPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const TabPlaceholderPage(
        title: 'Fitness',
        icon: Icons.fitness_center_rounded,
        color: AppColors.tertiary,
        description:
            'Access personalized workout plans, log exercises, and track your fitness progress.',
      );
}

/// Nutrition tab placeholder.
class NutritionPlaceholderPage extends StatelessWidget {
  const NutritionPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const TabPlaceholderPage(
        title: 'Nutrition',
        icon: Icons.restaurant_rounded,
        color: AppColors.warning,
        description:
            'Log meals, track macros, discover healthy recipes, and meet your calorie goals.',
      );
}

/// Profile tab placeholder.
class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const TabPlaceholderPage(
        title: 'Profile',
        icon: Icons.person_rounded,
        color: AppColors.chartSky,
        description:
            'Manage your account, health goals, preferences, and subscription.',
      );
}

/// AI Assistant placeholder.
class AiAssistantPlaceholderPage extends StatelessWidget {
  const AiAssistantPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Health Coach',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.tertiary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'AI Health Coach',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your personalized AI health assistant is coming soon.\nGet smart insights, meal suggestions, and workout advice.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.tertiary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '✨  Powered by Gemini AI',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.tertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

