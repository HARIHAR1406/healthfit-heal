import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CHART CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Styled container for all analytics charts.
///
/// Provides:
/// - Consistent card appearance (background, border, shadow)
/// - Title + optional subtitle header
/// - Optional legend row
/// - Loading shimmer state
/// - Error fallback state
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.child,
    required this.isDark,
    super.key,
    this.subtitle,
    this.height = 220,
    this.legend,
    this.isLoading = false,
    this.error,
    this.action,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool isDark;
  final double height;
  final List<LegendItem>? legend;
  final bool isLoading;
  final String? error;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: padding ??
                const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                    AppSpacing.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTypography.captionText.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),

          // ── Legend ─────────────────────────────────────────────────────────
          if (legend != null && legend!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: legend!.map((l) => _LegendDot(item: l)).toList(),
              ),
            ),

          // ── Chart Body ─────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? _ShimmerBox(height: height, isDark: isDark)
                : error != null
                    ? _ErrorBox(message: error!, height: height, isDark: isDark)
                    : SizedBox(height: height, child: child),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LEGEND ITEM
// ══════════════════════════════════════════════════════════════════════════════

/// Data class for chart legend entries.
class LegendItem {
  const LegendItem({required this.label, required this.color});
  final String label;
  final Color color;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.item});
  final LegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          item.label,
          style: AppTypography.captionText.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHIMMER PLACEHOLDER
// ══════════════════════════════════════════════════════════════════════════════

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.height, required this.isDark});
  final double height;
  final bool isDark;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
          ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value * 2, 0),
            end: Alignment(1 + _anim.value * 2, 0),
            colors: widget.isDark
                ? [
                    AppColors.shimmerBaseDark,
                    AppColors.shimmerHighlightDark,
                    AppColors.shimmerBaseDark,
                  ]
                : [
                    AppColors.shimmerBase,
                    AppColors.shimmerHighlight,
                    AppColors.shimmerBase,
                  ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ERROR BOX
// ══════════════════════════════════════════════════════════════════════════════

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(
      {required this.message, required this.height, required this.isDark});
  final String message;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: AppColors.error.withOpacity(0.4), size: 40),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Failed to load chart',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REPORT TILE
// ══════════════════════════════════════════════════════════════════════════════

/// Simple row tile used inside section lists on the dashboard.
class ReportTile extends StatelessWidget {
  const ReportTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.isDark,
    super.key,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      leading: leading,
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
    );
  }
}

