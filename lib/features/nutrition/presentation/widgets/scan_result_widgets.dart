import 'package:flutter/material.dart';

import '../../../../core/trust/domain/entities/data_source_info.dart';
import '../../../../core/trust/domain/entities/meal_nutrition_result.dart';
import '../../../../core/trust/domain/entities/trusted_recommendation.dart';
import '../../../../core/trust/health_rules/health_classification.dart';
import '../../../../core/trust/recommendation/recommendation_context.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

// ── Meal Nutrition Summary Card ────────────────────────────────────────────────

/// Summary card showing total macros for the entire scanned meal.
class MealNutritionSummaryCard extends StatelessWidget {
  const MealNutritionSummaryCard({
    required this.mealResult,
    required this.isDark,
    super.key,
  });

  final MealNutritionResult mealResult;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.primaryDark.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Summary',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Calorie hero
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mealResult.totalCalories.toStringAsFixed(0),
                style: AppTypography.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 48,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kcal',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: Colors.white24, thickness: 0.5),
          const SizedBox(height: AppSpacing.sm),

          // Macros row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroChip(
                label: 'Protein',
                value: mealResult.totalProteinG,
                unit: 'g',
              ),
              _MacroChip(
                label: 'Carbs',
                value: mealResult.totalCarbsG,
                unit: 'g',
              ),
              _MacroChip(
                label: 'Fat',
                value: mealResult.totalFatG,
                unit: 'g',
              ),
              if (mealResult.totalFiberG > 0)
                _MacroChip(
                  label: 'Fiber',
                  value: mealResult.totalFiberG,
                  unit: 'g',
                ),
            ],
          ),

          // Data source attribution
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                'Trusted nutrition data',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value != null ? '${value!.toStringAsFixed(1)}$unit' : 'N/A',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ── Per-food Nutrition Row ─────────────────────────────────────────────────────

/// Expanded tile showing nutrition breakdown for a single food item.
class FoodNutritionTile extends StatelessWidget {
  const FoodNutritionTile({
    required this.result,
    required this.isDark,
    super.key,
  });

  final FoodNutritionResult result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Use calculatedFacts for the actual per-serving values
    final facts = result.calculatedFacts;
    final v = result.verifiedNutrition;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                result.foodName,
                style: AppTypography.bodyLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Data source badge
            _SourceBadge(source: v.source, isDark: isDark),
          ],
        ),
        subtitle: Text(
          _calorieSubtitle(result),
          style: AppTypography.bodySmall.copyWith(color: secondaryColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                const Divider(),
                _NutrientRow(
                    label: 'Protein', value: facts.proteinG, unit: 'g', isDark: isDark),
                _NutrientRow(
                    label: 'Carbohydrates', value: facts.carbsG, unit: 'g', isDark: isDark),
                _NutrientRow(
                    label: 'Fat', value: facts.fatG, unit: 'g', isDark: isDark),
                if (facts.fiberG > 0)
                  _NutrientRow(
                      label: 'Fibre', value: facts.fiberG, unit: 'g', isDark: isDark),
                if (facts.sugarG > 0)
                  _NutrientRow(
                      label: 'Sugar', value: facts.sugarG, unit: 'g', isDark: isDark),
                if (facts.sodiumMg > 0)
                  _NutrientRow(
                      label: 'Sodium', value: facts.sodiumMg, unit: 'mg', isDark: isDark),
                if (facts.iron > 0)
                  _NutrientRow(
                      label: 'Iron (% DV)', value: facts.iron, unit: '%', isDark: isDark),
                if (facts.calcium > 0)
                  _NutrientRow(
                      label: 'Calcium (% DV)', value: facts.calcium, unit: '%', isDark: isDark),
                if (v.potassiumMg != null)
                  _NutrientRow(
                      label: 'Potassium', value: v.potassiumMg, unit: 'mg', isDark: isDark),
                // Data provenance
                const SizedBox(height: AppSpacing.xs),
                _ProvenanceRow(source: v.source, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calorieSubtitle(FoodNutritionResult result) {
    return '${result.calories.toStringAsFixed(0)} kcal';
  }
}

// ── Nutrient Row ───────────────────────────────────────────────────────────────

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  final String label;
  final double? value;
  final String unit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  AppTypography.bodyMedium.copyWith(color: secondaryColor),
            ),
          ),
          // NEVER show 0 for unavailable data — show "Not available"
          Text(
            value != null
                ? '${value!.toStringAsFixed(value! < 1 ? 2 : 1)} $unit'
                : 'Not available',
            style: AppTypography.bodyMedium.copyWith(
              color: value != null ? textColor : secondaryColor,
              fontWeight:
                  value != null ? FontWeight.w500 : FontWeight.w400,
              fontStyle:
                  value == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Provenance Row ─────────────────────────────────────────────────────────────

class _ProvenanceRow extends StatelessWidget {
  const _ProvenanceRow({required this.source, required this.isDark});
  final DataSourceInfo source;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _sourceIcon(source.sourceType),
          size: 12,
          color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Source: ${source.sourceName ?? source.sourceType.label} · '
            '${source.externalId ?? source.verificationStatus.label}',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  IconData _sourceIcon(DataSourceType type) => switch (type) {
        DataSourceType.usdaFoodData => Icons.science_outlined,
        DataSourceType.openFoodFacts => Icons.public_outlined,
        DataSourceType.nutritionix => Icons.restaurant_outlined,
        DataSourceType.appSeedData => Icons.storage_outlined,
        DataSourceType.userEntered => Icons.person_outline,
        DataSourceType.calculated => Icons.calculate_outlined,
        DataSourceType.externalApi => Icons.api_outlined,
        DataSourceType.unknown => Icons.help_outline,
      };
}

// ── Source Badge ───────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, required this.isDark});
  final DataSourceInfo source;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (source.sourceType) {
      DataSourceType.usdaFoodData ||
      DataSourceType.openFoodFacts ||
      DataSourceType.nutritionix ||
      DataSourceType.appSeedData =>
        (AppColors.success, 'Verified'),
      DataSourceType.calculated => (AppColors.info, 'Calculated'),
      DataSourceType.userEntered => (AppColors.tertiary, 'User'),
      DataSourceType.externalApi => (AppColors.warning, 'External'),
      DataSourceType.unknown => (AppColors.textSecondaryLight, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Unresolvable Foods Warning ─────────────────────────────────────────────────

class UnresolvableFoodsWarning extends StatelessWidget {
  const UnresolvableFoodsWarning({
    required this.items,
    required this.isDark,
    super.key,
  });

  final List<String> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nutrition data unavailable for:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...items.map((name) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  '• $name',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'These items could not be matched in our trusted food database. '
            'The nutrition totals do not include them.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommendation Card ────────────────────────────────────────────────────────

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    required this.recommendation,
    required this.context,
    required this.isDark,
    super.key,
  });

  final TrustedRecommendation recommendation;
  final RecommendationContext context;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasCritical = this.context.hasCriticalFlags;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: hasCritical
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Smart Recommendation',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Title
          Text(
            recommendation.title,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // AI explanation (if available) or disclaimer
          if (recommendation.hasAiExplanation) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'AI Explanation',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.aiExplanation!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              recommendation.disclaimer,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Safety warnings (from recommendation.safetyWarnings)
          if (recommendation.hasSafetyWarnings) ...[
            const SizedBox(height: AppSpacing.sm),
            ...recommendation.safetyWarnings
                .map((w) => _SafetyWarningRow(message: w, isDark: isDark)),
          ],

          // Safety flags (from RecommendationContext)
          if (this.context.requiresProfessionalConsultation) ...[
            const SizedBox(height: AppSpacing.sm),
            _DisclaimerBanner(isDark: isDark),
          ],

          // Data provenance note
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Based on verified nutrition data · '
                  'Not a medical recommendation',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.flag, required this.isDark});
  final SafetyFlag flag;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              flag.message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services_outlined,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Please consult a qualified healthcare professional '
              'before making dietary decisions based on this information.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Safety Warning Row ─────────────────────────────────────────────────────────

class _SafetyWarningRow extends StatelessWidget {
  const _SafetyWarningRow({required this.message, required this.isDark});
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_outlined,
              size: 14,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health Flags Summary ───────────────────────────────────────────────────────

/// Shows health rule classifications (from HealthRuleEngine) with colored chips.
class HealthFlagsRow extends StatelessWidget {
  const HealthFlagsRow({
    required this.classifications,
    required this.isDark,
    super.key,
  });

  final List<HealthClassification> classifications;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (classifications.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: classifications.map((c) => _HealthChip(c: c)).toList(),
    );
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.c});
  final HealthClassification c;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(c.level);
    return Chip(
      label: Text(
        '${c.metricType}: ${c.level.label}',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _levelColor(HealthLevel level) => switch (level) {
        HealthLevel.normal => AppColors.success,
        HealthLevel.needsAttention => AppColors.warning,
        HealthLevel.highRisk => AppColors.error,
        HealthLevel.critical => AppColors.error,
      };
}

// ── Goal Context Banner ────────────────────────────────────────────────────────

/// Shows whether user goal context was available for the recommendation.
class GoalContextBanner extends StatelessWidget {
  const GoalContextBanner({
    required this.context,
    required this.isDark,
    super.key,
  });

  final RecommendationContext context;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasGoals = this.context.userGoals.isNotEmpty;

    if (hasGoals) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.info),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Nutrition goals are not set. '
              'This recommendation uses general guidelines only.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _formatValue(double? value) {
  if (value == null) return '—';
  return value.toStringAsFixed(0);
}
