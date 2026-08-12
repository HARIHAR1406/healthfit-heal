import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/quick_action_entity.dart';

/// A single quick-action tile in the shortcut grid.
///
/// Tapping navigates to [QuickActionEntity.route].
class QuickActionCard extends StatefulWidget {
  const QuickActionCard({required this.action, super.key});

  final QuickActionEntity action;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  // ── Visual mapping ────────────────────────────────────────────────────────

  IconData get _icon => switch (widget.action.type) {
        QuickActionType.health => Icons.monitor_heart_rounded,
        QuickActionType.fitness => Icons.fitness_center_rounded,
        QuickActionType.nutrition => Icons.restaurant_rounded,
        QuickActionType.aiAssistant => Icons.auto_awesome_rounded,
        QuickActionType.reports => Icons.bar_chart_rounded,
        QuickActionType.medication => Icons.medication_rounded,
      };

  Color get _color => switch (widget.action.type) {
        QuickActionType.health => AppColors.chartCoral,
        QuickActionType.fitness => AppColors.tertiary,
        QuickActionType.nutrition => AppColors.chartAmber,
        QuickActionType.aiAssistant => AppColors.chartPink,
        QuickActionType.reports => AppColors.chartSky,
        QuickActionType.medication => AppColors.success,
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color;

    return Semantics(
      label: '${widget.action.title}. ${widget.action.subtitle}',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.reverse(),
        onTapUp: (_) {
          _scaleCtrl.forward();
          context.push(widget.action.route);
        },
        onTapCancel: () => _scaleCtrl.forward(),
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: AppSpacing.borderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : color.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(_icon, color: color, size: AppSpacing.iconMd),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Title
                Text(
                  widget.action.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                // Subtitle
                Text(
                  widget.action.subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Arrow indicator
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: color,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2-column grid of [QuickActionCard] shortcuts.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.actions, super.key});

  final List<QuickActionEntity> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => QuickActionCard(action: actions[i]),
    );
  }
}
