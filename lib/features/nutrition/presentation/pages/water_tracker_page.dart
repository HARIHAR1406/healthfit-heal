import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_state.dart';
import '../widgets/nutrition_widgets.dart';

/// Water tracker with progress ring, quick-add buttons, and history.
class WaterTrackerPage extends ConsumerWidget {
  const WaterTrackerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(waterTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Water Tracker',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Semantics(
            label: 'Add custom water amount',
            button: true,
            child: IconButton(
              icon: Icon(Icons.edit_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              onPressed: () =>
                  _showCustomAmountDialog(context, ref),
              tooltip: 'Custom Amount',
            ),
          ),
        ],
      ),
      body: switch (waterState) {
        WaterLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        WaterError(:final message) => Center(child: Text(message)),
        WaterLoaded(:final tracker) => _WaterBody(
            tracker: tracker,
            isDark: isDark,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _showCustomAmountDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Custom Amount'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ml = int.tryParse(ctrl.text);
              if (ml != null && ml > 0) {
                ref.read(waterTrackerProvider.notifier).addWater(ml);
                HapticFeedback.lightImpact();
              }
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.chartSky),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _WaterBody extends ConsumerWidget {
  const _WaterBody({required this.tracker, required this.isDark});
  final WaterTrackerEntity tracker;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Hero Progress Ring
        Center(
          child: Column(
            children: [
              WaterProgressWidget(
                currentMl: tracker.totalMl,
                goalMl: tracker.goalMl,
                size: 180,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (tracker.goalMet)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '🎉 Daily goal reached!',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Stats Row
        Row(
          children: [
            Expanded(
              child: _WaterStatCard(
                icon: Icons.water_drop_rounded,
                label: 'Consumed',
                value:
                    '${(tracker.totalMl / 1000).toStringAsFixed(2)} L',
                color: AppColors.chartSky,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _WaterStatCard(
                icon: Icons.local_drink_rounded,
                label: 'Remaining',
                value:
                    '${(tracker.remainingMl / 1000).toStringAsFixed(2)} L',
                color: AppColors.tertiary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Quick Add Buttons
        Text(
          'Quick Add',
          style: AppTypography.titleMedium.copyWith(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: kWaterQuickAmounts.map((ml) {
            return Semantics(
              label: 'Add $ml millilitres',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(waterTrackerProvider.notifier).addWater(ml);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.chartSky.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                        color: AppColors.chartSky.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💧', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(
                        '$ml ml',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.chartSky,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Intake History
        Row(
          children: [
            Expanded(
              child: Text(
                'Today\'s Intake',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${tracker.entries.length} entries',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (tracker.entries.isEmpty)
          Center(
            child: Text(
              'No intake logged yet. Start hydrating! 💧',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          )
        else
          ...tracker.entries.reversed.map(
            (e) => Dismissible(
              key: Key(e.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) =>
                  ref.read(waterTrackerProvider.notifier).removeEntry(e.id),
              background: Container(
                color: AppColors.error.withValues(alpha: 0.15),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: const Icon(Icons.delete_rounded,
                    color: AppColors.error),
              ),
              child: _WaterEntryTile(entry: e, isDark: isDark),
            ),
          ),

        // Reminder placeholder
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hydration Reminders',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Coming soon — set reminders to stay hydrated.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _WaterStatCard extends StatelessWidget {
  const _WaterStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterEntryTile extends StatelessWidget {
  const _WaterEntryTile({required this.entry, required this.isDark});
  final WaterIntakeEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(entry.loggedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: AppSpacing.borderThin,
          ),
        ),
        child: Row(
          children: [
            const Text('💧', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                timeStr,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Text(
              '${entry.amountMl} ml',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.chartSky,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
