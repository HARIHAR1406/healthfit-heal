import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/report_filter.dart';
import '../providers/reports_providers.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPORT FILTER BAR
// ══════════════════════════════════════════════════════════════════════════════

/// Horizontally scrolling filter chip row for date range selection.
///
/// When [DateFilter.custom] is tapped, opens a [DateRangePicker] dialog.
class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({
    super.key,
    this.onFilterChanged,
  });

  /// Optional callback invoked after filter changes so pages can reload data.
  final VoidCallback? onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(analyticsFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: DateFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final filter = DateFilter.values[i];
          final isActive = filter == active.filter;

          return _FilterChip(
            label: filter.label,
            isActive: isActive,
            isDark: isDark,
            onTap: () => _onTap(context, ref, filter, active),
          );
        },
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    DateFilter filter,
    ActiveFilter current,
  ) async {
    if (filter == DateFilter.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now(),
        initialDateRange: current.customRange != null
            ? DateTimeRange(
                start: current.customRange!.start,
                end: current.customRange!.end,
              )
            : null,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        ),
      );
      if (range == null) return;
      ref.read(analyticsFilterProvider.notifier).state = ActiveFilter(
        filter: DateFilter.custom,
        customRange: CustomDateRange(
          start: range.start,
          end: range.end,
        ),
      );
    } else {
      ref.read(analyticsFilterProvider.notifier).state =
          ActiveFilter(filter: filter);
    }
    onFilterChanged?.call();
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.25),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.textPrimaryDark : AppColors.primary),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
