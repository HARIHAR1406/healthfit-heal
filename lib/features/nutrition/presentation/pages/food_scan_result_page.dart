import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/trust/domain/entities/meal_nutrition_result.dart';
import '../../../../core/trust/domain/entities/trusted_recommendation.dart';
import '../../../../core/trust/recommendation/recommendation_context.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/detected_food.dart';
import '../providers/food_scanner_providers.dart';
import '../widgets/scan_result_widgets.dart';

/// Final result page — shows trusted nutrition data + recommendation.
///
/// This page is a pure presentation layer. All data was calculated by the
/// Phase 12 pipeline before this page was pushed.
///
/// Layout:
///   - Meal summary card (calories + macros)
///   - Goal context banner (if goals unavailable)
///   - Unresolvable foods warning (if any items were not in DB)
///   - Per-food nutrition tiles (expandable)
///   - Health flags row (HealthRuleEngine output)
///   - Recommendation card (verified insight)
///   - "Log to Meal" / "Done" actions
class FoodScanResultPage extends ConsumerWidget {
  const FoodScanResultPage({
    required this.imageBytes,
    required this.confirmedItems,
    required this.mealResult,
    required this.recommendation,
    required this.context,
    super.key,
  });

  final Uint8List imageBytes;
  final List<ConfirmedFoodItem> confirmedItems;
  final MealNutritionResult mealResult;
  final TrustedRecommendation recommendation;
  final RecommendationContext context;

  @override
  Widget build(BuildContext widgetContext, WidgetRef ref) {
    final isDark =
        Theme.of(widgetContext).brightness == Brightness.dark;
    final unresolvable = mealResult.unresolvableItems;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing app bar with food image ─────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary.withOpacity(0.2),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // Gradient overlay for text legibility
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                'Nutrition Results',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => widgetContext.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                tooltip: 'Share',
                onPressed: () {
                  // Share action (future implementation)
                  ScaffoldMessenger.of(widgetContext).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
              ),
            ],
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Provider attribution
                _ProviderAttribution(
                  providerName: ref.watch(visionProviderNameProvider),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),

                // Meal summary card (gradient hero)
                MealNutritionSummaryCard(
                  mealResult: mealResult,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),

                // Goal context warning if goals unavailable
                GoalContextBanner(
                  context: context,
                  isDark: isDark,
                ),

                // Unresolvable foods warning
                if (unresolvable.isNotEmpty) ...[
                  UnresolvableFoodsWarning(
                    items: unresolvable,
                    isDark: isDark,
                  ),
                ],

                // Section: Per-food breakdown
                _SectionTitle(
                  title: 'Food Breakdown',
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...mealResult.itemResults.map(
                  (result) => FoodNutritionTile(
                    result: result,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Section: Recommendation
                _SectionTitle(
                  title: 'Recommendation',
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                RecommendationCard(
                  recommendation: recommendation,
                  context: context,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions
                _ActionBar(isDark: isDark),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Provider Attribution ───────────────────────────────────────────────────────

class _ProviderAttribution extends StatelessWidget {
  const _ProviderAttribution({
    required this.providerName,
    required this.isDark,
  });

  final String providerName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_user_outlined,
            size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Recognized by $providerName · '
            'Nutrition from trusted database',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Title ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Action Bar ─────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Log to Meal (future: wires into nutrition tracker)
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeightMd,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Log to Meal'),
            onPressed: () {
              // Future: save to DailyNutritionEntity via NutritionNotifier
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meal logging coming in Phase 14'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Scan another food
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeightMd,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan Another Food'),
            onPressed: () {
              // Reset scanner and go back to scanner page
              ref.read(foodScannerProvider.notifier).reset();
              context.go(RouteNames.foodScanner);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 1.5,
              ),
              foregroundColor: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Done — go back to nutrition dashboard
        TextButton(
          onPressed: () => context.go(RouteNames.nutrition),
          child: Text(
            'Done',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
