import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_record_entity.dart';
import '../providers/health_providers.dart';

/// Health History screen — date-grouped timeline of health events.
class HealthHistoryPage extends ConsumerWidget {
  const HealthHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(healthHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by date (e.g. "28 Jul 2026")
    final grouped = <String, List<HealthHistoryItem>>{};
    for (final item in items) {
      final key = DateFormat('dd MMM yyyy').format(item.timestamp);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Health History',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: grouped.isEmpty
          ? _Empty(isDark: isDark)
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                for (final entry in grouped.entries) ...[
                  // Date group header
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xs,
                    ),
                    child: Text(
                      entry.key,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  // Timeline items
                  ...entry.value.asMap().entries.map(
                    (e) {
                      final item = e.value;
                      final isLast =
                          e.key == entry.value.length - 1;
                      return _TimelineItem(
                        item: item,
                        isLast: isLast,
                        isDark: isDark,
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
    );
  }
}

// ── Timeline Item ─────────────────────────────────────────────────────────────

class _TimelineItem extends StatefulWidget {
  const _TimelineItem({
    required this.item,
    required this.isLast,
    required this.isDark,
  });

  final HealthHistoryItem item;
  final bool isLast;
  final bool isDark;

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> {
  bool _expanded = false;

  Color get _dotColor => switch (widget.item.type) {
        HealthRecordType.labReport => AppColors.chartCoral,
        HealthRecordType.prescription => AppColors.success,
        HealthRecordType.imaging => AppColors.chartSky,
        HealthRecordType.consultation => AppColors.tertiary,
        HealthRecordType.vaccination => AppColors.chartAmber,
        HealthRecordType.other => AppColors.chartIndigo,
      };

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('hh:mm a').format(widget.item.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _dotColor.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: widget.isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  left: AppSpacing.sm,
                  bottom: widget.isLast ? 0 : AppSpacing.sm,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: widget.isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                    width: AppSpacing.borderThin,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: widget.isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.item.value} ${widget.item.unit}',
                          style: AppTypography.titleSmall.copyWith(
                            color: _dotColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: widget.isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight,
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          timeStr,
                          style: AppTypography.captionText.copyWith(
                            color: widget.isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight,
                          ),
                        ),
                      ),
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No history yet',
            style: AppTypography.titleMedium.copyWith(
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

