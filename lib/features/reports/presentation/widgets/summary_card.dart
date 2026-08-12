import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SUMMARY CARD
// ══════════════════════════════════════════════════════════════════════════════

/// KPI metric card with animated counter and trend badge.
///
/// Animates from 0 to [value] on first build using a [TweenAnimationBuilder].
/// Use [heroTag] to enable hero transitions between pages.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.isDark,
    super.key,
    this.delta,
    this.deltaLabel,
    this.heroTag,
    this.subtitle,
    this.onTap,
    this.formatValue,
    this.positiveIsGood = true,
  });

  final String title;

  /// The numeric value to display (animated from 0).
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isDark;

  /// Change vs. prior period. Positive = improvement, negative = decline.
  final double? delta;
  final String? deltaLabel;

  final String? heroTag;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Optional custom formatter. If null, uses [_defaultFormat].
  final String Function(double)? formatValue;

  /// When false, a positive delta is shown in red (e.g. blood sugar rising).
  final bool positiveIsGood;

  String _defaultFormat(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: AppSpacing.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (delta != null)
                  _TrendBadge(
                    delta: delta!,
                    label: deltaLabel,
                    positiveIsGood: positiveIsGood,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Animated value
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: (formatValue ?? _defaultFormat)(v),
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTypography.captionText.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark.withOpacity(0.7)
                      : AppColors.textSecondaryLight.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: card);
    }
    return card;
  }
}

// ── Trend Badge ───────────────────────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({
    required this.delta,
    this.label,
    this.positiveIsGood = true,
  });
  final double delta;
  final String? label;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = isGood ? const Color(0xFF00C896) : AppColors.error;
    final icon = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final text = label ??
        '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: AppTypography.captionText.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TREND INDICATOR (standalone)
// ══════════════════════════════════════════════════════════════════════════════

/// Standalone coloured trend arrow with percentage delta label.
class TrendIndicator extends StatelessWidget {
  const TrendIndicator({
    required this.delta,
    super.key,
    this.label,
    this.positiveIsGood = true,
    this.compact = false,
  });

  final double delta;
  final String? label;

  /// When false, a positive delta is shown in red (e.g. blood sugar increasing).
  final bool positiveIsGood;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    final isGood = positiveIsGood ? isUp : !isUp;
    final color = isGood ? const Color(0xFF00C896) : AppColors.error;
    final icon =
        isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: compact ? 14 : 18),
        const SizedBox(width: 4),
        Text(
          label ??
              '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}${delta.abs() < 10 ? '' : ''}',
          style: (compact
                  ? AppTypography.captionText
                  : AppTypography.bodySmall)
              .copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANALYTICS CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Gradient category card used on the Reports Dashboard.
class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradientColors,
    required this.onTap,
    super.key,
    this.score,
    this.isDark = false,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final double? score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Text(
                      '${score!.toInt()}',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'View Analytics',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON WIDGET
// ══════════════════════════════════════════════════════════════════════════════

/// "This Period vs. Last Period" comparison banner.
class ComparisonWidget extends StatelessWidget {
  const ComparisonWidget({
    required this.label,
    required this.current,
    required this.previous,
    required this.unit,
    required this.color,
    required this.isDark,
    super.key,
    this.positiveIsGood = true,
  });

  final String label;
  final double current;
  final double previous;
  final String unit;
  final Color color;
  final bool isDark;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final delta = previous == 0 ? 0.0 : (current - previous) / previous * 100;
    final isUp = delta >= 0;
    final isGood = positiveIsGood ? isUp : !isUp;
    final trendColor = isGood ? const Color(0xFF00C896) : AppColors.error;
    final maxVal = math.max(current, previous);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TrendIndicator(
                delta: delta,
                label:
                    '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}%',
                positiveIsGood: positiveIsGood,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Current bar
          _ComparisonBar(
            label: 'This Period',
            value: current,
            maxVal: maxVal,
            unit: unit,
            color: color,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Previous bar
          _ComparisonBar(
            label: 'Last Period',
            value: previous,
            maxVal: maxVal,
            unit: unit,
            color: color.withOpacity(0.4),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxVal,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  final String label;
  final double value;
  final double maxVal;
  final String unit;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = maxVal == 0 ? 0.0 : (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 56,
          child: Text(
            '${value.toStringAsFixed(0)} $unit',
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

