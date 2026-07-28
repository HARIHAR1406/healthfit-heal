import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_record_entity.dart';
import '../providers/health_providers.dart';
import '../widgets/health_action_tile.dart';

/// Medical Records screen — searchable, filterable list.
class MedicalRecordsPage extends ConsumerWidget {
  const MedicalRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredMedicalRecordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Medical Records',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              onChanged: (q) =>
                  ref.read(medicalRecordsSearchProvider.notifier).state = q,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Search records, doctors, tags…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: const BorderSide(
                      color: AppColors.secondary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
          ),

          // ── Filter Chips ───────────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: Consumer(
              builder: (context, ref, _) {
                final selected = ref.watch(medicalRecordsFilterProvider);
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: selected == null,
                      onTap: () => ref
                          .read(medicalRecordsFilterProvider.notifier)
                          .state = null,
                      isDark: isDark,
                    ),
                    ...HealthRecordType.values.map((t) => _FilterChip(
                          label: t.label,
                          selected: selected == t,
                          onTap: () => ref
                              .read(medicalRecordsFilterProvider.notifier)
                              .state = t,
                          isDark: isDark,
                        )),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Records List ───────────────────────────────────────────────────
          Expanded(
            child: records.isEmpty
                ? _EmptyState(isDark: isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    itemCount: records.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => MedicalRecordTile(
                      record: records[i],
                      onTap: () => _showRecordDetails(context, records[i], isDark),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(
      BuildContext context, HealthRecordEntity record, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordDetailSheet(record: record, isDark: isDark),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.12)
              : isDark
                  ? AppColors.cardDark
                  : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.secondary
                : isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected
                ? AppColors.secondary
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 64,
            color: isDark
                ? AppColors.textHintDark
                : AppColors.textHintLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No records found',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            'Try adjusting the search or filter.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textHintDark
                  : AppColors.textHintLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Record Detail Sheet ────────────────────────────────────────────────────────

class _RecordDetailSheet extends StatelessWidget {
  const _RecordDetailSheet({required this.record, required this.isDark});
  final HealthRecordEntity record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            record.title,
            style: AppTypography.titleLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            record.type.label,
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary),
          ),
          const SizedBox(height: AppSpacing.md),

          if (record.doctorName != null)
            _DetailRow(
                icon: Icons.person_rounded,
                label: record.doctorName!,
                isDark: isDark),
          if (record.hospitalName != null)
            _DetailRow(
                icon: Icons.local_hospital_rounded,
                label: record.hospitalName!,
                isDark: isDark),
          _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: record.date.toString().split(' ').first,
              isDark: isDark),

          if (record.notes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                record.notes!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ),
          ],

          if (record.hasAttachment) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded,
                      color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Attachment available\n(file_picker integration required)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon,
              size: AppSpacing.iconSm,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
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
